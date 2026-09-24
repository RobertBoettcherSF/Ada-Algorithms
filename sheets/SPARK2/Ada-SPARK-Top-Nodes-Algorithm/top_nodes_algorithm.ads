pragma SPARK_Mode (On);

package Top_Nodes_Algorithm is
   Max_Nodes : constant := 4;
   subtype Node_Id is Positive range 1 .. Max_Nodes;
   subtype Node_Score is Natural range 0 .. 100;
   type Score_Array is array (Node_Id) of Node_Score;

   function Top_Node (Scores : Score_Array) return Node_Id;
end Top_Nodes_Algorithm;
