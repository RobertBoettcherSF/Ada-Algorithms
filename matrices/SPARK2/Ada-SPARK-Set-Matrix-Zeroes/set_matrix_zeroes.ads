pragma Ada_2022;

package Set_Matrix_Zeroes with SPARK_Mode => On is
   Side : constant := 3;
   subtype Index is Positive range 1 .. Side;
   subtype Value is Integer range 0 .. 9;
   type Matrix is array (Index, Index) of Value;

   procedure Zero (Input : in out Matrix);
end Set_Matrix_Zeroes;
