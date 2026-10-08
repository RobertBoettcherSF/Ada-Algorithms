pragma Ada_2022;
package body Surrounded_Regions with SPARK_Mode => On is
   procedure Capture_Interior (G : in out Grid) is
   begin
      for R in 2 .. Size - 1 loop
         for C in 2 .. Size - 1 loop
            if G (R, C) = 0 then
               G (R, C) := 1;
            end if;
         end loop;
      end loop;
   end Capture_Interior;
end Surrounded_Regions;
