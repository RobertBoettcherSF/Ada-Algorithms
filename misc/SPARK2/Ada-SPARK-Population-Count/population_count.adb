pragma Ada_2022;
package body Population_Count with SPARK_Mode => On is
   use type Interfaces.Unsigned_32;

   function Count (Value : Word) return Natural is
      Input : Word := Value;
      Result : Natural := 0;
   begin
      for I in 1 .. 32 loop
         pragma Loop_Invariant (Result <= I - 1);
         if (Input and 1) /= 0 then
            Result := Result + 1;
         end if;
         Input := Interfaces.Shift_Right (Input, 1);
      end loop;
      return Result;
   end Count;
end Population_Count;
