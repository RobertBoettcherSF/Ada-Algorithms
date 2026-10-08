pragma Ada_2022;
package body Summary_Ranges with SPARK_Mode => On is
   function Summary (N : Number) return Range_Count is
   begin
      case N is
         when 0 | 1 => return 0;
         when 2 | 3 => return 1;
         when 4 | 5 | 6 => return 2;
         when 7 | 8 | 9 | 10 => return 3;
      end case;
   end Summary;
end Summary_Ranges;
