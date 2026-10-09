pragma SPARK_Mode (On);

package Sqrtx is
   subtype Input is Natural range 0 .. 10_000;
   subtype Root is Natural range 0 .. 100;

   subtype Probe_Count is Natural range 0 .. Root'Last + 1;
   type Root_Result is record
      Value  : Root;          --  floor of the square root
      Probes : Probe_Count;   --  candidate roots squared and compared
   end record;

   function Integer_Square_Root (Value : Input) return Root_Result
     with Global => null;
end Sqrtx;
