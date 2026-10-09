with Ada.Text_IO;
with Count_Square_Submatrices_With_All_Ones;
with Own_Checks;
procedure Tests is
   use Count_Square_Submatrices_With_All_Ones;
   Zero : constant Matrix := [others => [others => 0]];
   M    : Matrix;
begin
   pragma Assert (Count_Squares ([[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]) = 30);
   pragma Assert (Count_Squares ([[1, 0, 1, 0], [0, 1, 0, 1], [1, 0, 1, 0], [0, 1, 0, 1]]) = 8);
   --  Hand-worked (V&V sweep, agent A3; tests/SOURCES.txt).
   pragma Assert (Count_Squares (Zero) = 0);
   M := Zero; M (4, 4) := 1;
   pragma Assert (Count_Squares (M) = 1);
   M := Zero; M (3, 3) := 1; M (3, 4) := 1; M (4, 3) := 1; M (4, 4) := 1;
   pragma Assert (Count_Squares (M) = 5);
   M := Zero; M (1, 1) := 1; M (1, 2) := 1; M (2, 1) := 1;
   pragma Assert (Count_Squares (M) = 3);
   --  Top-left 3 x 3 block: 9 + 4 + 1.
   M := Zero;
   for R in 1 .. 3 loop
      for C in 1 .. 3 loop
         M (R, C) := 1;
      end loop;
   end loop;
   pragma Assert (Count_Squares (M) = 14);
   --  Bottom-right 3 x 3 block.
   M := Zero;
   for R in 2 .. 4 loop
      for C in 2 .. 4 loop
         M (R, C) := 1;
      end loop;
   end loop;
   pragma Assert (Count_Squares (M) = 14);
   --  All ones except one corner: 15 + 8 (2 x 2 not using (4, 4)) + 3 + 0.
   M := [others => [others => 1]]; M (4, 4) := 0;
   pragma Assert (Count_Squares (M) = 15 + 8 + 3);
   --  All ones except the centre cell (2, 2).
   M := [others => [others => 1]]; M (2, 2) := 0;
   pragma Assert (Count_Squares (M) = 15 + 5);  -- every 3 x 3 square holds (2, 2)
   --  A full row: 4 cells, no square.
   M := Zero; M (2, 1) := 1; M (2, 2) := 1; M (2, 3) := 1; M (2, 4) := 1;
   pragma Assert (Count_Squares (M) = 4);
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Count_Square_Submatrices_With_All_Ones");
end Tests;
