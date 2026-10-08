pragma Ada_2022;

package K_Closest_Points_Stub with SPARK_Mode => On is
   subtype Point_Index is Positive range 1 .. 6;
   subtype Result_Index is Positive range 1 .. 3;
   subtype Coordinate is Integer range -20 .. 20;
   subtype Distance_Value is Natural range 0 .. 800;
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;
   type Point_Array is array (Point_Index) of Point;
   type Result_Array is array (Result_Index) of Point;

   function K_Closest (Points : Point_Array) return Result_Array
     with Global => null;
end K_Closest_Points_Stub;
