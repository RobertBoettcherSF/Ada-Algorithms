with Ada.Assertions; use Ada.Assertions;
with Palindrome_Partitioning_II; use Palindrome_Partitioning_II;

procedure Tests is
   A : constant Text := "aab             ";
   B : constant Text := "a               ";
   C : constant Text := "ab              ";
   D : constant Text := "aabb            ";
begin
   Assert (Min_Cuts (A, 3) = 1);
   Assert (Min_Cuts (B, 1) = 0);
   Assert (Min_Cuts (C, 2) = 1);
   Assert (Min_Cuts (D, 4) = 1);
end Tests;
