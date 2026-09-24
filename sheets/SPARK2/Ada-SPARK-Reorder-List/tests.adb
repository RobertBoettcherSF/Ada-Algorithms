with Reorder_List;
with Ada.Text_IO;
procedure Tests is
   use Reorder_List;
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4); Append (L, 5);
   Reorder (L);
   pragma Assert (Element (L, 1) = 1);
   pragma Assert (Element (L, 2) = 5);
   pragma Assert (Element (L, 3) = 2);
   pragma Assert (Element (L, 4) = 4);
   pragma Assert (Element (L, 5) = 3);
   Ada.Text_IO.Put_Line ("Reorder list: OK");
end Tests;
