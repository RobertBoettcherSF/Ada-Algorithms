pragma Ada_2022;
package body Count_Sorted_Vowel_Strings with SPARK_Mode => On is
   function Number_Of_Strings (N : Length) return Count is
   begin
      -- C(n + 4, 4), tabulated for the bounded exercise.
      case N is
         when 0 => return 1;
         when 1 => return 5;
         when 2 => return 15;
         when 3 => return 35;
         when 4 => return 70;
         when 5 => return 126;
         when 6 => return 210;
         when 7 => return 330;
         when 8 => return 495;
         when 9 => return 715;
         when 10 => return 1_001;
         when 11 => return 1_365;
         when 12 => return 1_820;
         when 13 => return 2_380;
         when 14 => return 3_060;
         when 15 => return 3_876;
         when 16 => return 4_845;
      end case;
   end Number_Of_Strings;
end Count_Sorted_Vowel_Strings;
