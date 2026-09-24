pragma Ada_2022;
package Swim_In_Rising_Water with SPARK_Mode => On is
   Side : constant := 4;
   Cells : constant := Side * Side;
   subtype Cell is Positive range 1 .. Cells;
   subtype Elevation is Natural range 0 .. 100;
   type Elevation_Array is array (Cell) of Elevation;
   procedure Compute (Grid : in Elevation_Array; Result : out Elevation);
end Swim_In_Rising_Water;
