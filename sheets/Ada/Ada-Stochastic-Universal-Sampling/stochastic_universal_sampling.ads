--  Stochastic_Universal_Sampling — Ada 2023 educational package for
--  Wikipedia "Stochastic universal sampling" (Baker): fitness-
--  proportionate selection with evenly spaced pointers (low bias,
--  minimal spread). Also provides classic roulette-wheel FPS for
--  contrast. Fitness must be non-negative; costs can be shifted to
--  fitness via Shift_Costs_To_Fitness.
--  Primary source:
--  https://en.wikipedia.org/wiki/Stochastic_universal_sampling
--  Siblings: Ada-Truncation-Selection; Ada-Tournament-Selection
--  (README links; no package deps).

pragma Ada_2022;

package Stochastic_Universal_Sampling
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Non_Negative is Real range 0.0 .. Real'Last;

   --  Candidate solution carrier. Tag is an opaque identity for tests /
   --  callers (not used by the selection logic itself). Fitness must be
   --  non-negative for Select_SUS / Select_Roulette.
   type Individual is record
      Fitness : Real    := 0.0;
      Tag     : Natural := 0;
   end record;

   type Population is array (Positive range <>) of Individual;

   --  Indices into a population (within the array bounds).
   type Index_List is array (Positive range <>) of Positive;

   --  Cumulative fitness sums (same index bounds as the population).
   type Fitness_Array is array (Positive range <>) of Real;

   ---------------------------------------------------------------------------
   -- Configuration
   ---------------------------------------------------------------------------

   --  Seed : initial LCG seed (informational / for Make_Config +
   --         Seed_RNG convenience). Selection count N is passed per call.
   type Config is record
      Seed : Natural := 1;
   end record;

   function Default_Config return Config
     with Global => null;

   function Make_Config (Seed : Natural := 1) return Config
     with Global => null;

   --  True when Pop_Size ≥ 1 and Select_Count ≥ 1 (N offspring).
   function Valid_Config
     (Cfg          : Config;
      Pop_Size     : Natural;
      Select_Count : Natural) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Fitness validation / cost → fitness shift
   ---------------------------------------------------------------------------

   --  True iff every Fitness ≥ 0.
   function All_Non_Negative (Pop : Population) return Boolean
     with Global => null;

   --  Sum of Fitness over Pop. Empty → 0.
   function Total_Fitness (Pop : Population) return Real
     with Global => null;

   --  Treat Pop.Fitness as costs (lower better). Return a copy with
   --  Fitness_i = Max_Cost − Cost_i. If all costs equal, every fitness
   --  becomes 1.0 so the wheel is well-defined. Raises Invalid_Argument
   --  if Pop is empty.
   function Shift_Costs_To_Fitness (Pop : Population) return Population
     with Global => null;

   ---------------------------------------------------------------------------
   -- Cumulative wheel / pointer map (RWS helper)
   ---------------------------------------------------------------------------

   --  Cumul(I) = sum of Fitness from Pop'First through I inclusive.
   --  Raises Invalid_Argument if Pop empty, any Fitness < 0, or total = 0.
   function Cumulative_Fitness (Pop : Population) return Fitness_Array
     with Global => null;

   --  Map a pointer in [0, F] onto a population index via the cumulative
   --  wheel: smallest I with Cumul(I) ≥ Pointer (Wikipedia RWS). Pointer
   --  ≤ 0 → Pop'First; Pointer ≥ Cumul(Last) → Pop'Last.
   --  Raises Invalid_Argument if Cumul empty.
   function Map_Pointer
     (Cumul   : Fitness_Array;
      Pointer : Real) return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible draws
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   procedure Seed_RNG (State : out RNG_State; Cfg : Config)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   --  Uniform real in [Lo, Hi). Requires Lo < Hi.
   function Next_Real
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo < Hi, Global => null;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Baker SUS / classic FPS roulette
   ---------------------------------------------------------------------------

   --  Stochastic universal sampling (Baker): one Start ~ U(0, P) with
   --  P = F/N, pointers Start + i·P for i = 0 .. N−1, each mapped by
   --  RWS (Map_Pointer). Returns N population indices.
   --  Raises Invalid_Argument if Pop empty, N < 1, any Fitness < 0,
   --  or total fitness F = 0.
   function Select_SUS
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Index_List
     with Global => null;

   function Select_SUS
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Population
     with Global => null;

   --  Classic fitness-proportionate roulette: N independent draws
   --  U ~ Uniform(0, F), each mapped by RWS. Higher sampling variance
   --  than SUS; provided for contrast tests.
   --  Same Invalid_Argument conditions as Select_SUS.
   function Select_Roulette
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Index_List
     with Global => null;

   function Select_Roulette
     (Pop   : Population;
      N     : Positive;
      State : in out RNG_State) return Population
     with Global => null;

   --  Convenience: seed from Cfg then Select_SUS / Select_Roulette.
   function Select_SUS
     (Pop   : Population;
      N     : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Index_List
     with Global => null;

   function Select_Roulette
     (Pop   : Population;
      N     : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Index_List
     with Global => null;

end Stochastic_Universal_Sampling;
