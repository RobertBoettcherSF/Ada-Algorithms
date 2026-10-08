pragma Ada_2022;

package body First_Unique_Character with SPARK_Mode => On is
   function First_Unique (Input : Text_Array) return Index_Or_Zero is
      Count : Natural range 0 .. Length;
   begin
      for I in Index loop
         Count := 0;
         for J in Index loop
            if Input (I) = Input (J) then
               Count := Count + 1;
            end if;
         end loop;
         if Count = 1 then
            return I;
         end if;
      end loop;
      return 0;
   end First_Unique;
end First_Unique_Character;
