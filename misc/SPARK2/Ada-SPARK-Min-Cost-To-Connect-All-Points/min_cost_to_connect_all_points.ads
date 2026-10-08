pragma Ada_2022;
package Min_Cost_To_Connect_All_Points with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Point_Index is Positive range 1 .. Capacity;
   subtype Coordinate is Integer range -20 .. 20;
   subtype Link_Cost is Natural range 0 .. 80;
   subtype Total_Cost is Natural range 0 .. 640;
   type Point is record X, Y : Coordinate; end record;
   type Point_Array is array (Point_Index) of Point;
   procedure Compute (Points : in Point_Array; Result : out Total_Cost);
end Min_Cost_To_Connect_All_Points;
