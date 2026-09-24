pragma SPARK_Mode (On);

package Eval_RPN is
   subtype Value is Integer range -100 .. 100;
   subtype Result is Integer range -10_000 .. 10_000;
   type Operator is (Add, Subtract, Multiply);

   function Evaluate (Left, Right : Value; Op : Operator) return Result
     with Global => null;
end Eval_RPN;
