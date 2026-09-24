with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Implement_Queue_Using_Stacks; use Implement_Queue_Using_Stacks;
procedure Tests is Q : Queue := Empty; V : Value; begin
   Enqueue (Q, 4); Enqueue (Q, 9); Dequeue (Q, V); Assert (V = 4);
   Enqueue (Q, -2); Dequeue (Q, V); Assert (V = 9); Dequeue (Q, V); Assert (V = -2);
   Put_Line ("PASS Implement_Queue_Using_Stacks");
end Tests;
