pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Deque_Bounded; use Deque_Bounded;
procedure Tests is D : Deque; V : Integer;
begin Initialize (D); Push_Back (D, 2); Push_Front (D, 1); Push_Back (D, 3); Pop_Front (D, V); Assert (V = 1); Pop_Back (D, V); Assert (V = 3); Put_Line ("PASS Deque_Bounded"); end Tests;
