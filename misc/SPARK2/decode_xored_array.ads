pragma Ada_2022;
with Interfaces;
package Decode_XORed_Array with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   type Encoded_Array is array (1 .. 3) of Byte;
   type Original_Array is array (1 .. 4) of Byte;
   function Decode (First : Byte; Encoded : Encoded_Array) return Original_Array
     with Global => null;
end Decode_XORed_Array;
