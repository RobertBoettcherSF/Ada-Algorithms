with Ada.Assertions; use Ada.Assertions;
with Three_Sum_Closest; use Three_Sum_Closest;

procedure Tests is
   Data : constant Values := (-4, 1, 2, 5, 5, others => 0);
   Other : constant Values := (-5, -2, 3, 4, 5, others => 0);
begin
   Assert (Closest (Data, 5, 6) = 6);
   Assert (Closest (Other, 5, 1) = 2);
end Tests;
