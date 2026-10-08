pragma Ada_2022;

package body Open_The_Lock with SPARK_Mode => On is
   function Turn_Sum (G : Grid) return Count is
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
   end Turn_Sum;
end Open_The_Lock;
