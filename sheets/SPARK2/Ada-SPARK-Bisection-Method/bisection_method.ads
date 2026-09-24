pragma Ada_2022;
package Bisection_Method with SPARK_Mode => On is
   subtype Input is Integer range 0 .. 10_000;
   function Sqrt (N : Input) return Integer with Global => null;
end Bisection_Method;
