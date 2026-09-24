pragma SPARK_Mode (On);

package Ugly_Number is
   subtype Number is Positive range 1 .. 2_147_483_647;

   function Is_Ugly (N : Number) return Boolean;
end Ugly_Number;
