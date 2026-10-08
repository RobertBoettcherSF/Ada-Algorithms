pragma Ada_2022;

package body Contains_Duplicate_II with SPARK_Mode => On is
   function Has_Nearby_Duplicate (Input : Input_Array) return Boolean is
   begin
      for I in Index loop
         for J in Index loop
            if J < I and then I - J <= Distance and then Input (J) = Input (I) then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Nearby_Duplicate;
end Contains_Duplicate_II;
