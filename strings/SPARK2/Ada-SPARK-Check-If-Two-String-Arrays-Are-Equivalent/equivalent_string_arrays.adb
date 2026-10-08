pragma Ada_2022;

package body Equivalent_String_Arrays with SPARK_Mode => On is
   function Are_Equivalent (Left : Text; Left_Length : Length_Type;
                            Right : Text; Right_Length : Length_Type) return Boolean is
   begin
      if Left_Length /= Right_Length then
         return False;
      end if;
      for I in 1 .. Left_Length loop
         if Left (Index (I)) /= Right (Index (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Are_Equivalent;
end Equivalent_String_Arrays;
