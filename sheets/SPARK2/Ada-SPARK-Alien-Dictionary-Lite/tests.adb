with Ada.Assertions; use Ada.Assertions;
with Alien_Dictionary; use Alien_Dictionary;
procedure Tests is
   A, B : Word := [others => 'a'];
   O : Alphabet_Order := [others => 0];
begin
   for C in Letter loop
      O (C) := Rank_Value (Character'Pos (C) - Character'Pos ('a'));
   end loop;
   A (1) := 'a'; B (1) := 'b';
   Assert (Is_Ordered (A, B, 1, 1, O));
   Assert (not Is_Ordered (B, A, 1, 1, O));
end Tests;
