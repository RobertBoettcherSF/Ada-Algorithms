pragma SPARK_Mode (On);

package body Basic_Calculator_Stub is
   function Calculate (Left, Right : Value; Op : Operator) return Result is
   begin
      case Op is
         when Add => return Result (Left + Right);
         when Subtract => return Result (Left - Right);
         when Multiply => return Result (Left * Right);
         when Divide => return Result (Left / Right);
      end case;
   end Calculate;
end Basic_Calculator_Stub;
