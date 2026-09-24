pragma Ada_2022;

package Search_2D_Matrix with SPARK_Mode => On is
   Side : constant := 3;
   subtype Index is Positive range 1 .. Side;
   subtype Value is Integer range 0 .. 99;
   type Matrix is array (Index, Index) of Value;

   function Contains (Input : Matrix; Target : Value) return Boolean
     with Global => null;
end Search_2D_Matrix;
