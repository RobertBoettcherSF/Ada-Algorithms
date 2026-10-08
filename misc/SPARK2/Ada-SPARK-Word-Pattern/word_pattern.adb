pragma Ada_2022;
package body Word_Pattern with SPARK_Mode => On is
   function Matches (P : Pattern; W : Words) return Boolean is
   begin
      for I in Index loop
         for J in Index loop
            if (P (I) = P (J)) /= (W (I) = W (J)) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Matches;
end Word_Pattern;
