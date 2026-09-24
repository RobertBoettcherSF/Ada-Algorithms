pragma SPARK_Mode (On);

package body Max_Stack_Stub is
   function Empty return Stack is
   begin
      return (Size => 0, V1 => 0, V2 => 0, V3 => 0, V4 => 0);
   end Empty;

   function Push (S : Stack; V : Value) return Stack is
      R : Stack := S;
   begin
      case S.Size is
         when 0 => R.V1 := V; R.Size := 1;
         when 1 => R.V2 := V; R.Size := 2;
         when 2 => R.V3 := V; R.Size := 3;
         when 3 => R.V4 := V; R.Size := 4;
         when 4 => null;
      end case;
      return R;
   end Push;

   function Pop (S : Stack) return Stack is
      R : Stack := S;
   begin
      case S.Size is
         when 0 => null;
         when 1 => R.Size := 0;
         when 2 => R.Size := 1;
         when 3 => R.Size := 2;
         when 4 => R.Size := 3;
      end case;
      return R;
   end Pop;

   function Top_Value (S : Stack) return Value is
   begin
      case S.Size is
         when 0 => return 0;
         when 1 => return S.V1;
         when 2 => return S.V2;
         when 3 => return S.V3;
         when 4 => return S.V4;
      end case;
   end Top_Value;

   function Max_Value (S : Stack) return Value is
      M : Value := S.V1;
   begin
      if S.Size = 0 then return 0; end if;
      if S.Size >= 2 and then S.V2 > M then M := S.V2; end if;
      if S.Size >= 3 and then S.V3 > M then M := S.V3; end if;
      if S.Size >= 4 and then S.V4 > M then M := S.V4; end if;
      return M;
   end Max_Value;
end Max_Stack_Stub;
