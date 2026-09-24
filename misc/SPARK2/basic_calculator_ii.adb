pragma Ada_2022;
package body Basic_Calculator_II with SPARK_Mode => On is
   function Evaluate (Left : Number; Right : Number; Op : Operator) return Number is Result : Integer;
   begin
      case Op is when Plus => Result := Left + Right; when Minus => Result := Left - Right; when Times => Result := Left * Right; when Divide => Result := Left / Right; end case;
      if Result < Number'First then return Number'First; elsif Result > Number'Last then return Number'Last; else return Result; end if;
   end Evaluate;
end Basic_Calculator_II;
