pragma Ada_2022;
package Fixed_Point_Iteration with SPARK_Mode => On is
   subtype Value is Integer range 0 .. 1_000;
   function Iterate (Initial : Value; Target : Value) return Integer
     with Global => null;
end Fixed_Point_Iteration;
