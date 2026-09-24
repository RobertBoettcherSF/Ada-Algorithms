with Ada.Assertions; use Ada.Assertions;
with Heaters; use Heaters;

procedure Tests is
   Houses  : constant Position_Array := [1, 2, 3, 4, 5, 6, 7, 8];
   Sources : constant Position_Array := [2, 4, 6, 8, 10, 12, 14, 16];
begin
   Assert (Required_Radius (Houses, Sources) = 8);
   Assert (Required_Radius (Sources, Sources) = 0);
end Tests;
