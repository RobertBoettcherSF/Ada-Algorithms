pragma Ada_2022;

--  Combination Sum II, counting version: the number of ways to write Value
--  as a sum of distinct candidates from 1 .. Max_Part (each used at most
--  once, order does not matter). With Max_Part = Value this is q (Value),
--  the number of partitions into distinct parts.
package Combination_Sum_II with SPARK_Mode => On is
   subtype Target is Integer range 0 .. 30;
   subtype Combination_Count is Natural range 0 .. 2 ** 30;

   --  2 ** E, only used in the bound on Q. The own checks regenerate every
   --  entry by doubling.
   function Pow2 (E : Target) return Combination_Count is
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
        when 30 => 1_073_741_824)
   with Ghost;

   --  Q (N, C): sets of distinct parts from 1 .. C that sum to N. Either C
   --  is not used (Q (N, C - 1)) or it is, once (Q (N - C, C - 1)). There
   --  are only 2 ** C subsets of 1 .. C, so Q (N, C) <= 2 ** C.
   function Q (N, C : Target) return Combination_Count
   with
     Ghost,
     Post               => Q'Result <= Pow2 (C),
     Subprogram_Variant => (Decreases => C);

   function Count_Limited (Value, Max_Part : Target) return Combination_Count
   with
     Global => null,
     Post   => Count_Limited'Result = Q (Value, Max_Part);

   function Count_Distinct_Combinations (Value : Target) return Combination_Count
   with
     Global => null,
     Post   => Count_Distinct_Combinations'Result = Q (Value, Value);

private
   function Q (N, C : Target) return Combination_Count is
     (if N = 0 then 1
      elsif C = 0 then 0
      elsif C > N then Q (N, C - 1)
      else Q (N, C - 1) + Q (N - C, C - 1));
end Combination_Sum_II;
