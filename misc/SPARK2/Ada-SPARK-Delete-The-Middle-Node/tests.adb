with Ada.Text_IO;
with Delete_The_Middle_Node;
procedure Tests is
   use Delete_The_Middle_Node;
   L : List := Empty;
   P : Position;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4); Append (L, 5);
   Delete_Middle (L);
   pragma Assert (Length (L) = 4);
   P := 3; pragma Assert (Element (L, P) = 4);
   Ada.Text_IO.Put_Line ("Delete the middle node: OK");
end Tests;
