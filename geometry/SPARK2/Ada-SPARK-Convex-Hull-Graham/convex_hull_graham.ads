pragma Ada_2022;
package Convex_Hull_Graham with SPARK_Mode => On is
   Max_Points : constant := 16;
   subtype Coordinate is Integer range -100 .. 100;
   subtype Index is Integer range 1 .. Max_Points;
   subtype Count is Index;
   subtype Hull_Length is Integer range 0 .. Max_Points;
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;
   type Point_Array is array (Index) of Point;

   procedure Scan (Points : in Point_Array; Number_Of_Points : in Count;
                   Hull : out Point_Array; Hull_Count : out Hull_Length)
     with Global => null;
end Convex_Hull_Graham;
