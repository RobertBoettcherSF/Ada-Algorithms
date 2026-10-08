pragma Ada_2022;
with Interfaces;
package Encode_And_Decode_Strings_Lite with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   function Encode (Value : Byte) return Byte
     with Global => null;
   function Decode (Value : Byte) return Byte
     with Global => null;
end Encode_And_Decode_Strings_Lite;
