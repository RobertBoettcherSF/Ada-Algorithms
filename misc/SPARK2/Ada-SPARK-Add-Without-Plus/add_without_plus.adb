pragma SPARK_Mode (On);

package body Add_Without_Plus is
   function Add (Left, Right : Operand) return Integer is
      Result : Integer := Left;
      Remaining : Natural;
   begin
      if Right >= 0 then
         Remaining := Right;
         while Remaining > 0 loop
            pragma Loop_Invariant (Result + Remaining = Left + Right);
            pragma Loop_Variant (Decreases => Remaining);
            Result := Result + 1;
            Remaining := Remaining - 1;
         end loop;
      else
         Remaining := -Right;
         while Remaining > 0 loop
            pragma Loop_Invariant (Result - Remaining = Left + Right);
            pragma Loop_Variant (Decreases => Remaining);
            Result := Result - 1;
            Remaining := Remaining - 1;
         end loop;
      end if;
      return Result;
   end Add;
end Add_Without_Plus;
