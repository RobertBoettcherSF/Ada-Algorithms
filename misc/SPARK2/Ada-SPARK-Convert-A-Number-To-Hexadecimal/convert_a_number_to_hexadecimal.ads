pragma Ada_2022;
with Interfaces;
package Convert_A_Number_To_Hexadecimal with SPARK_Mode => On is
   subtype Nibble is Interfaces.Unsigned_8 range 0 .. 15;
   function Digit (Value : Nibble) return Character with Global => null;
end Convert_A_Number_To_Hexadecimal;
