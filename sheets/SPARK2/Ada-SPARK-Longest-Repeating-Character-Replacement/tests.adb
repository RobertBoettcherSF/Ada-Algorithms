pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Longest_Repeating_Character_Replacement; use Longest_Repeating_Character_Replacement;
procedure Tests is
begin
   Assert (Longest ("AABABBAA") = 4);
   Assert (Longest ("ABCDEFGH") = 2);
   Assert (Longest ("AAAAAAAA") = 8);
end Tests;
