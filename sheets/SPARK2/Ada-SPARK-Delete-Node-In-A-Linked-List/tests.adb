with Delete_Node_In_A_Linked_List;
with Ada.Text_IO;
procedure Tests is
   use Delete_Node_In_A_Linked_List;
   L : List := Empty;
   P : constant Position := 2;
begin
   Append (L, 10); Append (L, 20); Append (L, 30); Append (L, 40);
   Delete_At (L, P);
   pragma Assert (Length (L) = 3);
   pragma Assert (Element (L, P) = 30);
   Ada.Text_IO.Put_Line ("Delete node in a linked list: OK");
end Tests;
