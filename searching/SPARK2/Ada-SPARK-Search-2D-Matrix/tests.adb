pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Search_2D_Matrix; use Search_2D_Matrix;

procedure Tests is
   --  1, 3, 5, .., 127 would leave Value; use (K - 1) * 3 / 2 + 1 for the
   --  K-th cell in row-major order: 1 2 4 5 7 8 .. 95 (sorted, gaps).
   Steps : constant Matrix :=
     [for R in Row => [for C in Column => ((R - 1) * Cols + C - 1) * 3 / 2 + 1]];
   --  Rows of equal values: row R holds 10 * R everywhere.
   Flat  : constant Matrix := [for R in Row => [for C in Column => 10 * R]];

   --  A halving search over the 64 cells in row-major order needs at most
   --  7 comparisons (65 insertion points) plus 1 for the cell found; the
   --  bound asserted here is floor (log2 64) + 2 = 8.
   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   Bound : constant Natural := Floor_Log2 (Rows * Cols) + 2;

   procedure Expect (M : Matrix; Target : Value; Want : Boolean; Label : String) is
      R : constant Search_Result := Contains (M, Target);
   begin
      if R.Found /= Want then
         raise Program_Error with Label & " target" & Target'Image & ": found " & R.Found'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & " target" & Target'Image & ":" & R.Probes'Image
           & " comparisons, more than floor (log2 64) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (Steps, 1, True, "steps");       --  first cell
   Expect (Steps, 95, True, "steps");      --  last cell
   Expect (Steps, 11, True, "steps");      --  last cell of row 1
   Expect (Steps, 13, True, "steps");      --  first cell of row 2
   Expect (Steps, 12, False, "steps");     --  between rows 1 and 2
   Expect (Steps, 3, False, "steps");      --  a gap
   Expect (Steps, 0, False, "steps");      --  below everything
   Expect (Steps, 96, False, "steps");     --  above everything
   for T in Value loop
      Expect (Flat, T, T mod 10 = 0 and then T in 10 .. 80, "rows of equal values");
   end loop;
   Put_Line ("Search_2D_Matrix: PASS");
end Tests;
