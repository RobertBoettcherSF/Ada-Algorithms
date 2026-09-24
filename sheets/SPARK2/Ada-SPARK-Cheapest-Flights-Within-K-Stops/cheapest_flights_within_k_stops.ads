pragma Ada_2022;
package Cheapest_Flights_Within_K_Stops with SPARK_Mode => On is
   Capacity : constant := 6;
   Edge_Capacity : constant := 16;
   Infinity : constant := 1_000;
   subtype Node is Positive range 1 .. Capacity;
   subtype Edge_Index is Positive range 1 .. Edge_Capacity;
   subtype Fare is Natural range 0 .. 100;
   subtype Cost is Natural range 0 .. Infinity;
   subtype Stop_Count is Natural range 0 .. Capacity;
   type Edge is record U, V : Node; Price : Fare; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   procedure Compute (Edges : in Edge_Array; Source, Destination : in Node;
                       K : in Stop_Count; Result : out Cost);
end Cheapest_Flights_Within_K_Stops;
