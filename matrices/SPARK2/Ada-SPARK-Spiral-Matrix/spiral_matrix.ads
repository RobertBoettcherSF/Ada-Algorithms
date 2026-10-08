pragma Ada_2022;

package Spiral_Matrix with SPARK_Mode => On is
   Side : constant := 3;
   subtype Index is Positive range 1 .. Side;
   subtype Output_Index is Positive range 1 .. Side * Side;
   subtype Value is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Value;
   type Sequence is array (Output_Index) of Value;

   function Traverse (Input : Matrix) return Sequence
     with Global => null;
end Spiral_Matrix;
