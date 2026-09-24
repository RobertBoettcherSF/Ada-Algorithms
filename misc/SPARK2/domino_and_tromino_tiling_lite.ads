pragma Ada_2022;
package Domino_And_Tromino_Tiling_Lite with SPARK_Mode => On is
   subtype Column_Count is Natural range 0 .. 16;
   subtype Tiling_Count is Natural range 0 .. 200_000;
   function Number_Of_Tilings (Columns : Column_Count) return Tiling_Count
     with Global => null;
end Domino_And_Tromino_Tiling_Lite;
