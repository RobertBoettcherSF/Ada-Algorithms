pragma Ada_2022;

package Basic_Calculator with SPARK_Mode => On is
   subtype Operand is Integer range -8 .. 8;
   subtype Result is Integer range -64 .. 64;
   type Operator is (Add, Subtract, Multiply);

   function Evaluate (Left, Right : Operand; Op : Operator) return Result
     with Global => null;
end Basic_Calculator;
