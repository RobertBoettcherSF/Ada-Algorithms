pragma Ada_2022;

--  Failing-test scaffold: the range is widened to targets <= 30 and
--  Count_Limited is declared so the new test compiles; the body is still
--  the table for targets <= 12.
package Combination_Sum_II with SPARK_Mode => On is
   subtype Target is Integer range 0 .. 30;
   subtype Combination_Count is Natural range 0 .. 2 ** 30;

   function Count_Distinct_Combinations
     (Value : Target) return Combination_Count with Global => null;

   function Count_Limited (Value, Max_Part : Target) return Combination_Count
     with Global => null;
end Combination_Sum_II;
