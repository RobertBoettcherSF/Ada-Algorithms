pragma Ada_2022;
package Bounding_Box with SPARK_Mode => On is
   Max_Points : constant := 16;
   subtype Coordinate is Integer range -1_000 .. 1_000;
   subtype Index is Integer range 1 .. Max_Points;
   subtype Count is Index;
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;
   type Point_Array is array (Index) of Point;
   type Box is record
      Min_X : Coordinate;
      Min_Y : Coordinate;
      Max_X : Coordinate;
      Max_Y : Coordinate;
   end record;

   function Enclose (Points : Point_Array; Number_Of_Points : Count) return Box
     with Global => null;
end Bounding_Box;
