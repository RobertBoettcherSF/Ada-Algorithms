pragma Ada_2022;
package Prims_Algorithm with SPARK_Mode => On is
   Capacity : constant := 4;
   Infinity : constant := 1000;
   subtype Node is Positive range 1 .. Capacity;
   subtype Weight is Natural range 0 .. Infinity;
   type Weight_Matrix is array (Node, Node) of Weight;
   type Parent_Array is array (Node) of Node;
   procedure Compute (Graph : in Weight_Matrix; Parent : out Parent_Array);
end Prims_Algorithm;
