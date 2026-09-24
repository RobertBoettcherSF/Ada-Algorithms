pragma Ada_2022;
with Interfaces;
package Checksum_Ones_Complement with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;
   Max_Length : constant := 64;

   function Compute (Data : Byte_Array) return Interfaces.Unsigned_16
     with Global => null,
          Pre => Data'First = 1 and then Data'Last <= Max_Length;
end Checksum_Ones_Complement;
