pragma Ada_2022;
package Babylonian_Sqrt with SPARK_Mode => On is
   subtype Input is Integer range 0 .. 10_000;
   function Sqrt (N : Input) return Integer with Global => null;
end Babylonian_Sqrt;
