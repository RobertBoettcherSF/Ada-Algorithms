with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Replace_Words; use Replace_Words;
procedure Tests is
   Token : constant Word := (Len => 4, Chars => ['d','a','d','a','a','a','a','a']);
   Roots : constant Word_Array := (1 => (Len => 2, Chars => ['d','a','a','a','a','a','a','a']), others => (Len => 0, Chars => (others => 'a')));
   Answer : constant Word := Replace (Token, Roots);
begin
   Assert (Answer.Len = 2);
   Put_Line ("PASS Replace_Words");
end Tests;
