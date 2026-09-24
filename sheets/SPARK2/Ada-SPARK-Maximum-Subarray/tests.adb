with Ada.Assertions; use Ada.Assertions;
with Maximum_Subarray; use Maximum_Subarray;

procedure Tests is
   A : Values := (others => 0);
begin
   Assert (Best_Sum (A, 0) = 0);
   A (1) := -2; A (2) := 3; A (3) := -1; A (4) := 2;
   Assert (Best_Sum (A, 4) = 4);
   A (1) := -7; A (2) := -3;
   Assert (Best_Sum (A, 2) = -3);
end Tests;
