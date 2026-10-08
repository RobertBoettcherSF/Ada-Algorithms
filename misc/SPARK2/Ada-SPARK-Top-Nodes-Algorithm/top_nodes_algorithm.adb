pragma SPARK_Mode (On);

package body Top_Nodes_Algorithm is
   function Top_Node (Scores : Score_Array) return Node_Id is
      Best : Node_Id := Node_Id'First;
   begin
      for N in Node_Id loop
         if Scores (N) > Scores (Best) then
            Best := N;
         end if;
      end loop;
      return Best;
   end Top_Node;
end Top_Nodes_Algorithm;
