pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Find_Minimum_In_Rotated_Sorted_Array; use Find_Minimum_In_Rotated_Sorted_Array;
procedure Tests is
   --  0 2 4 .. 62 turned so that it starts at 40: minimum 0 at position 13.
   Turned : constant Data_Array := [for I in Index => (2 * (I + 19)) mod 64];
   --  Not turned: minimum at position 1.
   Plain : constant Data_Array := [for I in Index => I + 50];
   --  Turned by one: 100, then 1 .. 31; minimum at position 2.
   By_One : constant Data_Array := [for I in Index => (if I = 1 then 100 else I - 1)];
   R : Search_Result;
begin
   R := Find_Minimum (Turned);
   pragma Assert (R.Position = 13 and then Minimum (Turned) = 0);
   R := Find_Minimum (Plain);
   pragma Assert (R.Position = 1 and then R.Probes = 5 and then Minimum (Plain) = 51);
   R := Find_Minimum (By_One);
   pragma Assert (R.Position = 2 and then Minimum (By_One) = 1);
   Put_Line ("Find_Minimum_In_Rotated_Sorted_Array: PASS");
end Tests;
