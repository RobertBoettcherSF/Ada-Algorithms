pragma SPARK_Mode (On);

package N_Th_Tribonacci is
   subtype Input is Natural range 0 .. 32;
   subtype Result is Natural range 0 .. 1_000_000_000;

   function Compute (N : Input) return Result;
end N_Th_Tribonacci;
