pragma Ada_2022;
package Number_Complement with SPARK_Mode => On is
   subtype Byte is Natural range 0 .. 255;
   function Complement (Value : Byte) return Byte
     with Global => null,
          Post => Complement'Result = 255 - Value;
end Number_Complement;
