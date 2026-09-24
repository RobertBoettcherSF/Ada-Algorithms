pragma Ada_2022;
package Lagrange_Interpolation with SPARK_Mode => On is
   subtype Value is Integer range -10 .. 10;
   subtype Argument is Integer range -1 .. 1;
   function Interpolate (Y0, Y1, Y2 : Value; X : Argument) return Integer
     with Global => null;
end Lagrange_Interpolation;
