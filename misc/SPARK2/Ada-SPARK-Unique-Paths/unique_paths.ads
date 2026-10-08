pragma Ada_2022;
package Unique_Paths with SPARK_Mode => On is
   subtype Dimension is Positive range 1 .. 4;
   subtype Path_Count is Natural range 0 .. 64;
   function Count (Rows, Columns : Dimension) return Path_Count with Global => null;
end Unique_Paths;
