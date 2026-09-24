pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Longest_Substring_Without_Repeating; use Longest_Substring_Without_Repeating;
procedure Tests is
begin
   Assert (Longest ("abcabcbb") = 3);
   Assert (Longest ("abcdefgh") = 8);
   Assert (Longest ("aaaaaaaa") = 1);
end Tests;
