pragma Ada_2022;
package Bellman_Ford_Algorithm with SPARK_Mode => On is
   Capacity : constant := 4;
   Infinity : constant := 1000;
   subtype Node is Positive range 1 .. Capacity;
   subtype Edge_Index is Positive range 1 .. 16;
   subtype Edge_Weight is Integer range -20 .. 100;
   subtype Distance is Integer range -1000 .. Infinity;
   type Edge is record U, V : Node; Weight : Edge_Weight; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   type Distance_Array is array (Node) of Distance;
   procedure Compute (Edges : in Edge_Array; Source : in Node; D : out Distance_Array);
end Bellman_Ford_Algorithm;
