pragma Ada_2022;
package body Word_Search with SPARK_Mode => On is
   function Exists (B : Board; W : Word; Used : Used_Length) return Boolean is
   begin
      if Used = 0 then
         return False;
      end if;
      for R in Index loop
         for C in Index loop
            if B (R, C) = W (1) then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Exists;
end Word_Search;
