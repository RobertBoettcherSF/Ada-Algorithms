--  Nested_Sampling — Ada 2023 educational package for Wikipedia
--  "Nested sampling algorithm" (John Skilling, 2004 / 2006):
--  approximate Bayesian evidence Z = P(D|M) = ∫ L(θ) π(θ) dθ and produce
--  posterior-weighted discarded samples. Implements the Wikipedia /
--  Skilling shell schedule X_i = exp(-i/N) (optional debiased (1-1/N)^i),
--  weights w_i = X_{i-1}-X_i, MCMC replacement under the constrained prior
--  L(θ) > L_i, and optional live-point remainder X_j * mean(L).
--  Related (README): MultiNest, PolyChord — not implemented here.

pragma Ada_2022;

package Nested_Sampling
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable evidence / weight arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dims    : constant Positive := 4;
   Max_Live    : constant Positive := 256;
   Max_Samples : constant Positive := 4096;

   subtype Dim_Count  is Natural  range 0 .. Max_Dims;
   subtype Dim_Index  is Positive range 1 .. Max_Dims;
   subtype Live_Count is Natural  range 0 .. Max_Live;
   subtype Live_Index is Positive range 1 .. Max_Live;
   subtype Sample_Count is Natural range 0 .. Max_Samples;
   subtype Sample_Index is Positive range 1 .. Max_Samples;

   --  Parameter vector; valid entries occupy 1 .. Dim.
   type Param_Vector is array (Dim_Index) of Real;

   type Live_Point is record
      Theta : Param_Vector := [others => 0.0];
      L     : Real := 0.0;
      Dim   : Dim_Count := 0;
   end record;

   type Live_Point_Array is array (Live_Index) of Live_Point;

   type Live_Set is record
      Points : Live_Point_Array := [others => <>];
      Count  : Live_Count := 0;
      Dim    : Dim_Count := 0;
   end record;

   type Sample_Point is record
      Theta  : Param_Vector := [others => 0.0];
      L      : Real := 0.0;
      Weight : Non_Negative := 0.0;
      Dim    : Dim_Count := 0;
   end record;

   type Sample_Array is array (Sample_Index) of Sample_Point;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Log_Sum (A, B : Real) return Real
     with Global => null;
   --  Stable log(exp(A)+exp(B)); treats very negative as -∞ for toys.

   function Safe_Log (X : Real) return Real
     with Global => null;
   --  Natural log; returns a large negative sentinel for X <= 0.

   ---------------------------------------------------------------------------
   -- Prior-volume schedule (Skilling)
   ---------------------------------------------------------------------------

   type Volume_Schedule is (Exponential_Shrink, Debiased_Shrink);
   --  Exponential_Shrink : X_i = exp(-i/N)
   --  Debiased_Shrink    : X_i = (1 - 1/N)^i   (removes O(1/N) positive bias)

   function Prior_Volume
     (Iteration : Natural;
      N_Live    : Positive;
      Schedule  : Volume_Schedule := Exponential_Shrink) return Unit_Interval
     with Pre => N_Live >= 1, Global => null;
   --  X_0 = 1; for i > 0 returns X_i under the chosen schedule.

   function Shell_Weight
     (X_Prev, X_Curr : Unit_Interval) return Non_Negative
     with Global => null;
   --  w_i = X_{i-1} - X_i (clamped at 0 if numerical noise).

   ---------------------------------------------------------------------------
   -- Seeded RNG (LCG) for reproducible MCMC / prior draws
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Real
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Likelihood / prior hooks
   ---------------------------------------------------------------------------

   type Likelihood_Fn is access function
     (Theta : Param_Vector; Dim : Dim_Count) return Real;

   type Prior_Density_Fn is access function
     (Theta : Param_Vector; Dim : Dim_Count) return Real;

   --  Built-in educational models with known / analytic evidence.
   type Built_In_Model is
     (Flat_Unit,          -- π = U[0,1], L=1           → Z = 1
      Exponential_Unit,   -- π = U[0,1], L=exp(-θ)     → Z = 1 - e^{-1}
      Gaussian_Bump,      -- π = U[-5,5], L=exp(-θ²/2) → Z ≈ √(2π)/10
      Theta_Unit);        -- π = U[0,1], L=θ           → Z = 1/2

   function Model_Dim (Model : Built_In_Model) return Dim_Count
     with Global => null;
   --  All built-ins are 1-D.

   function Model_Low (Model : Built_In_Model) return Param_Vector
     with Global => null;

   function Model_High (Model : Built_In_Model) return Param_Vector
     with Global => null;

   function Analytic_Evidence (Model : Built_In_Model) return Positive_Real
     with Global => null;
   --  Exact (Flat, Exponential) or high-accuracy numeric reference (Gaussian).

   function Built_In_Likelihood
     (Model : Built_In_Model; Theta : Param_Vector; Dim : Dim_Count)
      return Real
     with Global => null;

   function Built_In_Prior_Density
     (Model : Built_In_Model; Theta : Param_Vector; Dim : Dim_Count)
      return Real
     with Global => null;
   --  Uniform box density 1/∏(Hi-Lo) inside support, else 0.

   function In_Prior_Box
     (Theta, Low, High : Param_Vector; Dim : Dim_Count) return Boolean
     with Pre => Dim >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Run parameters / result
   ---------------------------------------------------------------------------

   type Parameters is record
      N_Live        : Positive := 50;
      Max_Iters     : Positive := 500;
      MCMC_Steps    : Positive := 20;
      Tol           : Non_Negative := 1.0E-4;
      Seed          : Natural := 1;
      Schedule      : Volume_Schedule := Exponential_Shrink;
      Add_Remainder : Boolean := True;
      Dim           : Dim_Count := 1;
      Low           : Param_Vector := [others => 0.0];
      High          : Param_Vector := [others => 1.0];
      Proposal_Scale : Positive_Real := 0.1;
      --  Random-walk step = Proposal_Scale * (High-Low) per coordinate.
   end record;

   type Result is record
      Evidence            : Non_Negative := 0.0;
      Log_Evidence        : Real := -1.0E30;
      Iters               : Natural := 0;
      Num_Samples         : Sample_Count := 0;
      Samples             : Sample_Array := [others => <>];
      Final_X             : Unit_Interval := 1.0;
      Remainder           : Non_Negative := 0.0;
      Last_MCMC_Accepted  : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Live-set utilities
   ---------------------------------------------------------------------------

   procedure Init_Live_From_Prior
     (Live   : out Live_Set;
      Params : Parameters;
      Likely : Likelihood_Fn;
      State  : in out RNG_State);
   --  Draw N_Live points uniformly in [Low, High]^Dim and evaluate L.
   --  Raises Invalid_Argument if N_Live / Dim out of bounds.

   function Min_Likelihood_Index (Live : Live_Set) return Live_Index
     with Pre => Live.Count >= 1, Global => null;

   function Mean_Likelihood (Live : Live_Set) return Real
     with Pre => Live.Count >= 1, Global => null;

   procedure Replace_Lowest_MCMC
     (Live       : in out Live_Set;
      L_Star     : Real;
      Params     : Parameters;
      Likely     : Likelihood_Fn;
      State      : in out RNG_State;
      Accepted   : out Natural);
   --  Replace the lowest-L live point by a random-walk MCMC started from a
   --  random other live point; proposals rejected if L <= L_Star or outside
   --  the prior box.

   ---------------------------------------------------------------------------
   -- Library-level likelihoods (safe for Likelihood_Fn'Access from callers)
   ---------------------------------------------------------------------------

   function Likelihood_Flat
     (Theta : Param_Vector; Dim : Dim_Count) return Real
     with Global => null;

   function Likelihood_Exponential
     (Theta : Param_Vector; Dim : Dim_Count) return Real
     with Global => null;

   function Likelihood_Gaussian_Bump
     (Theta : Param_Vector; Dim : Dim_Count) return Real
     with Global => null;

   function Likelihood_Theta
     (Theta : Param_Vector; Dim : Dim_Count) return Real
     with Global => null;
   --  L(θ)=θ_1; with U[0,1] prior, Z = 1/2.

   ---------------------------------------------------------------------------
   -- Main driver
   ---------------------------------------------------------------------------

   function Run_Nested_Sampling
     (Params : Parameters;
      Likely : Likelihood_Fn) return Result;
   --  Full nested sampling loop. Raises Invalid_Argument on bad Params;
   --  Capacity_Exceeded if sample buffer would overflow.

   function Run_Built_In
     (Model  : Built_In_Model;
      Params : Parameters := (others => <>)) return Result;
   --  Convenience: fills Dim/Low/High from the model and runs.

end Nested_Sampling;
