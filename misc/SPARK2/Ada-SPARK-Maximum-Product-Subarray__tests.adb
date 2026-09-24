with Ada.Assertions; use Ada.Assertions;
with Maximum_Product_Subarray; use Maximum_Product_Subarray;

procedure Tests is
   A : Values := (others => 0);
begin
   Assert (Best_Product (A, 0) = 0);
   A (1) := 2; A (2) := 3; A (3) := -2; A (4) := 4;
   Assert (Best_Product (A, 4) = 6);
   A (1) := -2; A (2) := 3; A (3) := -4;
   Assert (Best_Product (A, 3) = 24);
end Tests;
