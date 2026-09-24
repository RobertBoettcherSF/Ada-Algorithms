with Ada.Assertions; use Ada.Assertions;
with Continuous_Subarray_Sum; use Continuous_Subarray_Sum;

procedure Tests is
   A : Values := [others => 2];
begin
   Assert (Total (A) = 64);
   A (1) := 10;
   Assert (Total (A) = 72);
end Tests;
