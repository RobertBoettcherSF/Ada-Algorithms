--  Binary_GCD body — Stein binary GCD (iterative + recursive) and
--  classical Euclidean reference on U64.
--  SPARK Level 4: Loop_Variant for termination;
--  no heap, no exceptions, unsigned U64 arithmetic.
--  Zero Intentional Annotate — all checks proved.

package body Binary_GCD
  with SPARK_Mode => On
is

   -------------------------------------------------------------------------
   -- Bit helpers
   -------------------------------------------------------------------------

   function Trailing_Zeros (N : U64) return Natural is
      X     : U64 := N;
      Count : Natural := 0;
   begin
      if X = 0 then
         return 64;
      end if;

      --  Cap at 63 so Natural cannot wrap; nonzero U64 always yields.
      while X rem 2 = 0 and then Count < 63 loop
         pragma Loop_Variant (Decreases => 63 - Count);
         pragma Loop_Invariant (X > 0);
         X := X / 2;
         Count := Count + 1;
      end loop;

      pragma Assert (Count <= 63);
      return Count;
   end Trailing_Zeros;

   function Shift_Right (N : U64; Amount : Natural) return U64 is
      X : U64 := N;
   begin
      if Amount >= 64 then
         return 0;
      end if;

      for I in 1 .. Amount loop
         pragma Loop_Invariant (I <= 64);
         X := X / 2;
      end loop;
      return X;
   end Shift_Right;

   function Shift_Left (N : U64; Amount : Natural) return U64 is
      X : U64 := N;
   begin
      if Amount >= 64 then
         return 0;
      end if;

      for I in 1 .. Amount loop
         pragma Loop_Invariant (I <= 64);
         X := X * 2;
      end loop;
      return X;
   end Shift_Left;

   -------------------------------------------------------------------------
   -- Classical Euclidean (reference) — before Gcd for Stein fallback
   -------------------------------------------------------------------------

   function Gcd_Euclidean (A, B : U64) return U64 is
      U : U64 := A;
      V : U64 := B;
      T : U64;
   begin
      if B = 0 then
         return A;
      elsif A = 0 then
         return B;
      end if;

      while V /= 0 loop
         pragma Loop_Variant (Decreases => V);
         pragma Loop_Invariant (U > 0);
         T := U rem V;
         U := V;
         V := T;
      end loop;

      pragma Assert (U > 0);
      return U;
   end Gcd_Euclidean;

   -------------------------------------------------------------------------
   -- Iterative Stein binary GCD
   --
   -- Identities (Wikipedia):
   --   gcd(u, 0) = u
   --   gcd(2u, 2v) = 2 · gcd(u, v)
   --   gcd(u, 2v) = gcd(u, v)   if u odd
   --   gcd(u, v) = gcd(u, v−u)  if u, v odd and u ≤ v
   --
   -- Layout matches Ada-SPARK-Euclidean-Algorithm Binary_Gcd: strip
   -- shared factors of two, strip U to odd, then bounded subtract /
   -- re-normalize loop. Classroom ceiling falls back to Gcd_Euclidean.
   -------------------------------------------------------------------------

   function Gcd (A, B : U64) return U64 is
      U     : U64 := A;
      V     : U64 := B;
      Shift : Natural := 0;
   begin
      if U = 0 then
         return V;
      elsif V = 0 then
         return U;
      end if;

      --  Strip shared factors of 2 (at most 63 times for nonzero U, V).
      while U rem 2 = 0 and then V rem 2 = 0 and then Shift < 63 loop
         pragma Loop_Variant (Decreases => 63 - Shift);
         pragma Loop_Invariant (U > 0 and then V > 0);
         U := U / 2;
         V := V / 2;
         Shift := Shift + 1;
      end loop;

      while U rem 2 = 0 loop
         pragma Loop_Variant (Decreases => U);
         pragma Loop_Invariant (U > 0);
         pragma Loop_Invariant (Shift <= 63);
         U := U / 2;
      end loop;

      pragma Assert (U > 0 and then U rem 2 = 1);
      pragma Assert (Shift <= 63);

      for Step in 1 .. Max_Stein_Steps loop
         pragma Loop_Invariant (U > 0 and then U rem 2 = 1);
         pragma Loop_Invariant (Shift <= 63);
         exit when V = 0;

         while V rem 2 = 0 loop
            pragma Loop_Variant (Decreases => V);
            pragma Loop_Invariant (V > 0);
            pragma Loop_Invariant (U > 0 and then U rem 2 = 1);
            pragma Loop_Invariant (Shift <= 63);
            V := V / 2;
         end loop;

         if U > V then
            declare
               Tmp : constant U64 := U;
            begin
               U := V;
               V := Tmp;
            end;
         end if;

         pragma Assert (U > 0);
         V := V - U;
      end loop;

      if V /= 0 then
         return Gcd_Euclidean (A, B);
      end if;

      pragma Assert (U > 0);
      pragma Assert (Shift <= 63);
      --  Restore shared factor of two: U * 2**Shift (Shift ≤ 63).
      return U * (2 ** Shift);
   end Gcd;

   -------------------------------------------------------------------------
   -- Recursive entry — delegates to iterative Stein (Level 4 VC size)
   -------------------------------------------------------------------------

   function Gcd_Recursive (A, B : U64) return U64 is
   begin
      return Gcd (A, B);
   end Gcd_Recursive;

   -------------------------------------------------------------------------
   -- Are_Coprime
   -------------------------------------------------------------------------

   function Are_Coprime (A, B : U64) return Boolean is
   begin
      return Gcd (A, B) = 1;
   end Are_Coprime;

end Binary_GCD;
