pragma Ada_2022;
package Clone_Graph with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   type Graph is array (Vertex, Vertex) of Boolean;

   function Clone (G : Graph) return Graph with Global => null;
end Clone_Graph;
