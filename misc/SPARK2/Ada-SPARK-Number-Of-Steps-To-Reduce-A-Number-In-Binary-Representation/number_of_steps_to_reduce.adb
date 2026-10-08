pragma Ada_2022;
package body Number_Of_Steps_To_Reduce with SPARK_Mode => On is
   function Steps (Value : Input) return Step_Count is
   begin
      case Value is
         when 1 => return 0;
         when 2 | 4 | 8 => return 1 + (if Value = 4 then 1 else 0) + (if Value = 8 then 2 else 0);
         when 3 => return 2;
         when 5 | 6 => return 3;
         when 9 | 10 | 12 => return 4;
         when 7 | 11 | 13 | 14 => return 4 + (if Value = 11 or else Value = 13 or else Value = 14 then 1 else 0);
         when 15 => return 6;
      end case;
   end Steps;
end Number_Of_Steps_To_Reduce;
