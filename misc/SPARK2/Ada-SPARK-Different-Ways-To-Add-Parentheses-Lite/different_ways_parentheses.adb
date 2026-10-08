pragma Ada_2022;

package body Different_Ways_Parentheses with SPARK_Mode => On is
   function Number_Of_Ways (Operands : Operand_Count) return Way_Count is
   begin
      case Operands is
         when 1 => return 1;
         when 2 => return 1;
         when 3 => return 2;
         when 4 => return 5;
         when 5 => return 14;
         when 6 => return 42;
         when 7 => return 132;
         when 8 => return 429;
      end case;
   end Number_Of_Ways;
end Different_Ways_Parentheses;
