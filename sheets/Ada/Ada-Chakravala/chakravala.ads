--  Chakravala — Ada 2023 educational package for the chakravala
--  (cyclic) method solving Pell's equation
--      x² − n y² = 1
--  for nonsquare positive integer n.
--  Primary source:
--  https://en.wikipedia.org/wiki/Chakravala_method
--  Sibling packages (README only; do not `with`):
--    Ada-Extended-Euclidean-Algorithm, Ada-Dixon,
--    Ada-Integer-Factorization.

pragma Ada_2022;

package Chakravala
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Integer)
   ---------------------------------------------------------------------------

   --  Soft classroom bound on the Pell parameter N.
   --  Solutions for some N ≤ Max_N still grow large; classic demos that
   --  fit comfortably in signed 64-bit Long_Integer include
   --  N ∈ {2,3,5,6,7,10,11,13,61,…}.  Intermediate products may raise
   --  Constraint_Error if a solution overflows Long_Integer.
   Max_N : constant Long_Integer := 200;

   --  Safety cap on cyclic iterations (educational; method always
   --  terminates for nonsquare N, but we bound classroom runs).
   Max_Steps : constant Natural := 10_000;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Results / auxiliary types
   ---------------------------------------------------------------------------

   --  Minimal positive solution of x² − N y² = 1 (Y > 0).
   type Pell_Pair is record
      X : Long_Integer := 0;
      Y : Long_Integer := 0;
   end record;

   --  Auxiliary equation a² − N b² = k (Bhāskara triple).
   type Auxiliary_Triple is record
      A : Long_Integer := 0;
      B : Long_Integer := 0;
      K : Long_Integer := 0;
   end record;

   --  One chakravala step: the new triple and the m that produced it
   --  (M = 0 marks the initial triple).
   type Chakravala_Step is record
      Triple : Auxiliary_Triple;
      M      : Long_Integer := 0;
   end record;

   type Chakravala_Chain is array (Positive range <>) of Chakravala_Step;

   --  Solution plus the educational inspection chain (m choices).
   type Solve_With_Chain_Result (Length : Natural) is record
      Solution : Pell_Pair;
      Chain    : Chakravala_Chain (1 .. Length);
   end record;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Abs_LI (V : Long_Integer) return Long_Integer
     with Global => null;

   --  Integer square root floor(√N), N ≥ 0.  No Float.
   function Floor_Sqrt (N : Long_Integer) return Long_Integer
     with Pre => N >= 0, Global => null;

   --  True iff N is a perfect square (0, 1, 4, 9, …).  N < 0 → False.
   function Is_Perfect_Square (N : Long_Integer) return Boolean
     with Global => null;

   --  True iff X² − N Y² = 1.
   function Verify_Pell
     (N : Long_Integer; P : Pell_Pair) return Boolean
     with Global => null;

   --  True iff A² − N B² = K.
   function Verify_Triple
     (N : Long_Integer; T : Auxiliary_Triple) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Brahmagupta–Bhāskara composition
   ---------------------------------------------------------------------------

   --  Compose (X1,Y1,K1) with (X2,Y2,K2) via Brahmagupta's identity:
   --    X = X1·X2 + N·Y1·Y2
   --    Y = X1·Y2 + X2·Y1
   --    K = K1·K2
   --  so that X² − N Y² = K.
   function Compose
     (N                    : Long_Integer;
      X1, Y1, K1, X2, Y2, K2 : Long_Integer) return Auxiliary_Triple
     with Global => null;

   function Compose
     (N : Long_Integer; T1, T2 : Auxiliary_Triple) return Auxiliary_Triple
     with Global => null;

   ---------------------------------------------------------------------------
   -- Chakravala step helpers
   ---------------------------------------------------------------------------

   --  Initial triple: b = 1 and a ≈ √N minimizing |a² − N|.
   function Initial_Triple (N : Long_Integer) return Auxiliary_Triple
     with Global => null;

   --  Positive m minimizing |m² − N| such that (A + B·m) is divisible
   --  by K (Bhāskara's lemma precondition).  Raises Invalid_Argument
   --  if K = 0.
   function Choose_M
     (N, A, B, K : Long_Integer) return Long_Integer
     with Global => null;

   --  One cyclic step: compose with (m,1,m²−N) and scale by |K|
   --  (Bhāskara's lemma).
   function Chakravala_Step_From
     (N : Long_Integer;
      T : Auxiliary_Triple;
      M : Long_Integer) return Auxiliary_Triple
     with Global => null;

   ---------------------------------------------------------------------------
   -- Solve Pell x² − N y² = 1
   ---------------------------------------------------------------------------

   --  Fundamental solution (X, Y) with Y > 0.
   --  Raises Invalid_Argument if N ≤ 0, N > Max_N, or N is square.
   function Solve_Pell (N : Long_Integer) return Pell_Pair
     with Global => null;

   --  Same as Solve_Pell, plus the chain of (a,b,k) and m choices for
   --  classroom inspection.  Length is the number of recorded steps
   --  (initial triple included).
   function Solve_Pell_With_Chain
     (N : Long_Integer) return Solve_With_Chain_Result
     with Global => null;

end Chakravala;
