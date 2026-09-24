with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Map_Sum_Pairs; use Map_Sum_Pairs;
procedure Tests is
   Prefix : constant Word := (Len => 1, Chars => ['a','a','a','a','a','a','a','a']);
   M : constant Map :=
     (1 => ((Len => 2, Chars => ['a','b','a','a','a','a','a','a']), 3),
      2 => ((Len => 2, Chars => ['a','c','a','a','a','a','a','a']), 4),
      others => ((Len => 0, Chars => (others => 'a')), 0));
begin
   Assert (Sum (M, Prefix) = 7);
   Put_Line ("PASS Map_Sum_Pairs");
end Tests;
