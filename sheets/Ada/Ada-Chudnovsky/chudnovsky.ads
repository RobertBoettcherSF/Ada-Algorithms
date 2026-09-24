--  Chudnovsky — Ada 2023 educational package for Wikipedia
--  "Chudnovsky algorithm" (Ramanujan–Sato series for 1/π, 1988).
--  Educational Long_Float: sum first Terms terms (k = 0 .. Terms−1)
--  via term-ratio recurrence (avoids huge intermediate factorials).
--  Each term adds ~14 correct decimal digits; Long_Float saturates
--  by ~2 terms, so the public cap is Max_Terms = 8.
--  Production digit records use big-int + binary splitting
--  (see Ada-Binary-Splitting sibling).
--  Primary source:
--  https://en.wikipedia.org/wiki/Chudnovsky_algorithm
--  Siblings (README): Ada-Gauss-Legendre, Ada-Binary-Splitting,
--  Ada-Spigot-Algorithm; upcoming Borwein, BBP.

pragma Ada_2022;

package Chudnovsky
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float Chudnovsky series)
   ---------------------------------------------------------------------------

   --  Number of series terms k = 0 .. Terms−1. Hardware / multiprecision
   --  Chudnovsky would run far further; double precision is saturated
   --  well before 8 terms (~14 digits per term).
   Max_Terms : constant Positive := 8;

   subtype Term_Count is Positive range 1 .. Max_Terms;

   Default_Terms : constant Term_Count := 4;

   --  Valid series index k in the partial sum (0-based).
   subtype Term_Index is Natural range 0 .. Max_Terms - 1;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Reference π (same digits as Ada.Numerics.Pi, as Long_Float).
   Pi_Constant : constant Long_Float :=
     3.141_592_653_589_793_238_46;

   --  Series constants (Wikipedia / practical rearranged form).
   --  Linear polynomial in k: 545140134·k + 13591409.
   A_Const : constant Long_Float := 13591409.0;
   B_Const : constant Long_Float := 545140134.0;
   --  C = 640320;  C³ = 262537412640768000 used in the term ratio.
   C_Const : constant Long_Float := 640320.0;
   C3_Const : constant Long_Float := 262_537_412_640_768_000.0;
   --  Prefactor for π = (426880 · √10005) / Σ t_k.
   Prefactor_Int : constant Long_Float := 426880.0;

   Invalid_Argument : exception;
   --  Raised by Series_Term when K is out of Term_Index, by
   --  Approximate_Pi / Series_Sum when Terms = 0 or Terms > Max_Terms
   --  (defence if called with unconstrained Natural), and if the
   --  accumulated sum is non-positive (should not occur for valid Terms).

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
   -- Series building blocks (term-ratio recurrence)
   ---------------------------------------------------------------------------

   --  Prefactor 426880 · √10005  (numerator of the practical π form).
   function Pi_Numerator return Long_Float
     with Global => null;

   --  Ratio t_{K+1} / t_K for K ≥ 0 (Long_Float). Used to advance terms
   --  without computing (6k)! etc. directly.
   --  Raises Invalid_Argument if K > Max_Terms − 2 (no next term in cap).
   function Term_Ratio (K : Natural) return Long_Float
     with Global => null;

   --  Series term t_K for the rearranged sum:
   --    t_k = (−1)^k (6k)! (A + B k) / ((3k)! (k!)^3 C^{3k})
   --  with A=13591409, B=545140134, C=640320, built by multiplying
   --  successive Term_Ratio values onto t_0 = A.
   --  Raises Invalid_Argument if K > Max_Terms − 1.
   function Series_Term (K : Natural) return Long_Float
     with Global => null;

   --  Partial sum S = Σ_{k=0}^{Terms−1} t_k via term-ratio recurrence.
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Terms.
   function Series_Sum (Terms : Natural) return Long_Float
     with Global => null;

   --  π estimate from a partial sum: Pi_Numerator / Sum.
   --  Raises Invalid_Argument if Sum ≤ 0.
   function Pi_From_Sum (Sum : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core π approximation
   ---------------------------------------------------------------------------

   --  Run Terms Chudnovsky terms (k = 0 .. Terms−1) and return
   --  π ≈ Pi_Numerator / Series_Sum (Terms).
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Terms.
   function Approximate_Pi
     (Terms : Term_Count := Default_Terms) return Long_Float
     with Global => null;

   --  Same as Approximate_Pi but also returns the partial sum S.
   procedure Approximate_Pi
     (Terms    :     Term_Count := Default_Terms;
      Estimate : out Long_Float;
      Sum      : out Long_Float)
     with Global => null;

end Chudnovsky;
