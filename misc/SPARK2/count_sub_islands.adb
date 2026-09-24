pragma Ada_2022;
package body Count_Sub_Islands with SPARK_Mode => On is
   function Count_Sub (Base : Grid; Candidate : Grid) return Count is
      Total : Count := 0;
   begin
      for R in Index loop
         for C in Index loop
            if Base (R, C) = 1 and then Candidate (R, C) = 1 then
               Total := Total + 1;
            end if;
         end loop;
      end loop;
      return Total;
   end Count_Sub;
end Count_Sub_Islands;
