pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Symmetric_Tree; use Symmetric_Tree;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 1, 2, 3);
   Set_Node (T, 2, 2, 4, 5);
   Set_Node (T, 3, 2, 6, 7);
   Set_Node (T, 4, 3, 0, 0);
   Set_Node (T, 5, 4, 0, 0);
   Set_Node (T, 6, 4, 0, 0);
   Set_Node (T, 7, 3, 0, 0);
   if not Is_Symmetric (T, 1) then
      raise Program_Error;
   end if;
   Set_Node (T, 7, 8, 0, 0);
   if Is_Symmetric (T, 1) then
      raise Program_Error;
   end if;
   Put_Line ("Symmetric Tree: PASS");
end Tests;
