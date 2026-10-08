pragma Ada_2022;
package Critical_Connections_In_A_Network_Lite with SPARK_Mode => On is
   Capacity : constant := 6;
   Edge_Capacity : constant := 16;
   subtype Node is Positive range 1 .. Capacity;
   subtype Edge_Index is Positive range 1 .. Edge_Capacity;
   subtype Bridge_Count is Natural range 0 .. Edge_Capacity;
   type Edge is record U, V : Node; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   procedure Count_Bridges (Edges : in Edge_Array; Result : out Bridge_Count);
end Critical_Connections_In_A_Network_Lite;
