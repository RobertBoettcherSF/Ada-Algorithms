pragma Ada_2022;

package body Plus_One with SPARK_Mode => On is
   function Increment (Input : Digit_Array) return Digit_Array is
   begin
      if Input (4) < 9 then
         return [Input (1), Input (2), Input (3), Input (4) + 1];
      elsif Input (3) < 9 then
         return [Input (1), Input (2), Input (3) + 1, 0];
      elsif Input (2) < 9 then
         return [Input (1), Input (2) + 1, 0, 0];
      elsif Input (1) < 9 then
         return [Input (1) + 1, 0, 0, 0];
      else
         return [1, 0, 0, 0];
      end if;
   end Increment;
end Plus_One;
