pragma Ada_2022;
package body Pow_X_N with SPARK_Mode => On is
   function Power (X : Base_Value; N : Exponent) return Power_Value is
   begin
      case X is
         when -2 =>
            case N is
               when 0 => return 1;
               when 1 => return -2;
               when 2 => return 4;
               when 3 => return -8;
               when 4 => return 16;
               when 5 => return -32;
            end case;
         when -1 =>
            case N is
               when 0 => return 1;
               when 1 => return -1;
               when 2 | 4 => return 1;
               when 3 | 5 => return -1;
            end case;
         when 0 =>
            case N is
               when 0 => return 1;
               when 1 .. 5 => return 0;
            end case;
         when 1 => return 1;
         when 2 =>
            case N is
               when 0 => return 1;
               when 1 => return 2;
               when 2 => return 4;
               when 3 => return 8;
               when 4 => return 16;
               when 5 => return 32;
            end case;
      end case;
   end Power;
end Pow_X_N;
