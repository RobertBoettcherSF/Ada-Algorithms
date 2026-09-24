pragma Ada_2022;
package body UTF_8_Validation with SPARK_Mode => On is
   function Is_ASCII (Value : Byte) return Boolean is
   begin
      return Value <= 127;
   end Is_ASCII;
end UTF_8_Validation;
