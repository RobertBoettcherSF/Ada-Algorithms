with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Design_A_Stack_With_Increment_Operation; use Design_A_Stack_With_Increment_Operation;
procedure Tests is S : Stack := Empty; V : Value; begin
   Push (S, 1); Push (S, 2); Push (S, 3); Increment (S, 2, 5); Pop (S, V); Assert (V = 3); Pop (S, V); Assert (V = 7); Pop (S, V); Assert (V = 6);
   Put_Line ("PASS Design_A_Stack_With_Increment_Operation");
end Tests;
