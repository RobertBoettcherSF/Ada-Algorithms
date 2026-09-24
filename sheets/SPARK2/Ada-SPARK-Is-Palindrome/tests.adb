with Ada.Assertions; use Ada.Assertions;
with Is_Palindrome; use Is_Palindrome;
procedure Tests is
   Palindrome : constant Text_Array := "racecar";
   Not_Palindrome : constant Text_Array := "abcdefg";
begin
   Assert (Check (Palindrome));
   Assert (not Check (Not_Palindrome));
end Tests;
