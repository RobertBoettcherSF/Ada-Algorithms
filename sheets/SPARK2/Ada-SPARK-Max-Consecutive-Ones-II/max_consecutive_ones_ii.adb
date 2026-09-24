pragma SPARK_Mode (On);
package body Max_Consecutive_Ones_II is
   function Find (Bits : Bit_Array) return Count is
      Without_Flip : Count := 0;
      With_Flip : Count := 0;
      Best : Count := 0;
   begin
      for I in Index loop
         if Bits (I) = 1 then
            if Without_Flip < Count'Last then
               Without_Flip := Without_Flip + 1;
            end if;
            if With_Flip < Count'Last then
               With_Flip := With_Flip + 1;
            end if;
         else
            if Without_Flip = Count'Last then
               With_Flip := 1;
            else
               With_Flip := Without_Flip + 1;
            end if;
            Without_Flip := 0;
         end if;
         if With_Flip > Best then
            Best := With_Flip;
         end if;
      end loop;
      return Best;
   end Find;
end Max_Consecutive_Ones_II;
