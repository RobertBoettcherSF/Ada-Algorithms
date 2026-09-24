pragma Ada_2022;
package Delta_Encoding with SPARK_Mode => On is
   Max_Length : constant := 16;
   type Sample is range -128 .. 127;
   type Sample_Array is array (Positive range <>) of Sample;

   function Net_Delta (Input : Sample_Array) return Integer
     with
       Global => null,
       Pre => Input'First = 1 and then Input'Last >= Input'First and then Input'Last <= Max_Length,
       Post => Net_Delta'Result in -255 .. 255;
end Delta_Encoding;
