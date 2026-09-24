pragma Ada_2022;
with Interfaces;
package Count_Triplets_Equal_XOR with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   type Triple is array (1 .. 3) of Byte;
   subtype Count is Natural range 0 .. 1;
   function Triplets (Values : Triple) return Count
     with Global => null;
end Count_Triplets_Equal_XOR;
