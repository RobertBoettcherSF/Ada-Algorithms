pragma Ada_2022;
package Horner_Scheme with SPARK_Mode => On is
   subtype Index is Integer range 1 .. 4;
   subtype Coefficient is Integer range -100 .. 100;
   type Coefficients is array (Index) of Coefficient;
   subtype Argument is Integer range -10 .. 10;
   function Evaluate (C : Coefficients; X : Argument) return Integer
     with Global => null;
end Horner_Scheme;
