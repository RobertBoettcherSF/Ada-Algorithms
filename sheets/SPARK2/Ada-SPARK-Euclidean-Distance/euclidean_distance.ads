pragma Ada_2022;
package Euclidean_Distance with SPARK_Mode => On is
   subtype Coordinate is Integer range -10 .. 10;
   type Point is array (1 .. 2) of Coordinate;
   function Distance (A, B : Point) return Integer with Global => null;
end Euclidean_Distance;
