pragma SPARK_Mode (On);

package body Smallest_Integer_Divisible_By_K is
   function Smallest_Length (K : Divisor) return Length is
      Remainder : Natural range 0 .. 49 := 0;
   begin
      for I in 1 .. K loop
         Remainder := (Remainder * 10 + 1) mod K;
         if Remainder = 0 then
            return Length (I);
         end if;
      end loop;
      return 0;
   end Smallest_Length;
end Smallest_Integer_Divisible_By_K;
