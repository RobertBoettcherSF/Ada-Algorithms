pragma SPARK_Mode (On);

package Find_If_Path_Exists_In_Graph with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   type Graph is array (Vertex, Vertex) of Boolean;

   function Path_Exists (Edges : Graph; Start, Goal : Vertex) return Boolean
     with Global => null;
end Find_If_Path_Exists_In_Graph;
