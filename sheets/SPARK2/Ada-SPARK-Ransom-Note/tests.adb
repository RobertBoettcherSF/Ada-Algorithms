with Ada.Assertions; use Ada.Assertions;
with Ransom_Note; use Ransom_Note;
procedure Tests is
begin
   Assert (Can_Construct ("aabbcc  ", "abcabc  "));
   Assert (not Can_Construct ("aabbccd ", "abcabcde"));
   Assert (Can_Construct ("        ", "        "));
end Tests;
