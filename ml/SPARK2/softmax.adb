pragma Ada_2022;
package body Softmax with SPARK_Mode => On is
   function Exp_100 (X : Logit) return Integer is
   begin
      -- A small, deterministic e^x lookup table scaled by 100.
      case X is
         when -2 => return 14;
         when -1 => return 37;
         when  0 => return 100;
         when  1 => return 271;
         when  2 => return 738;
      end case;
   end Exp_100;

   function Weight (A : Logits; I : Index) return Probability is
      Total : constant Integer := Exp_100 (A (1)) + Exp_100 (A (2)) + Exp_100 (A (3));
   begin
      return (100 * Exp_100 (A (I))) / Total;
   end Weight;
end Softmax;
