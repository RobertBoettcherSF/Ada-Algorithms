pragma SPARK_Mode (On);

package body Extended_Euclidean is
   function GCD (A, B : Input) return Input is
      Remainder : Natural := A;
      Divisor   : Natural := B;
   begin
      while Divisor /= 0 loop
         pragma Loop_Invariant (Remainder in 1 .. 1_000 and Divisor in 0 .. 1_000);
         pragma Loop_Variant (Decreases => Divisor);
         declare
            Next : constant Natural := Remainder mod Divisor;
         begin
            Remainder := Divisor;
            Divisor := Next;
         end;
      end loop;
      return Remainder;
   end GCD;
end Extended_Euclidean;
