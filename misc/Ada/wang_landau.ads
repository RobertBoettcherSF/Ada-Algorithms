--  Wang_Landau — Ada 2023 educational package for Wang–Landau sampling
--  (flat-histogram density-of-states estimation; Wang & Landau 2001).
--  Maintains ln g(E) and histogram H(E); proposes neighbour moves accepted
--  with min(1, exp(ln g(E) − ln g(E'))); updates ln g += ln f, H += 1;
--  when H is flat enough, ln f := ln f / 2 and resets H; stops when ln f
--  is small. Educational demos: two-level toy, binomial bit model, 1D Ising.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Wang_and_Landau_algorithm
--  Wang, F.; Landau, D. P. (2001). Phys. Rev. Lett. 86 (10): 2050–2053.
--  Siblings (Monte Carlo survey): Ada-MISER, Ada-Metropolis-Hastings,
--  Ada-Gibbs-Sampling, Ada-Hybrid-Monte-Carlo (README links).

pragma Ada_2022;

package Wang_Landau
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

   --  Cap on discrete energy bins (binomial L<=16, 1D Ising N<=8, two-level).
   Max_Bins : constant Positive := 32;
   subtype Bin_Count is Positive range 1 .. Max_Bins;
   subtype Bin_Index is Natural range 0 .. Max_Bins - 1;

   type Ln_G_Array is array (Bin_Index range <>) of Real;
   type Visit_Array is array (Bin_Index range <>) of Natural;
   type Density_Array is array (Bin_Index range <>) of Non_Negative;

   --  Flatness     : require min H >= Flatness * mean H on visited bins
   --  F_Final      : stop when modification factor f satisfies f-1 < F_Final
   --                 (equivalently ln f < ln(1+F_Final) ≈ F_Final for small f-1)
   --  Ln_F_Initial : starting ln f (classically 1 ⇒ f = e)
   --  Max_Stages   : hard cap on f-reduction stages
   --  Steps_Per_Check : Monte Carlo steps between flatness checks
   --  Min_Entries  : minimum total histogram entries before a flatness check
   --  Seed         : RNG seed (Ada.Numerics.Float_Random)
   type Config is record
      Flatness        : Unit_Fraction := 0.8;
      F_Final         : Positive_Real := 1.0E-8;
      Ln_F_Initial    : Positive_Real := 1.0;
      Max_Stages      : Positive      := 40;
      Steps_Per_Check : Positive      := 1_000;
      Min_Entries     : Positive      := 100;
      Seed            : Integer       := 42;
   end record;

   --  Discriminated result: bins 0 .. Last_Bin inclusive (N = Last_Bin+1).
   type Result (Last_Bin : Bin_Index) is record
      Ln_G        : Ln_G_Array (0 .. Last_Bin) := [others => 0.0];
      Visits      : Visit_Array (0 .. Last_Bin) := [others => 0];
      Stages      : Natural := 0;
      Total_Steps : Natural := 0;
      Converged   : Boolean := False;
      Final_Ln_F  : Real := 0.0;
   end record;

   --  Number of energy bins (= Last_Bin + 1).
   function N_Bins (R : Result) return Bin_Count
     with Inline;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-12;

   --  Normalize so sum_E g(E) = Total (default 1). Returns g from ln g,
   --  shifting by max(ln g) for numerical stability.
   function Normalize_Density
     (Ln_G  : Ln_G_Array;
      Total : Non_Negative := 1.0) return Density_Array
     with Pre => Ln_G'Length >= 1 and then Total >= 0.0;

   --  Exact binomial coefficients C(L,k) as Real, k = 0 .. L.
   function Exact_Binomial_Density (L : Positive) return Density_Array
     with Pre => L < Max_Bins;

   --  Relative L1 error between estimated and reference densities
   --  (both should share the same length and preferably the same Total).
   function Relative_L1
     (Estimate : Density_Array;
      Exact    : Density_Array) return Non_Negative
     with Pre => Estimate'Length = Exact'Length and then Estimate'Length >= 1;

   --  Optional thermodynamics: canonical mean energy at temperature T > 0
   --  using E_k = Energy_Of_Bin(k) with caller-supplied energies.
   type Energy_Array is array (Bin_Index range <>) of Real;

   function Canonical_Mean_Energy
     (Ln_G     : Ln_G_Array;
      Energies : Energy_Array;
      T        : Positive_Real) return Real
     with Pre =>
       Ln_G'Length = Energies'Length
       and then Ln_G'First = Energies'First
       and then Ln_G'Last = Energies'Last;

   ---------------------------------------------------------------------------
   -- Core algorithms / educational models
   ---------------------------------------------------------------------------

   --  Two-level toy: G0 microstates at energy 0, G1 at energy 1.
   --  Uniform proposal over G0+G1 labelled states. Exact g = (G0, G1).
   function Estimate_Two_Level
     (G0  : Positive;
      G1  : Positive;
      Cfg : Config := (others => <>)) return Result
     with Post => Estimate_Two_Level'Result.Last_Bin = 1;

   --  Binomial / bit-count model: L bits, E = Hamming weight ∈ {0..L}.
   --  Propose a random single-bit flip. Exact g(E) = C(L, E).
   function Estimate_Binomial
     (L   : Positive;
      Cfg : Config := (others => <>)) return Result
     with Pre => L < Max_Bins,
          Post => Estimate_Binomial'Result.Last_Bin = L;

   --  Tiny 1D Ising chain, N spins ±1, periodic BC, J = 1:
   --    E = −∑_{i=1}^N s_i s_{i+1}  ∈ {−N, −N+2, …, N}.
   --  Propose a random single-spin flip. N ≤ 8 for pedagogy.
   Max_Ising_N : constant Positive := 8;

   function Estimate_Ising_1D
     (N   : Positive;
      Cfg : Config := (others => <>)) return Result
     with Pre => N >= 2 and then N <= Max_Ising_N,
          Post => Estimate_Ising_1D'Result.Last_Bin = N;

   --  Aliases matching the series API naming.
   function Run_Two_Level
     (G0  : Positive;
      G1  : Positive;
      Cfg : Config := (others => <>)) return Result
     renames Estimate_Two_Level;

   function Run_Binomial
     (L   : Positive;
      Cfg : Config := (others => <>)) return Result
     renames Estimate_Binomial;

   function Run_Ising_1D
     (N   : Positive;
      Cfg : Config := (others => <>)) return Result
     renames Estimate_Ising_1D;

   --  Generic name: density of states for the binomial educational model.
   function Estimate_Density_Of_States
     (L   : Positive;
      Cfg : Config := (others => <>)) return Result
     renames Estimate_Binomial;

   --  Exact 1D Ising DOS by full enumeration (N ≤ 8): g for bins of E=−N+2k.
   function Exact_Ising_1D_Density (N : Positive) return Density_Array
     with Pre => N >= 2 and then N <= Max_Ising_N;

   --  Map Ising energy E ∈ {−N..N step 2} to bin index k = (E + N) / 2.
   function Ising_Energy_To_Bin (E : Integer; N : Positive) return Bin_Index
     with Pre => N >= 2 and then N <= Max_Ising_N;

   function Ising_Bin_To_Energy (K : Bin_Index; N : Positive) return Integer
     with Pre => N >= 2 and then N <= Max_Ising_N and then K <= N;

end Wang_Landau;
