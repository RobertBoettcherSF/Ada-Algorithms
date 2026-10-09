pragma Ada_2022;
package body Newton_Raphson with SPARK_Mode => On is
   function Sqrt (N : Input) return Root is
      X : Integer := 100;
   begin
      --  Newton steps X := (X + N / X) / 2 from above. In integers they can end one too high
      --  (for N = k**2 - 1 they alternate between k - 1 and k), so the result is corrected below.
      for Step in 1 .. 8 loop
         pragma Loop_Invariant (X in 1 .. 10_000);
         --  Stays in 1 .. 10_000 without clamping: X >= 1 and N >= 1 give a
         --  step >= 1, and X, N / X <= 10_000 give a step <= 10_000.
         X := (X + N / X) / 2;
      end loop;
      while X * X > N loop
         pragma Loop_Invariant (X in 2 .. 10_000);
         pragma Loop_Variant (Decreases => X);
         X := X - 1;
      end loop;
      pragma Assert (X >= 1);   --  1 * 1 <= N
      while X < 100 and then (X + 1) * (X + 1) <= N loop
         pragma Loop_Invariant (X >= 1 and then X * X <= N);
         pragma Loop_Variant (Increases => X);
         X := X + 1;
      end loop;
      return X;
   end Sqrt;
end Newton_Raphson;
