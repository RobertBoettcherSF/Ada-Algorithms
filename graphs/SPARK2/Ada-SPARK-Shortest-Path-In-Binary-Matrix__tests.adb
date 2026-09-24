with Ada.Assertions; use Ada.Assertions;
with Shortest_Path_In_Binary_Matrix; use Shortest_Path_In_Binary_Matrix;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Path_Length (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Path_Length (G) = 3);
end Tests;
