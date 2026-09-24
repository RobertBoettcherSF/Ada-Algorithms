pragma SPARK_Mode (On);

package body Modular_Exponentiation is
   function Power (Value : Base; Exp : Exponent; Modulo : Modulus) return Result is
      Accumulator : Natural := 1 mod Modulo;
      Factor      : Natural := Value mod Modulo;
      Remaining   : Natural := Exp;
   begin
      while Remaining > 0 loop
         pragma Loop_Invariant (Accumulator in 0 .. 100);
         pragma Loop_Invariant (Factor in 0 .. 100);
         pragma Loop_Invariant (Remaining in 0 .. 16);
         pragma Loop_Variant (Decreases => Remaining);
         if Remaining mod 2 = 1 then
            Accumulator := (Accumulator * Factor) mod Modulo;
         end if;
         Factor := (Factor * Factor) mod Modulo;
         Remaining := Remaining / 2;
      end loop;
      return Accumulator;
   end Power;
end Modular_Exponentiation;
