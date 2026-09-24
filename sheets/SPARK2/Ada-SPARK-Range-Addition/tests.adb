with Ada.Assertions; use Ada.Assertions;
with Range_Addition; use Range_Addition;

procedure Tests is
   A : Values := [others => 1];
begin
   Assert (Updated_Total (A, 1, 4, 2) = 12);
   A (3) := 5;
   Assert (Updated_Total (A, 2, 3, 1) = 8);
end Tests;
