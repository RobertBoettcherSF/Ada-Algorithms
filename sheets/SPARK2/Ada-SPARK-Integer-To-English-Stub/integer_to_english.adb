pragma SPARK_Mode (On);

package body Integer_To_English is
   function To_English (Value : Number) return English_Number is
   begin
      case Value is
         when 0 => return Zero;
         when 1 => return One;
         when 2 => return Two;
         when 3 => return Three;
         when 4 => return Four;
         when 5 => return Five;
         when 6 => return Six;
         when 7 => return Seven;
         when 8 => return Eight;
         when 9 => return Nine;
         when 10 => return Ten;
         when 11 => return Eleven;
         when 12 => return Twelve;
         when 13 => return Thirteen;
         when 14 => return Fourteen;
         when 15 => return Fifteen;
         when 16 => return Sixteen;
         when 17 => return Seventeen;
         when 18 => return Eighteen;
         when 19 => return Nineteen;
      end case;
   end To_English;
end Integer_To_English;
