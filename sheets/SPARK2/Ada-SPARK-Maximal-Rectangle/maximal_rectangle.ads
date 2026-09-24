pragma Ada_2022;

package Maximal_Rectangle with SPARK_Mode => On is
   subtype Count is Natural range 0 .. 4;
   subtype Row is Positive range 1 .. 4;
   subtype Column is Positive range 1 .. 4;
   subtype Cell is Natural range 0 .. 1;
   subtype Area is Natural range 0 .. 64;
   type Matrix is array (Row, Column) of Cell;

   function Max_Area (M : Matrix; Rows, Columns : Count) return Area
     with Global => null;
end Maximal_Rectangle;
