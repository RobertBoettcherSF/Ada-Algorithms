pragma Ada_2022;

package body Permutations_II with SPARK_Mode => On is
   function Count_Permutations
     (Items : Item_Count; Has_Repeated_Pair : Boolean)
      return Permutation_Count is
   begin
      if Has_Repeated_Pair and then Items >= 2 then
         case Items is
            when 0 | 1 => return 1;
            when 2 => return 1;
            when 3 => return 3;
            when 4 => return 12;
            when 5 => return 60;
            when 6 => return 360;
            when 7 => return 2_520;
            when 8 => return 20_160;
            when 9 => return 181_440;
            when 10 => return 1_814_400;
            when 11 => return 19_958_400;
            when 12 => return 239_500_800;
         end case;
      else
         case Items is
            when 0 | 1 => return 1;
            when 2 => return 2;
            when 3 => return 6;
            when 4 => return 24;
            when 5 => return 120;
            when 6 => return 720;
            when 7 => return 5_040;
            when 8 => return 40_320;
            when 9 => return 362_880;
            when 10 => return 3_628_800;
            when 11 => return 39_916_800;
            when 12 => return 479_001_600;
         end case;
      end if;
   end Count_Permutations;
end Permutations_II;
