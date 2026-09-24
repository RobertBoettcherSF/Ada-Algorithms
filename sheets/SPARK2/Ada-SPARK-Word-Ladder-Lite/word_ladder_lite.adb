pragma SPARK_Mode (On);

package body Word_Ladder_Lite with SPARK_Mode => On is
   function Ladder_Length (Start, Goal : Letter_Word) return Distance is
      Different : Distance := 0;
   begin
      for I in 1 .. Word_Length loop
         if Start (I) /= Goal (I) and then Different < Distance'Last then
            Different := Different + 1;
         end if;
      end loop;
      if Different = 0 then
         return 1;
      elsif Different = 1 then
         return 2;
      else
         return 0;
      end if;
   end Ladder_Length;
end Word_Ladder_Lite;
