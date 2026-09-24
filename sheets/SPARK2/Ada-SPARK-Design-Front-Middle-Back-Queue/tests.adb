pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Design_Front_Middle_Back_Queue; use Design_Front_Middle_Back_Queue;
procedure Tests is Q : Queue; V : Integer;
begin Initialize (Q); Assert (Is_Empty (Q)); Enqueue (Q, 10); Enqueue (Q, 20); Assert (Length (Q) = 2); Dequeue (Q, V); Assert (V = 10); Dequeue (Q, V); Assert (V = 20 and then Is_Empty (Q)); Put_Line ("PASS queue"); end Tests;
