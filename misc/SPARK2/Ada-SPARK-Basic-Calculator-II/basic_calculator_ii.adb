pragma Ada_2022;
package body Basic_Calculator_II with SPARK_Mode => On is
   function Evaluate (Left : Operand; Right : Operand; Op : Operator) return Number is
   begin
      case Op is
         when Plus   => return Left + Right;
         when Minus  => return Left - Right;
         when Times  => return Left * Right;
         when Divide => return Left / Right;
      end case;
   end Evaluate;
end Basic_Calculator_II;
