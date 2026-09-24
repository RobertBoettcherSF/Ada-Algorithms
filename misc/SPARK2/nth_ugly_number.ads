pragma SPARK_Mode (On);

package Nth_Ugly_Number is
   subtype Input is Positive range 1 .. 32;
   subtype Number is Positive range 1 .. 1_000;

   function Is_Ugly (N : Number) return Boolean;
   function Compute (N : Input) return Number;
end Nth_Ugly_Number;
