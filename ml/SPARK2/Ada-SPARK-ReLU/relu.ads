pragma Ada_2022;
package ReLU with SPARK_Mode => On is
   subtype Input is Integer range -100 .. 100;
   function Activate (X : Input) return Input with Global => null;
end ReLU;
