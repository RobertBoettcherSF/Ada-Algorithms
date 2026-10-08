pragma Ada_2022;

package Subsets with SPARK_Mode => On is
   subtype Item_Count is Integer range 0 .. 12;
   subtype Subset_Count is Integer range 1 .. 4_096;

   function Count_Subsets (Items : Item_Count) return Subset_Count
     with Global => null;
end Subsets;
