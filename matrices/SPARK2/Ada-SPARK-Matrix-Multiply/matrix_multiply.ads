pragma Ada_2022;
package Matrix_Multiply with SPARK_Mode => On is
   Matrix_Size : constant := 4;
   subtype Index is Integer range 1 .. Matrix_Size;
   subtype Element is Long_Long_Integer range -10 .. 10;
   subtype Result_Element is Long_Long_Integer range -400 .. 400;
   type Input_Matrix is array (Index, Index) of Element;
   type Matrix is array (Index, Index) of Result_Element;

   function Multiply (Left, Right : Input_Matrix) return Matrix
     with Global => null;
end Matrix_Multiply;
