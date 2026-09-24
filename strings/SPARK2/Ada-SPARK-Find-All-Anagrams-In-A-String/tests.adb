pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Find_All_Anagrams_In_A_String; use Find_All_Anagrams_In_A_String;
procedure Tests is
begin
   Assert (Count_Anagrams ("cbaebabd") = 3);
   Assert (Count_Anagrams ("abababab") = 7);
   Assert (Count_Anagrams ("cccccccc") = 0);
end Tests;
