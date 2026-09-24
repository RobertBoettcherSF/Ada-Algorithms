with Ada.Text_IO;
with Convert_Binary_Number_In_A_Linked_List_To_Integer;
procedure Tests is
   use Convert_Binary_Number_In_A_Linked_List_To_Integer;
   L : List := Empty;
   Answer : Result;
begin
   Append (L, 1); Append (L, 0); Append (L, 1); Append (L, 1);
   Answer := To_Integer (L);
   pragma Assert (Answer = 11);
   Ada.Text_IO.Put_Line ("Convert binary number in a linked list: OK");
end Tests;
