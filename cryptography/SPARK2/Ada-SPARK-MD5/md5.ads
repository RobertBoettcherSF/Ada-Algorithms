pragma Ada_2022;
package MD5 with SPARK_Mode => On is
   Max_Message_Length : constant := 64;
   subtype Message_Length is Natural range 0 .. Max_Message_Length;
   Digest_Length : constant Positive := 16;
   Block_Size : constant Positive := 64;

   function Padded_Length (Length : Message_Length) return Natural
     with
       Global => null,
       Post => Padded_Length'Result in Block_Size .. 2 * Block_Size;
end MD5;
