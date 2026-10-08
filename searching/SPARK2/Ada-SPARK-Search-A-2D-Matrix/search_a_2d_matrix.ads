pragma Ada_2022;

package Search_A_2D_Matrix with SPARK_Mode => On is
   Rows : constant := 8;
   Cols : constant := 8;
   subtype Row is Positive range 1 .. Rows;
   subtype Column is Positive range 1 .. Cols;
   subtype Value is Integer range 0 .. 100;
   type Matrix is array (Row, Column) of Value;

   function Contains (Grid : Matrix; Target : Value) return Boolean
     with Global => null;
end Search_A_2D_Matrix;
