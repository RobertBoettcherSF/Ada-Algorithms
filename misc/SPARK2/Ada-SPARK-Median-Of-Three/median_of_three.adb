pragma SPARK_Mode (On);

package body Median_Of_Three is
   function Median (A, B, C : Value) return Value is
   begin
      if (A <= B and B <= C) or else (C <= B and B <= A) then
         return B;
      elsif (B <= A and A <= C) or else (C <= A and A <= B) then
         return A;
      else
         return C;
      end if;
   end Median;
end Median_Of_Three;
