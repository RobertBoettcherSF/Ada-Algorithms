pragma Ada_2022;
package Newton_Raphson with SPARK_Mode => On is
   subtype Input is Integer range 1 .. 10_000;
   function Sqrt (N : Input) return Integer with Global => null;
end Newton_Raphson;
