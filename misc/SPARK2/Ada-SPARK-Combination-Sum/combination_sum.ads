pragma Ada_2022;

--  Combination Sum, counting version: the number of ways to write Value as
--  a sum of candidates 1 .. Max_Part, each usable any number of times,
--  where order does not matter (multisets). With Max_Part = Value this is
--  the partition number p (Value).
--
--  Why 31: the proof bounds every count by P (N, C) <= 2 ** (N + C) (each
--  step of the recurrence at most doubles), so N + C <= 62 keeps every
--  count inside Long_Long_Integer (2 ** 62 < 2 ** 63 - 1): Value and
--  Max_Part <= 31. The true counts are far smaller (p (31) = 6_842; p (n)
--  fits Natural up to n = 121), but the simple recurrence gives no tighter
--  bound. The run-time check of the ghost P in the tests also grows fast
--  with the target (about 8 s for every pair up to 30).
package Combination_Sum with SPARK_Mode => On is
   subtype Target is Integer range 0 .. 31;
   subtype Combination_Count is Long_Long_Integer range 0 .. 2 ** 62;

   subtype Exponent is Natural range 0 .. 62;

   --  2 ** E, only used in the bound on P. The own checks regenerate every
   --  entry by doubling.
   function Pow2 (E : Exponent) return Combination_Count is
     (case E is
        when 0 => 1, when 1 => 2, when 2 => 4, when 3 => 8, when 4 => 16,
        when 5 => 32, when 6 => 64, when 7 => 128, when 8 => 256,
        when 9 => 512, when 10 => 1_024, when 11 => 2_048, when 12 => 4_096,
        when 13 => 8_192, when 14 => 16_384, when 15 => 32_768,
        when 16 => 65_536, when 17 => 131_072, when 18 => 262_144,
        when 19 => 524_288, when 20 => 1_048_576, when 21 => 2_097_152,
        when 22 => 4_194_304, when 23 => 8_388_608, when 24 => 16_777_216,
        when 25 => 33_554_432, when 26 => 67_108_864, when 27 => 134_217_728,
        when 28 => 268_435_456, when 29 => 536_870_912,
        when 30 => 1_073_741_824, when 31 => 2_147_483_648,
        when 32 => 4_294_967_296, when 33 => 8_589_934_592,
        when 34 => 17_179_869_184, when 35 => 34_359_738_368,
        when 36 => 68_719_476_736, when 37 => 137_438_953_472,
        when 38 => 274_877_906_944, when 39 => 549_755_813_888,
        when 40 => 1_099_511_627_776, when 41 => 2_199_023_255_552,
        when 42 => 4_398_046_511_104, when 43 => 8_796_093_022_208,
        when 44 => 17_592_186_044_416, when 45 => 35_184_372_088_832,
        when 46 => 70_368_744_177_664, when 47 => 140_737_488_355_328,
        when 48 => 281_474_976_710_656, when 49 => 562_949_953_421_312,
        when 50 => 1_125_899_906_842_624, when 51 => 2_251_799_813_685_248,
        when 52 => 4_503_599_627_370_496, when 53 => 9_007_199_254_740_992,
        when 54 => 18_014_398_509_481_984, when 55 => 36_028_797_018_963_968,
        when 56 => 72_057_594_037_927_936,
        when 57 => 144_115_188_075_855_872,
        when 58 => 288_230_376_151_711_744,
        when 59 => 576_460_752_303_423_488,
        when 60 => 1_152_921_504_606_846_976,
        when 61 => 2_305_843_009_213_693_952,
        when 62 => 4_611_686_018_427_387_904)
   with Ghost;

   --  P (N, C): multisets of parts in 1 .. C that sum to N. Either no part
   --  equals C (P (N, C - 1)), or one part C is taken off (P (N - C, C)).
   --  P (N, C) <= 2 ** (N + C) keeps every count inside Combination_Count.
   function P (N, C : Target) return Combination_Count
   with
     Ghost,
     Post               => P'Result <= Pow2 (N + C),
     Subprogram_Variant => (Decreases => N, Decreases => C);

   function Count_Limited (Value, Max_Part : Target) return Combination_Count
   with
     Global => null,
     Post   => Count_Limited'Result = P (Value, Max_Part);

   function Count_Combinations (Value : Target) return Combination_Count
   with
     Global => null,
     Post   => Count_Combinations'Result = P (Value, Value);

private
   function P (N, C : Target) return Combination_Count is
     (if N = 0 then 1
      elsif C = 0 then 0
      elsif C > N then P (N, C - 1)
      else P (N, C - 1) + P (N - C, C));
end Combination_Sum;
