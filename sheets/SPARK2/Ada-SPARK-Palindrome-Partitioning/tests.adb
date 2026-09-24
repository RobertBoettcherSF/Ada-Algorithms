with Ada.Assertions; use Ada.Assertions;
with Palindrome_Partitioning; use Palindrome_Partitioning;

procedure Tests is
   A : Word := (1, 2, 1, 3);
   B : Word := (1, 2, 2, 1);
begin
   Assert (Minimum_Cuts (A, 3) = 0);
   Assert (Minimum_Cuts (B, 4) = 0);
   Assert (Minimum_Cuts (A, 4) = 3);
end Tests;
