pragma Ada_2022;
package Find_The_City_With_Smallest_Number_Of_Neighbors with SPARK_Mode => On is
   Capacity : constant := 6;
   Edge_Capacity : constant := 16;
   Infinity : constant := 1_000;
   subtype Node is Positive range 1 .. Capacity;
   subtype Edge_Index is Positive range 1 .. Edge_Capacity;
   subtype Weight is Natural range 0 .. 100;
   subtype Distance is Natural range 0 .. Infinity;
   subtype Threshold_Value is Natural range 0 .. 100;
   type Edge is record U, V : Node; W : Weight; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   procedure Compute (Edges : in Edge_Array; Threshold : in Threshold_Value;
                       Result : out Node);
end Find_The_City_With_Smallest_Number_Of_Neighbors;
