--  Demon_Method — Ada 2023 educational package for Wikipedia
--  "Demon algorithm" (Creutz, 1983): microcanonical Monte Carlo for the
--  2-D Ising model. An auxiliary non-negative "demon" energy exchanges
--  energy with the lattice so that E_system + E_demon is conserved.
--  Primary source: https://en.wikipedia.org/wiki/Demon_algorithm
--  Sibling (canonical / heat-bath): Ada-Glauber-Dynamics (link in README).

pragma Ada_2022;

package Demon_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

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
   --  No inverse temperature: the demon sets the microcanonical energy.
   type Config is record
      J : Real := 1.0;
      H : Real := 0.0;
   end record;

   --  Creutz demon: E_d ≥ 0, exchanges energy with the system.
   type Demon_State is record
      Energy : Non_Negative := 0.0;
   end record;

   type Sweep_Order is (Random_Sites, Sequential);

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

   function Bond_Count (Lat : Lattice) return Positive
     with Global => null;
   --  2 L² nearest-neighbor bonds on the torus.

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
   -- Demon accept / reject and updates
   ---------------------------------------------------------------------------

   function Would_Accept
     (Demon_E : Non_Negative; Delta_E : Real) return Boolean
     with Global => null;
   --  True iff the Creutz rule accepts ΔE given current demon energy.
   --  ΔE ≤ 0 always; ΔE > 0 only if Demon_E ≥ ΔE.

   function New_Demon_Energy
     (Demon_E : Non_Negative; Delta_E : Real) return Non_Negative
     with Pre => Would_Accept (Demon_E, Delta_E), Global => null;
   --  Demon_E − ΔE after an accepted move (always ≥ 0).

   procedure Demon_Update_Site
     (Lat      : in out Lattice;
      X, Y     : Coord;
      Cfg      : Config;
      Dem      : in out Demon_State;
      Accepted : out Boolean)
     with Pre => X <= Lat.L and then Y <= Lat.L, Global => null;
   --  Propose flip at (X,Y); apply Creutz accept/reject; update demon.

   procedure Demon_Sweep
     (Lat   : in out Lattice;
      Cfg   : Config;
      Dem   : in out Demon_State;
      State : in out RNG_State;
      Order : Sweep_Order := Random_Sites)
     with Global => null;
   --  One sweep = L² attempted site updates.

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

   function Total_Energy
     (Lat : Lattice; Cfg : Config; Dem : Demon_State) return Real
     with Global => null;
   --  E_system + E_demon (conserved by accepted/rejected moves).

   function Temperature_From_Mean_Demon
     (Mean_Demon_Energy : Non_Negative) return Non_Negative
     with Global => null;
   --  Continuous classical estimator: ⟨E_d⟩ = kT with k = 1 ⇒ T = ⟨E_d⟩.
   --  For discrete Ising demons this is only a rough thermometer; see README.

   function Ising_Demon_Temperature_Estimator
     (Mean_Demon_Energy : Non_Negative; Quantum : Positive_Real := 4.0)
     return Non_Negative
     with Global => null;
   --  Discrete Creutz estimator for energy quanta of size Quantum (ε):
   --  ⟨E_d⟩ = ε / (e^{ε/T} − 1)  ⇒  T = ε / ln(1 + ε/⟨E_d⟩)
   --  when Mean_Demon_Energy > 0; returns 0 when Mean = 0.

end Demon_Method;
