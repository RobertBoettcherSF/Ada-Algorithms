pragma Ada_2022;
package Binary_Number_With_Alternating_Bits with SPARK_Mode => On is
   subtype Byte is Natural range 0 .. 255;
   function Has_Alternating_Bits (Value : Byte) return Boolean
     with Global => null,
          Post => Has_Alternating_Bits'Result =
            (Value = 85 or else Value = 170);
end Binary_Number_With_Alternating_Bits;
