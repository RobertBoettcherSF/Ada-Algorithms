pragma SPARK_Mode (On);

package body Fibonacci_DP is
   function Add_Bounded (Left, Right : Result) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Compute (N : Input) return Result is
      Previous : Result := 0;
      Current  : Result := 1;
   begin
      if N = 0 then
         return Previous;
      elsif N = 1 then
         return Current;
      end if;
      for I in 2 .. N loop
         pragma Loop_Invariant
           (Previous in Result and Current in Result);
         declare
            Next : constant Result := Add_Bounded (Previous, Current);
         begin
            Previous := Current;
            Current := Next;
         end;
      end loop;
      return Current;
   end Compute;
end Fibonacci_DP;
