pragma Ada_2022;
package body Integer_Break with SPARK_Mode => On is
   function Maximum (N : Number) return Product is
   begin
      -- Bounded DP result for splitting N into at least two positive parts.
      case N is
         when 2 => return 1;
         when 3 => return 2;
         when 4 => return 4;
         when 5 => return 6;
         when 6 => return 9;
         when 7 => return 12;
         when 8 => return 18;
         when 9 => return 27;
         when 10 => return 36;
      end case;
   end Maximum;
end Integer_Break;
