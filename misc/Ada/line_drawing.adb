package body Line_Drawing is

   --  Internal helper: absolute value of coordinate difference
   function Abs_Diff (A, B : Coordinate) return Coordinate_Distance is
      Diff : constant Long_Integer := Long_Integer (A) - Long_Integer (B);
   begin
      if Diff < 0 then
         return Coordinate_Distance (-Diff);
      else
         return Coordinate_Distance (Diff);
      end if;
   end Abs_Diff;

   function Manhattan_Distance (P1, P2 : Point) return Coordinate_Distance is
   begin
      return Abs_Diff (P1.X, P2.X) + Abs_Diff (P1.Y, P2.Y);
   end Manhattan_Distance;

   function Chebyshev_Distance (P1, P2 : Point) return Coordinate_Distance is
      DX : constant Coordinate_Distance := Abs_Diff (P1.X, P2.X);
      DY : constant Coordinate_Distance := Abs_Diff (P1.Y, P2.Y);
   begin
      if DX > DY then
         return DX;
      else
         return DY;
      end if;
   end Chebyshev_Distance;

   function Expected_Point_Count (P1, P2 : Point) return Positive is
   begin
      return Positive (Chebyshev_Distance (P1, P2) + 1);
   end Expected_Point_Count;

   --  Internal helper: normalizes endpoints so raster generation is perfectly
   --  symmetric regardless of traversal direction Line(A, B) vs Line(B, A).
   procedure Order_Endpoints
     (P1, P2     : Point;
      First_Pt   : out Point;
      Second_Pt  : out Point;
      Is_Swapped : out Boolean)
   is
   begin
      if P1.X < P2.X or else (P1.X = P2.X and then P1.Y <= P2.Y) then
         First_Pt   := P1;
         Second_Pt  := P2;
         Is_Swapped := False;
      else
         First_Pt   := P2;
         Second_Pt  := P1;
         Is_Swapped := True;
      end if;
   end Order_Endpoints;

   ----------------------------------------------------------------------
   --  Variant 1: Naive Line Algorithm
   ----------------------------------------------------------------------
   function Naive_Line (Start_Pt, End_Pt : Point) return Point_Array is
      Count : constant Positive := Expected_Point_Count (Start_Pt, End_Pt);
      Result : Point_Array (1 .. Count);
      DX : constant Long_Integer := Long_Integer (End_Pt.X) - Long_Integer (Start_Pt.X);
      DY : constant Long_Integer := Long_Integer (End_Pt.Y) - Long_Integer (Start_Pt.Y);
   begin
      if Count = 1 then
         Result (1) := Start_Pt;
         return Result;
      end if;

      if abs (DX) >= abs (DY) then
         --  Driven along X axis
         declare
            Slope : constant Float := Float (DY) / Float (DX);
            Step_X : constant Integer := (if DX > 0 then 1 else -1);
            Curr_X : Coordinate := Start_Pt.X;
         begin
            for I in 1 .. Count loop
               declare
                  Rel_X : constant Float := Float (Long_Integer (Curr_X) - Long_Integer (Start_Pt.X));
                  Computed_Y : constant Long_Integer := Long_Integer (Float'Rounding (Float (Start_Pt.Y) + Rel_X * Slope));
               begin
                  Result (I) := (X => Curr_X, Y => Coordinate (Computed_Y));
               end;
               if I < Count then
                  Curr_X := Coordinate (Long_Integer (Curr_X) + Long_Integer (Step_X));
               end if;
            end loop;
         end;
      else
         --  Driven along Y axis
         declare
            Inv_Slope : constant Float := Float (DX) / Float (DY);
            Step_Y    : constant Integer := (if DY > 0 then 1 else -1);
            Curr_Y    : Coordinate := Start_Pt.Y;
         begin
            for I in 1 .. Count loop
               declare
                  Rel_Y : constant Float := Float (Long_Integer (Curr_Y) - Long_Integer (Start_Pt.Y));
                  Computed_X : constant Long_Integer := Long_Integer (Float'Rounding (Float (Start_Pt.X) + Rel_Y * Inv_Slope));
               begin
                  Result (I) := (X => Coordinate (Computed_X), Y => Curr_Y);
               end;
               if I < Count then
                  Curr_Y := Coordinate (Long_Integer (Curr_Y) + Long_Integer (Step_Y));
               end if;
            end loop;
         end;
      end if;

      Result (1) := Start_Pt;
      Result (Count) := End_Pt;
      return Result;
   end Naive_Line;

   ----------------------------------------------------------------------
   --  Variant 2: Digital Differential Analyzer (DDA)
   ----------------------------------------------------------------------
   function DDA_Line (Start_Pt, End_Pt : Point) return Point_Array is
      Count : constant Positive := Expected_Point_Count (Start_Pt, End_Pt);
      Result : Point_Array (1 .. Count);
      DX : constant Float := Float (Long_Integer (End_Pt.X) - Long_Integer (Start_Pt.X));
      DY : constant Float := Float (Long_Integer (End_Pt.Y) - Long_Integer (Start_Pt.Y));
      Steps : constant Float := Float (Count - 1);
   begin
      if Count = 1 then
         Result (1) := Start_Pt;
         return Result;
      end if;

      declare
         X_Inc : constant Float := DX / Steps;
         Y_Inc : constant Float := DY / Steps;
         Curr_X : Float := Float (Start_Pt.X);
         Curr_Y : Float := Float (Start_Pt.Y);
      begin
         for I in 1 .. Count loop
            Result (I) := (X => Coordinate (Long_Integer (Float'Rounding (Curr_X))),
                           Y => Coordinate (Long_Integer (Float'Rounding (Curr_Y))));
            Curr_X := Curr_X + X_Inc;
            Curr_Y := Curr_Y + Y_Inc;
         end loop;
      end;

      Result (1) := Start_Pt;
      Result (Count) := End_Pt;
      return Result;
   end DDA_Line;

   ----------------------------------------------------------------------
   --  Variant 3: Bresenham's Line Algorithm
   --  Strictly symmetric rasterization across forward and backward traversals
   ----------------------------------------------------------------------
   function Bresenham_Line (Start_Pt, End_Pt : Point) return Point_Array is
      Count : constant Positive := Expected_Point_Count (Start_Pt, End_Pt);
      Result : Point_Array (1 .. Count);

      P_A, P_B : Point;
      Swapped  : Boolean;
   begin
      if Count = 1 then
         Result (1) := Start_Pt;
         return Result;
      end if;

      Order_Endpoints (Start_Pt, End_Pt, P_A, P_B, Swapped);

      declare
         DX_Full : constant Long_Integer := Long_Integer (P_B.X) - Long_Integer (P_A.X);
         DY_Full : constant Long_Integer := Long_Integer (P_B.Y) - Long_Integer (P_A.Y);
         Step_X  : constant Long_Integer := (if DX_Full >= 0 then 1 else -1);
         Step_Y  : constant Long_Integer := (if DY_Full >= 0 then 1 else -1);
         Abs_DX  : constant Long_Integer := abs (DX_Full);
         Abs_DY  : constant Long_Integer := abs (DY_Full);

         Cur_X : Long_Integer := Long_Integer (P_A.X);
         Cur_Y : Long_Integer := Long_Integer (P_A.Y);
      begin
         if Abs_DX >= Abs_DY then
            declare
               Err : Long_Integer := 2 * Abs_DY - Abs_DX;
            begin
               for I in 1 .. Count loop
                  declare
                     Target_Idx : constant Positive := (if Swapped then Count - I + 1 else I);
                  begin
                     Result (Target_Idx) := (X => Coordinate (Cur_X), Y => Coordinate (Cur_Y));
                  end;
                  if Err > 0 then
                     Cur_Y := Cur_Y + Step_Y;
                     Err := Err - 2 * Abs_DX;
                  end if;
                  Err := Err + 2 * Abs_DY;
                  Cur_X := Cur_X + Step_X;
               end loop;
            end;
         else
            declare
               Err : Long_Integer := 2 * Abs_DX - Abs_DY;
            begin
               for I in 1 .. Count loop
                  declare
                     Target_Idx : constant Positive := (if Swapped then Count - I + 1 else I);
                  begin
                     Result (Target_Idx) := (X => Coordinate (Cur_X), Y => Coordinate (Cur_Y));
                  end;
                  if Err > 0 then
                     Cur_X := Cur_X + Step_X;
                     Err := Err - 2 * Abs_DY;
                  end if;
                  Err := Err + 2 * Abs_DX;
                  Cur_Y := Cur_Y + Step_Y;
               end loop;
            end;
         end if;
      end;

      Result (1) := Start_Pt;
      Result (Count) := End_Pt;
      return Result;
   end Bresenham_Line;

   ----------------------------------------------------------------------
   --  Variant 4: Midpoint Line Algorithm
   --  Strictly symmetric rasterization across forward and backward traversals
   ----------------------------------------------------------------------
   function Midpoint_Line (Start_Pt, End_Pt : Point) return Point_Array is
      Count : constant Positive := Expected_Point_Count (Start_Pt, End_Pt);
      Result : Point_Array (1 .. Count);

      P_A, P_B : Point;
      Swapped  : Boolean;
   begin
      if Count = 1 then
         Result (1) := Start_Pt;
         return Result;
      end if;

      Order_Endpoints (Start_Pt, End_Pt, P_A, P_B, Swapped);

      declare
         DX_Full : constant Long_Integer := Long_Integer (P_B.X) - Long_Integer (P_A.X);
         DY_Full : constant Long_Integer := Long_Integer (P_B.Y) - Long_Integer (P_A.Y);
         Step_X  : constant Long_Integer := (if DX_Full >= 0 then 1 else -1);
         Step_Y  : constant Long_Integer := (if DY_Full >= 0 then 1 else -1);
         Abs_DX  : constant Long_Integer := abs (DX_Full);
         Abs_DY  : constant Long_Integer := abs (DY_Full);

         Cur_X : Long_Integer := Long_Integer (P_A.X);
         Cur_Y : Long_Integer := Long_Integer (P_A.Y);
      begin
         if Abs_DX >= Abs_DY then
            declare
               D      : Long_Integer := 2 * Abs_DY - Abs_DX;
               Inc_E  : constant Long_Integer := 2 * Abs_DY;
               Inc_NE : constant Long_Integer := 2 * (Abs_DY - Abs_DX);
            begin
               for I in 1 .. Count loop
                  declare
                     Target_Idx : constant Positive := (if Swapped then Count - I + 1 else I);
                  begin
                     Result (Target_Idx) := (X => Coordinate (Cur_X), Y => Coordinate (Cur_Y));
                  end;
                  if D > 0 then
                     Cur_Y := Cur_Y + Step_Y;
                     D := D + Inc_NE;
                  else
                     D := D + Inc_E;
                  end if;
                  Cur_X := Cur_X + Step_X;
               end loop;
            end;
         else
            declare
               D      : Long_Integer := 2 * Abs_DX - Abs_DY;
               Inc_N  : constant Long_Integer := 2 * Abs_DX;
               Inc_NE : constant Long_Integer := 2 * (Abs_DX - Abs_DY);
            begin
               for I in 1 .. Count loop
                  declare
                     Target_Idx : constant Positive := (if Swapped then Count - I + 1 else I);
                  begin
                     Result (Target_Idx) := (X => Coordinate (Cur_X), Y => Coordinate (Cur_Y));
                  end;
                  if D > 0 then
                     Cur_X := Cur_X + Step_X;
                     D := D + Inc_NE;
                  else
                     D := D + Inc_N;
                  end if;
                  Cur_Y := Cur_Y + Step_Y;
               end loop;
            end;
         end if;
      end;

      Result (1) := Start_Pt;
      Result (Count) := End_Pt;
      return Result;
   end Midpoint_Line;

   ----------------------------------------------------------------------
   --  Variant 5: Xiaolin Wu's Antialiased Line Algorithm
   ----------------------------------------------------------------------
   function Xiaolin_Wu_Line (Start_Pt, End_Pt : Point) return Shaded_Point_Array is
      --  Maximum capacity is 2 points per step along the major axis + 4 endpoints
      Max_Elements : constant Natural := Natural (Expected_Point_Count (Start_Pt, End_Pt)) * 2 + 4;
      Temp : Shaded_Point_Array (1 .. Max_Elements);
      Count : Natural := 0;

      procedure Add_Pixel (X, Y : Coordinate; Alpha : Float) is
         Val : Float := Alpha;
      begin
         if Val < 0.0 then
            Val := 0.0;
         elsif Val > 1.0 then
            Val := 1.0;
         end if;

         if Val > 0.001 then
            Count := Count + 1;
            Temp (Count) := (Coord => (X => X, Y => Y),
                             Alpha => Intensity (Val));
         end if;
      end Add_Pixel;

      function F_Part (X : Float) return Float is
      begin
         return X - Float'Floor (X);
      end F_Part;

      function RF_Part (X : Float) return Float is
      begin
         return 1.0 - F_Part (X);
      end RF_Part;

      X0 : Float := Float (Start_Pt.X);
      Y0 : Float := Float (Start_Pt.Y);
      X1 : Float := Float (End_Pt.X);
      Y1 : Float := Float (End_Pt.Y);
      Steep : constant Boolean := abs (Y1 - Y0) > abs (X1 - X0);
   begin
      --  Single point edge case
      if Start_Pt = End_Pt then
         declare
            Single : Shaded_Point_Array (1 .. 1);
         begin
            Single (1) := (Coord => Start_Pt, Alpha => 1.0);
            return Single;
         end;
      end if;

      if Steep then
         declare
            T : Float;
         begin
            T := X0; X0 := Y0; Y0 := T;
            T := X1; X1 := Y1; Y1 := T;
         end;
      end if;

      if X0 > X1 then
         declare
            T : Float;
         begin
            T := X0; X0 := X1; X1 := T;
            T := Y0; Y0 := Y1; Y1 := T;
         end;
      end if;

      declare
         DX : constant Float := X1 - X0;
         DY : constant Float := Y1 - Y0;
         Gradient : Float := 1.0;
         X_End : Float;
         Y_End : Float;
         X_Gap : Float;
         X_Pixel_1, Y_Pixel_1 : Coordinate;
         X_Pixel_2, Y_Pixel_2 : Coordinate;
         Inter_Y : Float;
      begin
         if DX /= 0.0 then
            Gradient := DY / DX;
         end if;

         --  First endpoint
         X_End := Float'Rounding (X0);
         Y_End := Y0 + Gradient * (X_End - X0);
         X_Gap := RF_Part (X0 + 0.5);
         X_Pixel_1 := Coordinate (Long_Integer (X_End));
         Y_Pixel_1 := Coordinate (Long_Integer (Float'Floor (Y_End)));

         if Steep then
            Add_Pixel (Y_Pixel_1,     X_Pixel_1, RF_Part (Y_End) * X_Gap);
            Add_Pixel (Y_Pixel_1 + 1, X_Pixel_1,  F_Part (Y_End) * X_Gap);
         else
            Add_Pixel (X_Pixel_1, Y_Pixel_1,     RF_Part (Y_End) * X_Gap);
            Add_Pixel (X_Pixel_1, Y_Pixel_1 + 1,  F_Part (Y_End) * X_Gap);
         end if;

         Inter_Y := Y_End + Gradient;

         --  Second endpoint
         X_End := Float'Rounding (X1);
         Y_End := Y1 + Gradient * (X_End - X1);
         X_Gap := F_Part (X1 + 0.5);
         X_Pixel_2 := Coordinate (Long_Integer (X_End));
         Y_Pixel_2 := Coordinate (Long_Integer (Float'Floor (Y_End)));

         if Steep then
            Add_Pixel (Y_Pixel_2,     X_Pixel_2, RF_Part (Y_End) * X_Gap);
            Add_Pixel (Y_Pixel_2 + 1, X_Pixel_2,  F_Part (Y_End) * X_Gap);
         else
            Add_Pixel (X_Pixel_2, Y_Pixel_2,     RF_Part (Y_End) * X_Gap);
            Add_Pixel (X_Pixel_2, Y_Pixel_2 + 1,  F_Part (Y_End) * X_Gap);
         end if;

         --  Main loop between endpoints
         if Steep then
            for X_Step in (Long_Integer (X_Pixel_1) + 1) .. (Long_Integer (X_Pixel_2) - 1) loop
               declare
                  X_Coord : constant Coordinate := Coordinate (X_Step);
                  Y_Coord : constant Coordinate := Coordinate (Long_Integer (Float'Floor (Inter_Y)));
               begin
                  Add_Pixel (Y_Coord,     X_Coord, RF_Part (Inter_Y));
                  Add_Pixel (Y_Coord + 1, X_Coord,  F_Part (Inter_Y));
                  Inter_Y := Inter_Y + Gradient;
               end;
            end loop;
         else
            for X_Step in (Long_Integer (X_Pixel_1) + 1) .. (Long_Integer (X_Pixel_2) - 1) loop
               declare
                  X_Coord : constant Coordinate := Coordinate (X_Step);
                  Y_Coord : constant Coordinate := Coordinate (Long_Integer (Float'Floor (Inter_Y)));
               begin
                  Add_Pixel (X_Coord, Y_Coord,     RF_Part (Inter_Y));
                  Add_Pixel (X_Coord, Y_Coord + 1,  F_Part (Inter_Y));
                  Inter_Y := Inter_Y + Gradient;
               end;
            end loop;
         end if;
      end;

      if Count = 0 then
         declare
            Fallback : Shaded_Point_Array (1 .. 1);
         begin
            Fallback (1) := (Coord => Start_Pt, Alpha => 1.0);
            return Fallback;
         end;
      end if;

      return Temp (1 .. Count);
   end Xiaolin_Wu_Line;

end Line_Drawing;
