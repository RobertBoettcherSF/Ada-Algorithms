pragma SPARK_Mode (On);

--  N! for N <= 20.
--
--  Why 20: 20! = 2_432_902_008_176_640_000 <= Long_Long_Integer'Last
--  (2 ** 63 - 1), while 21! = 51_090_942_171_709_440_000 does not fit. (With
--  Natural the limit would be 12: 13! = 6_227_020_800.)
package Factorial is
   subtype Input is Natural range 0 .. 20;
   subtype Result is Long_Long_Integer range 1 .. Long_Long_Integer'Last;

   --  Ghost proof aid for the overflow bound: N! for N <= 20. The proof
   --  checks every entry against the recurrence (Post of Fact); the tests
   --  regenerate it. The code does not use it.
   function Fact_Table (N : Input) return Result is
     (case N is
        when 0 => 1, when 1 => 1, when 2 => 2, when 3 => 6, when 4 => 24,
        when 5 => 120, when 6 => 720, when 7 => 5_040, when 8 => 40_320,
        when 9 => 362_880, when 10 => 3_628_800, when 11 => 39_916_800,
        when 12 => 479_001_600, when 13 => 6_227_020_800,
        when 14 => 87_178_291_200, when 15 => 1_307_674_368_000,
        when 16 => 20_922_789_888_000, when 17 => 355_687_428_096_000,
        when 18 => 6_402_373_705_728_000, when 19 => 121_645_100_408_832_000,
        when 20 => 2_432_902_008_176_640_000)
   with Ghost;

   --  The definition: 0! = 1, N! = N * (N - 1)!.
   function Fact (N : Input) return Result
   with
     Ghost,
     Post               => Fact'Result = Fact_Table (N),
     Subprogram_Variant => (Decreases => N);

   function Compute (N : Input) return Result
   with
     Global => null,
     Post   => Compute'Result = Fact (N);

private
   function Fact (N : Input) return Result is
     (if N = 0 then 1 else Long_Long_Integer (N) * Fact (N - 1));
end Factorial;
