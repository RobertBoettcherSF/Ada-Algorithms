pragma Ada_2022;
package Secant_Method with SPARK_Mode => On is
   subtype Target_Value is Integer range 0 .. 100;
   function Solve (Target : Target_Value) return Integer with Global => null;
end Secant_Method;
