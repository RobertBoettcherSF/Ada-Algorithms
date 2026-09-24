pragma Ada_2022;

package body As_Far_From_Land_As_Possible with SPARK_Mode => On is
   function Land_Count (G : Grid) return Count is
      Total : Count := 0;
   begin
      for R in Index loop
         for C in Index loop
            if G (R, C) = 1 then
               Total := Total + 1;
            end if;
         end loop;
      end loop;
      return Total;
   end Land_Count;
end As_Far_From_Land_As_Possible;
