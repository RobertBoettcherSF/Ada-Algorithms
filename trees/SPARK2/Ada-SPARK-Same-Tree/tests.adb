pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Same_Tree; use Same_Tree;

procedure Tests is
   T : Tree := Empty;
   U : Tree := Empty;
begin
   Set_Node (T, 1, 7, 2, 3);
   Set_Node (T, 2, 4, 0, 0);
   Set_Node (T, 3, 9, 0, 0);
   Set_Node (U, 5, 7, 6, 7);
   Set_Node (U, 6, 4, 0, 0);
   Set_Node (U, 7, 9, 0, 0);
   if not Are_Same (T, U, 1, 5) then
      raise Program_Error;
   end if;
   Set_Node (U, 7, 8, 0, 0);
   if Are_Same (T, U, 1, 5) then
      raise Program_Error;
   end if;
   Put_Line ("Same Tree: PASS");
end Tests;
