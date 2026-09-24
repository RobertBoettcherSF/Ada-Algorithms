pragma Ada_2022;
package body Nth_Digit_Stub with SPARK_Mode => On is
   function Nth_Digit (P : Position) return Digit is
   begin
      -- Digits of the bounded sequence 1234567890, indexed from zero.
      case P is
         when 0 => return 1;
         when 1 => return 2;
         when 2 => return 3;
         when 3 => return 4;
         when 4 => return 5;
         when 5 => return 6;
         when 6 => return 7;
         when 7 => return 8;
         when 8 => return 9;
         when 9 => return 0;
      end case;
   end Nth_Digit;
end Nth_Digit_Stub;
