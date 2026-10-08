pragma SPARK_Mode (On);

package body Studio_Probe
  with SPARK_Mode => On
is
   function Abs_Diff (A, B : Value) return Non_Neg is
   begin
      if A >= B then
         return A - B;
      else
         return B - A;
      end if;
   end Abs_Diff;
end Studio_Probe;
