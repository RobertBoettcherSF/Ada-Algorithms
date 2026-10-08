with Ada.Assertions; use Ada.Assertions;
with Container_With_Most_Water; use Container_With_Most_Water;
with Own_Checks;

procedure Tests is
   Data : Heights := (1 => 1, 2 => 8, 3 => 6, 4 => 2, 5 => 5, 6 => 4, 7 => 8, 8 => 3, 9 => 7, others => 0);
begin
   Assert (Max_Area (Data, 9) = 49);
   Assert (Max_Area (Data, 1) = 0);
   Own_Checks;
end Tests;
