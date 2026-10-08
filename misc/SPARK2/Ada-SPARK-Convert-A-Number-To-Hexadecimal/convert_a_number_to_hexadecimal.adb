pragma Ada_2022;
package body Convert_A_Number_To_Hexadecimal with SPARK_Mode => On is
   function Digit (Value : Nibble) return Character is
   begin
      case Value is
         when 0 => return '0'; when 1 => return '1';
         when 2 => return '2'; when 3 => return '3';
         when 4 => return '4'; when 5 => return '5';
         when 6 => return '6'; when 7 => return '7';
         when 8 => return '8'; when 9 => return '9';
         when 10 => return 'A'; when 11 => return 'B';
         when 12 => return 'C'; when 13 => return 'D';
         when 14 => return 'E'; when 15 => return 'F';
      end case;
   end Digit;
end Convert_A_Number_To_Hexadecimal;
