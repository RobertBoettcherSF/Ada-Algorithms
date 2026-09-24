with Ada.Text_IO;
with Swapping_Nodes_In_A_Linked_List;
procedure Tests is
   use Swapping_Nodes_In_A_Linked_List;
   L : List := Empty;
   P : Position;
begin
   Append (L, 10); Append (L, 20); Append (L, 30);
   Swap_Nodes (L, 1, 3);
   P := 1; pragma Assert (Element (L, P) = 30);
   P := 3; pragma Assert (Element (L, P) = 10);
   Ada.Text_IO.Put_Line ("Swapping nodes in a linked list: OK");
end Tests;
