--  Alpha_Max_Plus_Beta_Min — Ada 2023 educational package for Wikipedia
--  "Alpha max plus beta min algorithm": high-speed approximation of
--  Pythagorean addition |z| = sqrt(a^2 + b^2) without squares or square
--  roots, via α·Max(|a|,|b|) + β·Min(|a|,|b|). Educational Long_Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Alpha_max_plus_beta_min_algorithm
--  Siblings (README): Ada-Square-Root-Algorithms, Ada-Nth-Root;
--  upcoming Spigot, Rounding, Newton multiplicative inverse.

pragma Ada_2022;

package Alpha_Max_Plus_Beta_Min
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Closest geometric (minimax) coefficients from Wikipedia:
   --    α₀ = 2 cos(π/8) / (1 + cos(π/8)) = 1 − tan²(π/16) ≈ 0.960433870103
   --    β₀ = 2 sin(π/8) / (1 + cos(π/8)) = 2 tan(π/16)     ≈ 0.397824734759
   --  Maximum relative error ≈ 3.96%.
   Alpha_Optimal : constant Long_Float := 0.960_433_870_103;
   Beta_Optimal  : constant Long_Float := 0.397_824_734_759;

   --  Classic classroom / DSP presets (α, β) and wiki largest-error %:
   --    (1, 1/2)     ≈ 11.80%
   --    (1, 1/4)     ≈ 11.61%
   --    (1, 3/8)     ≈  6.80%   — binary-shift friendly
   --    (15/16,15/32)≈  6.25%   — shift-friendly tighter fit
   Alpha_Half          : constant Long_Float := 1.0;
   Beta_Half           : constant Long_Float := 0.5;
   Alpha_Quarter       : constant Long_Float := 1.0;
   Beta_Quarter        : constant Long_Float := 0.25;
   Alpha_Shift         : constant Long_Float := 1.0;
   Beta_Shift          : constant Long_Float := 0.375;  -- 3/8
   Alpha_Fifteenths    : constant Long_Float := 15.0 / 16.0;
   Beta_Fifteenths     : constant Long_Float := 15.0 / 32.0;

   --  Documented max relative-error ceilings (slightly above wiki %).
   Max_Rel_Half       : constant Long_Float := 0.12;    -- ~11.80%
   Max_Rel_Quarter    : constant Long_Float := 0.12;    -- ~11.61%
   Max_Rel_Shift      : constant Long_Float := 0.07;    -- ~6.80%
   Max_Rel_Fifteenths : constant Long_Float := 0.065;   -- ~6.25%
   Max_Rel_Optimal    : constant Long_Float := 0.04;    -- ~3.96%

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (Approx_V, Exact_V : Long_Float) return Long_Float
     with Global => null;

   --  |Approx − Exact| / |Exact|; returns 0 when Exact = 0 and Approx = 0;
   --  returns a large sentinel when Exact = 0 and Approx ≠ 0.
   function Rel_Error (Approx_V, Exact_V : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Exact oracle (educational; keep |A|,|B| modest to avoid overflow)
   ---------------------------------------------------------------------------

   --  Exact_Hypot(A,B) = sqrt(A² + B²) via Long_Float elementary Sqrt.
   --  Not overflow-safe for huge magnitudes — educational oracle only.
   function Exact_Hypot (A, B : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core approximation
   ---------------------------------------------------------------------------

   --  Approx = α · max(|A|,|B|) + β · min(|A|,|B|).
   function Approx
     (A, B       : Long_Float;
      Alpha, Beta : Long_Float) return Long_Float
     with Global => null;

   --  Clamped form (wiki improvement when α < 1):
   --    max(Max, α·Max + β·Min)
   --  so the estimate never falls below Max near the axes.
   function Approx_Clamped
     (A, B       : Long_Float;
      Alpha, Beta : Long_Float) return Long_Float
     with Global => null;

   --  Two-segment improvement: max(α₀·Max+β₀·Min, α₁·Max+β₁·Min).
   function Approx_Two_Segment
     (A, B                 : Long_Float;
      Alpha_0, Beta_0      : Long_Float;
      Alpha_1, Beta_1      : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Named presets
   ---------------------------------------------------------------------------

   function Approx_Half (A, B : Long_Float) return Long_Float
     with Global => null;
   --  α=1, β=1/2

   function Approx_Quarter (A, B : Long_Float) return Long_Float
     with Global => null;
   --  α=1, β=1/4

   function Approx_Shift_Friendly (A, B : Long_Float) return Long_Float
     with Global => null;
   --  α=1, β=3/8 (bit-shift friendly)

   function Approx_Fifteenths (A, B : Long_Float) return Long_Float
     with Global => null;
   --  α=15/16, β=15/32

   function Approx_Optimal (A, B : Long_Float) return Long_Float
     with Global => null;
   --  α₀, β₀ minimax geometric coefficients

   function Approx_Optimal_Clamped (A, B : Long_Float) return Long_Float
     with Global => null;
   --  Clamped optimal: max(Max, α₀·Max + β₀·Min)

end Alpha_Max_Plus_Beta_Min;
