pragma Ada_2022;
package Number_Of_Islands_DFS with SPARK_Mode => On is
   Grid_Size : constant := 4;
   subtype Coordinate is Positive range 1 .. Grid_Size;
   type Grid is array (Coordinate, Coordinate) of Boolean;
   subtype Island_Count is Natural range 0 .. 16;
   function Count (G : Grid) return Island_Count with Global => null;
end Number_Of_Islands_DFS;
