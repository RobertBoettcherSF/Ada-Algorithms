pragma Ada_2022;
package Unique_Paths_With_Obstacles with SPARK_Mode => On is
   Grid_Size : constant := 4;
   subtype Coordinate is Positive range 1 .. Grid_Size;
   type Grid is array (Coordinate, Coordinate) of Boolean;
   subtype Path_Count is Natural range 0 .. 64;
   function Count (G : Grid) return Path_Count with Global => null;
end Unique_Paths_With_Obstacles;
