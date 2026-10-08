pragma Ada_2022;
package body Max_Area_Of_Island with SPARK_Mode => On is
   function Max_Area (G : Grid) return Area is
      Total : Area := 0;
   begin
      for R in Index loop
         for C in Index loop
            if G (R, C) = 1 then
               Total := Total + 1;
            end if;
         end loop;
      end loop;
      return Total;
   end Max_Area;
end Max_Area_Of_Island;
