pragma Ada_2022;

package body Permutations with SPARK_Mode => On is
   function Count_Permutations (Items : Item_Count) return Permutation_Count is
   begin
      case Items is
         when 0 => return 1;
         when 1 => return 1;
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
   end Count_Permutations;
end Permutations;
