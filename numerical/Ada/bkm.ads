--  Bkm — Ada 2023 educational package for Wikipedia "BKM algorithm"
--  (Bajard–Kla–Muller shift-and-add). Prefill A_k = ln(1+2^{-k});
--  E-mode → Exp; L-mode → Ln. Educational Long_Float with multiplies by
--  2^{-k} (hardware intent: add/shift/compare only). No CORDIC-style K
--  gain factor. Cap ≤ 40. Real modes only in this package.
--  Primary source: https://en.wikipedia.org/wiki/BKM_algorithm
--  Sibling: Ada-CORDIC; upcoming Exponentiating by squaring,
--  Addition-chain exponentiation, SRT division.

pragma Ada_2022;

package Bkm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   --  Iteration count. Hardware BKM often uses word-width iterations;
   --  Double precision is effectively exhausted well before 40.
   Min_Iterations : constant Positive := 1;
   Max_Iterations : constant Positive := 40;

   subtype Iteration_Count is Positive range Min_Iterations .. Max_Iterations;

   Default_Iterations : constant Iteration_Count := 40;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  ln(2) — used for binary range reduction around the classic BKM cone.
   Ln_2 : constant Long_Float := 0.693_147_180_559_945_309_417_2;

   --  e = exp(1)
   E_Const : constant Long_Float := 2.718_281_828_459_045_235_36;

   --  Classic real BKM (d_k ∈ {0,1}) convergence bounds (infinite table):
   --    ∏_{k=0}^∞ (1+2^{-k}) ≈ 4.768462058…
   --    ∑_{k=0}^∞ ln(1+2^{-k}) = ln(∏…) ≈ 1.562436…
   --  After binary range reduction, Exp residual is in [0, ln 2] ⊂ [0, Σ]
   --  and Ln mantissa is in [1, 2) ⊂ [1, ∏].
   Prod_Bound : constant Long_Float := 4.768_462_058_0;
   Sum_Bound  : constant Long_Float := 1.562_436_0;

   Invalid_Argument : exception;
   --  Raised by Ln when the argument is non-positive.

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
   -- Prefill table accessors
   ---------------------------------------------------------------------------

   --  A_k = ln(1+2^{-k}) for k in 0 .. Max_Iterations-1.
   function Log_Table (K : Natural) return Long_Float
     with Pre => K < Max_Iterations, Global => null;

   --  Optional companion A_k^- = ln(1-2^{-k}) for k ≥ 1 (undefined / −∞ at
   --  k = 0). Full real BKM with d_k ∈ {−1,0,1} uses both; this educational
   --  package keeps d_k ∈ {0,1} plus binary range reduction, and exposes
   --  the minus table for documentation / experiments.
   function Log_Table_Minus (K : Natural) return Long_Float
     with Pre => K in 1 .. Max_Iterations - 1, Global => null;

   ---------------------------------------------------------------------------
   -- Oracles (Ada Long_Elementary_Functions; for tests / documentation)
   ---------------------------------------------------------------------------

   function Exact_Exp (Y : Long_Float) return Long_Float
     with Global => null;

   function Exact_Ln (X : Long_Float) return Long_Float
     with Pre => X > 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- E-mode — real exponential
   ---------------------------------------------------------------------------

   --  Real BKM E-mode with binary range reduction:
   --    Y = N·ln(2) + R,  R ∈ [0, ln 2],
   --    Exp(Y) = 2^N · Exp_Core(R),
   --  where Exp_Core is the classic shift-and-add product driven by comparing
   --  residual against A_k. No CORDIC-style scale factor K.
   function Exp
     (Y          : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- L-mode — real natural logarithm
   ---------------------------------------------------------------------------

   --  Real BKM L-mode with binary range reduction:
   --    X = M · 2^E,  M ∈ [1, 2),
   --    Ln(X) = Ln_Core(M) + E·ln(2).
   --  Raises Invalid_Argument when X ≤ 0.
   function Ln
     (X          : Long_Float;
      Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

end Bkm;
