pragma Ada_2022;
package Reshape_The_Matrix with SPARK_Mode => On is
   subtype Pixel is Integer range 0 .. 99;
   subtype Source_Row is Positive range 1 .. 2;
   subtype Source_Column is Positive range 1 .. 4;
   subtype Target_Row is Positive range 1 .. 4;
   subtype Target_Column is Positive range 1 .. 2;
   type Source is array (Source_Row, Source_Column) of Pixel;
   type Matrix is array (Target_Row, Target_Column) of Pixel;
   procedure Reshape (Input : in Source; Output : out Matrix);
end Reshape_The_Matrix;
