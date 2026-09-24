pragma Ada_2022;
with Interfaces;
package body Xor_Of_Numbers_Range with SPARK_Mode => On is
   use type Word;
   function Xor_0_To (Value : Word) return Word is
   begin
      case Value mod 4 is
         when 0 => return Value;
         when 1 => return 1;
         when 2 => return Value + 1;
         when others => return 0;
      end case;
   end Xor_0_To;
end Xor_Of_Numbers_Range;
