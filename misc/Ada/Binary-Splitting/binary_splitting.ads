--  Binary_Splitting — Ada 2023 educational package for Wikipedia
--  "Binary splitting": recursive integer products (P, Q) so a rational
--  series S = Σ p_n/q_n becomes one final ratio P/Q (here: partial sums
--  of e = Σ 1/n!). Cap N ≤ Max_N so N! and intermediates fit in
--  Long_Integer. Contrast with naïve Long_Float term-by-term sum.
--  Primary source:
--  https://en.wikipedia.org/wiki/Binary_splitting
--  Siblings (README): Ada-Kahan-Summation; nth root, square roots,
--  Spigot, Karatsuba, …

pragma Ada_2022;

package Binary_Splitting
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Integer products for the e-series)
   ---------------------------------------------------------------------------

   --  Max_N: N! and e·N! (≈ numerator Σ N!/k!) must fit in Long_Integer.
   --  On typical 64-bit GNAT, 20! ≈ 2.43e18 and e·20! ≈ 6.61e18 < 2^63−1.
   Max_N : constant := 20;

   subtype Split_Index is Natural range 0 .. Max_N;

   --  Half-open product interval endpoints used by Binary_Split (A, B)
   --  with 0 ≤ A ≤ B ≤ Max_N.
   subtype Bound is Natural range 0 .. Max_N;

   type Split_Result is record
      P : Long_Integer := 0;  -- Σ_{j=A+1}^{B} (B!/j!)   (0 if A = B)
      Q : Long_Integer := 1;  -- B!/A!                   (1 if A = B)
   end record;
   --  Invariant for A ≤ B:  (P + Q) / Q  =  Σ_{n=A}^{B} A!/n!
   --  In particular Binary_Split (0, N) yields
   --    (P + Q) / Q  =  Σ_{n=0}^{N} 1/n!   (partial sum for e).

   Invalid_Argument : exception;

   Epsilon_Tol : constant Long_Float := 1.0E-12;
   Near_Tol    : constant Long_Float := 1.0E-9;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (A, B : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core binary splitting (e-series / factorial denominators)
   ---------------------------------------------------------------------------

   --  Recursively compute (P, Q) for interval (A, B] per the product-tree
   --  combine of Wikipedia binary splitting specialised to Σ 1/n!:
   --    base B = A+1:  P = 1, Q = B
   --    empty  A = B:  P = 0, Q = 1
   --    else m = (A+B)/2; combine left (A,m] and right (m,B]:
   --      P := P_L·Q_R + P_R ;  Q := Q_L·Q_R
   function Binary_Split (A, B : Bound) return Split_Result
     with Pre => A <= B, Global => null;
   --  Raises Invalid_Argument if not A ≤ B (defence in body too).

   --  Same (P, Q) by left-to-right iterative product (educational oracle
   --  for the recursive tree on small intervals).
   function Binary_Split_Iterative (A, B : Bound) return Split_Result
     with Pre => A <= B, Global => null;

   ---------------------------------------------------------------------------
   -- Partial sums for e = Σ_{n=0}^∞ 1/n!
   ---------------------------------------------------------------------------

   --  Exact rational partial sum as integers: numerator Σ_{k=0}^{N} N!/k!
   --  and denominator N!, so Approximate_E (N) = Num/Den in Long_Float.
   function Exact_Numerator (N : Split_Index) return Long_Integer
     with Global => null;

   function Exact_Denominator (N : Split_Index) return Long_Integer
     with Global => null;
   --  Exact_Denominator (N) = N! = Binary_Split (0, N).Q

   --  Long_Float (P+Q) / Long_Float (Q) from Binary_Split (0, N).
   function Approximate_E (N : Split_Index) return Long_Float
     with Global => null;

   --  Naïve term-by-term Long_Float sum of 1/n! for n = 0 .. N.
   function Sum_Naive_Float (N : Split_Index) return Long_Float
     with Global => null;

   --  Convenience: ratio P/Q as Long_Float (0 if Q = 0 — should not occur).
   function Ratio (R : Split_Result) return Long_Float
     with Global => null;

   --  Partial-sum value (P+Q)/Q as Long_Float from a Split_Result for (0,N].
   function Partial_Sum (R : Split_Result) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Factorial helper (bounded)
   ---------------------------------------------------------------------------

   function Factorial (N : Split_Index) return Long_Integer
     with Global => null;
   --  N! with 0! = 1. Same as Exact_Denominator (N).

end Binary_Splitting;
