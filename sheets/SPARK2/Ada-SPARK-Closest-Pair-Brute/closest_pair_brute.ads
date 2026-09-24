pragma Ada_2022;
package Closest_Pair_Brute with SPARK_Mode => On is
   Max_Points : constant := 16;
   subtype Coordinate is Integer range -1_000 .. 1_000;
   subtype Index is Integer range 1 .. Max_Points;
   subtype Count is Index;
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;
   type Point_Array is array (Index) of Point;

   function Distance_Squared (Left, Right : Point) return Long_Long_Integer
     with Global => null;
   function Find (Points : Point_Array; Number_Of_Points : Count)
     return Long_Long_Integer with Global => null;
end Closest_Pair_Brute;
