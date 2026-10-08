--  Euclidean_Algorithm body — classical Euclidean GCD (iterative and
--  recursive), LCM on Max_Educational, Stein binary GCD, step counts.
--  SPARK Level 4: Loop_Variant / Subprogram_Variant for termination;
--  no heap, no exceptions, unsigned Value arithmetic.

package body Euclidean_Algorithm
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Gcd (iterative)
   ---------------------------------------------------------------------------

   function Gcd (A, B : Value) return Value is
      U : Value := A;
      V : Value := B;
      T : Value;
   begin
      --  Discharge zero-case posts by early return (same as mathematical
      --  base cases); avoids a hard modular rem path for A = 0.
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
   end Gcd;

   ---------------------------------------------------------------------------
   -- Gcd_Recursive
   ---------------------------------------------------------------------------

   function Gcd_Recursive (A, B : Value) return Value is
   begin
      if B = 0 then
         return A;
      elsif A = 0 then
         return B;
      else
         return Gcd_Recursive (B, A rem B);
      end if;
   end Gcd_Recursive;

   ---------------------------------------------------------------------------
   -- Lcm
   ---------------------------------------------------------------------------

   function Lcm (A, B : Value) return Value is
      G : Value;
   begin
      if A = 0 or else B = 0 then
         return 0;
      end if;
      G := Gcd (A, B);
      return (A / G) * B;
   end Lcm;

   ---------------------------------------------------------------------------
   -- Are_Coprime
   ---------------------------------------------------------------------------

   function Are_Coprime (A, B : Value) return Boolean is
   begin
      return Gcd (A, B) = 1;
   end Are_Coprime;

   ---------------------------------------------------------------------------
   -- Division_Steps (bounded for-loop — no Natural wrap)
   ---------------------------------------------------------------------------

   function Division_Steps (A, B : Value) return Natural is
      U     : Value := A;
      V     : Value := B;
      T     : Value;
      Steps : Natural := 0;
   begin
      if B = 0 then
         return 0;
      end if;

      for K in 1 .. Max_Division_Steps loop
         pragma Loop_Invariant (Steps = K - 1);
         pragma Loop_Invariant (Steps < Max_Division_Steps);
         exit when V = 0;
         T := U rem V;
         U := V;
         V := T;
         Steps := Steps + 1;
      end loop;

      return Steps;
   end Division_Steps;

   ---------------------------------------------------------------------------
   -- Binary_Gcd (Stein's algorithm)
   ---------------------------------------------------------------------------

   function Binary_Gcd (A, B : Value) return Value is
      U     : Value := A;
      V     : Value := B;
      Shift : Natural := 0;
   begin
      if U = 0 then
         return V;
      elsif V = 0 then
         return U;
      end if;

      --  Strip shared factors of 2 (at most 63 times for nonzero U,V).
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
         U := U / 2;
      end loop;

      pragma Assert (U > 0 and then U rem 2 = 1);

      for Step in 1 .. 4096 loop
         pragma Loop_Invariant (U > 0 and then U rem 2 = 1);
         pragma Loop_Invariant (Shift <= 63);
         exit when V = 0;

         while V rem 2 = 0 loop
            pragma Loop_Variant (Decreases => V);
            pragma Loop_Invariant (V > 0);
            pragma Loop_Invariant (U > 0 and then U rem 2 = 1);
            V := V / 2;
         end loop;

         if U > V then
            declare
               Tmp : constant Value := U;
            begin
               U := V;
               V := Tmp;
            end;
         end if;

         pragma Assert (U > 0);
         V := V - U;
      end loop;

      if V /= 0 then
         return Gcd (A, B);
      end if;

      pragma Assert (U > 0);
      pragma Assert (Shift <= 63);
      return U * (2 ** Shift);
   end Binary_Gcd;

end Euclidean_Algorithm;
