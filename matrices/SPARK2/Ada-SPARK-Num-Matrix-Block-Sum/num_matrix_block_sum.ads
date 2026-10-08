pragma Ada_2022;
package Num_Matrix_Block_Sum with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 4;
   subtype Cell is Natural range 0 .. 9;
   subtype Radius is Natural range 0 .. 3;
   type Matrix is array (Index, Index) of Cell;
   function Block_Sum (A : Matrix; Row, Col : Index; K : Radius) return Long_Long_Integer with Global => null;
end Num_Matrix_Block_Sum;
