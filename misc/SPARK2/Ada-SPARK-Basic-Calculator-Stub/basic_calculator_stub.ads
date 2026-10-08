pragma SPARK_Mode (On);

package Basic_Calculator_Stub is
   subtype Value is Integer range -100 .. 100;
   subtype Result is Integer range -10_000 .. 10_000;
   type Operator is (Add, Subtract, Multiply, Divide);

   function Calculate (Left, Right : Value; Op : Operator) return Result
     with Pre => Op /= Divide or else Right /= 0,
          Global => null;
end Basic_Calculator_Stub;
