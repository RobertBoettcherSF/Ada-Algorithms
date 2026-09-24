pragma Ada_2022;

package body Beautiful_Array with SPARK_Mode => On is
   function Is_Beautiful (Input : Input_Array) return Boolean is
   begin
      for I in Index loop
         for K in I + 1 .. Length loop
            for J in K + 1 .. Length loop
               if 2 * Input (K) = Input (I) + Input (J) then
                  return False;
               end if;
            end loop;
         end loop;
      end loop;
      return True;
   end Is_Beautiful;
end Beautiful_Array;
