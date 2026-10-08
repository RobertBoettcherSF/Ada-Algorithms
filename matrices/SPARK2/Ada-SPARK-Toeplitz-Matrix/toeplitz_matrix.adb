pragma Ada_2022;
package body Toeplitz_Matrix with SPARK_Mode => On is
   function Is_Toeplitz (Input : Matrix) return Boolean is
      Result : Boolean := True;
   begin
      for Row in 2 .. Side loop
         for Column in 2 .. Side loop
            if Input (Row, Column) /= Input (Row - 1, Column - 1) then
               Result := False;
            end if;
         end loop;
      end loop;
      return Result;
   end Is_Toeplitz;
end Toeplitz_Matrix;
