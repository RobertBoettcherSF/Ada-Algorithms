pragma Ada_2022;

package body Sqrt_X with SPARK_Mode => On is

   subtype Small is Wide range 0 .. 2 ** 31;

   --  One Newton step from X with N < (X + 1) ** 2 keeps that bound (the
   --  loop itself stops once a step no longer lowers X). With Q = N / X
   --  and Y = (X + Q) / 2:
   --    4 (Y + 1) ** 2 >= (X + Q + 1) ** 2      (2 (Y + 1) >= X + Q + 1)
   --                   >= 4 X (Q + 1)          (AM-GM: (X - Q - 1) ** 2 >= 0)
   --                   >  4 N                  (N < (Q + 1) X).
   procedure Lemma_Step (N : Small; X : Small)
   with
     Ghost,
     Pre  => X > 0 and then X <= 46_340 and then N < (X + 1) * (X + 1),
     Post => N < ((X + N / X) / 2 + 1) * ((X + N / X) / 2 + 1)
   is
      Q : constant Wide := N / X;
      R : constant Wide := N mod X;
      Y : constant Wide := (X + Q) / 2;
      A : constant Wide := X + Q + 1;
      D : constant Long_Long_Integer := X - Q - 1;
      B : constant Wide := 2 * (Y + 1);
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
   end Lemma_Step;

   function Sqrt (N : Number) return Sqrt_Result is
      X     : Small := Wide (Root'Last);   --  46_341 ** 2 > Natural'Last >= N
      Y     : Small;
      Steps : Step_Count := 0;
   begin
      loop
         pragma Loop_Invariant (X <= Wide (Root'Last));
         pragma Loop_Invariant (Wide (N) < (X + 1) * (X + 1));
         pragma Loop_Invariant (Wide (Steps) + X <= Wide (Root'Last));
         pragma Loop_Variant (Decreases => X);
         exit when X = 0;
         Lemma_Step (Wide (N), X);
         Y := (X + Wide (N) / X) / 2;
         Steps := Steps + 1;
         exit when Y >= X;   --  then X * X <= N
         X := Y;
      end loop;
      return (Root => Natural (X), Steps => Steps);
   end Sqrt;
end Sqrt_X;
