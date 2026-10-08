pragma Ada_2022;

package Evaluate_Reverse_Polish_Notation with SPARK_Mode => On is
   subtype Operand is Integer range -8 .. 8;
   subtype Result is Integer range -64 .. 64;
   type Operator is (Add, Subtract, Multiply);

   function Evaluate (Left, Right : Operand; Op : Operator) return Result
     with Global => null;
end Evaluate_Reverse_Polish_Notation;
