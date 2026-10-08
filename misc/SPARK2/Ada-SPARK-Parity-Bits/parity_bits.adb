pragma Ada_2022;
package body Parity_Bits with SPARK_Mode => On is
   use type Interfaces.Unsigned_32;

   function Even (Value : Word) return Boolean is
      Input : Word := Value;
      Result : Boolean := True;
   begin
      for I in 1 .. 32 loop
         if (Input and 1) /= 0 then
            Result := not Result;
         end if;
         Input := Interfaces.Shift_Right (Input, 1);
      end loop;
      return Result;
   end Even;

   function Odd (Value : Word) return Boolean is
   begin
      return not Even (Value);
   end Odd;
end Parity_Bits;
