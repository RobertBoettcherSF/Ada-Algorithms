pragma Ada_2022;
package body Pow_X_N_Stub with SPARK_Mode => On is
   function Power (X : Base; N : Exponent) return Result is
   begin
      case N is
         when 0 => return 1;
         when 1 => return X;
         when 2 => return X * X;
         when 3 => return X * X * X;
         when 4 => return X * X * X * X;
         when 5 => return X * X * X * X * X;
      end case;
   end Power;
end Pow_X_N_Stub;
