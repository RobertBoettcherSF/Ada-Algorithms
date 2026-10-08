pragma SPARK_Mode (On);

package body Fast_Pow is
   function Power (Value : Base; Exp : Exponent) return Result is
   begin
      case Value is
         when 0 => if Exp = 0 then return 1; else return 0; end if;
         when 1 => return 1;
         when 2 =>
            case Exp is
               when 0 => return 1; when 1 => return 2; when 2 => return 4;
               when 3 => return 8; when 4 => return 16; when 5 => return 32;
               when 6 => return 64; when 7 => return 128; when 8 => return 256;
               when 9 => return 512; when 10 => return 1_024; when 11 => return 2_048;
               when 12 => return 4_096;
            end case;
         when 3 =>
            case Exp is
               when 0 => return 1; when 1 => return 3; when 2 => return 9;
               when 3 => return 27; when 4 => return 81; when 5 => return 243;
               when 6 => return 729; when 7 => return 2_187; when 8 => return 6_561;
               when 9 => return 19_683; when 10 => return 59_049; when 11 => return 177_147;
               when 12 => return 531_441;
            end case;
         when 4 =>
            case Exp is
               when 0 => return 1; when 1 => return 4; when 2 => return 16;
               when 3 => return 64; when 4 => return 256; when 5 => return 1_024;
               when 6 => return 4_096; when 7 => return 16_384; when 8 => return 65_536;
               when 9 => return 262_144; when 10 => return 1_048_576; when 11 => return 4_194_304;
               when 12 => return 16_777_216;
            end case;
         when 5 =>
            case Exp is
               when 0 => return 1; when 1 => return 5; when 2 => return 25;
               when 3 => return 125; when 4 => return 625; when 5 => return 3_125;
               when 6 => return 15_625; when 7 => return 78_125; when 8 => return 390_625;
               when 9 => return 1_953_125; when 10 => return 9_765_625;
               when 11 => return 48_828_125; when 12 => return 244_140_625;
            end case;
      end case;
   end Power;
end Fast_Pow;
