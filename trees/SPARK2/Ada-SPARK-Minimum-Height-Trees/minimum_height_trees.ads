pragma SPARK_Mode (On);

package Minimum_Height_Trees with SPARK_Mode => On is
   Capacity : constant := 4;
   subtype Vertex is Positive range 1 .. Capacity;
   type Graph is array (Vertex, Vertex) of Boolean;

   function Center (Edges : Graph) return Vertex
     with Global => null;
end Minimum_Height_Trees;
