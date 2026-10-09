pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Search_A_2D_Matrix_II; use Search_A_2D_Matrix_II;
with Own_Checks;

procedure Tests is
   --  1 .. 64 row by row: rows and columns rise.
   Grid : constant Matrix :=
     [[ 1,  2,  3,  4,  5,  6,  7,  8],
      [ 9, 10, 11, 12, 13, 14, 15, 16],
      [17, 18, 19, 20, 21, 22, 23, 24],
      [25, 26, 27, 28, 29, 30, 31, 32],
      [33, 34, 35, 36, 37, 38, 39, 40],
      [41, 42, 43, 44, 45, 46, 47, 48],
      [49, 50, 51, 52, 53, 54, 55, 56],
      [57, 58, 59, 60, 61, 62, 63, 64]];
   --  4 * R + 3 * C: rows and columns rise, but a row ends above where
   --  the next one starts, so the cells are not sorted row by row.
   Slope : constant Matrix := [for R in Row => [for C in Column => 4 * R + 3 * C]];
   --  R + C: equal values along each anti-diagonal.
   Diag  : constant Matrix := [for R in Row => [for C in Column => R + C]];

   --  Starting in the top-right corner, each comparison drops a row or
   --  a column (or ends the search), so at most Rows + Cols - 1 = 15:
   --  the number of cells on a monotone path from the top-right to the
   --  bottom-left corner, counted here step by step.
   function Path_Cells (Height, Width : Positive) return Natural is
      R     : Positive := 1;
      C     : Positive := Width;
      Count : Natural := 1;
   begin
      while R < Height or else C > 1 loop
         if R < Height then
            R := R + 1;
         else
            C := C - 1;
         end if;
         Count := Count + 1;
      end loop;
      return Count;
   end Path_Cells;

   Bound : constant Natural := Path_Cells (Rows, Cols);
   Most  : Natural := 0;   --  largest count seen

   function Scan (M : Matrix; T : Value) return Boolean is
     (for some R in Row => (for some C in Column => M (R, C) = T));

   procedure Expect (M : Matrix; Target : Value; Label : String) is
      R : constant Search_Result := Contains (M, Target);
   begin
      if R.Found /= Scan (M, Target) then
         raise Program_Error with Label & " target" & Target'Image & ": found " & R.Found'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & " target" & Target'Image & ":" & R.Probes'Image
           & " comparisons, more than Rows + Cols - 1 =" & Bound'Image;
      end if;
      Most := Natural'Max (Most, R.Probes);
   end Expect;
begin
   Expect (Grid, 63, "1 .. 64");
   Expect (Grid, 0, "1 .. 64");
   for T in Value loop
      Expect (Grid, T, "1 .. 64");
      Expect (Slope, T, "4 R + 3 C");
      Expect (Diag, T, "R + C");
   end loop;
   --  The bound is reached: 1 .. 64 with target 57 (bottom-left corner)
   --  walks the whole staircase.
   if Most /= Bound then
      raise Program_Error with "largest count" & Most'Image & ", expected" & Bound'Image;
   end if;
   Put_Line ("Search_A_2D_Matrix_II: PASS");
   Own_Checks;
end Tests;
