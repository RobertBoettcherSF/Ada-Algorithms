pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Invert_Binary_Tree; use Invert_Binary_Tree;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3);
   Set_Node (T, 2, 2, 0, 0);
   Set_Node (T, 3, 3, 0, 0);
   Invert (T);
   if Left_Child (T, 1) /= 3 or else Right_Child (T, 1) /= 2 then
      raise Program_Error;
   end if;
   Put_Line ("Invert Binary Tree: PASS");
end Tests;
