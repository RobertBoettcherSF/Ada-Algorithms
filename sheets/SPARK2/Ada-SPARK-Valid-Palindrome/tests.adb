with Ada.Assertions; use Ada.Assertions;
with Valid_Palindrome; use Valid_Palindrome;
procedure Tests is
begin
   Assert (Is_Palindrome ("racecar"));
   Assert (not Is_Palindrome ("adSPARK"));
end Tests;
