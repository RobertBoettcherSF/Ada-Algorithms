pragma Ada_2022;
package body Horner_Scheme with SPARK_Mode => On is
   function Evaluate (C : Coefficients; X : Argument) return Integer is
      Result : Integer := C (Index'First);
   begin
      for I in 2 .. Index'Last loop
         Result := Result * X + C (I);
      end loop;
      return Result;
   end Evaluate;
end Horner_Scheme;
