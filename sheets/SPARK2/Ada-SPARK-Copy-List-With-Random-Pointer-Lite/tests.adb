with Ada.Text_IO;
with Copy_List_With_Random_Pointer_Lite;
procedure Tests is
   use Copy_List_With_Random_Pointer_Lite;
   L : List := Empty;
   C : List;
   P : Position;
begin
   Append (L, 7); Append (L, 9);
   Set_Random (L, 1, 2);
   C := Copy_List (L);
   P := 1; pragma Assert (Element (C, P) = 7);
   pragma Assert (Random_Of (C, P) = 2);
   Ada.Text_IO.Put_Line ("Copy list with random pointer lite: OK");
end Tests;
