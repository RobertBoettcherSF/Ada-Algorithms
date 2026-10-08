pragma SPARK_Mode (On);

package body Fibonacci_Number is
   function Compute (N : Input) return Result is
      Previous : Result := 0;
      Current  : Result := 1;
   begin
      pragma Assert (Is_Fibonacci);
      if N = 0 then
         return Previous;
      elsif N = 1 then
         return Current;
      end if;
      for I in 2 .. N loop
         pragma Loop_Invariant
           (Previous = Fib (I - 2) and then Current = Fib (I - 1));
         --  F (I) = F (I - 1) + F (I - 2) <= F (32), so the sum fits.
         pragma Assert (Previous + Current = Fib (I));
         declare
            Next : constant Result := Previous + Current;
         begin
            Previous := Current;
            Current := Next;
         end;
      end loop;
      return Current;
   end Compute;
end Fibonacci_Number;
