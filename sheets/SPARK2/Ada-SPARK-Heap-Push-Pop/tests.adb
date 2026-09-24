with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Heap_Push_Pop; use Heap_Push_Pop;
procedure Tests is H : Heap := Empty; V : Value; begin
   Push (H, 7); Push (H, 2); Push (H, 5); Push (H, 1); Pop_Min (H, V); Assert (V = 1); Pop_Min (H, V); Assert (V = 2);
   Put_Line ("PASS Heap_Push_Pop");
end Tests;
