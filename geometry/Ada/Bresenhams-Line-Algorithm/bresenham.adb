package body Bresenham with
   SPARK_Mode => On
is

   -------------------
   -- Line_Octant_0 --
   -------------------

   procedure Line_Octant_0
     (P1     : Point;
      P2     : Point;
      Result : out Point_List)
   is
      Dx : constant Long_Integer := Long_Integer (P2.X) - Long_Integer (P1.X);
      Dy : constant Long_Integer := Long_Integer (P2.Y) - Long_Integer (P1.Y);

      --  Initial decision parameter: D = 2*dy - dx
      D  : Long_Integer := 2 * Dy - Dx;
      Y  : Coordinate   := P1.Y;
   begin
      Result.Length := 0;

      for Cur_X in P1.X .. P2.X loop
         Result.Length := Result.Length + 1;
         Result.Points (Result.Length) := Point'(X => Cur_X, Y => Y);

         if D > 0 then
            Y := Y + 1;
            D := D + 2 * (Dy - Dx);
         else
            D := D + 2 * Dy;
         end if;
      end loop;
   end Line_Octant_0;

   ------------------
   -- Line_General --
   ------------------

   procedure Line_General
     (P1     : Point;
      P2     : Point;
      Result : out Point_List)
   is
      Cur_X : Coordinate   := P1.X;
      Cur_Y : Coordinate   := P1.Y;
      Dx    : constant Long_Integer := abs (Long_Integer (P2.X) - Long_Integer (P1.X));
      Sx    : constant Coordinate   := (if P1.X < P2.X then 1 else -1);
      Dy    : constant Long_Integer := -abs (Long_Integer (P2.Y) - Long_Integer (P1.Y));
      Sy    : constant Coordinate   := (if P1.Y < P2.Y then 1 else -1);
      Err   : Long_Integer := Dx + Dy;
      E2    : Long_Integer;
   begin
      Result.Length := 0;

      loop
         Result.Length := Result.Length + 1;
         Result.Points (Result.Length) := Point'(X => Cur_X, Y => Cur_Y);

         exit when Cur_X = P2.X and then Cur_Y = P2.Y;

         E2 := 2 * Err;

         if E2 >= Dy then
            if Cur_X = P2.X then
               exit;
            end if;
            Err := Err + Dy;
            Cur_X := Cur_X + Sx;
         end if;

         if E2 <= Dx then
            if Cur_Y = P2.Y then
               exit;
            end if;
            Err := Err + Dx;
            Cur_Y := Cur_Y + Sy;
         end if;
      end loop;
   end Line_General;

   ---------------------------
   -- Line_General_Callback --
   ---------------------------

   procedure Line_General_Callback
     (P1   : Point;
      P2   : Point;
      Plot : Plot_Procedure)
   is
      Cur_X : Coordinate   := P1.X;
      Cur_Y : Coordinate   := P1.Y;
      Dx    : constant Long_Integer := abs (Long_Integer (P2.X) - Long_Integer (P1.X));
      Sx    : constant Coordinate   := (if P1.X < P2.X then 1 else -1);
      Dy    : constant Long_Integer := -abs (Long_Integer (P2.Y) - Long_Integer (P1.Y));
      Sy    : constant Coordinate   := (if P1.Y < P2.Y then 1 else -1);
      Err   : Long_Integer := Dx + Dy;
      E2    : Long_Integer;
   begin
      loop
         Plot (Point'(X => Cur_X, Y => Cur_Y));

         exit when Cur_X = P2.X and then Cur_Y = P2.Y;

         E2 := 2 * Err;

         if E2 >= Dy then
            if Cur_X = P2.X then
               exit;
            end if;
            Err := Err + Dy;
            Cur_X := Cur_X + Sx;
         end if;

         if E2 <= Dx then
            if Cur_Y = P2.Y then
               exit;
            end if;
            Err := Err + Dx;
            Cur_Y := Cur_Y + Sy;
         end if;
      end loop;
   end Line_General_Callback;

   ----------------
   -- Line_Thick --
   ----------------

   procedure Line_Thick
     (P1        : Point;
      P2        : Point;
      Thickness : Thickness_Type;
      Result    : out Point_List)
   is
      Base_Line : Point_List (Capacity => Expected_Line_Length (P1, P2));
      Dx        : constant Long_Integer := abs (Long_Integer (P2.X) - Long_Integer (P1.X));
      Dy        : constant Long_Integer := abs (Long_Integer (P2.Y) - Long_Integer (P1.Y));
      Is_Major_X : constant Boolean := Dx >= Dy;
      T_Count   : constant Integer := Integer (Thickness);
      Offset_Start : constant Integer := -(T_Count / 2);
   begin
      Line_General (P1, P2, Base_Line);
      Result.Length := 0;

      for Step_Idx in 0 .. T_Count - 1 loop
         declare
            Shift : constant Coordinate := Coordinate (Offset_Start + Step_Idx);
         begin
            for Pt_Idx in 1 .. Base_Line.Length loop
               Result.Length := Result.Length + 1;
               if Is_Major_X then
                  Result.Points (Result.Length) :=
                    Point'(X => Base_Line.Points (Pt_Idx).X,
                           Y => Base_Line.Points (Pt_Idx).Y + Shift);
               else
                  Result.Points (Result.Length) :=
                    Point'(X => Base_Line.Points (Pt_Idx).X + Shift,
                           Y => Base_Line.Points (Pt_Idx).Y);
               end if;
            end loop;
         end;
      end loop;
   end Line_Thick;

end Bresenham;
