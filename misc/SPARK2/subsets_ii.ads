pragma Ada_2022;

package Subsets_II with SPARK_Mode => On is
   subtype Distinct_Value_Count is Integer range 0 .. 12;
   subtype Subset_Count is Integer range 1 .. 4_096;

   function Count_Distinct_Subsets
     (Distinct_Values : Distinct_Value_Count) return Subset_Count
     with Global => null;
end Subsets_II;
