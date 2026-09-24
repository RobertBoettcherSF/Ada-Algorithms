pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Reverse_Linked_List; use Reverse_Linked_List;

procedure Tests is
   L : List := Empty;
begin
   Append (L, 1); Append (L, 2); Append (L, 3); Append (L, 4);
   Reverse_List (L);
   if Length (L) /= 4 or else Element (L, 1) /= 4 or else Element (L, 4) /= 1 then raise Program_Error; end if;
   Put_Line ("Reverse linked list: PASS");
end Tests;
