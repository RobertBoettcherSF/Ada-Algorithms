pragma SPARK_Mode (On);
package body Max_Consecutive_Ones is
   function Find (Bits : Bit_Array) return Count is
      Current : Count := 0;
      Best : Count := 0;
   begin
      for I in Index loop
         if Bits (I) = 1 then
            if Current < Count'Last then
               Current := Current + 1;
            end if;
            if Current > Best then
               Best := Current;
            end if;
         else
            Current := 0;
         end if;
      end loop;
      return Best;
   end Find;
end Max_Consecutive_Ones;
