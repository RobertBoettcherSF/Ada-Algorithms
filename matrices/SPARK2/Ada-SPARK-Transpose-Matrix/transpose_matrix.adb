pragma Ada_2022;
package body Transpose_Matrix with SPARK_Mode => On is
   procedure Transpose (Input : in out Matrix) is
      Temp : Pixel;
   begin
      for Row in Index loop
         for Column in Index loop
            if Column > Row then
               Temp := Input (Row, Column);
               Input (Row, Column) := Input (Column, Row);
               Input (Column, Row) := Temp;
            end if;
         end loop;
      end loop;
   end Transpose;
end Transpose_Matrix;
