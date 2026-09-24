--  Gauss_Legendre — Ada 2023 educational package for Wikipedia
--  "Gauss–Legendre algorithm" (Brent–Salamin / AGM iteration for π).
--  Educational Long_Float: a₀=1, b₀=1/√2, t₀=1/4, p₀=1; each step
--  replaces (a,b) by arithmetic / geometric means and updates t,p.
--  Digits roughly double per iteration; Long_Float saturates by ~5–6
--  steps, so the public cap is Max_Iterations = 20.
--  Primary source:
--  https://en.wikipedia.org/wiki/Gauss–Legendre_algorithm
--  Siblings (README): Ada-Division-Algorithms, Ada-Spigot-Algorithm;
--  upcoming Chudnovsky, Borwein, BBP.

pragma Ada_2022;

package Gauss_Legendre
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float AGM / Brent–Salamin)
   ---------------------------------------------------------------------------

   --  Iteration count including the initial (0-step) state. Hardware /
   --  multiprecision AGM would run further; double precision is saturated
   --  well before 20 iterations (digit doubling ≈ 1, 3, 8, 19, …).
   Max_Iterations : constant Natural := 20;

   subtype Iteration_Count is Natural range 0 .. Max_Iterations;

   Default_Iterations : constant Iteration_Count := 8;

   Near_Tol : constant Long_Float := 1.0E-9;

   --  Reference π (same digits as Ada.Numerics.Pi, as Long_Float).
   Pi_Constant : constant Long_Float :=
     3.141_592_653_589_793_238_46;

   Invalid_Argument : exception;
   --  Raised by Iterate when S.Iterations ≥ Max_Iterations or S.T ≤ 0,
   --  and by Pi_Estimate when S.T ≤ 0.

   ---------------------------------------------------------------------------
   -- AGM / Brent–Salamin state
   ---------------------------------------------------------------------------

   --  One AGM iterate: a ≥ b ≥ 0, t > 0, p = 2^n after n steps from p₀=1.
   type State is record
      A          : Long_Float := 1.0;
      B          : Long_Float := 0.0;
      T          : Long_Float := 0.25;
      P          : Long_Float := 1.0;
      Iterations : Natural    := 0;
   end record;

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
   -- Oracles / reference
   ---------------------------------------------------------------------------

   --  Ada.Numerics.Pi converted to Long_Float (for tests / demos).
   function Ada_Pi return Long_Float
     with Global => null;

   --  4·Arctan(1) via Long_Elementary_Functions (cross-check).
   function Elementary_Pi return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core AGM iteration
   ---------------------------------------------------------------------------

   --  Initial state: a₀=1, b₀=1/√2, t₀=1/4, p₀=1, Iterations=0.
   function Initial_State return State
     with Global => null;

   --  One Brent–Salamin step:
   --    a' = (a+b)/2,  b' = √(a·b),
   --    t' = t − p·(a−a')²,  p' = 2p,
   --  Iterations := Iterations + 1.
   --  Raises Invalid_Argument if S.Iterations ≥ Max_Iterations or S.T ≤ 0.
   function Iterate (S : State) return State
     with Global => null;

   --  π estimate from a state: (a+b)² / (4t).
   --  Raises Invalid_Argument if S.T ≤ 0.
   function Pi_Estimate (S : State) return Long_Float
     with Global => null;

   --  Run Iterations AGM steps from Initial_State and return π ≈ (a+b)²/(4t).
   --  Iterations = 0 returns the estimate from the initial state alone.
   function Approximate_Pi
     (Iterations : Iteration_Count := Default_Iterations) return Long_Float
     with Global => null;

   --  Same as Approximate_Pi but also returns the final AGM state.
   procedure Approximate_Pi
     (Iterations :     Iteration_Count := Default_Iterations;
      Final      : out State;
      Estimate   : out Long_Float)
     with Global => null;

end Gauss_Legendre;
