pragma SPARK_Mode (On);

--  Integer square root: the largest R with R * R <= Value, found by
--  halving the candidate roots 0 .. 100.
package Sqrtx is
   subtype Input is Natural range 0 .. 10_000;
   subtype Root is Natural range 0 .. 100;

   --  101 candidates: at most ceil (log2 101) = 7 squared.
   subtype Probe_Count is Natural range 0 .. 7;
   type Root_Result is record
      Value  : Root;          --  floor of the square root
      Probes : Probe_Count;   --  candidate roots squared and compared
   end record;

   function Integer_Square_Root (Value : Input) return Root_Result
   with
     Global => null,
     Post   =>
       Integer_Square_Root'Result.Value * Integer_Square_Root'Result.Value <= Value
       and then Value < (Integer_Square_Root'Result.Value + 1) * (Integer_Square_Root'Result.Value + 1);
end Sqrtx;
