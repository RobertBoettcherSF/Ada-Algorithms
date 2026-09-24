--  Contour_Lines body — contour intervals, bilinear sampling, gradients,
--  2×2 cell isoline tracing, multi-level contour maps, spacing classes,
--  labeling helpers, transect profiles, and terrain fixtures.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;

package body Contour_Lines
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Internal helpers
   -----------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   function Exp_Safe (X : Real) return Real is
   begin
      if X < -80.0 then
         return 0.0;
      elsif X > 80.0 then
         return Real (Exp (80.0));
      else
         return Real (Exp (Float (X)));
      end if;
   end Exp_Safe;

   --  Cell corners: 0=TL, 1=TR, 2=BR, 3=BL. Edges: 0=top,1=right,2=bottom,3=left.
   subtype Cell_Corner is Natural range 0 .. 3;
   subtype Cell_Edge is Natural range 0 .. 3;
   subtype Case_Index is Natural range 0 .. 15;

   type Edge_Ends is array (0 .. 1) of Cell_Corner;
   type Edge_Table is array (Cell_Edge) of Edge_Ends;

   Cell_Edge_Verts : constant Edge_Table :=
     [0 => [0, 1],
      1 => [1, 2],
      2 => [2, 3],
      3 => [3, 0]];

   function Corner_Scalar
     (C : Cell_Corner; TL, TR, BR, BL : Real) return Real
   is
   begin
      case C is
         when 0 => return TL;
         when 1 => return TR;
         when 2 => return BR;
         when 3 => return BL;
      end case;
   end Corner_Scalar;

   function Corner_Point
     (C : Cell_Corner; TL, TR, BR, BL : Point2) return Point2
   is
   begin
      case C is
         when 0 => return TL;
         when 1 => return TR;
         when 2 => return BR;
         when 3 => return BL;
      end case;
   end Corner_Point;

   function Cell_Case
     (TL, TR, BR, BL : Real; Level : Real) return Case_Index
   is
      Idx : Natural := 0;
   begin
      if TL >= Level then
         Idx := Idx + 8;
      end if;
      if TR >= Level then
         Idx := Idx + 4;
      end if;
      if BR >= Level then
         Idx := Idx + 2;
      end if;
      if BL >= Level then
         Idx := Idx + 1;
      end if;
      return Case_Index (Idx);
   end Cell_Case;

   function Interpolate_Edge
     (P0, P1 : Point2;
      V0, V1 : Real;
      Level  : Real) return Point2
   is
      Denom : constant Real := V1 - V0;
      T     : Real;
   begin
      if abs (Denom) < 1.0E-12 then
         return P0;
      end if;
      T := (Level - V0) / Denom;
      T := Clamp (T, 0.0, 1.0);
      return P0 + (T * (P1 - P0));
   end Interpolate_Edge;

   procedure Lookup_Edges
     (Index      : Case_Index;
      Center_Avg : Real;
      Level      : Real;
      Edge_A     : out Integer;
      Edge_B     : out Integer;
      Edge_C     : out Integer;
      Edge_D     : out Integer;
      Seg_Count  : out Natural)
   is
      Above : constant Boolean := Center_Avg >= Level;
   begin
      Edge_A := -1;
      Edge_B := -1;
      Edge_C := -1;
      Edge_D := -1;
      Seg_Count := 0;

      case Index is
         when 0 | 15 =>
            null;
         when 1 =>
            Edge_A := 3; Edge_B := 2; Seg_Count := 1;
         when 2 =>
            Edge_A := 2; Edge_B := 1; Seg_Count := 1;
         when 3 =>
            Edge_A := 3; Edge_B := 1; Seg_Count := 1;
         when 4 =>
            Edge_A := 0; Edge_B := 1; Seg_Count := 1;
         when 5 =>
            Seg_Count := 2;
            if Above then
               Edge_A := 0; Edge_B := 1;
               Edge_C := 2; Edge_D := 3;
            else
               Edge_A := 0; Edge_B := 3;
               Edge_C := 1; Edge_D := 2;
            end if;
         when 6 =>
            Edge_A := 0; Edge_B := 2; Seg_Count := 1;
         when 7 =>
            Edge_A := 0; Edge_B := 3; Seg_Count := 1;
         when 8 =>
            Edge_A := 0; Edge_B := 3; Seg_Count := 1;
         when 9 =>
            Edge_A := 0; Edge_B := 2; Seg_Count := 1;
         when 10 =>
            Seg_Count := 2;
            if Above then
               Edge_A := 0; Edge_B := 3;
               Edge_C := 1; Edge_D := 2;
            else
               Edge_A := 0; Edge_B := 1;
               Edge_C := 2; Edge_D := 3;
            end if;
         when 11 =>
            Edge_A := 0; Edge_B := 1; Seg_Count := 1;
         when 12 =>
            Edge_A := 3; Edge_B := 1; Seg_Count := 1;
         when 13 =>
            Edge_A := 2; Edge_B := 1; Seg_Count := 1;
         when 14 =>
            Edge_A := 3; Edge_B := 2; Seg_Count := 1;
      end case;
   end Lookup_Edges;

   function Grid_AABB
     (Positions : Position_Field;
      Min_P, Max_P : out Point2) return Boolean
   is
      P : Point2;
   begin
      Min_P := Positions (Positions'First (1), Positions'First (2));
      Max_P := Min_P;
      for I in Positions'Range (1) loop
         for J in Positions'Range (2) loop
            P := Positions (I, J);
            if P.X < Min_P.X then Min_P.X := P.X; end if;
            if P.Y < Min_P.Y then Min_P.Y := P.Y; end if;
            if P.X > Max_P.X then Max_P.X := P.X; end if;
            if P.Y > Max_P.Y then Max_P.Y := P.Y; end if;
         end loop;
      end loop;
      return True;
   end Grid_AABB;

   -----------------------------------------------------------------------
   -- Vector helpers
   -----------------------------------------------------------------------

   function Length (V : Vec2) return Non_Negative is
      S : constant Real := V.X * V.X + V.Y * V.Y;
   begin
      return Non_Negative (Sqrt_Safe (S));
   end Length;

   function Normalize (V : Vec2) return Vec2 is
      L : constant Non_Negative := Length (V);
   begin
      if L = 0.0 then
         raise Degenerate_Geometry with "Normalize of zero vector";
      end if;
      return (V.X / L, V.Y / L);
   end Normalize;

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   function "-" (A, B : Vec2) return Vec2 is
   begin
      return (A.X - B.X, A.Y - B.Y);
   end "-";

   function "+" (A, B : Vec2) return Vec2 is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end "+";

   function "*" (S : Real; V : Vec2) return Vec2 is
   begin
      return (S * V.X, S * V.Y);
   end "*";

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Distance_Between (A, B : Vec2) return Non_Negative is
   begin
      return Length (A - B);
   end Distance_Between;

   function Perp (V : Vec2) return Vec2 is
   begin
      return (-V.Y, V.X);
   end Perp;

   -----------------------------------------------------------------------
   -- 1. Contour interval helpers
   -----------------------------------------------------------------------

   function Contour_Level_Count
     (Min_Level : Level_Value;
      Max_Level : Level_Value;
      Interval  : Contour_Interval_Value) return Natural
   is
      Span : constant Real := Real (Max_Level - Min_Level);
      Step : constant Real := Real (Interval);
      N    : Natural;
   begin
      if Interval <= 0.0 then
         raise Invalid_Argument with "Contour_Level_Count: non-positive interval";
      end if;
      if Max_Level < Min_Level then
         raise Invalid_Argument with "Contour_Level_Count: max < min";
      end if;
      N := Natural (Float'Floor (Float (Span / Step) + 1.0E-5)) + 1;
      if N > Max_Levels then
         return Max_Levels;
      end if;
      return N;
   end Contour_Level_Count;

   function Level_From_Index
     (Min_Level : Level_Value;
      Interval  : Contour_Interval_Value;
      Index     : Natural) return Level_Value
   is
   begin
      if Interval <= 0.0 then
         raise Invalid_Argument with "Level_From_Index: non-positive interval";
      end if;
      return Min_Level + Level_Value (Real (Index) * Real (Interval));
   end Level_From_Index;

   function Contour_Interval_Of
     (Min_Level : Level_Value;
      Max_Level : Level_Value;
      Levels    : Positive) return Contour_Interval_Value
   is
   begin
      if Max_Level <= Min_Level or else Levels < 2 then
         raise Invalid_Argument with "Contour_Interval_Of: bad range";
      end if;
      return Contour_Interval_Value
        (Real (Max_Level - Min_Level) / Real (Levels - 1));
   end Contour_Interval_Of;

   -----------------------------------------------------------------------
   -- 2. Sampling
   -----------------------------------------------------------------------

   function Sample_Height_Field
     (Values : Scalar_Field;
      I, J   : Natural) return Real
   is
   begin
      if I not in Values'Range (1) or else J not in Values'Range (2) then
         raise Invalid_Argument with "Sample_Height_Field: index out of range";
      end if;
      return Values (I, J);
   end Sample_Height_Field;

   function Bilinear_Sample
     (Values    : Scalar_Field;
      Positions : Position_Field;
      P         : Point2) return Real
   is
      Min_P, Max_P : Point2;
      Ok : constant Boolean := Grid_AABB (Positions, Min_P, Max_P);
      I0, J0 : Natural;
      Tx, Ty : Real;
      X0, X1, Y0, Y1 : Real;
      V00, V10, V01, V11 : Real;
      A, B : Real;
   begin
      if not Ok then
         raise Invalid_Argument with "Bilinear_Sample: empty grid";
      end if;
      if P.X < Min_P.X - 1.0E-5 or else P.X > Max_P.X + 1.0E-5
        or else P.Y < Min_P.Y - 1.0E-5 or else P.Y > Max_P.Y + 1.0E-5
      then
         raise Invalid_Argument with "Bilinear_Sample: point outside grid";
      end if;

      --  Assume regular lattice from Positions (0,0) step.
      declare
         Origin : constant Point2 := Positions (Values'First (1), Values'First (2));
         Dx : constant Real :=
           Positions (Values'First (1) + 1, Values'First (2)).X - Origin.X;
         Dy : constant Real :=
           Positions (Values'First (1), Values'First (2) + 1).Y - Origin.Y;
         Fx, Fy : Real;
         Ii, Jj : Integer;
      begin
         if Dx <= 0.0 or else Dy <= 0.0 then
            raise Invalid_Argument with "Bilinear_Sample: non-positive spacing";
         end if;
         Fx := (P.X - Origin.X) / Dx;
         Fy := (P.Y - Origin.Y) / Dy;
         Ii := Integer (Float'Floor (Float (Fx)));
         Jj := Integer (Float'Floor (Float (Fy)));
         if Ii < Integer (Values'First (1)) then
            Ii := Integer (Values'First (1));
         end if;
         if Jj < Integer (Values'First (2)) then
            Jj := Integer (Values'First (2));
         end if;
         if Ii >= Integer (Values'Last (1)) then
            Ii := Integer (Values'Last (1)) - 1;
         end if;
         if Jj >= Integer (Values'Last (2)) then
            Jj := Integer (Values'Last (2)) - 1;
         end if;
         I0 := Natural (Ii);
         J0 := Natural (Jj);
         X0 := Positions (I0, J0).X;
         X1 := Positions (I0 + 1, J0).X;
         Y0 := Positions (I0, J0).Y;
         Y1 := Positions (I0, J0 + 1).Y;
         if X1 /= X0 then
            Tx := (P.X - X0) / (X1 - X0);
         else
            Tx := 0.0;
         end if;
         if Y1 /= Y0 then
            Ty := (P.Y - Y0) / (Y1 - Y0);
         else
            Ty := 0.0;
         end if;
         Tx := Clamp (Tx, 0.0, 1.0);
         Ty := Clamp (Ty, 0.0, 1.0);
         V00 := Values (I0, J0);
         V10 := Values (I0 + 1, J0);
         V01 := Values (I0, J0 + 1);
         V11 := Values (I0 + 1, J0 + 1);
         A := V00 * (1.0 - Tx) + V10 * Tx;
         B := V01 * (1.0 - Tx) + V11 * Tx;
         return A * (1.0 - Ty) + B * Ty;
      end;
   end Bilinear_Sample;

   -----------------------------------------------------------------------
   -- 3. Gradient
   -----------------------------------------------------------------------

   function Gradient_2D
     (Values    : Scalar_Field;
      Positions : Position_Field;
      I, J      : Natural) return Vec2
   is
      Gx, Gy : Real := 0.0;
   begin
      if I not in Values'Range (1) or else J not in Values'Range (2) then
         raise Invalid_Argument with "Gradient_2D: index out of range";
      end if;

      if I > Values'First (1) and then I < Values'Last (1) then
         declare
            Dx : constant Real :=
              Positions (I + 1, J).X - Positions (I - 1, J).X;
         begin
            if Dx /= 0.0 then
               Gx := (Values (I + 1, J) - Values (I - 1, J)) / Dx;
            end if;
         end;
      elsif I = Values'First (1) and then I < Values'Last (1) then
         declare
            Dx : constant Real :=
              Positions (I + 1, J).X - Positions (I, J).X;
         begin
            if Dx /= 0.0 then
               Gx := (Values (I + 1, J) - Values (I, J)) / Dx;
            end if;
         end;
      elsif I = Values'Last (1) and then I > Values'First (1) then
         declare
            Dx : constant Real :=
              Positions (I, J).X - Positions (I - 1, J).X;
         begin
            if Dx /= 0.0 then
               Gx := (Values (I, J) - Values (I - 1, J)) / Dx;
            end if;
         end;
      end if;

      if J > Values'First (2) and then J < Values'Last (2) then
         declare
            Dy : constant Real :=
              Positions (I, J + 1).Y - Positions (I, J - 1).Y;
         begin
            if Dy /= 0.0 then
               Gy := (Values (I, J + 1) - Values (I, J - 1)) / Dy;
            end if;
         end;
      elsif J = Values'First (2) and then J < Values'Last (2) then
         declare
            Dy : constant Real :=
              Positions (I, J + 1).Y - Positions (I, J).Y;
         begin
            if Dy /= 0.0 then
               Gy := (Values (I, J + 1) - Values (I, J)) / Dy;
            end if;
         end;
      elsif J = Values'Last (2) and then J > Values'First (2) then
         declare
            Dy : constant Real :=
              Positions (I, J).Y - Positions (I, J - 1).Y;
         begin
            if Dy /= 0.0 then
               Gy := (Values (I, J) - Values (I, J - 1)) / Dy;
            end if;
         end;
      end if;

      return (Gx, Gy);
   end Gradient_2D;

   function Gradient_Magnitude (G : Vec2) return Non_Negative is
   begin
      return Length (G);
   end Gradient_Magnitude;

   function Gradient_Perpendicular_Check
     (Gradient        : Vec2;
      Contour_Tangent : Vec2;
      Tolerance       : Real := 1.0E-3) return Boolean
   is
      Lg : constant Non_Negative := Length (Gradient);
      Lt : constant Non_Negative := Length (Contour_Tangent);
      Cos_Abs : Real;
   begin
      if Lg = 0.0 or else Lt = 0.0 then
         return True;
      end if;
      Cos_Abs := abs (Dot (Gradient, Contour_Tangent)) / (Lg * Lt);
      return Cos_Abs <= Tolerance;
   end Gradient_Perpendicular_Check;

   -----------------------------------------------------------------------
   -- 4. Isoline cell / grid extraction
   -----------------------------------------------------------------------

   procedure Trace_Isoline_Cell
     (TL, TR, BR, BL : Point2;
      V_TL, V_TR, V_BR, V_BL : Real;
      Level     : Level_Value;
      Out_Segs  : out Small_Segment_List;
      Out_Count : out Natural)
   is
      Lvl : constant Real := Real (Level);
      Idx : constant Case_Index :=
        Cell_Case (V_TL, V_TR, V_BR, V_BL, Lvl);
      Avg : constant Real := (V_TL + V_TR + V_BR + V_BL) / 4.0;
      EA, EB, EC, ED : Integer;
      N : Natural;

      function Edge_Point (E : Cell_Edge) return Point2 is
         C0 : constant Cell_Corner := Cell_Edge_Verts (E) (0);
         C1 : constant Cell_Corner := Cell_Edge_Verts (E) (1);
      begin
         return Interpolate_Edge
           (Corner_Point (C0, TL, TR, BR, BL),
            Corner_Point (C1, TL, TR, BR, BL),
            Corner_Scalar (C0, V_TL, V_TR, V_BR, V_BL),
            Corner_Scalar (C1, V_TL, V_TR, V_BR, V_BL),
            Lvl);
      end Edge_Point;
   begin
      Out_Segs := [others => ((0.0, 0.0), (0.0, 0.0))];
      Lookup_Edges (Idx, Avg, Lvl, EA, EB, EC, ED, N);
      Out_Count := N;
      if N >= 1 then
         Out_Segs (1) :=
           (Edge_Point (Cell_Edge (EA)), Edge_Point (Cell_Edge (EB)));
      end if;
      if N >= 2 then
         Out_Segs (2) :=
           (Edge_Point (Cell_Edge (EC)), Edge_Point (Cell_Edge (ED)));
      end if;
   end Trace_Isoline_Cell;

   function Empty_Polyline return Polyline is
      P : Polyline;
   begin
      P.Count := 0;
      P.Level := 0.0;
      return P;
   end Empty_Polyline;

   function Count_Segments (P : Polyline) return Natural is
   begin
      return Natural (P.Count);
   end Count_Segments;

   procedure Append_Segment (P : in out Polyline; S : Segment) is
   begin
      if P.Count = Max_Segments then
         raise Capacity_Exceeded with "Append_Segment: polyline full";
      end if;
      P.Count := P.Count + 1;
      P.Segs (P.Count) := S;
   end Append_Segment;

   function Total_Length (P : Polyline) return Non_Negative is
      Acc : Non_Negative := 0.0;
   begin
      for K in 1 .. P.Count loop
         Acc := Acc + Distance_Between (P.Segs (K).A, P.Segs (K).B);
      end loop;
      return Acc;
   end Total_Length;

   function Extract_Isolines_At_Level
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Level     : Level_Value) return Polyline
   is
      Result : Polyline := Empty_Polyline;
      Segs   : Small_Segment_List;
      N      : Natural;
   begin
      if Values'Length (1) > Max_Grid_Dim
        or else Values'Length (2) > Max_Grid_Dim
      then
         raise Invalid_Argument with "Extract_Isolines_At_Level: grid too large";
      end if;

      Result.Level := Level;

      for I in Values'First (1) .. Values'Last (1) - 1 loop
         for J in Values'First (2) .. Values'Last (2) - 1 loop
            Trace_Isoline_Cell
              (Positions (I, J + 1), Positions (I + 1, J + 1),
               Positions (I + 1, J), Positions (I, J),
               Values (I, J + 1), Values (I + 1, J + 1),
               Values (I + 1, J), Values (I, J),
               Level, Segs, N);
            for K in 1 .. N loop
               Append_Segment (Result, Segs (K));
            end loop;
         end loop;
      end loop;
      return Result;
   end Extract_Isolines_At_Level;

   -----------------------------------------------------------------------
   -- 5. Contour map
   -----------------------------------------------------------------------

   function Empty_Contour_Map return Contour_Map is
      M : Contour_Map;
   begin
      M.Count := 0;
      return M;
   end Empty_Contour_Map;

   function Contour_Map_Level_Count (M : Contour_Map) return Natural is
   begin
      return Natural (M.Count);
   end Contour_Map_Level_Count;

   function Build_Contour_Map
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Min_Level : Level_Value;
      Max_Level : Level_Value;
      Interval  : Contour_Interval_Value) return Contour_Map
   is
      M : Contour_Map := Empty_Contour_Map;
      N : Natural;
      L : Level_Value;
   begin
      if Interval <= 0.0 then
         raise Invalid_Argument with "Build_Contour_Map: non-positive interval";
      end if;
      if Max_Level < Min_Level then
         raise Invalid_Argument with "Build_Contour_Map: max < min";
      end if;

      M.Min_Level := Min_Level;
      M.Max_Level := Max_Level;
      M.Interval  := Interval;
      N := Contour_Level_Count (Min_Level, Max_Level, Interval);

      for Idx in 0 .. N - 1 loop
         exit when M.Count = Max_Levels;
         L := Level_From_Index (Min_Level, Interval, Idx);
         exit when L > Max_Level + Level_Value (Real (Interval) * 1.0E-6);
         M.Count := M.Count + 1;
         M.Levels (M.Count) := L;
         M.Contours (M.Count) :=
           Extract_Isolines_At_Level (Values, Positions, L);
      end loop;
      return M;
   end Build_Contour_Map;

   -----------------------------------------------------------------------
   -- 6. Spacing classification
   -----------------------------------------------------------------------

   function Classify_Spacing
     (Grad_Mag         : Non_Negative;
      Steep_Threshold  : Non_Negative := 1.0;
      Cliff_Threshold  : Non_Negative := 5.0;
      Gentle_Threshold : Non_Negative := 0.25) return Slope_Class
   is
   begin
      if Grad_Mag <= 1.0E-8 then
         return Flat;
      elsif Grad_Mag < Gentle_Threshold then
         return Gentle;
      elsif Grad_Mag < Steep_Threshold then
         return Moderate;
      elsif Grad_Mag < Cliff_Threshold then
         return Steep;
      else
         return Cliff;
      end if;
   end Classify_Spacing;

   function Spacing_From_Gradient
     (Grad_Mag : Non_Negative;
      Interval : Contour_Interval_Value) return Non_Negative
   is
   begin
      if Interval <= 0.0 then
         raise Invalid_Argument with "Spacing_From_Gradient: bad interval";
      end if;
      if Grad_Mag <= 1.0E-12 then
         return Non_Negative (Real'Last / 2.0);
      end if;
      return Non_Negative (Real (Interval) / Grad_Mag);
   end Spacing_From_Gradient;

   -----------------------------------------------------------------------
   -- 7. Labeling
   -----------------------------------------------------------------------

   function Closest_Contour_Label
     (Value     : Level_Value;
      Min_Level : Level_Value;
      Interval  : Contour_Interval_Value) return Level_Value
   is
      T : Real;
      K : Integer;
   begin
      if Interval <= 0.0 then
         raise Invalid_Argument with "Closest_Contour_Label: bad interval";
      end if;
      T := Real (Value - Min_Level) / Real (Interval);
      K := Integer (Float'Rounding (Float (T)));
      if K < 0 then
         K := 0;
      end if;
      return Level_From_Index (Min_Level, Interval, Natural (K));
   end Closest_Contour_Label;

   function Isoline_Kind_Name (K : Isoline_Kind) return String is
   begin
      case K is
         when Generic_Isoline => return "isoline";
         when Contour         => return "contour";
         when Isobar          => return "isobar";
         when Isotherm        => return "isotherm";
         when Isohyet         => return "isohyet";
         when Isobath         => return "isobath";
         when Isoheight       => return "isoheight";
         when Isopleth        => return "isopleth";
      end case;
   end Isoline_Kind_Name;

   function Format_Level_Label
     (Level : Level_Value;
      Kind  : Isoline_Kind := Contour) return String
   is
      package FIO is new Ada.Text_IO.Float_IO (Real);
      Buf  : String (1 .. 16);
      Last : Natural := Buf'First;
   begin
      FIO.Put (To => Buf, Item => Real (Level), Aft => 1, Exp => 0);
      while Last <= Buf'Last and then Buf (Last) = ' ' loop
         Last := Last + 1;
      end loop;
      if Last > Buf'Last then
         return Isoline_Kind_Name (Kind) & " 0.0";
      end if;
      return Isoline_Kind_Name (Kind) & " " & Buf (Last .. Buf'Last);
   end Format_Level_Label;

   -----------------------------------------------------------------------
   -- 8. Profile / transect
   -----------------------------------------------------------------------

   function Empty_Profile return Transect_Profile is
      P : Transect_Profile;
   begin
      P.Count := 0;
      return P;
   end Empty_Profile;

   function Profile_Along_Line
     (Values    : Scalar_Field;
      Positions : Position_Field;
      A, B      : Point2;
      Samples   : Positive) return Transect_Profile
   is
      Result : Transect_Profile := Empty_Profile;
      T : Real;
      P : Point2;
      Min_P, Max_P : Point2;
      Ok : constant Boolean := Grid_AABB (Positions, Min_P, Max_P);
      Q : Point2;
   begin
      if Samples < 2 or else Samples > Max_Profile then
         raise Invalid_Argument with "Profile_Along_Line: bad sample count";
      end if;
      if not Ok then
         raise Invalid_Argument with "Profile_Along_Line: empty grid";
      end if;

      for K in 1 .. Samples loop
         T := Real (K - 1) / Real (Samples - 1);
         P := A + (T * (B - A));
         --  Clamp into AABB so bilinear sampling stays valid.
         Q.X := Clamp (P.X, Min_P.X, Max_P.X);
         Q.Y := Clamp (P.Y, Min_P.Y, Max_P.Y);
         Result.Count := Result.Count + 1;
         Result.Points (Result.Count) := P;
         Result.Values (Result.Count) :=
           Bilinear_Sample (Values, Positions, Q);
      end loop;
      return Result;
   end Profile_Along_Line;

   -----------------------------------------------------------------------
   -- 9. Fixtures
   -----------------------------------------------------------------------

   procedure Fill_Lattice
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real)
   is
   begin
      if Spacing <= 0.0 then
         raise Invalid_Argument with "Fill_Lattice: non-positive spacing";
      end if;
      if Values'Length (1) > Max_Grid_Dim
        or else Values'Length (2) > Max_Grid_Dim
      then
         raise Invalid_Argument with "Fill_Lattice: grid too large";
      end if;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            Positions (I, J) :=
              (Origin.X + Real (I - Values'First (1)) * Spacing,
               Origin.Y + Real (J - Values'First (2)) * Spacing);
            Values (I, J) := 0.0;
         end loop;
      end loop;
   end Fill_Lattice;

   procedure Fill_Hill_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Center    : Point2;
      Peak      : Real := 10.0;
      Width     : Real := 3.0)
   is
      R2, W2 : Real;
   begin
      if Width <= 0.0 then
         raise Invalid_Argument with "Fill_Hill_Field: non-positive width";
      end if;
      Fill_Lattice (Values, Positions, Origin, Spacing);
      W2 := Width * Width;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            declare
               P : constant Point2 := Positions (I, J);
               D : constant Vec2 := P - Center;
            begin
               R2 := D.X * D.X + D.Y * D.Y;
               Values (I, J) := Peak * Exp_Safe (-R2 / W2);
            end;
         end loop;
      end loop;
   end Fill_Hill_Field;

   procedure Fill_Valley_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Center    : Point2;
      Floor_H   : Real := 0.0;
      Depth     : Real := 8.0;
      Width     : Real := 3.0)
   is
      R2, W2 : Real;
   begin
      if Width <= 0.0 then
         raise Invalid_Argument with "Fill_Valley_Field: non-positive width";
      end if;
      Fill_Lattice (Values, Positions, Origin, Spacing);
      W2 := Width * Width;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            declare
               P : constant Point2 := Positions (I, J);
               D : constant Vec2 := P - Center;
            begin
               R2 := D.X * D.X + D.Y * D.Y;
               Values (I, J) := Floor_H - Depth * Exp_Safe (-R2 / W2);
            end;
         end loop;
      end loop;
   end Fill_Valley_Field;

   procedure Fill_Ridge_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Axis_Y    : Real;
      Peak      : Real := 10.0;
      Width     : Real := 2.0)
   is
      Dy, W2 : Real;
   begin
      if Width <= 0.0 then
         raise Invalid_Argument with "Fill_Ridge_Field: non-positive width";
      end if;
      Fill_Lattice (Values, Positions, Origin, Spacing);
      W2 := Width * Width;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            Dy := Positions (I, J).Y - Axis_Y;
            Values (I, J) := Peak * Exp_Safe (-(Dy * Dy) / W2);
         end loop;
      end loop;
   end Fill_Ridge_Field;

end Contour_Lines;
