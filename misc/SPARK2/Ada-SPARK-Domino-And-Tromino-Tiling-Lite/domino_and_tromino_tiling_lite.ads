pragma Ada_2022;
package Domino_And_Tromino_Tiling_Lite with SPARK_Mode => On is
   --  Failing-test scaffold: Columns widened to 0 .. 28 (the body is still
   --  the n <= 16 table).
   subtype Column_Count is Natural range 0 .. 28;
   subtype Tiling_Count is Natural;
   function Number_Of_Tilings (Columns : Column_Count) return Tiling_Count
     with Global => null;
end Domino_And_Tromino_Tiling_Lite;
