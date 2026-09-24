pragma Ada_2022;
package Trapezoidal_Rule with SPARK_Mode => On is
   subtype Steps_Count is Integer range 1 .. 20;
   function Integrate (Steps : Steps_Count) return Integer with Global => null;
end Trapezoidal_Rule;
