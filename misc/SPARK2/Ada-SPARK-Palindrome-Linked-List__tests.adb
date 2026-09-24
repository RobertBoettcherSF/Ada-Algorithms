with Palindrome_Linked_List;
with Ada.Text_IO;
procedure Tests is
   use Palindrome_Linked_List;
   L : List := Empty;
   R : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 2); Append (L, 1);
   Append (R, 1); Append (R, 2); Append (R, 3);
   pragma Assert (Is_Palindrome (L));
   pragma Assert (not Is_Palindrome (R));
   pragma Assert (Element (L, 3) = 3);
   Ada.Text_IO.Put_Line ("Palindrome linked list: OK");
end Tests;
