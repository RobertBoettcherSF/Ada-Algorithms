pragma Ada_2022;
with Interfaces;
package CRC32 with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;
   Max_Length : constant := 64;

   function Compute (Data : Byte_Array) return Interfaces.Unsigned_32
     with Global => null,
          Pre => Data'First = 1 and then Data'Last <= Max_Length;
end CRC32;
