pragma Ada_2022;
package UTF_8_Validation with SPARK_Mode => On is
   subtype Byte is Natural range 0 .. 255;
   function Is_ASCII (Value : Byte) return Boolean
     with Global => null,
          Post => Is_ASCII'Result = (Value <= 127);
end UTF_8_Validation;
