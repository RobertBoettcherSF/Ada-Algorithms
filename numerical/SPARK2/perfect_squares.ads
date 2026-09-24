pragma Ada_2022;
package Perfect_Squares with SPARK_Mode => On is
   subtype Number is Natural range 0 .. 16;
   subtype Count is Natural range 0 .. 4;
   function Minimum (N : Number) return Count with Global => null;
end Perfect_Squares;
