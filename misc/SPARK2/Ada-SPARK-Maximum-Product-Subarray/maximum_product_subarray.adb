pragma SPARK_Mode (On);

package body Maximum_Product_Subarray is
   --  No saturation: with N <= 4 and every value in -10 .. 10, every running product before
   --  step I is bounded by 10 ** (I - 1) <= 1_000, so High * A (I) stays within 10_000,
   --  far inside Score; the loop invariants carry that bound.
   function Bound (I : Positive) return Score is
     (if I <= 2 then 10 elsif I = 3 then 100 else 1_000)
   with Pre => I <= 4;

   function Best_Product (A : Values; N : Length) return Score is
      High, Low, Best : Score;
      P1, P2, V : Score;
   begin
      if N = 0 then
         return 0;
      end if;
      High := Score (A (1));
      Low := High;
      Best := High;
      for I in 2 .. N loop
         pragma Loop_Invariant (High in -Bound (I) .. Bound (I));
         pragma Loop_Invariant (Low in -Bound (I) .. Bound (I));
         pragma Loop_Invariant (Best in -Bound (I) .. Bound (I));
         V := Score (A (I));
         P1 := High * A (I);
         P2 := Low * A (I);
         High := Score'Max (V, Score'Max (P1, P2));
         Low := Score'Min (V, Score'Min (P1, P2));
         Best := Score'Max (Best, High);
      end loop;
      return Best;
   end Best_Product;
end Maximum_Product_Subarray;
