--  BBP — Ada 2023 educational package for Wikipedia
--  "Bailey–Borwein–Plouffe formula" (base-16 series for π, 1995).
--  Educational Long_Float: sum first Terms terms (k = 0 .. Terms−1)
--  of the classic BBP series. Each term shrinks by ~1/16; Long_Float
--  saturates by ~10–15 terms, so the public cap is Max_Terms = 40.
--  Optional sketch: Hex_Digit_Of_Pi extracts the N-th hex digit after
--  the point via modular exponentiation / fractional parts (classic
--  BBP digit extraction), capped for classroom Long_Float reliability.
--  Primary source:
--  https://en.wikipedia.org/wiki/Bailey–Borwein–Plouffe_formula
--  Siblings (README): Ada-Borwein, Ada-Chudnovsky, Ada-Gauss-Legendre;
--  upcoming Computation of Pi survey.

pragma Ada_2022;

package BBP
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float BBP series)
   ---------------------------------------------------------------------------

   --  Number of series terms k = 0 .. Terms−1. Hardware / multiprecision
   --  BBP digit extraction would run far further; double precision for
   --  the full sum is saturated well before 40 terms (~4 bits / term).
   Max_Terms : constant Positive := 40;

   subtype Term_Count is Positive range 1 .. Max_Terms;

   Default_Terms : constant Term_Count := 12;

   --  Valid series index k in the partial sum (0-based).
   subtype Term_Index is Natural range 0 .. Max_Terms - 1;

   --  Hex digit index after the radix point (0 = first fractional digit).
   --  Educational Long_Float + modular-pow sketch; not a production spigot.
   Max_Hex_Digit : constant Natural := 12;

   subtype Hex_Digit_Index is Natural range 0 .. Max_Hex_Digit;

   --  One hexadecimal digit value 0 .. 15 (0..9,A..F).
   subtype Hex_Digit is Natural range 0 .. 15;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Reference π (same digits as Ada.Numerics.Pi, as Long_Float).
   Pi_Constant : constant Long_Float :=
     3.141_592_653_589_793_238_46;

   Invalid_Argument : exception;
   --  Raised by Series_Term when K is out of Term_Index, by
   --  Approximate_Pi / Series_Sum when Terms = 0 or Terms > Max_Terms
   --  (defence if called with unconstrained Natural), and by
   --  Hex_Digit_Of_Pi when N > Max_Hex_Digit.

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
   -- Series building blocks
   ---------------------------------------------------------------------------

   --  Inner parenthesis of the BBP term at index K:
   --    4/(8K+1) − 2/(8K+4) − 1/(8K+5) − 1/(8K+6)
   function Term_Parenthesis (K : Natural) return Long_Float
     with Global => null;

   --  Full series term t_K = 16^(−K) · Term_Parenthesis(K).
   --  Raises Invalid_Argument if K > Max_Terms − 1.
   function Series_Term (K : Natural) return Long_Float
     with Global => null;

   --  Partial sum S = Σ_{k=0}^{Terms−1} t_k.
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Terms.
   function Series_Sum (Terms : Natural) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core π approximation (partial BBP series)
   ---------------------------------------------------------------------------

   --  Run Terms BBP terms (k = 0 .. Terms−1) and return π ≈ Series_Sum.
   --  Raises Invalid_Argument if Terms = 0 or Terms > Max_Terms.
   function Approximate_Pi
     (Terms : Term_Count := Default_Terms) return Long_Float
     with Global => null;

   --  Same as Approximate_Pi but also returns the partial sum S
   --  (identical to Estimate for this formula).
   procedure Approximate_Pi
     (Terms    :     Term_Count := Default_Terms;
      Estimate : out Long_Float;
      Sum      : out Long_Float)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Educational hex-digit extraction sketch
   ---------------------------------------------------------------------------

   --  N-th hexadecimal digit of π after the radix point (0-based), via
   --  the classic BBP modular / fractional-part method (Wikipedia
   --  "BBP digit-extraction algorithm for π"). Caps at Max_Hex_Digit
   --  for Long_Float educational reliability.
   --  Raises Invalid_Argument if N > Max_Hex_Digit.
   function Hex_Digit_Of_Pi (N : Natural) return Hex_Digit
     with Global => null;

   --  Fractional part in [0,1) of 16^N · π used by Hex_Digit_Of_Pi
   --  (before ×16 and truncating). Useful for tests / demos.
   --  Raises Invalid_Argument if N > Max_Hex_Digit.
   function Hex_Fractional_Part (N : Natural) return Long_Float
     with Global => null;

end BBP;
