pragma Ada_2022;
package Gaussian_Elimination with SPARK_Mode => On is
   subtype Row is Integer range 1 .. 2;
   subtype Column is Integer range 1 .. 3;
   subtype Entry_Value is Integer range -10 .. 10;
   type Input_Matrix is array (Row, Column) of Entry_Value;
   type Reduced_Matrix is array (Row, Column) of Long_Long_Integer;

   function Eliminate (Augmented : Input_Matrix) return Reduced_Matrix
     with Global => null;
end Gaussian_Elimination;
