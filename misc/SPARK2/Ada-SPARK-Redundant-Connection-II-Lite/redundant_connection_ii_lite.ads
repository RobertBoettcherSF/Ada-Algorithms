pragma Ada_2022;
package Redundant_Connection_II_Lite with SPARK_Mode => On is
   Capacity : constant := 6;
   Edge_Capacity : constant := 16;
   subtype Node is Positive range 1 .. Capacity;
   subtype Edge_Index is Positive range 1 .. Edge_Capacity;
   subtype Node_Count is Positive range 1 .. Capacity;
   subtype Edge_Result is Natural range 0 .. Edge_Capacity;
   type Edge is record U, V : Node; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   procedure Find_Redundant (Edges : in Edge_Array; Nodes : in Node_Count;
                             Edge_Count : in Edge_Index; Result : out Edge_Result);
end Redundant_Connection_II_Lite;
