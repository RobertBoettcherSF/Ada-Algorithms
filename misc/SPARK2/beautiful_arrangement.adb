pragma Ada_2022;

package body Beautiful_Arrangement with SPARK_Mode => On is
   function Is_Beautiful (A : Arrangement; N : Size) return Boolean is
   begin
      for I in Size range 1 .. N loop
         if A (I) = 0 then
            return False;
         end if;
         if not (A (I) mod I = 0 or else I mod A (I) = 0) then
            return False;
         end if;
         for J in Size range 1 .. I - 1 loop
            if A (I) = A (J) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Beautiful;
end Beautiful_Arrangement;
