pragma Ada_2022;
package Network_Delay_Time with SPARK_Mode => On is
   Capacity : constant := 6;
   Edge_Capacity : constant := 16;
   Infinity : constant := 1_000;
   subtype Node is Positive range 1 .. Capacity;
   subtype Edge_Index is Positive range 1 .. Edge_Capacity;
   subtype Weight is Natural range 0 .. 100;
   subtype Distance is Integer range -Infinity .. Infinity;
   type Edge is record U, V : Node; W : Weight; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   type Distance_Array is array (Node) of Distance;
   procedure Compute (Edges : in Edge_Array; Source : in Node; Result : out Distance_Array);
end Network_Delay_Time;
