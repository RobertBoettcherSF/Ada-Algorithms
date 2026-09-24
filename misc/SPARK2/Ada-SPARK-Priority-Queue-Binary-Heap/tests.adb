pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO; with Priority_Queue_Binary_Heap; use Priority_Queue_Binary_Heap;
procedure Tests is Q : Queue; V : Integer;
begin Initialize (Q); Insert (Q, 7); Insert (Q, 2); Insert (Q, 5); Insert (Q, 1); Assert (Minimum (Q) = 1); Remove_Min (Q, V); Assert (V = 1); Remove_Min (Q, V); Assert (V = 2); Remove_Min (Q, V); Assert (V = 5); Put_Line ("PASS Priority_Queue_Binary_Heap"); end Tests;
