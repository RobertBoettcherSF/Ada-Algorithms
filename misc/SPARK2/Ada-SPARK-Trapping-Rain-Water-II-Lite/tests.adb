pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Trapping_Rain_Water_II_Lite; use Trapping_Rain_Water_II_Lite;
with Own_Checks;

procedure Tests is
   Data : constant Heights := [0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1, others => 0];
begin
   Assert (Trapped (Data, 12) = 6);
   Own_Checks;
end Tests;
