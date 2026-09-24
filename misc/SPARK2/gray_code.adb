pragma Ada_2022;
package body Gray_Code with SPARK_Mode => On is
   use type Word;

   function Encode (Value : Word) return Word is
   begin
      return Value xor Interfaces.Shift_Right (Value, 1);
   end Encode;

   function Decode (Value : Word) return Word is
      Result : Word := Value;
   begin
      Result := Result xor Interfaces.Shift_Right (Result, 1);
      Result := Result xor Interfaces.Shift_Right (Result, 2);
      Result := Result xor Interfaces.Shift_Right (Result, 4);
      Result := Result xor Interfaces.Shift_Right (Result, 8);
      Result := Result xor Interfaces.Shift_Right (Result, 16);
      return Result;
   end Decode;
end Gray_Code;
