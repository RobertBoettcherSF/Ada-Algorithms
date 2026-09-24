pragma Ada_2022;
package body Number_Of_Islands with SPARK_Mode => On is
   function Count_Islands (G : Grid) return Count is
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
   end Count_Islands;
end Number_Of_Islands;
