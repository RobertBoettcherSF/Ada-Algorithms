pragma Ada_2022;
package Complement_Of_Base_10 with SPARK_Mode => On is
   subtype Number is Natural range 0 .. 999;
   function Complement (Value : Number) return Number
     with Global => null,
          Post => Complement'Result = 999 - Value;
end Complement_Of_Base_10;
