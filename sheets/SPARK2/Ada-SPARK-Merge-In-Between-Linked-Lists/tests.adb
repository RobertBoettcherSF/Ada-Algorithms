with Ada.Text_IO;
with Merge_In_Between_Linked_Lists;
procedure Tests is
   use Merge_In_Between_Linked_Lists;
   L : List := Empty;
   P : Position;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4); Append (L, 5);
   Merge_In_Between (L, 2, 4, 9);
   P := 1; pragma Assert (Element (L, P) = 1);
   P := 3; pragma Assert (Element (L, P) = 9);
   P := 5; pragma Assert (Element (L, P) = 5);
   Ada.Text_IO.Put_Line ("Merge in between linked lists: OK");
end Tests;
