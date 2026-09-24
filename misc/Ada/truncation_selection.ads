--  Truncation_Selection — Ada 2023 educational package for Wikipedia
--  "Truncation selection": rank a population by fitness, keep the top
--  fraction T (or top K) as a breeding pool, then sample parents
--  uniformly with replacement from that truncated pool.
--  Used in Muhlenbein's breeder genetic algorithm and in animal/plant
--  breeding. Supports Maximize (higher fitness better) and Minimize
--  (lower cost better) senses.
--  Primary source:
--  https://en.wikipedia.org/wiki/Truncation_selection
--  Siblings: Ada-Memetic-Algorithm; Tournament selection / Stochastic
--  universal sampling forthcoming (README links; no package deps).

pragma Ada_2022;

package Truncation_Selection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Non_Negative is Real range 0.0 .. Real'Last;

   --  Fitness comparison direction.
   --  Maximize: higher Fitness is better (typical GA fitness).
   --  Minimize: lower Fitness is better (cost / objective value).
   type Fitness_Sense is (Maximize, Minimize);

   --  Candidate solution carrier. Tag is an opaque identity for tests /
   --  callers (not used by the selection logic itself).
   type Individual is record
      Fitness : Real    := 0.0;
      Tag     : Natural := 0;
   end record;

   type Population is array (Positive range <>) of Individual;

   --  Indices into a population / pool (1-based within the array bounds).
   type Index_List is array (Positive range <>) of Positive;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  True iff T is in (0, 1] (open at 0, closed at 1).
   function Valid_T (T : Real) return Boolean
     with Global => null;

   --  True iff A is strictly better than B under Sense.
   function Better
     (A, B : Real; Sense : Fitness_Sense) return Boolean
     with Global => null;

   --  True iff A is better than or equal to B under Sense.
   function Better_Or_Equal
     (A, B : Real; Sense : Fitness_Sense) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Truncation size
   ---------------------------------------------------------------------------

   --  Breeding-pool size K = ceil(T * N), clamped to [1, N].
   --  Raises Invalid_Argument if N = 0 or T not in (0, 1].
   function Truncation_Count (N : Natural; T : Real) return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Ranking
   ---------------------------------------------------------------------------

   --  In-place stable insertion sort: best individual first (index'First).
   --  Raises Invalid_Argument if Pop'Length = 0.
   procedure Sort_By_Fitness
     (Pop : in out Population; Sense : Fitness_Sense)
     with Global => null;

   --  Return a sorted copy (best first). Empty → Invalid_Argument.
   function Sort_By_Fitness
     (Pop : Population; Sense : Fitness_Sense) return Population
     with Global => null;

   ---------------------------------------------------------------------------
   -- Breeding pool (truncation)
   ---------------------------------------------------------------------------

   --  Rank Pop, then keep the top Truncation_Count(N, T) individuals.
   --  Raises Invalid_Argument if Pop empty or T not in (0, 1].
   function Select_Pool
     (Pop   : Population;
      T     : Real;
      Sense : Fitness_Sense) return Population
     with Global => null;

   --  Rank Pop, then keep the top K individuals (K clamped to N).
   --  Raises Invalid_Argument if Pop empty.
   function Select_Pool
     (Pop   : Population;
      K     : Positive;
      Sense : Fitness_Sense) return Population
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible parent sampling
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   --  Uniform integer in Lo .. Hi inclusive.
   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Parent sampling (uniform with replacement from pool)
   ---------------------------------------------------------------------------

   --  One parent index in Pool'Range, uniform with replacement.
   --  Raises Invalid_Argument if Pool empty.
   function Select_Parent_Index
     (Pool  : Population;
      State : in out RNG_State) return Positive
     with Global => null;

   --  Count parent indices sampled uniformly with replacement from Pool.
   --  Raises Invalid_Argument if Pool empty.
   function Select_Parents
     (Pool  : Population;
      Count : Positive;
      State : in out RNG_State) return Index_List
     with Global => null;

   --  Same sampling, returning the Individual records (with replacement).
   function Select_Parents
     (Pool  : Population;
      Count : Positive;
      State : in out RNG_State) return Population
     with Global => null;

end Truncation_Selection;
