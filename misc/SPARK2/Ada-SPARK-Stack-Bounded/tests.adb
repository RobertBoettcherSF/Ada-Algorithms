pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Stack_Bounded; use Stack_Bounded;
procedure Tests is S : Stack; V : Integer;
begin Initialize (S); Push (S, 10); Push (S, 20); Assert (Top (S) = 20); Pop (S, V); Assert (V = 20); Pop (S, V); Assert (V = 10); Put_Line ("PASS Stack_Bounded"); end Tests;
