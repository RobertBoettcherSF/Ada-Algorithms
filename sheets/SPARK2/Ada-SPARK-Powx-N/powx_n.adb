pragma SPARK_Mode (On);

package body Powx_N is
   function Power_Of (X : Base; N : Exponent) return Power is
   begin
      case N is
         when 0 => return 1;
         when 1 => return X;
         when 2 => return X * X;
      end case;
   end Power_Of;
end Powx_N;
