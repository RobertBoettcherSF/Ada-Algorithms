pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Lowest_Common_Ancestor_Of_BST; use Lowest_Common_Ancestor_Of_BST;
procedure Tests is
   T : Tree := Empty;
begin
   Set_Node (T, 1, 6, 2, 3); Set_Node (T, 2, 2, 4, 5); Set_Node (T, 3, 8, 0, 6);
   Set_Node (T, 4, 0, 0, 0); Set_Node (T, 5, 4, 0, 0); Set_Node (T, 6, 9, 0, 0);
   if Lowest_Common_Ancestor (T, 1, 0, 4) /= 2
     or else Lowest_Common_Ancestor (T, 1, 4, 9) /= 1 then raise Program_Error; end if;
   Put_Line ("Lowest common ancestor: PASS");
end Tests;
