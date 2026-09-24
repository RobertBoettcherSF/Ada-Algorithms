pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Subtree_Of_Another_Tree; use Subtree_Of_Another_Tree;
procedure Tests is
   T : Tree := Empty; P : Tree := Empty; Q : Tree := Empty;
begin
   Set_Node (T, 1, 3, 2, 3); Set_Node (T, 2, 4, 0, 0); Set_Node (T, 3, 5, 0, 0);
   Set_Node (P, 1, 3, 2, 3); Set_Node (P, 2, 4, 0, 0); Set_Node (P, 3, 5, 0, 0);
   Set_Node (Q, 1, 6, 0, 0);
   if not Is_Subtree (T, 1, P, 1) or else Is_Subtree (T, 1, Q, 1) then raise Program_Error; end if;
   Put_Line ("Subtree check: PASS");
end Tests;
