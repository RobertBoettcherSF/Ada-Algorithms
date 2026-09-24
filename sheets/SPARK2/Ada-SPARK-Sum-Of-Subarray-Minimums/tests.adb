with Ada.Assertions; use Ada.Assertions;
with Sum_Of_Subarray_Minimums; use Sum_Of_Subarray_Minimums;
procedure Tests is
   A : constant Values := [3, 1, 2, 4, others => 0];
begin
   Assert (Sum_Minimums (A, 4) = 17);
   Assert (Sum_Minimums (A, 0) = 0);
end Tests;
