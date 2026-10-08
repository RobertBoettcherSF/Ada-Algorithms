pragma SPARK_Mode (On);

package body N_Th_Tribonacci is
   function Add_Bounded (Left, Right : Result) return Result
     with Post => Add_Bounded'Result = Integer'Min (Left + Right, Result'Last)
   is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Compute (N : Input) return Result is
      A : Result := 0;
      B : Result := 1;
      C : Result := 1;
   begin
      if N = 0 then
         return A;
      elsif N = 1 then
         return B;
      elsif N = 2 then
         return C;
      end if;
      for I in 3 .. N loop
         pragma Loop_Invariant (A <= B and then B <= C);
         declare
            Next : constant Result := Add_Bounded (Add_Bounded (A, B), C);
         begin
            A := B;
            B := C;
            C := Next;
         end;
      end loop;
      return C;
   end Compute;
end N_Th_Tribonacci;
