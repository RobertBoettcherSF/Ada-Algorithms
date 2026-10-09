--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Clone-Graph implementation; see PROOFS.csv stub
pragma SPARK_Mode (On);

package Clone_Graph_Stub is
   Node_Count : constant := 4;
   subtype Node is Positive range 1 .. Node_Count;
   type Graph is array (Node, Node) of Boolean;

   function Clone (Input : Graph) return Graph;
end Clone_Graph_Stub;
