pragma Ada_2022;
with Interfaces;
package Minimum_Bit_Flips_To_Convert with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   subtype Bit_Index is Natural range 0 .. 7;
   subtype Flip_Count is Natural range 0 .. 8;
   function Count (Left, Right : Byte) return Flip_Count
     with Global => null;
end Minimum_Bit_Flips_To_Convert;
