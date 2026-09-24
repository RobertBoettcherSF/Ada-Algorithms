pragma SPARK_Mode (On);

package body Maximum_Subarray is
   function Add (Left : Score; Right : Value) return Score is
   begin
      if Left > 900 then
         return Score'Last;
      elsif Left < -900 then
         return Score'First;
      else
         return Left + Right;
      end if;
   end Add;

   function Best_Sum (A : Values; N : Length) return Score is
      Current, Best : Score;
   begin
      if N = 0 then
         return 0;
      end if;
      Current := Score (A (1));
      Best := Current;
      for I in 2 .. N loop
         if Current < 0 then
            Current := Score (A (I));
         else
            Current := Add (Current, A (I));
         end if;
         if Current > Best then
            Best := Current;
         end if;
      end loop;
      return Best;
   end Best_Sum;
end Maximum_Subarray;
