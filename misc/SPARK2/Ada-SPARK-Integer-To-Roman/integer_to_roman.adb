pragma SPARK_Mode (On);

package body Integer_To_Roman is
   function To_Roman (Value : Input) return Roman_Code is
   begin
      case Value is
         when 1 => return "    I";
         when 2 => return "   II";
         when 3 => return "  III";
         when 4 => return "   IV";
         when 5 => return "    V";
         when 6 => return "   VI";
         when 7 => return "  VII";
         when 8 => return " VIII";
         when 9 => return "   IX";
         when 10 => return "    X";
      end case;
   end To_Roman;
end Integer_To_Roman;
