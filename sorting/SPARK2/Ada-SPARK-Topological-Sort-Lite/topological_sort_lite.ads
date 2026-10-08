pragma SPARK_Mode (On);

package Topological_Sort_Lite with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   type Graph is array (Vertex, Vertex) of Boolean;
   type Order_Array is array (Vertex) of Vertex;

   function Is_Valid_Order
     (Edges : Graph; Order : Order_Array; N : Vertex) return Boolean
     with Global => null;
end Topological_Sort_Lite;
