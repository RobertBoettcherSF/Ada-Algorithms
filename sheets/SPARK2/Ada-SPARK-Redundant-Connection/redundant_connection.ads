pragma SPARK_Mode (On);

package Redundant_Connection is
   Capacity : constant := 5;
   subtype Vertex is Positive range 1 .. Capacity;
   type Edge is record
      From : Vertex;
      To   : Vertex;
   end record;
   type Edge_Array is array (Positive range 1 .. Capacity) of Edge;

   function Find_Redundant (Edges : Edge_Array) return Edge;
end Redundant_Connection;
