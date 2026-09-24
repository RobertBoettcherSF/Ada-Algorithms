with Ada.Assertions; use Ada.Assertions;
with Word_Ladder_Lite; use Word_Ladder_Lite;
procedure Tests is
   A : constant Letter_Word := ['c','o','d','e',' ', ' ', ' ', ' '];
   B : constant Letter_Word := ['c','o','d','s',' ', ' ', ' ', ' '];
   C : constant Letter_Word := ['c','a','t','s',' ', ' ', ' ', ' '];
begin
   Assert (Ladder_Length (A, A) = 1);
   Assert (Ladder_Length (A, B) = 2);
   Assert (Ladder_Length (A, C) = 0);
end Tests;
