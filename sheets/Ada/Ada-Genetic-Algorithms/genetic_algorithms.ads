--  Genetic_Algorithms — Ada 2023 educational package for Wikipedia
--  "Genetic algorithm": population-based evolutionary algorithm with
--  selection, crossover, and mutation on bit-string chromosomes.
--  Educational OneMax / Hamming drivers; tournament and fitness-
--  proportionate selection; one-/two-point crossover; bit-flip mutation;
--  generational replacement with optional elitism.
--  Primary source: https://en.wikipedia.org/wiki/Genetic_algorithm
--  Siblings: Ada-Memetic-Algorithm / Ada-Tournament-Selection /
--  Ada-Fitness-Proportionate-Selection / Ada-Stochastic-Universal-Sampling /
--  Ada-Truncation-Selection (README links; no package deps).

pragma Ada_2022;

package Genetic_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Bits : constant := 64;
   Max_Pop  : constant := 128;
   Max_Gens : constant := 500;

   subtype Bit_Count is Positive range 1 .. Max_Bits;
   subtype Pop_Size_T is Positive range 2 .. Max_Pop;
   subtype Tourney_K is Positive range 2 .. Max_Pop;
   subtype Elite_T is Natural range 0 .. Max_Pop;

   type Selection_Kind is (Tournament, Fitness_Proportionate);
   type Crossover_Kind is (One_Point, Two_Point);

   type Bit_String is array (Positive range <>) of Boolean;

   type Fitness_Array is array (Positive range <>) of Real;
   type Cost_Array is array (Positive range <>) of Real;
   type Index_Array is array (Positive range <>) of Positive;

   --  Pop_Size        : population size P
   --  Generations     : outer generations G (0 → init-only Result)
   --  Crossover_Rate  : probability of applying crossover (else clone A)
   --  Mutation_Rate   : per-locus Bernoulli bit-flip probability
   --  Tournament_K    : k for tournament selection
   --  Elite_Count     : top elites copied unchanged into next generation
   --  Seed            : LCG seed for reproducibility
   --  Selection       : Tournament or Fitness_Proportionate (FPS)
   --  Crossover       : One_Point or Two_Point
   type Config is record
      Pop_Size       : Pop_Size_T      := 30;
      Generations    : Natural         := 80;
      Crossover_Rate : Unit_Interval   := 0.8;
      Mutation_Rate  : Unit_Interval   := 0.02;
      Tournament_K   : Tourney_K       := 3;
      Elite_Count    : Elite_T         := 1;
      Seed           : Natural         := 1;
      Selection      : Selection_Kind  := Tournament;
      Crossover      : Crossover_Kind  := One_Point;
   end record;

   --  Packed result: best chromosome (prefix N), best fitness (max) /
   --  best cost (min), generations run (= history length), evaluations.
   type Result is record
      Best_Bits       : Bit_String (1 .. Max_Bits) := [others => False];
      N               : Bit_Count := 1;
      Best_Fitness    : Real    := 0.0;
      Best_Cost       : Real    := 0.0;
      Generations_Run : Natural := 0;
      Evaluations     : Natural := 0;
      History_Length  : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Pop_Size       : Pop_Size_T     := 30;
      Generations    : Natural        := 80;
      Crossover_Rate : Unit_Interval  := 0.8;
      Mutation_Rate  : Unit_Interval  := 0.02;
      Tournament_K   : Tourney_K      := 3;
      Elite_Count    : Elite_T        := 1;
      Seed           : Natural        := 1;
      Selection      : Selection_Kind := Tournament;
      Crossover      : Crossover_Kind := One_Point) return Config
     with Global => null;

   function Config_Is_Valid (Cfg : Config) return Boolean
     with Global => null;
   --  True iff Tournament_K ≤ Pop_Size and Elite_Count < Pop_Size
   --  (Elite_Count = Pop_Size would freeze evolution).

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible GA
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Bit-string utilities
   ---------------------------------------------------------------------------

   function Hamming_Distance (A, B : Bit_String) return Natural
     with Pre => A'Length = B'Length, Global => null;

   function Zero_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Ones_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String
     with Pre => Index in Bits'Range, Global => null;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
     with Global => null;

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String
     with Pre => Src'Length >= N, Global => null;

   function All_Ones (N : Bit_Count) return Bit_String
     with Global => null;

   function All_Zeros (N : Bit_Count) return Bit_String
     with Global => null;

   function Equal_Bits (A, B : Bit_String) return Boolean
     with Pre => A'Length = B'Length, Global => null;

   ---------------------------------------------------------------------------
   -- Fitness / cost (educational)
   ---------------------------------------------------------------------------

   function Fitness_OneMax (Bits : Bit_String) return Real
     with Global => null;
   --  Maximize: number of ones (∈ [0, n]).

   function Cost_Zero_Count (Bits : Bit_String) return Real
     with Global => null;
   --  Minimize: number of zeros ≡ n − Ones_Count.

   function Cost_Hamming (Bits, Target : Bit_String) return Real
     with Pre => Bits'Length = Target'Length, Global => null;
   --  Minimize: Hamming distance to Target.

   function Fitness_Hamming (Bits, Target : Bit_String) return Real
     with Pre => Bits'Length = Target'Length, Global => null;
   --  Maximize: n − Hamming (aligned with FPS on fitness).

   ---------------------------------------------------------------------------
   -- Selection operators (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Tournament_Select
     (State   : in out RNG_State;
      Fitness : Fitness_Array;
      K       : Tourney_K) return Positive
     with Pre => Fitness'Length >= 2
            and then Natural (K) <= Fitness'Length,
          Global => null;
   --  k-tournament (with replacement): return index of highest Fitness.

   function Tournament_Select_Min
     (State : in out RNG_State;
      Costs : Cost_Array;
      K     : Tourney_K) return Positive
     with Pre => Costs'Length >= 2
            and then Natural (K) <= Costs'Length,
          Global => null;
   --  k-tournament for minimization (lowest Cost wins).

   function Fitness_Proportionate_Select
     (State   : in out RNG_State;
      Fitness : Fitness_Array) return Positive
     with Pre => Fitness'Length >= 1, Global => null;
   --  Roulette-wheel / FPS: P(i) ∝ max(Fitness(i), 0); if total = 0,
   --  uniform over indices.

   ---------------------------------------------------------------------------
   -- Crossover / mutation operators (exposed for unit tests)
   ---------------------------------------------------------------------------

   function One_Point_Crossover
     (Parent_A, Parent_B : Bit_String;
      State              : in out RNG_State) return Bit_String
     with Pre => Parent_A'Length = Parent_B'Length
            and then Parent_A'Length >= 1
            and then Parent_A'Length <= Max_Bits,
          Global => null;
   --  Cut after random locus c ∈ {0..N}; child = A(1..c) ‖ B(c+1..N).

   function Two_Point_Crossover
     (Parent_A, Parent_B : Bit_String;
      State              : in out RNG_State) return Bit_String
     with Pre => Parent_A'Length = Parent_B'Length
            and then Parent_A'Length >= 1
            and then Parent_A'Length <= Max_Bits,
          Global => null;
   --  Two cuts Lo ≤ Hi; child takes A outside [Lo..Hi], B inside.

   function Crossover
     (Parent_A, Parent_B : Bit_String;
      Kind               : Crossover_Kind;
      Rate               : Unit_Interval;
      State              : in out RNG_State) return Bit_String
     with Pre => Parent_A'Length = Parent_B'Length
            and then Parent_A'Length >= 1
            and then Parent_A'Length <= Max_Bits,
          Global => null;
   --  With Prob Rate apply Kind crossover; else clone Parent_A.

   function Mutate_Bits
     (Bits  : Bit_String;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Bit_String
     with Pre => Bits'Length >= 1 and then Bits'Length <= Max_Bits,
          Global => null;
   --  Independent Bernoulli(Rate) flip per bit.

   ---------------------------------------------------------------------------
   -- Elitism helpers
   ---------------------------------------------------------------------------

   function Elite_Indices_Max
     (Fitness : Fitness_Array;
      Count   : Natural) return Index_Array
     with Pre => Count <= Fitness'Length, Global => null;
   --  Count indices of the highest-fitness individuals (stable ties).

   function Elite_Indices_Min
     (Costs : Cost_Array;
      Count : Natural) return Index_Array
     with Pre => Count <= Costs'Length, Global => null;
   --  Count indices of the lowest-cost individuals (stable ties).

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Maximize_OneMax
     (N : Bit_Count; Cfg : Config) return Result
     with Pre => Config_Is_Valid (Cfg), Global => null;
   --  Classic OneMax: maximize ones count. Best_Fitness → n at optimum.

   function Minimize_Hamming
     (Target : Bit_String; Cfg : Config) return Result
     with Pre => Target'Length >= 1
            and then Target'Length <= Max_Bits
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Minimize Hamming distance to Target. Best_Cost → 0 at optimum.

   function Maximize_Hamming_Fitness
     (Target : Bit_String; Cfg : Config) return Result
     with Pre => Target'Length >= 1
            and then Target'Length <= Max_Bits
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Same search as Minimize_Hamming but tracks Best_Fitness = n − d_H.

   function Minimize_Zero_Count
     (N : Bit_Count; Cfg : Config) return Result
     with Pre => Config_Is_Valid (Cfg), Global => null;
   --  Dual of OneMax: minimize zeros (same optimum: all ones).

end Genetic_Algorithms;
