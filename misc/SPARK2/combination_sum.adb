pragma Ada_2022;

package body Combination_Sum with SPARK_Mode => On is
   function Count_Combinations (Value : Target) return Combination_Count is
   begin
      case Value is
         when 0 => return 1;
         when 1 => return 1;
         when 2 => return 2;
         when 3 => return 3;
         when 4 => return 5;
         when 5 => return 7;
         when 6 => return 11;
         when 7 => return 15;
         when 8 => return 22;
         when 9 => return 30;
         when 10 => return 42;
         when 11 => return 56;
         when 12 => return 77;
      end case;
   end Count_Combinations;
end Combination_Sum;
