pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Top_Nodes_Algorithm; use Top_Nodes_Algorithm;

procedure Tests is
   Scores   : Score_Array := (10, 75, 40, 60);
   Selected : Node_Id;
begin
   Selected := Top_Node (Scores);
   if Selected /= 2 then raise Program_Error; end if;
   Put_Line ("Top-nodes: PASS");
end Tests;
