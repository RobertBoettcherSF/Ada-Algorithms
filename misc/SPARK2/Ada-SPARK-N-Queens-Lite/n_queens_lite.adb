pragma Ada_2022;

package body N_Queens_Lite with SPARK_Mode => On is
   function Is_Solution (P : Positions) return Boolean is
   begin
      for R in Row range 1 .. 3 loop
         if P (R) = 0 then
            return False;
         end if;
         for S in Row range R + 1 .. 4 loop
            if P (S) = 0 or else P (R) = P (S) then
               return False;
            end if;
            if abs (Integer (P (R)) - Integer (P (S))) = S - R then
               return False;
            end if;
         end loop;
      end loop;
      return P (4) /= 0;
   end Is_Solution;
end N_Queens_Lite;
