pragma Ada_2022;
package Kruskals_Algorithm with SPARK_Mode => On is
   Vertex_Count : constant := 4;
   Edge_Capacity : constant := 8;
   subtype Node is Positive range 1 .. Vertex_Count;
   subtype Edge_Index is Positive range 1 .. Edge_Capacity;
   subtype Edge_Count is Natural range 0 .. Edge_Capacity;
   subtype Edge_Weight is Natural range 0 .. 100;
   type Edge is record U, V : Node; Weight : Edge_Weight; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   type Parent_Array is array (Node) of Node;
   procedure Compute (Edges : in Edge_Array; Chosen : out Edge_Array; Count : out Edge_Count; Total : out Natural);
end Kruskals_Algorithm;
