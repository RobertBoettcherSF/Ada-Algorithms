pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with N_Ary_Tree_Preorder_Traversal; use N_Ary_Tree_Preorder_Traversal;

procedure Tests is
   T : Tree := Empty;
   R : Visit_Result;
begin
   Set_Node (T, 1, 1); Set_Node (T, 2, 2); Set_Node (T, 3, 3); Set_Node (T, 4, 4);
   Set_Child (T, 1, 1, 2); Set_Child (T, 1, 2, 3); Set_Child (T, 2, 1, 4);
   R := Preorder (T, 1);
   if R.Length /= 4 or else R.Values (1) /= 1 or else R.Values (2) /= 2 or else R.Values (3) /= 4 or else R.Values (4) /= 3 then
      raise Program_Error;
   end if;
   Put_Line ("N_Ary_Tree_Preorder_Traversal: PASS");
end Tests;
