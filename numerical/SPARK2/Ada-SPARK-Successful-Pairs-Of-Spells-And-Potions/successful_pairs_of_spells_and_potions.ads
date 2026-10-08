pragma SPARK_Mode (On);

package Successful_Pairs_Of_Spells_And_Potions is
   subtype Strength is Integer range 1 .. 8;
   subtype Success_Threshold is Integer range 1 .. 64;
   subtype Pair_Count is Natural range 0 .. 4;
   type Strengths is array (1 .. 2) of Strength;

   function Successful_Pairs
     (Spells, Potions : Strengths;
      Threshold : Success_Threshold) return Pair_Count;
end Successful_Pairs_Of_Spells_And_Potions;
