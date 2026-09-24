with Ada.Assertions; use Ada.Assertions;
with Third_Maximum_Number; use Third_Maximum_Number;
procedure Tests is
   A : Int_Array := [others => 0];
   B : Int_Array := [others => 0];
begin
   A (1 .. 5) := [3, 2, 1, 5, 4];
   Assert (Third_Maximum (A) = 3);
   B (1 .. 3) := [2, 2, 1];
   Assert (Third_Maximum (B) = 0);
end Tests;
