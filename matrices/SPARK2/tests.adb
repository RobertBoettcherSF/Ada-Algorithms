with Ada.Assertions; use Ada.Assertions;
with Matrix_01; use Matrix_01;

procedure Tests is
   G : Grid := [others => [others => 0]];
begin
   Assert (Zero_Count (G) = 0);
   G (1, 1) := 1;
   G (4, 5) := 1;
   G (8, 8) := 1;
   Assert (Zero_Count (G) = 3);
end Tests;
