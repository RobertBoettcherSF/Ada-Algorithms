pragma Ada_2022;

package body Babylonian_Sqrt with SPARK_Mode => On is

   --  One Newton step from X > floor (sqrt N) - 1 stays above it, and
   --  falls while X * X > N.
   --  With Q = N / X and Y = (X + Q) / 2:
   --    4 (Y + 1) ** 2 >= (X + Q + 1) ** 2      (2 (Y + 1) >= X + Q + 1)
   --                   >= 4 X (Q + 1)          (AM-GM: (X - Q - 1) ** 2 >= 0)
   --                   >  4 N                  (N < (Q + 1) X).
   procedure Lemma_Step (N : Input; X : Root)
   with
     Ghost,
     Pre  => X > 0 and then N < (X + 1) * (X + 1),
     Post => N < ((X + N / X) / 2 + 1) * ((X + N / X) / 2 + 1)
             and then (if X * X > N then (X + N / X) / 2 < X)
   is
      Q : constant Natural := N / X;
      R : constant Natural := N mod X;
      Y : constant Natural := (X + Q) / 2;
      A : constant Natural := X + Q + 1;
      D : constant Integer := X - Q - 1;
      B : constant Natural := 2 * (Y + 1);
   begin
      pragma Assert (N = Q * X + R and R < X);
      pragma Assert (N < (Q + 1) * X);
      pragma Assert (B >= A);
      pragma Assert (B * B = A * B + (B - A) * B);
      pragma Assert ((B - A) * B >= 0);
      pragma Assert (A * B = A * A + A * (B - A));
      pragma Assert (A * (B - A) >= 0);
      pragma Assert (4 * (Y + 1) * (Y + 1) = B * B);
      pragma Assert (A * A = D * D + 4 * X * (Q + 1));
      pragma Assert (D * D >= 0);
      pragma Assert (A * A >= 4 * X * (Q + 1));
      pragma Assert (4 * (Y + 1) * (Y + 1) > 4 * N);
      if X * X > N then
         pragma Assert (Q * X < X * X);
         pragma Assert (Q < X);
      end if;
   end Lemma_Step;

   function Sqrt (N : Input) return Sqrt_Result is
      X     : Root := Root'Last;   --  101 * 101 > 10,000 >= N
      Y     : Natural;
      Steps : Step_Count := 0;
   begin
      loop
         pragma Loop_Invariant (N < (X + 1) * (X + 1));
         pragma Loop_Invariant (Steps + X <= Root'Last);
         pragma Loop_Variant (Decreases => X);
         exit when X = 0;
         Lemma_Step (N, X);
         Y := (X + N / X) / 2;
         Steps := Steps + 1;
         exit when Y >= X;   --  then X * X <= N
         X := Y;
      end loop;
      return (Root => X, Steps => Steps);
   end Sqrt;
end Babylonian_Sqrt;
