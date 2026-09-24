pragma Ada_2022;
package Toeplitz_Matrix with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Pixel;
   function Is_Toeplitz (Input : Matrix) return Boolean;
end Toeplitz_Matrix;
