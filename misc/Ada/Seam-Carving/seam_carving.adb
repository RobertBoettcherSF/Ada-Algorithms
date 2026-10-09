--  seam_carving.adb
--  Implementation of the Seam Carving algorithm.

package body Seam_Carving is

   type Energy_Map is array (Positive range <>, Positive range <>) of Integer;

   --  Helper: Calculate absolute difference between two pixels
   function Pixel_Diff (P1, P2 : Pixel) return Integer is
   begin
      return abs (P1.R - P2.R) + abs (P1.G - P2.G) + abs (P1.B - P2.B);
   end Pixel_Diff;

   --  Helper: Safely access pixel with edge mirroring
   function Get_Pixel (Img : Image; X, Y : Integer) return Pixel is
      Safe_X : constant Positive := Positive'Max (Img'First (1), Integer'Min (Img'Last (1), X));
      Safe_Y : constant Positive := Positive'Max (Img'First (2), Integer'Min (Img'Last (2), Y));
   begin
      return Img (Safe_X, Safe_Y);
   end Get_Pixel;

   --  Helper: Transpose image to reuse vertical logic for horizontal operations
   function Transpose (Img : Image) return Image is
      Result : Image (Img'Range (2), Img'Range (1));
   begin
      for X in Img'Range (1) loop
         for Y in Img'Range (2) loop
            Result (Y, X) := Img (X, Y);
         end loop;
      end loop;
      return Result;
   end Transpose;

   --  Helper: Calculate standard backward energy map (Dual-Gradient)
   function Calculate_Backward_Energy (Img : Image) return Energy_Map is
      Map : Energy_Map (Img'Range (1), Img'Range (2));
      Dx, Dy : Integer;
   begin
      for Y in Img'Range (2) loop
         for X in Img'Range (1) loop
            Dx := Pixel_Diff (Get_Pixel (Img, X + 1, Y), Get_Pixel (Img, X - 1, Y));
            Dy := Pixel_Diff (Get_Pixel (Img, X, Y + 1), Get_Pixel (Img, X, Y - 1));
            Map (X, Y) := Dx + Dy;
         end loop;
      end loop;
      return Map;
   end Calculate_Backward_Energy;

   --  Core Algorithm: Find vertical seam using Dynamic Programming.
   --  Works on a copy of Img with bounds 1 .. W, 1 .. H, so every pixel
   --  lookup and the returned seam (values 1 .. W) use the same coordinates
   --  whatever Img's own bounds are. Each cell records the column it was
   --  reached from, and the seam is traced through those links, so the
   --  traced seam is the one whose cost the DP computed (for forward energy
   --  the step costs differ by direction, so comparing DP values of the row
   --  above would not retrace it).
   function Find_Vertical_Seam (Img : Image; Energy_Type : Energy_Function_Type) return Seam is
      W : constant Positive := Img'Length (1);
      H : constant Positive := Img'Length (2);
      Local       : Image (1 .. W, 1 .. H);
      DP_Map      : Energy_Map (1 .. W, 1 .. H);
      From        : array (1 .. W, 1 .. H) of Positive;
      Result_Seam : Seam (1 .. H);

      Cu, Cl, Cr : Integer;
      Min_Prev   : Integer;
      Prev_X     : Positive;
   begin
      for X in 1 .. W loop
         for Y in 1 .. H loop
            Local (X, Y) := Img (Img'First (1) + X - 1, Img'First (2) + Y - 1);
         end loop;
      end loop;

      declare
         Base_Energy : constant Energy_Map := Calculate_Backward_Energy (Local);
      begin
         -- First row initialization
         for X in 1 .. W loop
            DP_Map (X, 1) := (if Energy_Type = Backward_Energy then Base_Energy (X, 1) else 0);
            From (X, 1) := X;
         end loop;

         -- Populate DP Map
         for Y in 2 .. H loop
            for X in 1 .. W loop
               if Energy_Type = Forward_Energy then
                  -- Step costs from the edges the removal creates
                  Cu := Pixel_Diff (Get_Pixel (Local, X + 1, Y), Get_Pixel (Local, X - 1, Y));
                  Cl := Cu + Pixel_Diff (Get_Pixel (Local, X, Y - 1), Get_Pixel (Local, X - 1, Y));
                  Cr := Cu + Pixel_Diff (Get_Pixel (Local, X, Y - 1), Get_Pixel (Local, X + 1, Y));
               else
                  Cu := Base_Energy (X, Y);
                  Cl := Cu;
                  Cr := Cu;
               end if;

               Min_Prev := DP_Map (X, Y - 1) + Cu; -- from directly above
               Prev_X := X;
               if X > 1 and then DP_Map (X - 1, Y - 1) + Cl < Min_Prev then
                  Min_Prev := DP_Map (X - 1, Y - 1) + Cl;
                  Prev_X := X - 1;
               end if;
               if X < W and then DP_Map (X + 1, Y - 1) + Cr < Min_Prev then
                  Min_Prev := DP_Map (X + 1, Y - 1) + Cr;
                  Prev_X := X + 1;
               end if;
               DP_Map (X, Y) := Min_Prev;
               From (X, Y) := Prev_X;
            end loop;
         end loop;
      end;

      -- Backtrack from the cheapest bottom cell (leftmost on ties)
      declare
         Min_Val : Integer := Integer'Last;
         Min_X   : Positive := 1;
      begin
         for X in 1 .. W loop
            if DP_Map (X, H) < Min_Val then
               Min_Val := DP_Map (X, H);
               Min_X := X;
            end if;
         end loop;
         Result_Seam (H) := Min_X;
         for Y in reverse 1 .. H - 1 loop
            Result_Seam (Y) := From (Result_Seam (Y + 1), Y + 1);
         end loop;
      end;

      return Result_Seam;
   end Find_Vertical_Seam;

   function Find_Seam (Img : Image; Dir : Seam_Direction; Energy_Type : Energy_Function_Type) return Seam is
   begin
      if Dir = Vertical then
         return Find_Vertical_Seam (Img, Energy_Type);
      else
         return Find_Vertical_Seam (Transpose (Img), Energy_Type);
      end if;
   end Find_Seam;

   function Remove_Seam (Img : Image; S : Seam; Dir : Seam_Direction) return Image is
   begin
      if Dir = Horizontal then
         return Transpose (Remove_Seam (Transpose (Img), S, Vertical));
      end if;

      if Img'Length (1) <= 1 then
         raise Image_Too_Small;
      end if;

      declare
         Result : Image (1 .. Img'Length (1) - 1, 1 .. Img'Length (2));
         Target_X : Positive;
      begin
         for Y in Img'Range (2) loop
            Target_X := 1;
            for X in Img'Range (1) loop
               -- Skip the seam pixel
               if X - Img'First (1) + 1 /= S (S'First + Y - Img'First (2)) then
                  Result (Target_X, Y - Img'First (2) + 1) := Img (X, Y);
                  Target_X := Target_X + 1;
               end if;
            end loop;
         end loop;
         return Result;
      end;
   end Remove_Seam;

   function Insert_Seam (Img : Image; S : Seam; Dir : Seam_Direction) return Image is
   begin
      if Dir = Horizontal then
         return Transpose (Insert_Seam (Transpose (Img), S, Vertical));
      end if;

      declare
         Result : Image (1 .. Img'Length (1) + 1, 1 .. Img'Length (2));
         Target_X : Positive;
         P_Avg : Pixel;
      begin
         for Y in Img'Range (2) loop
            Target_X := 1;
            for X in Img'Range (1) loop
               Result (Target_X, Y - Img'First (2) + 1) := Img (X, Y);
               Target_X := Target_X + 1;
               
               -- Insert averaged pixel after the seam pixel
               if X - Img'First (1) + 1 = S (S'First + Y - Img'First (2)) then
                  declare
                     P1 : constant Pixel := Img (X, Y);
                     P2 : constant Pixel := Get_Pixel (Img, X + 1, Y);
                  begin
                     P_Avg := (R => (P1.R + P2.R) / 2, G => (P1.G + P2.G) / 2, B => (P1.B + P2.B) / 2);
                     Result (Target_X, Y - Img'First (2) + 1) := P_Avg;
                     Target_X := Target_X + 1;
                  end;
               end if;
            end loop;
         end loop;
         return Result;
      end;
   end Insert_Seam;

end Seam_Carving;
