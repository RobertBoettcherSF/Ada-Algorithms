with Ada.Assertions; use Ada.Assertions;
with Degree_Of_An_Array; use Degree_Of_An_Array;
procedure Tests is
   A : Int_Array := [others => 0];
begin
   A (1 .. 7) := [1, 2, 2, 3, 1, 4, 2];
   Assert (Degree (A) = 25);
   A := [others => 7];
   Assert (Degree (A) = 32);
end Tests;
