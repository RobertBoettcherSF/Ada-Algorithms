with Ada.Assertions; use Ada.Assertions;
with Squares_Of_A_Sorted_Array; use Squares_Of_A_Sorted_Array;
with Own_Checks;
procedure Tests is
   A : Int_Array := [others => 10];
   S : Square_Array;
begin
   --  sorted input -4 -1 0 3 10 10 ... -> sorted squares 0 1 9 16 100 100 ...
   A (1 .. 5) := [-4, -1, 0, 3, 10];
   S := Squares (A);
   Assert (S (1) = 0 and then S (2) = 1 and then S (3) = 9 and then S (4) = 16 and then S (5) = 100
           and then S (32) = 100);
   Own_Checks;
end Tests;
