pragma Ada_2022;

package body Pattern_132 with SPARK_Mode => On is
   function Exists (A : Values; Length : Length_Type) return Boolean is
   begin
      for I in 1 .. Length loop
         for J in I + 1 .. Length loop
            if A (J) > A (I) then
               for K in J + 1 .. Length loop
                  if A (I) < A (K) and A (K) < A (J) then
                     return True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      return False;
   end Exists;
end Pattern_132;
