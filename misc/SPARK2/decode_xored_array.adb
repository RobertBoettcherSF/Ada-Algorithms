pragma Ada_2022;
package body Decode_XORed_Array with SPARK_Mode => On is
   use type Byte;
   function Decode (First : Byte; Encoded : Encoded_Array) return Original_Array is
   begin
      return [First,
              First xor Encoded (1),
              First xor Encoded (1) xor Encoded (2),
              First xor Encoded (1) xor Encoded (2) xor Encoded (3)];
   end Decode;
end Decode_XORed_Array;
