--  Harmony_Search — Ada 2023 educational package for Wikipedia
--  "Harmony search" (Geem, Kim & Loganathan, 2001): metaheuristic inspired
--  by jazz improvisation. Maintain a harmony memory (HM) of HMS candidate
--  vectors; improvise a new harmony via memory considering (HMCR) and
--  pitch adjusting (PAR / BW); replace the worst member if the candidate
--  is better (minimization). Primary source:
--  https://en.wikipedia.org/wiki/Harmony_search
--  (page may redirect to the metaphor-based metaheuristics list).
--  Siblings: Ada-Simulated-Annealing / Ada-Tabu-Search / Ada-Random-Search.

pragma Ada_2022;

package Harmony_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim : constant := 8;
   Max_HMS : constant := 50;
   Max_Bits : constant := 32;

   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype HMS_Count is Positive range 1 .. Max_HMS;
   subtype Bit_Count is Positive range 1 .. Max_Bits;

   type Point is array (Dim_Index range <>) of Real;

   type Bound is record
      Lo : Real := -1.0;
      Hi : Real := 1.0;
   end record;

   type Bounds is array (Dim_Index range <>) of Bound;

   --  HMS                  : harmony memory size
   --  HMCR                 : harmony memory considering rate in [0,1]
   --  PAR                  : pitch adjusting rate in [0,1]
   --  BW                   : continuous pitch bandwidth (≥ 0)
   --  Max_Improvisations   : improvisation budget (0 → init-only Result)
   --  Seed                 : LCG seed for reproducibility
   type Config is record
      HMS                : HMS_Count     := 10;
      HMCR               : Unit_Interval := 0.90;
      PAR                : Unit_Interval := 0.30;
      BW                 : Non_Negative  := 0.20;
      Max_Improvisations : Natural       := 1_000;
      Seed               : Natural       := 1;
   end record;

   type Result is record
      Best_Cost      : Real      := 0.0;
      Best_X         : Point (1 .. Max_Dim) := [others => 0.0];
      Dim            : Dim_Count := 1;
      Improvisations : Natural   := 0;
      HMS_Used       : Natural   := 0;
   end record;

   type Bit_String is array (Positive range <>) of Boolean;

   type Bit_Result is record
      Best_Bits      : Bit_String (1 .. Max_Bits) := [others => False];
      N              : Bit_Count := 1;
      Best_Cost      : Real      := 0.0;
      Improvisations : Natural   := 0;
      HMS_Used       : Natural   := 0;
   end record;

   type Objective_Fn is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Continuous harmony memory
   ---------------------------------------------------------------------------

   type Harmony is record
      X    : Point (1 .. Max_Dim) := [others => 0.0];
      Cost : Real                 := Real'Last;
      Dim  : Dim_Count            := 1;
   end record;

   type Harmony_Array is array (Positive range <>) of Harmony;

   type Harmony_Memory (Capacity : Positive) is record
      Members : Harmony_Array (1 .. Capacity) := [others => <>];
      Size    : Natural   := 0;
      Dim     : Dim_Count := 1;
   end record;

   ---------------------------------------------------------------------------
   -- Discrete (bit-string) harmony memory
   ---------------------------------------------------------------------------

   type Bit_Harmony is record
      Bits : Bit_String (1 .. Max_Bits) := [others => False];
      Cost : Real                       := Real'Last;
      N    : Bit_Count                  := 1;
   end record;

   type Bit_Harmony_Array is array (Positive range <>) of Bit_Harmony;

   type Bit_Harmony_Memory (Capacity : Positive) is record
      Members : Bit_Harmony_Array (1 .. Capacity) := [others => <>];
      Size    : Natural   := 0;
      N       : Bit_Count := 1;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Global => null;

   function Default_Config
     (HMS                : HMS_Count     := 10;
      HMCR               : Unit_Interval := 0.90;
      PAR                : Unit_Interval := 0.30;
      BW                 : Non_Negative  := 0.20;
      Max_Improvisations : Natural       := 1_000;
      Seed               : Natural       := 1) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible improvisation
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;
   --  Uniform on [Lo, Hi].

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;
   --  Uniform integer in [Lo, Hi].

   ---------------------------------------------------------------------------
   -- Built-in continuous objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y) = (1−x)² + 100(y−x²)²; min 0 at (1,1).
   --  Uses first two coordinates (requires Dim ≥ 2).

   function Shifted_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   ---------------------------------------------------------------------------
   -- Bit helpers / OneMax cost (minimize zeros)
   ---------------------------------------------------------------------------

   function Zero_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Ones_Count (Bits : Bit_String) return Natural
     with Global => null;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String
     with Pre => Index in Bits'Range, Global => null;

   ---------------------------------------------------------------------------
   -- HM core: Init_HM / Improvise / Update_HM
   ---------------------------------------------------------------------------

   procedure Init_HM
     (HM        : in out Harmony_Memory;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then HM.Capacity >= 1,
          Global => null;
   --  Fill HM with Capacity random points in box B; evaluate costs.
   --  Sets HM.Size = Capacity and HM.Dim = B'Length.

   function Improvise
     (HM    : Harmony_Memory;
      B     : Bounds;
      Cfg   : Config;
      State : in out RNG_State) return Harmony
     with Pre => HM.Size >= 1
            and then B'Length = Natural (HM.Dim)
            and then B'Length >= 1
            and then B'Length <= Max_Dim,
          Global => null;
   --  Classic continuous improvisation (Geem et al.):
   --  for each dim, with prob HMCR take from a random HM member
   --  (then with prob PAR pitch-adjust ± U·BW, clamped); else random in bounds.
   --  Cost is left as Real'Last (caller evaluates).

   procedure Update_HM
     (HM        : in out Harmony_Memory;
      Candidate : Harmony)
     with Pre => HM.Size >= 1
            and then Candidate.Dim = HM.Dim,
          Global => null;
   --  Replace worst member if Candidate.Cost is strictly better (minimize).

   function Worst_Index (HM : Harmony_Memory) return Positive
     with Pre => HM.Size >= 1, Global => null;

   function Best_Index (HM : Harmony_Memory) return Positive
     with Pre => HM.Size >= 1, Global => null;

   procedure Init_Bit_HM
     (HM    : in out Bit_Harmony_Memory;
      N     : Bit_Count;
      State : in out RNG_State)
     with Pre => HM.Capacity >= 1, Global => null;
   --  Random bit strings; cost = Zero_Count (OneMax minimization).

   function Improvise_Bits
     (HM    : Bit_Harmony_Memory;
      Cfg   : Config;
      State : in out RNG_State) return Bit_Harmony
     with Pre => HM.Size >= 1, Global => null;
   --  Discrete improvisation: HMCR picks a bit from random HM member;
   --  PAR flips that bit (discrete neighbor); else random bit.

   procedure Update_Bit_HM
     (HM        : in out Bit_Harmony_Memory;
      Candidate : Bit_Harmony)
     with Pre => HM.Size >= 1
            and then Candidate.N = HM.N,
          Global => null;

   function Worst_Bit_Index (HM : Bit_Harmony_Memory) return Positive
     with Pre => HM.Size >= 1, Global => null;

   function Best_Bit_Index (HM : Bit_Harmony_Memory) return Positive
     with Pre => HM.Size >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize_Box
     (Objective : Objective_Fn;
      B         : Bounds;
      Cfg       : Config) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Continuous HS on box [Lo,Hi]^n (n ≤ Max_Dim). Returns best harmony
   --  after Max_Improvisations updates (plus initial HM evaluation).

   function Minimize_OneMax
     (N   : Bit_Count;
      Cfg : Config) return Bit_Result
     with Global => null;
   --  Discrete HS on bit strings of length N; cost = number of False bits.

end Harmony_Search;
