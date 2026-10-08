pragma Ada_2022;

package Minimum_Number_Of_Days_To_Make_M_Bouquets with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Day is Positive range 1 .. 1_000;
   subtype Bouquet_Size is Positive range 1 .. Length;
   type Bloom_Array is array (Index) of Day;

   function Minimum_Day
     (Bloom_Days : Bloom_Array; Size : Bouquet_Size) return Day
     with Global => null;
end Minimum_Number_Of_Days_To_Make_M_Bouquets;
