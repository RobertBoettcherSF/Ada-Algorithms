pragma Ada_2022;
package Delta_Encoding with SPARK_Mode => On is
   Max_Length : constant := 16;
   type Sample is range -128 .. 127;
   type Sample_Array is array (Positive range <>) of Sample;

   function Net_Delta (Input : Sample_Array) return Integer
     with
       Global => null,
       Pre => Input'Length in 1 .. Max_Length,  --  any Input'First
       Post => Net_Delta'Result in -255 .. 255;
end Delta_Encoding;
