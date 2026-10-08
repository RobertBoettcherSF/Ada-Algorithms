pragma Ada_2022;
package body Binary_Number_With_Alternating_Bits with SPARK_Mode => On is
   function Has_Alternating_Bits (Value : Byte) return Boolean is
   begin
      return Value = 85 or else Value = 170;
   end Has_Alternating_Bits;
end Binary_Number_With_Alternating_Bits;
