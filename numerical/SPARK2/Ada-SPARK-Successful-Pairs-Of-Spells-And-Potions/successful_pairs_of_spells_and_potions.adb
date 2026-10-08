pragma SPARK_Mode (On);

package body Successful_Pairs_Of_Spells_And_Potions is
   function Successful (S, P : Strength; T : Success_Threshold) return Pair_Count is
   begin
      if S * P >= T then
         return 1;
      else
         return 0;
      end if;
   end Successful;

   function Successful_Pairs
     (Spells, Potions : Strengths;
      Threshold : Success_Threshold) return Pair_Count is
   begin
      return Successful (Spells (1), Potions (1), Threshold)
        + Successful (Spells (1), Potions (2), Threshold)
        + Successful (Spells (2), Potions (1), Threshold)
        + Successful (Spells (2), Potions (2), Threshold);
   end Successful_Pairs;
end Successful_Pairs_Of_Spells_And_Potions;
