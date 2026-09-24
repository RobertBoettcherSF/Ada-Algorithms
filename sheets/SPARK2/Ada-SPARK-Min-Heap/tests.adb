pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Min_Heap; use Min_Heap;
procedure Tests is
   H : Heap; Added, Removed : Boolean; V : Integer;
begin
   Initialize (H);
   Push (H, 7, Added); Assert (Added); Push (H, 2, Added); Assert (Added); Push (H, 9, Added); Assert (Added);
   Pop (H, V, Removed); Assert (Removed and then V = 2);
   Put_Line ("PASS Min Heap");
end Tests;
