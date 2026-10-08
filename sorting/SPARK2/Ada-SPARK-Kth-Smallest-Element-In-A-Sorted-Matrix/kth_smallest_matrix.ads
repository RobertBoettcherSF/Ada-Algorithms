pragma Ada_2022;
package Kth_Smallest_Matrix with SPARK_Mode => On is
   Matrix_Size : constant := 8;
   subtype Dimension is Positive range 1 .. Matrix_Size;
   subtype Rank is Positive range 1 .. Matrix_Size * Matrix_Size;
   type Matrix is array (Dimension, Dimension) of Integer;
   function Kth (M : Matrix; N : Dimension; K : Rank) return Integer
     with Pre => K <= N * N;
end Kth_Smallest_Matrix;
