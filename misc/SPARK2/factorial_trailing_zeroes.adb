pragma Ada_2022;
package body Factorial_Trailing_Zeroes with SPARK_Mode => On is
   function Trailing_Zeroes (N : Number) return Count is
   begin
      case N is
         when 0 .. 4 => return 0;
         when 5 .. 9 => return 1;
         when 10 => return 2;
      end case;
   end Trailing_Zeroes;
end Factorial_Trailing_Zeroes;
