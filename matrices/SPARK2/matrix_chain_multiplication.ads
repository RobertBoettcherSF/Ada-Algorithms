pragma Ada_2022;
package Matrix_Chain_Multiplication with SPARK_Mode => On is
   subtype Dimension is Positive range 1 .. 20;
   type Dimension_Array is array (Positive range 1 .. 4) of Dimension;
   subtype Cost is Integer;

   function Minimum_Cost (Dimensions : Dimension_Array) return Cost;
end Matrix_Chain_Multiplication;
