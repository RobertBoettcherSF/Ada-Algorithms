pragma Ada_2022;
package Matrix_Diagonal_Sum with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Pixel is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Pixel;
   function Diagonal_Sum (Input : Matrix) return Integer;
end Matrix_Diagonal_Sum;
