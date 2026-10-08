pragma Ada_2022;
package body Matrix_Diagonal_Sum with SPARK_Mode => On is
   function Diagonal_Sum (Input : Matrix) return Integer is
      Result : Integer := 0;
   begin
      for Position in Index loop
         Result := Result + Input (Position, Position);
         Result := Result + Input (Position, Index'Last + Index'First - Position);
      end loop;
      return Result;
   end Diagonal_Sum;
end Matrix_Diagonal_Sum;
