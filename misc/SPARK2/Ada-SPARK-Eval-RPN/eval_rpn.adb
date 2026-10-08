pragma SPARK_Mode (On);

package body Eval_RPN is
   function Evaluate (Left, Right : Value; Op : Operator) return Result is
   begin
      case Op is
         when Add => return Result (Left + Right);
         when Subtract => return Result (Left - Right);
         when Multiply => return Result (Left * Right);
      end case;
   end Evaluate;
end Eval_RPN;
