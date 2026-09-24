pragma Ada_2022;
with Interfaces;
package Total_Hamming_Distance with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   subtype Bit_Count is Natural range 0 .. 32;
   function Distance (Left, Right : Word) return Bit_Count
     with Global => null;
end Total_Hamming_Distance;
