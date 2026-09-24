--  Glauber_Dynamics — Ada 2023 educational package for Wikipedia
--  "Glauber dynamics" (Roy J. Glauber, 1963): classical single-spin-flip
--  heat-bath MCMC for the 2-D Ising model on an L×L lattice with periodic
--  boundary conditions. Also provides Metropolis single-spin acceptance as
--  an optional comparison helper. Observables: magnetization, energy,
--  susceptibility estimators. Exact 2×2 Boltzmann checks in the test suite.
--  Primary source: https://en.wikipedia.org/wiki/Glauber_dynamics

pragma Ada_2022;

package Glauber_Dynamics
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Educational bound; Jacobi-style dense ops are not needed here.
   Max_L : constant Positive := 32;

   subtype Lattice_Size is Positive range 1 .. Max_L;
   subtype Coord        is Positive range 1 .. Max_L;

   --  Classical Ising spin σ ∈ {−1, +1}.
   type Spin is range -1 .. 1
     with Static_Predicate => Spin /= 0;

   type Spin_Grid is array (Coord range <>, Coord range <>) of Spin;

   type Lattice is record
      L     : Lattice_Size := 2;
      Spins : Spin_Grid (1 .. Max_L, 1 .. Max_L) :=
        [others => [others => 1]];
   end record;

   --  Couplings: Hamiltonian
   --    H = −J ∑_{⟨i,j⟩} σ_i σ_j − h ∑_i σ_i
   --  with inverse temperature β = 1/T (k_B = 1).
   type Config is record
      J    : Real := 1.0;
      H    : Real := 0.0;
      Beta : Real := 1.0;
   end record;

   type Sweep_Order is (Random_Sites, Sequential, Checkerboard);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible MCMC
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Index
     (State : in out RNG_State; L : Lattice_Size) return Coord
     with Global => null;
   --  Uniform integer in 1 .. L.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp01 (X : Real) return Unit_Interval
     with Global => null;

   ---------------------------------------------------------------------------
   -- Lattice initialization
   ---------------------------------------------------------------------------

   procedure Init_All (Lat : in out Lattice; L : Lattice_Size; Value : Spin)
     with Global => null;
   --  Set every site to Value; Lat.L := L.

   procedure Init_Random
     (Lat   : in out Lattice;
      L     : Lattice_Size;
      State : in out RNG_State)
     with Global => null;
   --  Independent ±1 draws at each site.

   function Site_Count (Lat : Lattice) return Positive
     with Global => null;
   --  N = L².

   function Get_Spin (Lat : Lattice; X, Y : Coord) return Spin
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;

   procedure Set_Spin (Lat : in out Lattice; X, Y : Coord; S : Spin)
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;

   ---------------------------------------------------------------------------
   -- Local field / neighbors (periodic BCs)
   ---------------------------------------------------------------------------

   function Wrap (I : Integer; L : Lattice_Size) return Coord
     with Global => null;
   --  1-based modular wrap into 1 .. L.

   function Neighbor_Sum (Lat : Lattice; X, Y : Coord) return Real
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  S = σ_{x+1,y} + σ_{x−1,y} + σ_{x,y+1} + σ_{x,y−1}  (four nn, PBC).

   function Local_Field
     (Lat : Lattice; X, Y : Coord; Cfg : Config) return Real
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  h_i = J · Neighbor_Sum + h.

   function Delta_E_Flip
     (Lat : Lattice; X, Y : Coord; Cfg : Config) return Real
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  Energy change if spin (X,Y) is flipped: ΔE = 2 σ_i (J S + h).

   ---------------------------------------------------------------------------
   -- Heat-bath (Glauber) and Metropolis acceptance
   ---------------------------------------------------------------------------

   function Heatbath_Prob_Plus
     (Local_H : Real; Beta : Real) return Unit_Interval
     with Global => null;
   --  P(σ_i ← +1) = 1 / (1 + exp(−2 β h_i)).

   function Heatbath_Flip_Prob
     (Lat : Lattice; X, Y : Coord; Cfg : Config) return Unit_Interval
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  Wikipedia Fermi form: p(ΔE) = 1 / (1 + exp(β ΔE)) to flip current spin.

   function Metropolis_Accept_Prob
     (Delta_E : Real; Beta : Real) return Unit_Interval
     with Global => null;
   --  min(1, exp(−β ΔE)).

   procedure Glauber_Update_Site
     (Lat   : in out Lattice;
      X, Y  : Coord;
      Cfg   : Config;
      State : in out RNG_State)
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  Heat-bath resample of site (X,Y): set σ=+1 with Heatbath_Prob_Plus.

   procedure Metropolis_Update_Site
     (Lat   : in out Lattice;
      X, Y  : Coord;
      Cfg   : Config;
      State : in out RNG_State)
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  Propose flip; accept with Metropolis_Accept_Prob.

   procedure Glauber_Sweep
     (Lat   : in out Lattice;
      Cfg   : Config;
      State : in out RNG_State;
      Order : Sweep_Order := Random_Sites)
     with Global => null;
   --  One sweep = L² attempted site updates.

   procedure Metropolis_Sweep
     (Lat   : in out Lattice;
      Cfg   : Config;
      State : in out RNG_State;
      Order : Sweep_Order := Random_Sites)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Observables
   ---------------------------------------------------------------------------

   function Magnetization (Lat : Lattice) return Real
     with Global => null;
   --  m = N^{−1} ∑ σ_i  ∈ [−1, 1].

   function Absolute_Magnetization (Lat : Lattice) return Non_Negative
     with Global => null;

   function Energy (Lat : Lattice; Cfg : Config) return Real
     with Global => null;
   --  Full Hamiltonian H (each bond once).

   function Energy_Density (Lat : Lattice; Cfg : Config) return Real
     with Global => null;
   --  H / N.

   function Susceptibility_Estimator
     (Mean_M, Mean_M2 : Real; Beta : Real; N : Positive) return Real
     with Pre => Beta >= 0.0, Global => null;
   --  χ ≈ β N (⟨m²⟩ − ⟨m⟩²).

   ---------------------------------------------------------------------------
   -- Exact small-system helpers (2×2 Boltzmann weights)
   ---------------------------------------------------------------------------

   function Exact_2x2_Partition (Cfg : Config) return Positive_Real
     with Global => null;
   --  Z = ∑_{configs} exp(−β H) over all 16 spin assignments.

   function Exact_2x2_Mean_Magnetization (Cfg : Config) return Real
     with Global => null;
   --  ⟨m⟩ = Z^{−1} ∑ m(σ) exp(−β H).

   function Exact_2x2_Mean_Abs_Magnetization (Cfg : Config) return Non_Negative
     with Global => null;

   function Exact_2x2_Mean_Energy (Cfg : Config) return Real
     with Global => null;

end Glauber_Dynamics;
