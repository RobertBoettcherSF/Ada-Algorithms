pragma Ada_2022;
package K_Closest_Points with SPARK_Mode => On is
   Capacity : constant := 32;
   subtype Size is Positive range 1 .. Capacity;
   subtype Distance is Natural range 0 .. 20_000;
   subtype Coordinate is Integer range -100 .. 100;
   type Point is record X, Y : Coordinate; end record;
   type Point_Array is array (Size) of Point;
   function Kth_Distance (P : Point_Array; N : Size; K : Size) return Distance
     with Pre => K <= N;
end K_Closest_Points;
