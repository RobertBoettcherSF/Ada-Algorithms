pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Gas_Station; use Gas_Station;
procedure Tests is
   Fuel : Values := [others => 0];
   Cost : Values := [others => 0];
begin
   Fuel (1) := 3;
   Cost (1) := 2;
   Assert (Starting_Station (Fuel, Cost, 1) = 1);
   Put_Line ("PASS Ada-SPARK-Gas-Station");
end Tests;
