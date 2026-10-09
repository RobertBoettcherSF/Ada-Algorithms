pragma SPARK_Mode (On);

package body Maximum_Subarray is
   --  No saturation: with N <= 4 and every value in -100 .. 100, the running sum stays in
   --  -100 .. 100 * (I - 1) <= 300, far inside Score; the loop invariants carry that bound.
   function Best_Sum (A : Values; N : Length) return Score is
      Current, Best : Score;
   begin
      if N = 0 then
         return 0;
      end if;
      Current := Score (A (1));
      Best := Current;
      for I in 2 .. N loop
         pragma Loop_Invariant (Current in -100 .. 100 * (I - 1));
         pragma Loop_Invariant (Best in -100 .. 100 * (I - 1));
         if Current < 0 then
            Current := Score (A (I));
         else
            Current := Current + A (I);
         end if;
         if Current > Best then
            Best := Current;
         end if;
      end loop;
      return Best;
   end Best_Sum;
end Maximum_Subarray;
