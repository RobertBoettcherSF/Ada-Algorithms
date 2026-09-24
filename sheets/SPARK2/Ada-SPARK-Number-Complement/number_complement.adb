pragma Ada_2022;
package body Number_Complement with SPARK_Mode => On is
   function Complement (Value : Byte) return Byte is
   begin
      return 255 - Value;
   end Complement;
end Number_Complement;
