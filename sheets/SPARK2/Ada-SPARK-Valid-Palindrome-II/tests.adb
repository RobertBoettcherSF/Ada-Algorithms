with Ada.Assertions; use Ada.Assertions;
with Valid_Palindrome_II; use Valid_Palindrome_II;
procedure Tests is
begin
   Assert (Is_Valid ("abccxcba"));
   Assert (Is_Valid ("raceecar"));
   Assert (not Is_Valid ("abcdefgh"));
end Tests;
