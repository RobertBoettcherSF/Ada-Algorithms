with Ada.Assertions; use Ada.Assertions;
with Longest_Palindromic_Subsequence; use Longest_Palindromic_Subsequence;

procedure Tests is
   A : constant Text := "bbbab           ";
   B : constant Text := "cbbd            ";
   C : constant Text := "abcdef          ";
begin
   Assert (Longest_Length (A, 5) = 4);
   Assert (Longest_Length (B, 4) = 2);
   Assert (Longest_Length (C, 6) = 1);
   Assert (Longest_Length (C, 0) = 0);
end Tests;
