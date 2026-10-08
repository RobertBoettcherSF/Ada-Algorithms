pragma Ada_2022;

package body Letter_Combinations_Of_A_Phone_Number
  with SPARK_Mode => On is
   function Count_Combinations (Number_Of_Digits : Digit_Count) return Combination_Count is
   begin
      case Number_Of_Digits is
         when 0 => return 1;
         when 1 => return 3;
         when 2 => return 9;
         when 3 => return 27;
         when 4 => return 81;
         when 5 => return 243;
         when 6 => return 729;
         when 7 => return 2_187;
         when 8 => return 6_561;
         when 9 => return 19_683;
         when 10 => return 59_049;
         when 11 => return 177_147;
         when 12 => return 531_441;
      end case;
   end Count_Combinations;
end Letter_Combinations_Of_A_Phone_Number;
