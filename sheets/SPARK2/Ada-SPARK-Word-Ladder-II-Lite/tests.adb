with Ada.Assertions; use Ada.Assertions;
with Word_Ladder_II_Lite; use Word_Ladder_II_Lite;
procedure Tests is
   A : constant Letter_Word := ['c','a','t',' ', ' ', ' ', ' ', ' '];
   B : constant Letter_Word := ['c','a','r',' ', ' ', ' ', ' ', ' '];
   C : constant Letter_Word := ['d','o','g',' ', ' ', ' ', ' ', ' '];
begin
   Assert (Shortest_Path (A, A) = 1);
   Assert (Shortest_Path (A, B) = 2);
   Assert (Shortest_Path (A, C) = 0);
end Tests;
