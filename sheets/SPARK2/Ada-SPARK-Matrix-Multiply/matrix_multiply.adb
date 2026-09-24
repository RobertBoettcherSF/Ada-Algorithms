pragma Ada_2022;
package body Matrix_Multiply with SPARK_Mode => On is
   function Multiply (Left, Right : Input_Matrix) return Matrix is
      Result : Matrix;
   begin
      for Row in Index loop
         for Column in Index loop
            Result (Row, Column) :=
              Result_Element
                (Long_Long_Integer (Left (Row, 1)) * Long_Long_Integer (Right (1, Column))
                 + Long_Long_Integer (Left (Row, 2)) * Long_Long_Integer (Right (2, Column))
                 + Long_Long_Integer (Left (Row, 3)) * Long_Long_Integer (Right (3, Column))
                 + Long_Long_Integer (Left (Row, 4)) * Long_Long_Integer (Right (4, Column)));
         end loop;
      end loop;
      return Result;
   end Multiply;
end Matrix_Multiply;
