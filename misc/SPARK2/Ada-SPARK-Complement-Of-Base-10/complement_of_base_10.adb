pragma Ada_2022;
package body Complement_Of_Base_10 with SPARK_Mode => On is
   function Complement (Value : Number) return Number is
   begin
      return 999 - Value;
   end Complement;
end Complement_Of_Base_10;
