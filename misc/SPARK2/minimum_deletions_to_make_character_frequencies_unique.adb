pragma Ada_2022;
pragma SPARK_Mode (On);
package body Minimum_Deletions_To_Make_Character_Frequencies_Unique is
   function Minimum_Deletions (Observed, Allowed : Frequency) return Frequency is
   begin
      if Observed > Allowed then return Observed - Allowed; else return 0; end if;
   end Minimum_Deletions;
end Minimum_Deletions_To_Make_Character_Frequencies_Unique;
