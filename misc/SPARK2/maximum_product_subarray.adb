pragma SPARK_Mode (On);

package body Maximum_Product_Subarray is
   function Multiply (Left : Score; Right : Value) return Score is
   begin
      if Left > 100_000 then
         return Score'Last;
      elsif Left < -100_000 then
         return Score'First;
      else
         return Left * Right;
      end if;
   end Multiply;

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
         V := Score (A (I));
         P1 := Multiply (High, A (I));
         P2 := Multiply (Low, A (I));
         High := Score'Max (V, Score'Max (P1, P2));
         Low := Score'Min (V, Score'Min (P1, P2));
         Best := Score'Max (Best, High);
      end loop;
      return Best;
   end Best_Product;
end Maximum_Product_Subarray;
