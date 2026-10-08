--  Euclidean_Algorithm — Ada/SPARK Level 4 educational package for the
--  classical Euclidean algorithm: gcd(a,b) by successive remainders
--
--      gcd(a, 0) = a
--      gcd(a, b) = gcd(b, a rem b)   (b ≠ 0)
--
--  Also: LCM on a capped educational domain, coprimality, division-step
--  counts, and Stein's binary GCD (same results as classical Gcd).
--
--  SPARK port of Ada-Euclidean-Algorithm: unsigned Value domain (no
--  signed Abs_LI), no exceptions — LCM overflow guard is a Pre on
--  Max_Educational rather than Invalid_Argument. Contracts replace
--  exception paths; Gcd(0,0) = 0 by definition.
--
--  Reference: https://en.wikipedia.org/wiki/Euclidean_algorithm
--  Note: spreadsheet title may say "Euclidian"; Wikipedia spelling is
--  Euclidean. Non-SPARK sibling uses the shorter package name Euclidean.

package Euclidean_Algorithm
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Word type and educational bound
   ---------------------------------------------------------------------------

   --  Nonnegative by construction (mod 2**64). Matches sibling SPARK
   --  number-theory / PRNG packages (BBS, LCG, ACORN).
   type Value is mod 2 ** 64;

   --  Soft classroom bound for LCM operands: (Max_Educational)^2 fits
   --  in Value without modular wrap (10^12 ≪ 2**64).
   Max_Educational : constant Value := 1_000_000;

   --  Euclidean remainder depth on a 64-bit word is < 100 (Fibonacci
   --  worst case). Used to bound Division_Steps without Natural wrap.
   Max_Division_Steps : constant Natural := 128;

   ---------------------------------------------------------------------------
   -- Divisibility helper (expression function — usable in contracts)
   ---------------------------------------------------------------------------

   --  True iff D ≠ 0 and N ≡ 0 (mod D).  Divides(0, _) is False.
   function Divides (D, N : Value) return Boolean is
     (D /= 0 and then N rem D = 0)
   with Global => null;

   ---------------------------------------------------------------------------
   -- Classical Euclidean GCD (iterative — preferred for SPARK)
   ---------------------------------------------------------------------------

   --  Classical successive-remainder GCD. Gcd(0,0) = 0; Gcd(A,0) = A;
   --  Gcd(0,B) = B. Nonnegative by construction. Both-nonzero ⇒ Result > 0.
   --  Full Divides / "greatest" uniqueness needs ghost lemmas beyond
   --  Level 4's automatic reach on modular words — tests check Divides.
   function Gcd (A, B : Value) return Value
     with
       Global => null,
       Post   =>
         (if A = 0 and then B = 0 then
            Gcd'Result = 0
          elsif B = 0 then
            Gcd'Result = A
          elsif A = 0 then
            Gcd'Result = B
          else
            Gcd'Result > 0);

   --  Recursive Euclidean identities (Subprogram_Variant on B).
   --  Same observable contracts as iterative Gcd.
   function Gcd_Recursive (A, B : Value) return Value
     with
       Global             => null,
       Subprogram_Variant => (Decreases => B),
       Post               =>
         (if A = 0 and then B = 0 then
            Gcd_Recursive'Result = 0
          elsif B = 0 then
            Gcd_Recursive'Result = A
          elsif A = 0 then
            Gcd_Recursive'Result = B
          else
            Gcd_Recursive'Result > 0);

   ---------------------------------------------------------------------------
   -- LCM (educational domain)
   ---------------------------------------------------------------------------

   --  Least common multiple. Lcm(0,0) = 0; if either is 0 then 0;
   --  otherwise (A / Gcd(A,B)) * B. Pre caps operands so the product
   --  cannot wrap in Value (replaces sibling Invalid_Argument).
   function Lcm (A, B : Value) return Value
     with
       Global => null,
       Pre    => A <= Max_Educational and then B <= Max_Educational,
       Post   =>
         (if A = 0 or else B = 0 then
            Lcm'Result = 0
          else
            Lcm'Result = (A / Gcd (A, B)) * B);

   ---------------------------------------------------------------------------
   -- Coprimality / step count / binary GCD
   ---------------------------------------------------------------------------

   --  True iff Gcd(A, B) = 1.
   function Are_Coprime (A, B : Value) return Boolean
     with
       Global => null,
       Post   => Are_Coprime'Result = (Gcd (A, B) = 1);

   --  Number of remainder iterations until the remainder is 0.
   --  Division_Steps(A, 0) = 0. Result ≤ Max_Division_Steps.
   function Division_Steps (A, B : Value) return Natural
     with
       Global => null,
       Post   =>
         Division_Steps'Result <= Max_Division_Steps
         and then (if B = 0 then Division_Steps'Result = 0);

   --  Binary (Stein's) GCD — educational alternate; same mathematical
   --  result as Gcd (checked by tests). Uses shifts / subtract only.
   function Binary_Gcd (A, B : Value) return Value
     with
       Global => null,
       Post   =>
         (if A = 0 and then B = 0 then
            Binary_Gcd'Result = 0
          elsif A = 0 then
            Binary_Gcd'Result = B
          elsif B = 0 then
            Binary_Gcd'Result = A
          else
            Binary_Gcd'Result > 0);

end Euclidean_Algorithm;
