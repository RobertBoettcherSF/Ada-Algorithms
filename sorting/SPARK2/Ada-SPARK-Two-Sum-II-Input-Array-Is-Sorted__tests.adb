with Ada.Assertions; use Ada.Assertions;
with Two_Sum_II_Input_Array_Is_Sorted;
use Two_Sum_II_Input_Array_Is_Sorted;

procedure Tests is
   Data : constant Values := (2, 7, 11, 15, others => 0);
begin
   Assert (Has_Pair (Data, 4, 9));
   Assert (not Has_Pair (Data, 4, 20));
end Tests;
