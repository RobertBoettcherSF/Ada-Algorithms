pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Circular_Queue; use Circular_Queue;
procedure Tests is Q : Queue; V : Integer;
begin
   Initialize (Q); for I in 1 .. Capacity loop Enqueue (Q, I); end loop;
   Assert (Is_Full (Q) and then Peek (Q) = 1); Dequeue (Q, V); Assert (V = 1);
   Enqueue (Q, 9); Dequeue (Q, V); Assert (V = 2); Put_Line ("PASS Circular_Queue");
end Tests;
