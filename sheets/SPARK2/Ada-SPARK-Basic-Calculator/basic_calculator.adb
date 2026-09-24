pragma Ada_2022;

package body Basic_Calculator with SPARK_Mode => On is
   function Evaluate (Left, Right : Operand; Op : Operator) return Result is
   begin
      case Op is
         when Add => return Left + Right;
         when Subtract => return Left - Right;
         when Multiply => return Left * Right;
      end case;
   end Evaluate;
end Basic_Calculator;
