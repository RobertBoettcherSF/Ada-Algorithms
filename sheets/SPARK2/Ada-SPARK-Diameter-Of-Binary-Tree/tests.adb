pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Diameter_Of_Binary_Tree; use Diameter_Of_Binary_Tree;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3);
   Set_Node (T, 2, 2, 4, 5);
   Set_Node (T, 3, 3, 0, 6);
   Set_Node (T, 4, 4, 0, 0);
   Set_Node (T, 5, 5, 0, 0);
   Set_Node (T, 6, 6, 0, 0);
   if Diameter (T, 1) /= 4 then
      raise Program_Error;
   end if;
   Put_Line ("Diameter Of Binary Tree: PASS");
end Tests;
