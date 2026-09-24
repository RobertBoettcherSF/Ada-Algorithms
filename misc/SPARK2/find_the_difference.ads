pragma Ada_2022;
with Interfaces;
package Find_The_Difference with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   function Difference (Original, Changed : Byte) return Byte
     with Global => null;
end Find_The_Difference;
