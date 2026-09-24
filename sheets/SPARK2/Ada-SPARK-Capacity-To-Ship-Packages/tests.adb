with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Capacity_To_Ship_Packages; use Capacity_To_Ship_Packages;

procedure Tests is
   W : constant Weight_Array := [1, 2, 3, 4, 5, 6, 7, 8];
begin
   Assert (Minimum_Capacity (W, 2) = 21);
   Assert (Minimum_Capacity (W, 8) = 8);
   Put_Line ("PASS Capacity_To_Ship_Packages");
end Tests;
