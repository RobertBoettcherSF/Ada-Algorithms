pragma Ada_2022;
package Basic_Calculator_II with SPARK_Mode => On is
   subtype Number is Integer range -1000 .. 1000;
   type Operator is (Plus, Minus, Times, Divide);
   function Evaluate (Left : Number; Right : Number; Op : Operator) return Number with Global => null, Pre => (if Op = Divide then Right /= 0 else True);
end Basic_Calculator_II;
