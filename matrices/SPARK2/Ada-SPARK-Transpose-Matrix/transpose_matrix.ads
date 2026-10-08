pragma Ada_2022;
package Transpose_Matrix with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Pixel;
   procedure Transpose (Input : in out Matrix);
end Transpose_Matrix;
