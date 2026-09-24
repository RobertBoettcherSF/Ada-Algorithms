with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Max_Stack; use Max_Stack;
procedure Tests is S : Stack := Empty; V : Value; begin
   Push (S, 4); Push (S, 9); Push (S, 2); Assert (Maximum (S) = 9); Pop (S, V); Pop (S, V); Assert (Maximum (S) = 4);
   Put_Line ("PASS Max_Stack");
end Tests;
