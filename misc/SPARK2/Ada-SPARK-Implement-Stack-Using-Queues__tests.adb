with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Implement_Stack_Using_Queues; use Implement_Stack_Using_Queues;
procedure Tests is S : Stack := Empty; V : Value; begin
   Push (S, 3); Push (S, 8); Pop (S, V); Assert (V = 8); Pop (S, V); Assert (V = 3);
   Put_Line ("PASS Implement_Stack_Using_Queues");
end Tests;
