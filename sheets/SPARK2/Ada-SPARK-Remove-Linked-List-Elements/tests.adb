with Remove_Linked_List_Elements;
with Ada.Text_IO;
procedure Tests is
   use Remove_Linked_List_Elements;
   L : List := Empty;
   I : Position;
begin
   Append (L, 4); Append (L, 7); Append (L, 7); Append (L, 9);
   Remove_First (L, 7);
   pragma Assert (Length (L) = 3);
   I := 2; pragma Assert (Element (L, I) = 7);
   Remove_First (L, 4);
   pragma Assert (Element (L, 1) = 7);
   Ada.Text_IO.Put_Line ("Remove linked list elements: OK");
end Tests;
