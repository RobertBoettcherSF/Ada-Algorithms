pragma Ada_2022;
package Pow_X_N_Stub with SPARK_Mode => On is
   subtype Base is Natural range 0 .. 4;
   subtype Exponent is Natural range 0 .. 5;
   subtype Result is Natural range 0 .. 1024;
   function Power (X : Base; N : Exponent) return Result with Global => null;
end Pow_X_N_Stub;
