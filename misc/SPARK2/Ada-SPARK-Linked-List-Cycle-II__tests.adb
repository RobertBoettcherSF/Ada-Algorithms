with Linked_List_Cycle_II;
with Ada.Text_IO;
procedure Tests is
   use Linked_List_Cycle_II;
   A : constant Chain := Make (5);
   B : constant Chain := Make (0);
   pragma Unreferenced (B);
begin
   pragma Assert (Has_Cycle (A));
   pragma Assert (Cycle_Entry (A) = 5);
   Ada.Text_IO.Put_Line ("Linked list cycle II: OK");
end Tests;
