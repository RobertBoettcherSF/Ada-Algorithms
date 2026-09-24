pragma SPARK_Mode (On);

package Dijkstra_Lite with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   subtype Weight is Natural range 0 .. Capacity;
   subtype Distance is Natural range 0 .. 255;
   type Graph is array (Vertex, Vertex) of Weight;

   function Shortest_Path (Edges : Graph; Start, Goal : Vertex) return Distance
     with Global => null;
end Dijkstra_Lite;
