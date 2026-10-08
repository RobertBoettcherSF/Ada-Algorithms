pragma SPARK_Mode (On);

package body Greatest_Common_Divisor is
   function GCD (A, B : Input) return Input is
      X : Natural := A;
      Y : Natural := B;
   begin
      while Y /= 0 loop
         pragma Loop_Invariant (X in 1 .. 1_000 and Y in 0 .. 1_000);
         pragma Loop_Variant (Decreases => Y);
         declare
            Remainder : constant Natural := X mod Y;
         begin
            X := Y;
            Y := Remainder;
         end;
      end loop;
      return X;
   end GCD;
end Greatest_Common_Divisor;
