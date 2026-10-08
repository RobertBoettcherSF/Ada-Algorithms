pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Longest_Repeating_Character_Replacement; use Longest_Repeating_Character_Replacement;
procedure Tests is
begin
   Assert (Longest ("AABABBAA") = 4);
   Assert (Longest ("ABCDEFGH") = 2);
   Assert (Longest ("AAAAAAAA") = 8);
   Assert (Longest ("ABABABAB") = 3);
   Assert (Longest ("AABAABAA") = 5);
   Assert (Longest ("ABCADABC") = 3);
   Assert (Longest ("AAABBBAA") = 4);
   Assert (Longest ("ABCDABCD") = 2);
end Tests;
