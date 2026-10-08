pragma SPARK_Mode (On);

package Prim_Mst_Lite with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   subtype Weight is Natural range 0 .. Capacity;
   subtype Total is Natural range 0 .. Capacity * Capacity;
   type Graph is array (Vertex, Vertex) of Weight;

   function Mst_Weight (Edges : Graph; N : Vertex) return Total
     with Global => null;
end Prim_Mst_Lite;
