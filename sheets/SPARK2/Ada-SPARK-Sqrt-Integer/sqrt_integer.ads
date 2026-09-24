pragma Ada_2022;
package Sqrt_Integer with SPARK_Mode => On is
   subtype Number is Natural range 0 .. 100;
   subtype Root is Natural range 0 .. 10;
   function Floor_Sqrt (N : Number) return Root with Global => null;
end Sqrt_Integer;
