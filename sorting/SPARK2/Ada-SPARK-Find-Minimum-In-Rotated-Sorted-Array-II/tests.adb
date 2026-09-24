with Ada.Assertions; use Ada.Assertions;
with Find_Minimum_In_Rotated_Sorted_Array_II;
use Find_Minimum_In_Rotated_Sorted_Array_II;

procedure Tests is
   Values : constant Value_Array := [4, 5, 6, 7, 0, 1, 2, 2];
   Negs   : constant Value_Array := [-4, -4, -2, -1, 0, 1, 2, 3];
begin
   Assert (Minimum (Values) = 0);
   Assert (Minimum (Negs) = -4);
end Tests;
