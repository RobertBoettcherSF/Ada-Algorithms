pragma Ada_2022;
package Island_Perimeter with SPARK_Mode => On is
   Grid_Size : constant := 4;
   subtype Coordinate is Positive range 1 .. Grid_Size;
   type Grid is array (Coordinate, Coordinate) of Boolean;
   subtype Perimeter_Value is Natural range 0 .. 64;
   subtype Cell_Value is Natural range 0 .. 4;
   function Perimeter (G : Grid) return Perimeter_Value with Global => null;
end Island_Perimeter;
