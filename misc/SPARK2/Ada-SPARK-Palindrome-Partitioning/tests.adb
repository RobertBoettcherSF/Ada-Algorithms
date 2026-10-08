pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Palindrome_Partitioning; use Palindrome_Partitioning;
with Own_Checks;

procedure Tests is
   A : constant Word := [1, 2, 1, 3];
   B : constant Word := [1, 2, 2, 1];
begin
   Assert (Minimum_Cuts (A, 3) = 0);
   Assert (Minimum_Cuts (B, 4) = 0);
   Assert (Minimum_Cuts (A, 4) = 1);   --  1 2 1 | 3
   Own_Checks;
end Tests;
