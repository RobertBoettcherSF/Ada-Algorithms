with Ada.Assertions; use Ada.Assertions;
with Longest_Palindromic_Substring; use Longest_Palindromic_Substring;
with Own_Checks;
procedure Tests is
begin
   Assert (Longest_Length ("abacaba") = 7);
   Assert (Longest_Length ("xxabaxy") = 5);
   Assert (Longest_Length ("abcdefg") = 1);
   Own_Checks;
end Tests;
