--  Computation_Of_Pi — Ada 2023 educational survey package for Wikipedia
--  "Computing π". Self-contained Long_Float sketches of contrasting
--  methods (series, Machin arctan, Archimedes polygons, tiny BBP / AGM /
--  Chudnovsky demos). Does not `with` sibling packages; README links them.
--  Primary source:
--  https://en.wikipedia.org/wiki/Computing_%CF%80
--  Siblings (README): Ada-Spigot-Algorithm, Ada-Gauss-Legendre,
--  Ada-Chudnovsky, Ada-Borwein, Ada-BBP, Ada-Binary-Splitting.

pragma Ada_2022;

package Computation_Of_Pi
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float survey sketches)
   ---------------------------------------------------------------------------

   --  Effort cap shared by dispatcher sketches. Meaning depends on Method
   --  (series terms, polygon doublings, AGM steps, BBP / Chudnovsky terms).
   Max_Effort : constant Positive := 10_000;

   subtype Effort_Count is Positive range 1 .. Max_Effort;

   Default_Effort : constant Effort_Count := 100;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Reference π (same digits as Ada.Numerics.Pi, as Long_Float).
   Pi_Constant : constant Long_Float :=
     3.141_592_653_589_793_238_46;

   Invalid_Argument : exception;
   --  Raised when Effort = 0 or Effort > Max_Effort (defence for
   --  unconstrained Natural), or when an internal sketch receives a
   --  non-positive term / doubling count.

   ---------------------------------------------------------------------------
   -- Method catalogue
   ---------------------------------------------------------------------------

   --  Contrasting educational sketches (not production digit engines).
   type Method is
     (Leibniz,          --  π/4 = Σ (−1)^k/(2k+1)
      Nilakantha,       --  π = 3 + Σ (−1)^{k}·4/((2k)(2k+1)(2k+2))
      Machin,           --  π/4 = 4 arctan(1/5) − arctan(1/239)
      Archimedes,       --  inscribed regular polygon perimeter doubling
      BBP_Partial,      --  tiny Bailey–Borwein–Plouffe partial sum
      AGM,              --  light Gauss–Legendre / Brent–Salamin steps
      Chudnovsky_Term); --  one-or-few Chudnovsky 1/π terms (catalogue)

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (Left, Right : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (Approx_V, Exact_V : Long_Float) return Long_Float
     with Global => null;

   --  |Approx − Exact| / |Exact|; 0 when both zero; large sentinel if Exact=0.
   function Rel_Error (Approx_V, Exact_V : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Oracles / reference
   ---------------------------------------------------------------------------

   --  Ada.Numerics.Pi converted to Long_Float (for tests / demos).
   function Ada_Pi return Long_Float
     with Global => null;

   --  4·Arctan(1) via Long_Elementary_Functions (cross-check).
   function Elementary_Pi return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Self-contained sketches (Long_Float)
   ---------------------------------------------------------------------------

   --  Leibniz: π ≈ 4 · Σ_{k=0}^{Terms−1} (−1)^k / (2k+1).
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Effort.
   function Leibniz_Pi (Terms : Natural) return Long_Float
     with Global => null;

   --  Nilakantha: π ≈ 3 + Σ_{k=1}^{Terms} (−1)^{k+1} · 4 / (2k(2k+1)(2k+2)).
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Effort.
   function Nilakantha_Pi (Terms : Natural) return Long_Float
     with Global => null;

   --  Arctan Taylor: arctan(x) ≈ Σ_{k=0}^{Terms−1} (−1)^k · x^{2k+1}/(2k+1).
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Effort.
   function Arctan_Series (X : Long_Float; Terms : Natural) return Long_Float
     with Global => null;

   --  Machin: π ≈ 4 · (4·arctan(1/5) − arctan(1/239)) with Arctan_Series.
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Effort.
   function Machin_Pi (Terms : Natural) return Long_Float
     with Global => null;

   --  Archimedes: start with inscribed regular hexagon (side = 1, radius = 1),
   --  double sides Doublings times via chord recurrence; return perimeter/2.
   --  Raises Invalid_Argument if Doublings = 0 or Doublings > Max_Effort.
   function Archimedes_Pi (Doublings : Natural) return Long_Float
     with Global => null;

   --  Tiny BBP partial sum: π ≈ Σ_{k=0}^{Terms−1} 16^{−k} ·
   --  (4/(8k+1) − 2/(8k+4) − 1/(8k+5) − 1/(8k+6)).
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Effort.
   function BBP_Partial_Pi (Terms : Natural) return Long_Float
     with Global => null;

   --  Light AGM / Brent–Salamin: Iterations steps from a₀=1, b₀=1/√2,
   --  t₀=1/4, p₀=1; estimate (a+b)²/(4t). Iterations = 0 allowed via
   --  Approximate_Pi only; this sketch requires ≥ 1.
   --  Raises Invalid_Argument if Iterations = 0 or Iterations > Max_Effort.
   function AGM_Pi (Iterations : Natural) return Long_Float
     with Global => null;

   --  Catalogue Chudnovsky: π ≈ 426880√10005 / S_N with N = Terms terms
   --  via term-ratio recurrence (educational; saturates quickly).
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Effort.
   function Chudnovsky_Pi (Terms : Natural) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Dispatcher
   ---------------------------------------------------------------------------

   --  Dispatch Effort to the named sketch. Effort meaning:
   --    Leibniz / Nilakantha / Machin / BBP_Partial / Chudnovsky_Term → terms
   --    Archimedes → polygon doublings
   --    AGM → AGM iterations
   --  Raises Invalid_Argument if Effort = 0 or Effort > Max_Effort.
   function Approximate_Pi
     (Which  : Method;
      Effort : Effort_Count := Default_Effort) return Long_Float
     with Global => null;

   --  Same as Approximate_Pi but also returns Abs_Error vs Pi_Constant.
   procedure Approximate_Pi
     (Which     :     Method;
      Effort    :     Effort_Count := Default_Effort;
      Estimate  : out Long_Float;
      Abs_Err   : out Long_Float)
     with Global => null;

end Computation_Of_Pi;
