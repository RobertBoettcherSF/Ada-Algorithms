pragma Ada_2022;
package Minimum_Path_Sum with SPARK_Mode => On is
   Grid_Size : constant := 4;
   subtype Coordinate is Positive range 1 .. Grid_Size;
   subtype Cost is Natural range 0 .. 9;
   type Grid is array (Coordinate, Coordinate) of Cost;
   subtype Path_Sum is Natural range 0 .. 72;
   function Minimum (G : Grid) return Path_Sum with Global => null;
end Minimum_Path_Sum;
