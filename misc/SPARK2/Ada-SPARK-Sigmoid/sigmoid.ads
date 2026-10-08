pragma Ada_2022;
package Sigmoid with SPARK_Mode => On is
   subtype Input is Integer range -4 .. 4;
   subtype Probability is Integer range 0 .. 100;
   function Evaluate (X : Input) return Probability with Global => null;
end Sigmoid;
