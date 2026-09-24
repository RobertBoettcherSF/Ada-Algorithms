--  Hybrid_Monte_Carlo — Ada 2023 educational package for Hybrid /
--  Hamiltonian Monte Carlo (HMC; Duane et al. 1987; Neal 2011).
--  Samples from π(q) ∝ exp(−U(q)) by proposing trajectories under
--  Hamiltonian dynamics (leapfrog integrator) with Metropolis
--  accept/reject on H = U + K, refreshing momentum from N(0,1)
--  each proposal. Primary API: 1D HMC for U(q)=q²/2 (standard normal);
--  optional isotropic / independent Gaussian targets in D ≤ 4.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Hamiltonian_Monte_Carlo
--  Duane, Kennedy, Kennedy & Pendleton (1987); Neal (2011).
--  Siblings (Monte Carlo survey): Ada-MISER, Ada-Wang-Landau,
--  Ada-Metropolis-Hastings, Ada-Gibbs-Sampling (README links).

pragma Ada_2022;

package Hybrid_Monte_Carlo
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Fraction is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Potential energy U(q) and its gradient ∇U(q) (1D).
   type Potential_1D is access function (Q : Real) return Real;
   type Gradient_1D  is access function (Q : Real) return Real;

   --  Educational dimension cap for optional multi-D HMC.
   Max_Dimension : constant Positive := 4;
   subtype Dimension_Count is Positive range 1 .. Max_Dimension;

   type Point is array (Positive range <>) of Real;

   type Potential_ND is access function (Q : Point) return Real;
   type Gradient_ND  is access function (Q : Point) return Point;

   --  Modest leapfrog trajectory length cap (educational).
   Max_L_Steps : constant Positive := 100;
   subtype Leapfrog_Steps is Positive range 1 .. Max_L_Steps;

   --  Cap on optionally stored post-burn-in samples (moments always kept).
   Max_Store : constant Positive := 20_000;
   subtype Store_Count is Natural range 0 .. Max_Store;
   type Sample_Array is array (Positive range <>) of Real;

   --  N_Samples : total HMC proposals after initialization
   --  Burn_In   : discarded initial proposals (not used in moments)
   --  Epsilon   : leapfrog step size ε
   --  L_Steps   : number of leapfrog steps L per proposal
   --  Seed      : RNG seed (Ada.Numerics.Float_Random)
   --  Start     : initial position q_0 (1D)
   --  Keep_Samples : if True, store up to Max_Store post-burn-in draws
   type Config is record
      N_Samples    : Positive       := 10_000;
      Burn_In      : Natural        := 1_000;
      Epsilon      : Positive_Real  := 0.1;
      L_Steps      : Leapfrog_Steps := 10;
      Seed         : Integer        := 42;
      Start        : Real           := 0.0;
      Keep_Samples : Boolean        := False;
   end record;

   --  Running moments over kept (post-burn-in) samples + acceptance rate.
   type Result is record
      Mean         : Real          := 0.0;
      Variance     : Real          := 0.0;
      Accept_Rate  : Unit_Fraction := 0.0;
      N_Kept       : Natural       := 0;
      N_Accepted   : Natural       := 0;
      N_Proposed   : Natural       := 0;
      Stored       : Store_Count   := 0;
      Samples      : Sample_Array (1 .. Max_Store) := [others => 0.0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers (energy, acceptance, leapfrog)
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-12;

   --  Kinetic energy K(p) = ‖p‖²/2 with unit mass (1D scalar or ND vector).
   function Kinetic_1D (P : Real) return Non_Negative
     with Global => null;

   function Kinetic_ND (P : Point) return Non_Negative
     with Global => null;

   --  Hamiltonian H(q,p) = U(q) + K(p).
   function Hamiltonian_1D (U_Q, P : Real) return Real
     with Global => null;

   function Hamiltonian_ND (U_Q : Real; P : Point) return Real
     with Global => null;

   --  Metropolis acceptance probability for ΔH = H' − H:
   --    α = min(1, exp(−ΔH)).
   function Accept_Probability (Delta_H : Real) return Unit_Fraction
     with Global => null;

   --  One leapfrog step (ε): half-kick, full-drift, half-kick (unit mass).
   procedure Leapfrog_Step_1D
     (Q       : in out Real;
      P       : in out Real;
      Grad_U  : Gradient_1D;
      Epsilon : Positive_Real)
     with Pre => Grad_U /= null;

   --  L consecutive leapfrog steps from (Q,P); updates in place.
   procedure Leapfrog_1D
     (Q       : in out Real;
      P       : in out Real;
      Grad_U  : Gradient_1D;
      Epsilon : Positive_Real;
      L       : Leapfrog_Steps)
     with Pre => Grad_U /= null;

   procedure Leapfrog_Step_ND
     (Q       : in out Point;
      P       : in out Point;
      Grad_U  : Gradient_ND;
      Epsilon : Positive_Real)
     with Pre => Grad_U /= null
                 and then Q'First = P'First
                 and then Q'Last = P'Last
                 and then Q'Length >= 1
                 and then Q'Length <= Max_Dimension;

   procedure Leapfrog_ND
     (Q       : in out Point;
      P       : in out Point;
      Grad_U  : Gradient_ND;
      Epsilon : Positive_Real;
      L       : Leapfrog_Steps)
     with Pre => Grad_U /= null
                 and then Q'First = P'First
                 and then Q'Last = P'Last
                 and then Q'Length >= 1
                 and then Q'Length <= Max_Dimension;

   ---------------------------------------------------------------------------
   -- Core algorithms (1D)
   ---------------------------------------------------------------------------

   --  Classical HMC on R¹:
   --    refresh p ~ N(0,1); leapfrog L steps of size ε; Metropolis on H.
   --  Target via Potential U and Grad_U (π ∝ exp(−U)).
   function Sample_1D
     (U      : Potential_1D;
      Grad_U : Gradient_1D;
      Cfg    : Config := (others => <>)) return Result
     with Pre => U /= null and then Grad_U /= null;

   --  Alias matching the series Run naming.
   function Run
     (U      : Potential_1D;
      Grad_U : Gradient_1D;
      Cfg    : Config := (others => <>)) return Result
     renames Sample_1D;

   ---------------------------------------------------------------------------
   -- Optional multi-D (D ≤ 4): independent coordinates, unit-mass HMC
   ---------------------------------------------------------------------------

   type Config_ND (D : Dimension_Count) is record
      N_Samples : Positive       := 10_000;
      Burn_In   : Natural        := 1_000;
      Epsilon   : Positive_Real  := 0.1;
      L_Steps   : Leapfrog_Steps := 10;
      Seed      : Integer        := 42;
      Start     : Point (1 .. D) := [others => 0.0];
   end record;

   type Result_ND (D : Dimension_Count) is record
      Mean        : Point (1 .. D) := [others => 0.0];
      Variance    : Point (1 .. D) := [others => 0.0];
      Accept_Rate : Unit_Fraction  := 0.0;
      N_Kept      : Natural        := 0;
      N_Accepted  : Natural        := 0;
      N_Proposed  : Natural        := 0;
   end record;

   function Sample_ND
     (U      : Potential_ND;
      Grad_U : Gradient_ND;
      Cfg    : Config_ND) return Result_ND
     with Pre => U /= null and then Grad_U /= null;

   ---------------------------------------------------------------------------
   -- Library-level educational potentials / gradients (for 'Access)
   ---------------------------------------------------------------------------

   --  Standard normal: U(q) = q²/2, ∇U(q) = q  ⇒  π = N(0,1).
   function U_Std_Normal (Q : Real) return Real;
   function Grad_U_Std_Normal (Q : Real) return Real;

   --  N(μ,1): U(q) = (q−μ)²/2 with μ = 2.
   function U_Normal_Mu2 (Q : Real) return Real;
   function Grad_U_Normal_Mu2 (Q : Real) return Real;

   --  N(0,σ²) with σ = 2: U(q) = q²/(2σ²), ∇U = q/σ².
   function U_Normal_Wide (Q : Real) return Real;
   function Grad_U_Normal_Wide (Q : Real) return Real;

   --  Independent standard normals in D coords: U = ‖q‖²/2, ∇U = q.
   function U_Iso_Normal_ND (Q : Point) return Real;
   function Grad_U_Iso_Normal_ND (Q : Point) return Point;

end Hybrid_Monte_Carlo;
