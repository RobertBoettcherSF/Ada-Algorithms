pragma Ada_2022;
package Is_Graph_Bipartite with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   type Graph is array (Vertex, Vertex) of Boolean;

   function Is_Bipartite (G : Graph) return Boolean with Global => null;
end Is_Graph_Bipartite;
