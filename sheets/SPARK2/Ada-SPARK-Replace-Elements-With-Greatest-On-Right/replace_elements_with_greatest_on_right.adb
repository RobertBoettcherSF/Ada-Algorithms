pragma Ada_2022;
package body Replace_Elements_With_Greatest_On_Right with SPARK_Mode => On is
   function Replace (A : Int_Array) return Int_Array is
      Result : Int_Array := A;
      Greatest : Value := Value'First;
      Old : Value;
   begin
      for I in reverse Index loop
         Old := Result (I);
         Result (I) := Greatest;
         if Old > Greatest then
            Greatest := Old;
         end if;
      end loop;
      return Result;
   end Replace;
end Replace_Elements_With_Greatest_On_Right;
