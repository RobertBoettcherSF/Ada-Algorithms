pragma Ada_2022;

package Unique_BSTs_Stub with SPARK_Mode => On is
   --  The count for 19 nodes (1,767,263,190) still fits in Integer; 20 does not.
   Max_Nodes : constant := 19;
   subtype Node_Count is Natural range 0 .. Max_Nodes;

   --  N! for N <= 19 (proof only): T (N) <= N! is the bound that keeps the
   --  dynamic-programming sums inside Long_Long_Integer.
   function Fact (N : Node_Count) return Long_Long_Integer is
     (case N is
         when 0 => 1,
         when 1 => 1,
         when 2 => 2,
         when 3 => 6,
         when 4 => 24,
         when 5 => 120,
         when 6 => 720,
         when 7 => 5_040,
         when 8 => 40_320,
         when 9 => 362_880,
         when 10 => 3_628_800,
         when 11 => 39_916_800,
         when 12 => 479_001_600,
         when 13 => 6_227_020_800,
         when 14 => 87_178_291_200,
         when 15 => 1_307_674_368_000,
         when 16 => 20_922_789_888_000,
         when 17 => 355_687_428_096_000,
         when 18 => 6_402_373_705_728_000,
         when 19 => 121_645_100_408_832_000)
     with Ghost;

   subtype Count is Long_Long_Integer range 1 .. 121_645_100_408_832_000;

   --  Number of structurally different binary search trees on the keys
   --  1 .. N (the N-th Catalan number).
   function Number_Of_Trees (N : Node_Count) return Count
     with Global => null,
          Post   => Number_Of_Trees'Result <= Fact (N);
end Unique_BSTs_Stub;
