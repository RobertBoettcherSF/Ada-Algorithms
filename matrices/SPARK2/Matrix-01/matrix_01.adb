pragma Ada_2022;

package body Matrix_01 with SPARK_Mode => On is
   function Zero_Count (G : Grid) return Count is
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
   end Zero_Count;
end Matrix_01;
