pragma SPARK_Mode (On);

package body Word_Ladder_II_Lite with SPARK_Mode => On is
   function Shortest_Path (Start, Goal : Letter_Word) return Path_Count is
      Changes : Path_Count := 0;
   begin
      for I in 1 .. Word_Length loop
         if Start (I) /= Goal (I) and then Changes < Path_Count'Last then
            Changes := Changes + 1;
         end if;
      end loop;
      if Changes <= 1 then
         return Changes + 1;
      else
         return 0;
      end if;
   end Shortest_Path;
end Word_Ladder_II_Lite;
