with Ada.Text_IO; use Ada.Text_IO;
with Design_Linked_List; use Design_Linked_List;
procedure Tests is
   L : List := Empty;
begin
   Append (L, 2); Append (L, 4); Push_Front (L, 1);
   if Length (L) /= 3 or else Element_At (L, 1) /= 1 or else Element_At (L, 3) /= 4 then raise Program_Error; end if;
   if not Contains (L, 2) or else Contains (L, 9) then raise Program_Error; end if;
   Put_Line ("Design linked list: PASS");
end Tests;
