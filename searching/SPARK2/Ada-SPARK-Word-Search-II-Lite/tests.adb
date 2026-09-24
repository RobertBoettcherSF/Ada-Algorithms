with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Word_Search_II_Lite; use Word_Search_II_Lite;
procedure Tests is
   B : constant Board :=
     [['a','b','c','d'], ['d','c','b','a'], ['a','a','a','a'], ['b','c','d','a']];
   Words : constant Pattern_List :=
     ([ 'a','b','c'], ['c','d','a'], ['d','d','d']);
begin
   Assert (Appears_Horizontally (B, Words (1)));
   Assert (Count_Found (B, Words) = 2);
   Put_Line ("PASS Word_Search_II_Lite");
end Tests;
