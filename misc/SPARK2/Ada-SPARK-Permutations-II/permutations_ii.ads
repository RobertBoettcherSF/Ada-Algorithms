pragma Ada_2022;

package Permutations_II with SPARK_Mode => On is
   subtype Item_Count is Integer range 0 .. 12;
   subtype Permutation_Count is Integer range 1 .. 479_001_600;

   function Count_Permutations
     (Items : Item_Count; Has_Repeated_Pair : Boolean)
      return Permutation_Count with Global => null;
end Permutations_II;
