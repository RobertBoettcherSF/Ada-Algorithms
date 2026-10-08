pragma Ada_2022;
package body Paint_Fence_Lite with SPARK_Mode => On is
   function Count (N : Number_Of_Posts) return Ways is
   begin
      -- Two colors, with no run of three equal colors; n <= 16.
      case N is
         when 1 => return 2;
         when 2 => return 4;
         when 3 => return 6;
         when 4 => return 10;
         when 5 => return 16;
         when 6 => return 26;
         when 7 => return 42;
         when 8 => return 68;
         when 9 => return 110;
         when 10 => return 178;
         when 11 => return 288;
         when 12 => return 466;
         when 13 => return 754;
         when 14 => return 1_220;
         when 15 => return 1_974;
         when 16 => return 3_194;
      end case;
   end Count;
end Paint_Fence_Lite;
