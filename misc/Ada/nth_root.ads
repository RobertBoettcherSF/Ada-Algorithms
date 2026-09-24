--  Nth_Root — Ada 2023 educational package for Wikipedia
--  "Nth root algorithm": Newton (and optional Halley) iteration for
--  the principal real n-th root r = x^{1/n}, plus Sqrt / Cbrt wrappers,
--  careful integer powering, and a digit-style integer floor root.
--  Cap N ∈ [Min_Degree .. Max_Degree]; educational Long_Float.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Nth_root_algorithm
--  https://en.wikipedia.org/wiki/Nth_root
--  Siblings (README): Ada-Binary-Splitting, Ada-Kahan-Summation;
--  upcoming Methods of computing square roots, Alpha max plus beta min,
--  Spigot, …

pragma Ada_2022;

package Nth_Root
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   --  Degree n of the root. Cap keeps Pow_Int / Newton well-behaved in
   --  double precision for typical classroom radicands.
   Min_Degree : constant Positive := 1;
   Max_Degree : constant Positive := 32;

   subtype Degree is Positive range Min_Degree .. Max_Degree;

   Default_Tol      : constant Long_Float := 1.0E-12;
   Default_Max_Iter : constant Positive   := 100;

   Epsilon_Tol : constant Long_Float := 1.0E-12;
   Near_Tol    : constant Long_Float := 1.0E-9;

   --  Status of Root_Newton / Root_Halley.
   --  Bad_Domain ≡ invalid argument (even N with X < 0, …).
   --  Root / Sqrt / Cbrt raise exception Invalid_Argument on failure.
   type Status_Kind is
     (Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   type Root_Result is record
      Value      : Long_Float  := 0.0;
      Iterations : Natural     := 0;
      Status     : Status_Kind := Bad_Domain;
   end record;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (A, B : Long_Float) return Long_Float
     with Global => null;

   --  Integer power Y^K by successive squaring (K ≥ 0). Y^0 = 1.
   --  Educational: avoids Long_Float "**" with a non-integer exponent.
   function Pow_Int (Y : Long_Float; K : Natural) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Newton nth-root extraction
   ---------------------------------------------------------------------------

   --  Solve y^n − x = 0 by Newton:
   --    y_{k+1} = (1/n) * ((n−1) y_k + x / y_k^{n−1})
   --  Domain: N ≥ 1; X ≥ 0 always; X < 0 only when N is odd.
   --  N = 1 returns X in 0 iterations. Does not raise; bad domain →
   --  Status = Bad_Domain, Value = 0.
   function Root_Newton
     (X        : Long_Float;
      N        : Degree;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Root_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Convenience: Root_Newton with defaults; raises Invalid_Argument if
   --  Status ≠ Converged.
   function Root (X : Long_Float; N : Degree) return Long_Float
     with Global => null;

   --  Square root (n = 2) and cube root (n = 3) wrappers.
   function Sqrt (X : Long_Float) return Long_Float
     with Global => null;
   --  Raises Invalid_Argument if X < 0.

   function Cbrt (X : Long_Float) return Long_Float
     with Global => null;
   --  Odd root: negative X allowed.

   ---------------------------------------------------------------------------
   -- Halley (optional cubic convergence educational contrast)
   ---------------------------------------------------------------------------

   --  Halley for f(y) = y^n − x:
   --    y ← y * ((n−1) y^n + (n+1) x) / ((n+1) y^n + (n−1) x)
   function Root_Halley
     (X        : Long_Float;
      N        : Degree;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Root_Result
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Integer floor nth root (digit / binary-search style)
   ---------------------------------------------------------------------------

   --  Largest Natural R such that R^N ≤ X (with 0^N = 0 for N ≥ 1,
   --  and convention 0^0 avoided by N ≥ 1). Educational positive-integer
   --  extraction via binary search over the floor root.
   function Integer_Nth_Root (X : Natural; N : Degree) return Natural
     with Global => null;

end Nth_Root;
