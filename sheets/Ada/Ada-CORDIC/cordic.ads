--  Cordic — Ada 2023 educational package for Wikipedia "CORDIC"
--  (coordinate rotation digital computer; Volder's circular algorithm).
--  Prefill θ_i = arctan(2^{-i}); rotation mode → sin/cos; vectoring mode
--  → atan2 / magnitude; gain K / 1/K compensation. Educational Long_Float
--  with multiplies by 2^{-i} (hardware intent: shift-and-add). Cap ≤ 40.
--  Primary source: https://en.wikipedia.org/wiki/CORDIC
--  Siblings (README): Ada-Montgomery-Reduction; upcoming BKM,
--  Exponentiation by squaring, Addition-chain exponentiation.

pragma Ada_2022;

package Cordic
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   --  Iteration count. Hardware CORDIC often uses word-width iterations;
   --  Double precision is effectively exhausted well before 40.
   Min_Iterations : constant Positive := 1;
   Max_Iterations : constant Positive := 40;

   subtype Iteration_Count is Positive range Min_Iterations .. Max_Iterations;

   Default_Iterations : constant Iteration_Count := 40;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Circular CORDIC product gain
   --    K_n = ∏_{i=0}^{n-1} cos(arctan(2^{-i})) = ∏_{i=0}^{n-1} 1/√(1+2^{-2i})
   --  As n→∞, K_∞ ≈ 0.6072529350088812561694… and A_∞ = 1/K_∞ ≈ 1.646760258121…
   --  (Wikipedia often writes A_n for the accumulated scale ≈ 1.646.)
   --  Prefilling uses Elementary_Functions once at elaboration; the iterative
   --  loop itself only adds/subtracts and multiplies by powers of one-half
   --  (stand-in for arithmetic right shifts).
   K_Inf     : constant Long_Float := 0.607_252_935_008_881_256_169_4;
   Inv_K_Inf : constant Long_Float := 1.646_760_258_121_072_0;  -- A_∞ = 1/K_∞

   Pi       : constant Long_Float := 3.141_592_653_589_793_238_46;
   Half_Pi  : constant Long_Float := 1.570_796_326_794_896_619_23;
   Two_Pi   : constant Long_Float := 6.283_185_307_179_586_476_92;
   Quarter_Pi : constant Long_Float := 0.785_398_163_397_448_309_62;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (Approx_V, Exact_V : Long_Float) return Long_Float
     with Global => null;

   --  |Approx − Exact| / |Exact|; 0 when both zero; large sentinel if Exact=0.
   function Rel_Error (Approx_V, Exact_V : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Angle helpers
   ---------------------------------------------------------------------------

   --  Reduce Angle into (−π, π] by adding/subtracting 2π.
   function Reduce_Angle (Angle : Long_Float) return Long_Float
     with Global => null;

   --  Prefill table entry θ_i = arctan(2^{-i}) for i in 0 .. Max_Iterations-1.
   function Arctan_Table (I : Natural) return Long_Float
     with Pre => I < Max_Iterations, Global => null;

   --  Product gain K for the first N iterations (exact product of cos factors).
   function Gain_K (N : Iteration_Count) return Long_Float
     with Global => null;

   --  Reciprocal A_n = 1/K_n (Wikipedia scale). Rotation starts at K_n;
   --  magnitude divides the vectoring X by A_n.
   function Inv_Gain_K (N : Iteration_Count) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Oracles (Ada Elementary_Functions; for tests / documentation)
   ---------------------------------------------------------------------------

   function Exact_Sin (Angle : Long_Float) return Long_Float
     with Global => null;
   function Exact_Cos (Angle : Long_Float) return Long_Float
     with Global => null;
   function Exact_Arctan (Y : Long_Float) return Long_Float
     with Global => null;
   function Exact_Atan2 (Y, X : Long_Float) return Long_Float
     with Global => null;
   function Exact_Hypot (X, Y : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Rotation mode — sin / cos
   ---------------------------------------------------------------------------

   --  Circular CORDIC rotation: drive residual angle Z → 0 by ±arctan(2^{-i})
   --  micro-rotations. Returns (Sin, Cos) ≈ (sin Angle, cos Angle) after
   --  quadrant reduction into the CORDIC convergence cone ≈ ±99.9°.
   procedure Sin_Cos
     (Angle      : Long_Float;
      Sin_V      : out Long_Float;
      Cos_V      : out Long_Float;
      Iterations : Iteration_Count := Default_Iterations)
     with Global => null;

   function Sin
     (Angle      : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   function Cos
     (Angle      : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Vectoring mode — atan2 / magnitude
   ---------------------------------------------------------------------------

   --  Drive Y → 0; accumulated Z → atan2(Y,X); final X → K · √(X²+Y²).
   --  Atan2 follows Ada / IEEE quadrant conventions (including axes).
   function Atan2
     (Y, X       : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   --  Magnitude √(X²+Y²) via vectoring + 1/K compensation.
   function Magnitude
     (X, Y       : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

end Cordic;
