package body Midpoint_Circle is

   function Implicit_Circle_Function
     (Pt     : Point;
      Center : Point;
      Radius : Radius_Type) return Long_Long_Integer
   is
      DX : constant Long_Long_Integer := Long_Long_Integer (Pt.X) - Long_Long_Integer (Center.X);
      DY : constant Long_Long_Integer := Long_Long_Integer (Pt.Y) - Long_Long_Integer (Center.Y);
      R  : constant Long_Long_Integer := Long_Long_Integer (Radius);
   begin
      return (DX * DX) + (DY * DY) - (R * R);
   end Implicit_Circle_Function;

   function Chebyshev_Distance (P1, P2 : Point) return Coordinate is
      DX : constant Coordinate := abs (P1.X - P2.X);
      DY : constant Coordinate := abs (P1.Y - P2.Y);
   begin
      return (if DX > DY then DX else DY);
   end Chebyshev_Distance;

   function Classify_Point
     (Pt     : Point;
      Center : Point;
      Radius : Radius_Type) return Location_Type
   is
      Val : constant Long_Long_Integer := Implicit_Circle_Function (Pt, Center, Radius);
   begin
      if Val < 0 then
         return Inside;
      elsif Val = 0 then
         return On_Boundary;
      else
         return Outside;
      end if;
   end Classify_Point;

   procedure Generate_Circle_Outline
     (Center : Point;
      Radius : Radius_Type;
      Output : out Point_Array;
      Count  : out Natural)
   is
      X, Y : Coordinate;
      D    : Long_Long_Integer;
      Idx  : Positive := Output'First;

      procedure Emit_Point (PX, PY : Coordinate) is
      begin
         if Idx > Output'Last then
            raise Buffer_Too_Small;
         end if;
         Output (Idx) := (X => PX, Y => PY);
         Idx := Idx + 1;
      end Emit_Point;

      procedure Emit_8_Symmetric (CX, CY, Off_X, Off_Y : Coordinate) is
      begin
         Emit_Point (CX + Off_X, CY + Off_Y);
         Emit_Point (CX - Off_X, CY + Off_Y);
         Emit_Point (CX + Off_X, CY - Off_Y);
         Emit_Point (CX - Off_X, CY - Off_Y);
         Emit_Point (CX + Off_Y, CY + Off_X);
         Emit_Point (CX - Off_Y, CY + Off_X);
         Emit_Point (CX + Off_Y, CY - Off_X);
         Emit_Point (CX - Off_Y, CY - Off_X);
      end Emit_8_Symmetric;
   begin
      if Radius = 0 then
         Output (Output'First) := Center;
         Count := 1;
         return;
      end if;

      X := 0;
      Y := Coordinate (Radius);
      -- Initial decision parameter: d = 1 - R (derived from (5/4) - R for integer steps)
      D := 1 - Long_Long_Integer (Radius);

      while X <= Y loop
         Emit_8_Symmetric (Center.X, Center.Y, X, Y);
         X := X + 1;
         if D < 0 then
            D := D + 2 * Long_Long_Integer (X) + 1;
         else
            Y := Y - 1;
            D := D + 2 * (Long_Long_Integer (X) - Long_Long_Integer (Y)) + 1;
         end if;
      end loop;

      Count := Idx - Output'First;
   end Generate_Circle_Outline;

   procedure Generate_Circle_Jesko
     (Center : Point;
      Radius : Radius_Type;
      Output : out Point_Array;
      Count  : out Natural)
   is
      T1, T2 : Long_Long_Integer;
      X, Y   : Coordinate;
      Idx    : Positive := Output'First;

      procedure Emit_Point (PX, PY : Coordinate) is
      begin
         if Idx > Output'Last then
            raise Buffer_Too_Small;
         end if;
         Output (Idx) := (X => PX, Y => PY);
         Idx := Idx + 1;
      end Emit_Point;

      procedure Emit_8_Symmetric (CX, CY, Off_X, Off_Y : Coordinate) is
      begin
         Emit_Point (CX + Off_X, CY + Off_Y);
         Emit_Point (CX - Off_X, CY + Off_Y);
         Emit_Point (CX + Off_X, CY - Off_Y);
         Emit_Point (CX - Off_X, CY - Off_Y);
         Emit_Point (CX + Off_Y, CY + Off_X);
         Emit_Point (CX - Off_Y, CY + Off_X);
         Emit_Point (CX + Off_Y, CY - Off_X);
         Emit_Point (CX - Off_Y, CY - Off_X);
      end Emit_8_Symmetric;
   begin
      if Radius = 0 then
         Output (Output'First) := Center;
         Count := 1;
         return;
      end if;

      -- Jesko's variant computes t1 = R / 16 and keeps track of delta differences
      T1 := Long_Long_Integer (Radius) / 16;
      X  := Coordinate (Radius);
      Y  := 0;

      while X >= Y loop
         Emit_8_Symmetric (Center.X, Center.Y, X, Y);
         Y := Y + 1;
         T1 := T1 + Long_Long_Integer (Y);
         T2 := T1 - Long_Long_Integer (X);
         if T2 >= 0 then
            T1 := T2;
            X := X - 1;
         end if;
      end loop;

      Count := Idx - Output'First;
   end Generate_Circle_Jesko;

   procedure Generate_Filled_Circle_Spans
     (Center : Point;
      Radius : Radius_Type;
      Output : out Span_Array;
      Count  : out Natural)
   is
      X, Y      : Coordinate;
      D         : Long_Long_Integer;
      Idx       : Positive := Output'First;
      Last_Y_Op : Coordinate;

      procedure Emit_Span (Y_Coord, Min_X, Max_X : Coordinate) is
      begin
         if Idx > Output'Last then
            raise Buffer_Too_Small;
         end if;
         Output (Idx) := (Y => Y_Coord, Left_X => Min_X, Right_X => Max_X);
         Idx := Idx + 1;
      end Emit_Span;
   begin
      if Radius = 0 then
         Output (Output'First) := (Y => Center.Y, Left_X => Center.X, Right_X => Center.X);
         Count := 1;
         return;
      end if;

      X := 0;
      Y := Coordinate (Radius);
      D := 1 - Long_Long_Integer (Radius);

      -- Emit the central horizontal span
      Emit_Span (Center.Y, Center.X - Coordinate (Radius), Center.X + Coordinate (Radius));
      Last_Y_Op := 0;

      while X < Y loop
         X := X + 1;
         if D < 0 then
            D := D + 2 * Long_Long_Integer (X) + 1;
         else
            Y := Y - 1;
            D := D + 2 * (Long_Long_Integer (X) - Long_Long_Integer (Y)) + 1;
         end if;

         -- To prevent double-drawing horizontal scanlines, only emit scanlines when Y changes
         if Y /= Last_Y_Op and Y > 0 then
            Emit_Span (Center.Y + Y, Center.X - X, Center.X + X);
            Emit_Span (Center.Y - Y, Center.X - X, Center.X + X);
            Last_Y_Op := Y;
         end if;
      end loop;

      Count := Idx - Output'First;
   end Generate_Filled_Circle_Spans;

   procedure Draw_Circle (Center : Point; Radius : Radius_Type) is
      X, Y : Coordinate;
      D    : Long_Long_Integer;

      procedure Plot_8 (CX, CY, Off_X, Off_Y : Coordinate) is
      begin
         Put_Pixel (CX + Off_X, CY + Off_Y);
         Put_Pixel (CX - Off_X, CY + Off_Y);
         Put_Pixel (CX + Off_X, CY - Off_Y);
         Put_Pixel (CX - Off_X, CY - Off_Y);
         Put_Pixel (CX + Off_Y, CY + Off_X);
         Put_Pixel (CX - Off_Y, CY + Off_X);
         Put_Pixel (CX + Off_Y, CY - Off_X);
         Put_Pixel (CX - Off_Y, CY - Off_X);
      end Plot_8;
   begin
      if Radius = 0 then
         Put_Pixel (Center.X, Center.Y);
         return;
      end if;

      X := 0;
      Y := Coordinate (Radius);
      D := 1 - Long_Long_Integer (Radius);

      while X <= Y loop
         Plot_8 (Center.X, Center.Y, X, Y);
         X := X + 1;
         if D < 0 then
            D := D + 2 * Long_Long_Integer (X) + 1;
         else
            Y := Y - 1;
            D := D + 2 * (Long_Long_Integer (X) - Long_Long_Integer (Y)) + 1;
         end if;
      end loop;
   end Draw_Circle;

end Midpoint_Circle;
