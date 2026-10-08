pragma Ada_2022;

package body Create_Maximum_Number_Lite with SPARK_Mode => On is
   function Maximum_Digit (A, B : Digit_Array; Length : Length_Type) return Digit is
      Best : Digit := 0;
   begin
      for I in 1 .. Length loop
         if A (I) > Best then
            Best := A (I);
         end if;
         if B (I) > Best then
            Best := B (I);
         end if;
      end loop;
      return Best;
   end Maximum_Digit;

   function Maximum_Prefix (A, B : Digit_Array; Length : Length_Type) return Digit_Array is
      Result : Digit_Array := [others => 0];
   begin
      for I in 1 .. Length loop
         if A (I) >= B (I) then
            Result (I) := A (I);
         else
            Result (I) := B (I);
         end if;
      end loop;
      return Result;
   end Maximum_Prefix;
end Create_Maximum_Number_Lite;
