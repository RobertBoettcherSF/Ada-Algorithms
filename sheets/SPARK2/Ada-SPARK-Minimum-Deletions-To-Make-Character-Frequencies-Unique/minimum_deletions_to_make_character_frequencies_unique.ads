pragma Ada_2022;
pragma SPARK_Mode (On);
package Minimum_Deletions_To_Make_Character_Frequencies_Unique is
   subtype Frequency is Natural range 0 .. 32;
   function Minimum_Deletions (Observed, Allowed : Frequency) return Frequency
     with Global => null;
end Minimum_Deletions_To_Make_Character_Frequencies_Unique;
