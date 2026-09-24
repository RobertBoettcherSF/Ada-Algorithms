with Ada.Assertions; use Ada.Assertions;
with Height_Checker; use Height_Checker;
procedure Tests is
   A : Int_Array := [others => 0];
   B : Int_Array := [others => 0];
begin
   A (1 .. 5) := [1, 1, 4, 2, 1];
   Assert (Mismatches (A) = 10);
   B := [others => 1];
   Assert (Mismatches (B) = 0);
end Tests;
