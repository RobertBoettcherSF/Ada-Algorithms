pragma Ada_2022;

package Spiral_Matrix_II with SPARK_Mode => On is
   subtype Size is Positive range 1 .. 8;
   subtype Index is Positive range 1 .. 8;
   subtype Cell is Natural range 0 .. 64;
   type Matrix is array (Index, Index) of Cell;

   function Generate (N : Size) return Matrix
     with Global => null;
end Spiral_Matrix_II;
