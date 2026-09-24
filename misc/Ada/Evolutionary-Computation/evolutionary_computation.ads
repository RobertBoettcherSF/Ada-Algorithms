--  Evolutionary_Computation — Ada 2023 educational survey package for
--  Wikipedia "Evolutionary computation": population-based metaheuristics
--  inspired by biological evolution (selection, mutation, recombination).
--  Ships shared EA-loop helpers, a compact bit-string GA generation step,
--  and a (1+1)-ES step with 1/5-rule σ adaptation. Taxonomy flags GA / ES /
--  Gene_Expression / Differential_Evolution / Memetic / Genetic_Programming
--  (DE and GP may be forthcoming; full solvers are sibling repos — README
--  links only; no package deps).
--  Primary source: https://en.wikipedia.org/wiki/Evolutionary_computation
--  Educational limits: bit length ≤ 64, population ≤ 64, dim ≤ 8.

pragma Ada_2022;

package Evolutionary_Computation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Bits : constant := 64;
   Max_Pop  : constant := 64;
   Max_Dim  : constant := 8;
   Max_Gens : constant := 500;

   subtype Bit_Count is Positive range 1 .. Max_Bits;
   subtype Pop_Size_T is Positive range 2 .. Max_Pop;
   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Tourney_K is Positive range 2 .. Max_Pop;
   subtype Elite_T is Natural range 0 .. Max_Pop;

   --  Generation counter for shared EA loops (0 = init-only / not started).
   type Generation_Count is new Natural range 0 .. Max_Gens;

   type Bit_String is array (Positive range <>) of Boolean;
   type Fitness_Array is array (Positive range <>) of Real;
   type Point is array (Dim_Index range <>) of Real;

   --  Compact bit individual for the embedded GA sketch.
   type Bit_Individual is record
      Bits    : Bit_String (1 .. Max_Bits) := [others => False];
      N       : Bit_Count := 1;
      Fitness : Real := 0.0;
   end record;

   type Bit_Population is array (Positive range <>) of Bit_Individual;

   --  Continuous individual for the embedded (1+1)-ES sketch.
   type Cont_Individual is record
      X       : Point (1 .. Max_Dim) := [others => 0.0];
      Dim     : Dim_Count := 1;
      Sigma   : Positive_Real := 1.0;
      Fitness : Real := Real'Last;  -- cost; lower is better
   end record;

   type Objective_Fn is access function (X : Point) return Real;

   --  Shared GA sketch controls.
   type GA_Config is record
      Pop_Size       : Pop_Size_T    := 20;
      Generations    : Generation_Count := 40;
      Crossover_Rate : Unit_Interval := 0.8;
      Mutation_Rate  : Unit_Interval := 0.05;
      Tournament_K   : Tourney_K     := 3;
      Elite_Count    : Elite_T       := 1;
      Seed           : Natural       := 1;
   end record;

   --  Shared (1+1)-ES sketch controls.
   type ES_Config is record
      Max_Gens       : Generation_Count := 200;
      Seed           : Natural          := 1;
      Init_Sigma     : Positive_Real    := 1.0;
      Success_Window : Positive         := 10;
   end record;

   type GA_Result is record
      Best_Bits       : Bit_String (1 .. Max_Bits) := [others => False];
      N               : Bit_Count := 1;
      Best_Fitness    : Real := 0.0;
      Generations_Run : Generation_Count := 0;
      Evaluations     : Natural := 0;
   end record;

   type ES_Result is record
      Best_X      : Point (1 .. Max_Dim) := [others => 0.0];
      Dim         : Dim_Count := 1;
      Best_Cost   : Real := 0.0;
      Best_Sigma  : Real := 0.0;
      Generations : Generation_Count := 0;
      Evaluations : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Method taxonomy (Wikipedia EC family)
   -- Full GA / ES / GEP / Memetic solvers = sibling packages.
   -- Differential_Evolution / Genetic_Programming may be forthcoming.
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Genetic_Algorithm,
      Evolution_Strategy,
      Gene_Expression,
      Differential_Evolution,
      Memetic,
      Genetic_Programming);

   type Method_Info is record
      Kind               : Method_Kind;
      Implemented        : Boolean;  -- True for bit-GA / (1+1)-ES sketches
      Uses_Recombination : Boolean;
      Forthcoming        : Boolean;  -- True for DE / GP placeholders
      Population_Based   : Boolean;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_GA_Config
     (Pop_Size       : Pop_Size_T        := 20;
      Generations    : Generation_Count  := 40;
      Crossover_Rate : Unit_Interval     := 0.8;
      Mutation_Rate  : Unit_Interval     := 0.05;
      Tournament_K   : Tourney_K         := 3;
      Elite_Count    : Elite_T           := 1;
      Seed           : Natural           := 1) return GA_Config
     with Global => null;

   function Default_ES_Config
     (Max_Gens       : Generation_Count := 200;
      Seed           : Natural          := 1;
      Init_Sigma     : Positive_Real    := 1.0;
      Success_Window : Positive         := 10) return ES_Config
     with Global => null;

   function GA_Config_Is_Valid (Cfg : GA_Config) return Boolean
     with Global => null;
   --  True iff Tournament_K ≤ Pop_Size and Elite_Count < Pop_Size.

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) + Box–Muller normal
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

   function Sample_Normal (State : in out RNG_State) return Real
     with Global => null;
   --  Standard normal N(0,1) via Marsaglia polar form.

   ---------------------------------------------------------------------------
   -- Bit-string utilities
   ---------------------------------------------------------------------------

   function Ones_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Hamming_Distance (A, B : Bit_String) return Natural
     with Pre => A'Length = B'Length, Global => null;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
     with Global => null;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String
     with Pre => Index in Bits'Range, Global => null;

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String
     with Pre => Src'Length >= N, Global => null;

   function All_Ones (N : Bit_Count) return Bit_String
     with Global => null;

   function All_Zeros (N : Bit_Count) return Bit_String
     with Global => null;

   ---------------------------------------------------------------------------
   -- Shared EA-loop helpers (population init / elitism / generation)
   ---------------------------------------------------------------------------

   procedure Init_Bit_Population
     (Pop   : in out Bit_Population;
      N     : Bit_Count;
      State : in out RNG_State)
     with Pre => Pop'Length >= 2 and then Pop'Length <= Max_Pop,
          Global => null;
   --  Fill Pop with random bit-strings of length N; Fitness ← Ones_Count.

   function Mean_Fitness (Fit : Fitness_Array) return Real
     with Pre => Fit'Length >= 1, Global => null;

   function Best_Index_Max (Fit : Fitness_Array) return Positive
     with Pre => Fit'Length >= 1, Global => null;
   --  Argmax of Fit (first on ties).

   function Best_Index_Min (Fit : Fitness_Array) return Positive
     with Pre => Fit'Length >= 1, Global => null;
   --  Argmin of Fit (first on ties).

   function Elitist_Merge_Max
     (Parents, Offspring : Fitness_Array;
      Elite              : Natural) return Fitness_Array
     with Pre => Parents'Length = Offspring'Length
            and then Parents'Length >= 1
            and then Parents'Length <= Max_Pop
            and then Elite <= Parents'Length,
          Global => null;
   --  Keep the Elite best parent fitnesses and fill the rest from
   --  offspring (maximise). Result length = Parents'Length.

   function Advance_Generation
     (G : Generation_Count; Steps : Natural := 1) return Generation_Count
     with Global => null;
   --  Saturating add: min(G + Steps, Max_Gens).

   function Generation_Budget_Exhausted
     (G : Generation_Count; Budget : Generation_Count) return Boolean
     with Global => null;
   --  True iff G ≥ Budget.

   ---------------------------------------------------------------------------
   -- Selection pressure / diversity notes
   ---------------------------------------------------------------------------

   function Selection_Pressure_Ratio (Fit : Fitness_Array) return Non_Negative
     with Pre => Fit'Length >= 1, Global => null;
   --  max(Fit) / mean(Fit) when mean > 0 (maximise); else 0.
   --  Higher ratio ≈ stronger selection pressure toward the elite.

   function Mean_Pairwise_Hamming
     (Pop : Bit_Population; N : Bit_Count) return Non_Negative
     with Pre => Pop'Length >= 2
            and then Pop'Length <= Max_Pop,
          Global => null;
   --  Average Hamming distance over unordered pairs (diversity proxy).
   --  Uses each individual's Bits (1 .. N).

   function Normalised_Diversity
     (Pop : Bit_Population; N : Bit_Count) return Unit_Interval
     with Pre => Pop'Length >= 2
            and then Pop'Length <= Max_Pop,
          Global => null;
   --  Mean pairwise Hamming / N ∈ [0, 1].

   ---------------------------------------------------------------------------
   -- Tiny embedded bit-GA step (not a full Genetic_Algorithms package)
   ---------------------------------------------------------------------------

   function Bit_Flip_Mutate
     (Bits  : Bit_String;
      Rate  : Unit_Interval;
      State : in out RNG_State) return Bit_String
     with Global => null;
   --  Independent Bernoulli flip per locus with probability Rate.

   procedure One_Point_Crossover
     (A, B     : Bit_String;
      Child_A  : out Bit_String;
      Child_B  : out Bit_String;
      State    : in out RNG_State)
     with Pre => A'Length = B'Length
            and then A'Length >= 1
            and then Child_A'Length = A'Length
            and then Child_B'Length = A'Length,
          Global => null;

   function Tournament_Select
     (Fit   : Fitness_Array;
      K     : Tourney_K;
      State : in out RNG_State) return Positive
     with Pre => Fit'Length >= 2
            and then Natural (K) <= Fit'Length,
          Global => null;
   --  Maximise: return index of best among K uniform draws (with replacement).

   procedure Step_Bit_GA
     (Pop   : in out Bit_Population;
      Cfg   : GA_Config;
      State : in out RNG_State;
      Evals : in out Natural)
     with Pre => Pop'Length = Natural (Cfg.Pop_Size)
            and then GA_Config_Is_Valid (Cfg),
          Global => null;
   --  One generational step: tournament → crossover → mutate → elitist
   --  replacement; Fitness = Ones_Count (OneMax maximise).

   function Maximize_OneMax
     (N   : Bit_Count;
      Cfg : GA_Config) return GA_Result
     with Pre => GA_Config_Is_Valid (Cfg), Global => null;
   --  Tiny OneMax driver using Step_Bit_GA for Cfg.Generations.

   ---------------------------------------------------------------------------
   -- Tiny embedded (1+1)-ES step (not a full Evolution_Strategy package)
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Mutate_Gaussian
     (Parent : Cont_Individual;
      State  : in out RNG_State) return Cont_Individual
     with Pre => Parent.Dim >= 1, Global => null;
   --  x' = x + σ N(0, I); σ unchanged.

   procedure Step_One_Plus_One_ES
     (Parent         : in out Cont_Individual;
      Objective      : Objective_Fn;
      State          : in out RNG_State;
      Successes      : in out Natural;
      Trials         : in out Natural;
      Success_Window : Positive;
      Evaluations    : in out Natural)
     with Pre => Parent.Dim >= 1 and then Objective /= null, Global => null;
   --  One (1+1) trial; every Success_Window trials adapt σ by 1/5 rule
   --  (σ ← σ·c if success rate > 1/5, σ ← σ/c if < 1/5; c = 0.817).

   function Minimize_Sphere_One_Plus_One
     (Dim : Dim_Count;
      Cfg : ES_Config) return ES_Result
     with Global => null;
   --  Tiny Sphere driver via repeated Step_One_Plus_One_ES.

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Uses_Recombination (Kind : Method_Kind) return Boolean
     with Global => null;

   function Method_Implemented (Kind : Method_Kind) return Boolean
     with Global => null;

   function Method_Forthcoming (Kind : Method_Kind) return Boolean
     with Global => null;

   function Method_Count return Positive
     with Global => null;

end Evolutionary_Computation;
