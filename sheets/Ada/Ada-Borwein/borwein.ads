--  Borwein — Ada 2023 educational package for Wikipedia
--  "Borwein's algorithm" (quartic AGM-style iteration for 1/π, 1985).
--  Educational Long_Float: y₀=√2−1, a₀=6−4√2; each step updates y,a
--  with quartic convergence (≈4× digits per iteration). Long_Float
--  saturates by ~2–3 steps, so the public cap is Max_Iterations = 20.
--  Primary source:
--  https://en.wikipedia.org/wiki/Borwein's_algorithm
--  Siblings (README): Ada-Chudnovsky, Ada-Gauss-Legendre; upcoming BBP.

pragma Ada_2022;

package Borwein
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float Borwein quartic)
   ---------------------------------------------------------------------------

   --  Iteration count including the initial (0-step) state. Hardware /
   --  multiprecision Borwein would run further; double precision is
   --  saturated well before 20 iterations (digit quadrupling ≈ 1, 4, 16…).
   Max_Iterations : constant Natural := 20;

   subtype Iteration_Count is Natural range 0 .. Max_Iterations;

   Default_Iterations : constant Iteration_Count := 4;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Reference π (same digits as Ada.Numerics.Pi, as Long_Float).
   Pi_Constant : constant Long_Float :=
     3.141_592_653_589_793_238_46;

   --  Reference 1/π literal (a_n target).
   Inv_Pi_Constant : constant Long_Float :=
     0.318_309_886_183_790_671_54;

   Invalid_Argument : exception;
   --  Raised by Iterate when S.Iterations ≥ Max_Iterations or S.A ≤ 0,
   --  and by Pi_Estimate / Inv_Pi_Estimate when S.A ≤ 0.

   ---------------------------------------------------------------------------
   -- Quartic Borwein state
   ---------------------------------------------------------------------------

   --  One quartic iterate: y ∈ [0,1), a > 0 → 1/π, Iterations = n.
   type State is record
      Y          : Long_Float := 0.0;
      A          : Long_Float := 0.0;
      Iterations : Natural    := 0;
   end record;

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
   -- Core quartic iteration
   ---------------------------------------------------------------------------

   --  Initial state: y₀=√2−1, a₀=6−4√2 (= 2(√2−1)²), Iterations=0.
   function Initial_State return State
     with Global => null;

   --  One Borwein quartic step (Wikipedia 1985 form), with n = S.Iterations:
   --    y' = (1 − (1−y⁴)^{1/4}) / (1 + (1−y⁴)^{1/4}),
   --    a' = a(1+y')⁴ − 2^{2n+3} y' (1 + y' + y'²),
   --  Iterations := Iterations + 1.
   --  Raises Invalid_Argument if S.Iterations ≥ Max_Iterations or S.A ≤ 0.
   function Iterate (S : State) return State
     with Global => null;

   --  1/π estimate from a state: simply A (a_n → 1/π).
   --  Raises Invalid_Argument if S.A ≤ 0.
   function Inv_Pi_Estimate (S : State) return Long_Float
     with Global => null;

   --  π estimate from a state: 1 / A.
   --  Raises Invalid_Argument if S.A ≤ 0.
   function Pi_Estimate (S : State) return Long_Float
     with Global => null;

   --  Run Iterations quartic steps from Initial_State; return π ≈ 1/a_n.
   --  Iterations = 0 returns the estimate from the initial state alone.
   function Approximate_Pi
     (Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   --  Same as Approximate_Pi but also returns the final state.
   procedure Approximate_Pi
     (Iterations :     Iteration_Count := Default_Iterations;
      Final      : out State;
      Estimate   : out Long_Float)
     with Global => null;

   --  Run Iterations steps; return a_n ≈ 1/π.
   function Approximate_Inv_Pi
     (Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   --  Same as Approximate_Inv_Pi but also returns the final state.
   procedure Approximate_Inv_Pi
     (Iterations :     Iteration_Count := Default_Iterations;
      Final      : out State;
      Estimate   : out Long_Float)
     with Global => null;

end Borwein;
