pragma Ada_2022;
package Count_Square_Submatrices_With_All_Ones with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 4;
   subtype Bit is Natural range 0 .. 1;
   type Matrix is array (Index, Index) of Bit;
   function Count_Squares (A : Matrix) return Long_Long_Integer with Global => null;
end Count_Square_Submatrices_With_All_Ones;
