pragma Ada_2022;

package body Subsets with SPARK_Mode => On is
   function Count_Subsets (Items : Item_Count) return Subset_Count is
   begin
      case Items is
         when 0 => return 1;
         when 1 => return 2;
         when 2 => return 4;
         when 3 => return 8;
         when 4 => return 16;
         when 5 => return 32;
         when 6 => return 64;
         when 7 => return 128;
         when 8 => return 256;
         when 9 => return 512;
         when 10 => return 1_024;
         when 11 => return 2_048;
         when 12 => return 4_096;
      end case;
   end Count_Subsets;
end Subsets;
