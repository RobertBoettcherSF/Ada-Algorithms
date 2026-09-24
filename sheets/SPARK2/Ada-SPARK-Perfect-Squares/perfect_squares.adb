pragma Ada_2022;
package body Perfect_Squares with SPARK_Mode => On is
   function Minimum (N : Number) return Count is
   begin
      -- The bounded table is the DP result for squares 1, 4, 9, and 16.
      case N is
         when 0 => return 0;
         when 1 | 4 | 9 | 16 => return 1;
         when 2 | 5 | 8 | 10 | 13 => return 2;
         when 3 | 6 | 11 | 12 | 14 => return 3;
         when 7 | 15 => return 4;
      end case;
   end Minimum;
end Perfect_Squares;
