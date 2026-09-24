with Ada.Assertions; use Ada.Assertions;
with Squares_Of_A_Sorted_Array; use Squares_Of_A_Sorted_Array;
procedure Tests is
   A : Int_Array := [others => 0];
   S : Square_Array;
begin
   A (1 .. 5) := [-4, -1, 0, 3, 10];
   S := Squares (A);
   Assert (S (1) = 16 and then S (2) = 1 and then S (5) = 100);
end Tests;
