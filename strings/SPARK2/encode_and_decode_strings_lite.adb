pragma Ada_2022;
package body Encode_And_Decode_Strings_Lite with SPARK_Mode => On is
   use type Byte;
   Key : constant Byte := 16#A5#;
   function Encode (Value : Byte) return Byte is
   begin
      return Value xor Key;
   end Encode;
   function Decode (Value : Byte) return Byte is
   begin
      return Value xor Key;
   end Decode;
end Encode_And_Decode_Strings_Lite;
