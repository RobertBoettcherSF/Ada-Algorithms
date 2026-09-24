pragma Ada_2022;
package Pow_X_N with SPARK_Mode => On is
   subtype Base_Value is Integer range -2 .. 2;
   subtype Exponent is Natural range 0 .. 5;
   subtype Power_Value is Integer range -32 .. 32;
   function Power (X : Base_Value; N : Exponent) return Power_Value
     with Global => null;
end Pow_X_N;
