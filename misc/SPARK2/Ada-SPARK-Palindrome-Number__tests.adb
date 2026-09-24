with Ada.Assertions; use Ada.Assertions;
with Palindrome_Number; use Palindrome_Number;

procedure Tests is
begin
   Assert (Is_Palindrome (0));
   Assert (Is_Palindrome (1));
   Assert (Is_Palindrome (121));
   Assert (not Is_Palindrome (1_000_000_000));
   Assert (not Is_Palindrome (123));
   Assert (not Is_Palindrome (10));
end Tests;
