pragma Ada_2022;
package Basic_Calculator_II with SPARK_Mode => On is
   subtype Number is Integer range -1000 .. 1000;
   --  operands are limited so that every result (31 * 31 = 961, -31 - 31 = -62) fits Number;
   --  larger operands are rejected by the type instead of being clamped
   subtype Operand is Number range -31 .. 31;
   type Operator is (Plus, Minus, Times, Divide);
   function Evaluate (Left : Operand; Right : Operand; Op : Operator) return Number
     with Global => null,
          Pre    => (if Op = Divide then Right /= 0),
          Post   => Evaluate'Result = (case Op is
                                         when Plus   => Left + Right,
                                         when Minus  => Left - Right,
                                         when Times  => Left * Right,
                                         when Divide => Left / Right);
end Basic_Calculator_II;
