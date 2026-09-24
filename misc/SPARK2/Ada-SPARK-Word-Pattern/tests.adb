with Ada.Assertions; use Ada.Assertions;
with Word_Pattern; use Word_Pattern;
procedure Tests is
begin
   Assert (Matches ("abba", ["dog ", "cat ", "cat ", "dog "]));
   Assert (not Matches ("abba", ["dog ", "cat ", "cat ", "fish"]));
   Assert (Matches ("aaaa", ["one ", "one ", "one ", "one "]));
end Tests;
