pragma Ada_2022;
package Softmax with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Logit is Integer range -2 .. 2;
   subtype Probability is Integer range 0 .. 100;
   type Logits is array (Index) of Logit;
   function Weight (A : Logits; I : Index) return Probability
     with Global => null;
end Softmax;
