--  Bees_Algorithm — Ada 2023 educational package for Wikipedia
--  "Bees algorithm" (Pham, Ghanbarzadeh et al., 2005): population-based
--  metaheuristic mimicking honey-bee foraging. Scout bees sample the
--  search box; the m best sites recruit foragers for neighbourhood
--  search (e elite sites get nep foragers, the other m−e get nsp);
--  remaining scouts explore globally at random. No gradients required.
--  Primary source:
--  https://en.wikipedia.org/wiki/Bees_algorithm
--  Siblings: Ada-Particle-Swarm / Ada-Harmony-Search /
--  Ada-Simulated-Annealing (README links).

pragma Ada_2022;

package Bees_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim     : constant := 8;
   Max_Colony  : constant := 80;
   Max_Foragers : constant := 40;

   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Scout_Count is Positive range 1 .. Max_Colony;
   subtype Site_Count is Positive range 1 .. Max_Colony;
   subtype Forager_Count is Positive range 1 .. Max_Foragers;

   type Point is array (Dim_Index range <>) of Real;

   type Bound is record
      Lo : Real := -1.0;
      Hi : Real := 1.0;
   end record;

   type Bounds is array (Dim_Index range <>) of Bound;

   --  N               : scout bees (colony size)
   --  M               : number of best sites selected for neighbourhood search
   --  E               : number of elite sites among the M best (E ≤ M ≤ N)
   --  Nep             : foragers recruited to each elite site
   --  Nsp             : foragers recruited to each remaining best site
   --  Ngh             : neighbourhood radius (absolute, per coordinate)
   --  Max_Iterations  : outer iteration budget (0 → init-only Result)
   --  Seed            : LCG seed for reproducibility
   type Config is record
      N              : Scout_Count   := 20;
      M              : Site_Count    := 5;
      E              : Site_Count    := 2;
      Nep            : Forager_Count := 10;
      Nsp            : Forager_Count := 5;
      Ngh            : Non_Negative  := 0.5;
      Max_Iterations : Natural       := 500;
      Seed           : Natural       := 1;
   end record;

   type Result is record
      Best_Cost  : Real      := 0.0;
      Best_X     : Point (1 .. Max_Dim) := [others => 0.0];
      Dim        : Dim_Count := 1;
      Iterations : Natural   := 0;
      Scouts_Used : Natural  := 0;
   end record;

   type Objective_Fn is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Bee / colony state
   ---------------------------------------------------------------------------

   type Bee is record
      X    : Point (1 .. Max_Dim) := [others => 0.0];
      Cost : Real                 := Real'Last;
      Dim  : Dim_Count            := 1;
   end record;

   type Bee_Array is array (Positive range <>) of Bee;

   type Colony (Capacity : Positive) is record
      Bees : Bee_Array (1 .. Capacity) := [others => <>];
      Size : Natural   := 0;
      Dim  : Dim_Count := 1;
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
     (N              : Scout_Count   := 20;
      M              : Site_Count    := 5;
      E              : Site_Count    := 2;
      Nep            : Forager_Count := 10;
      Nsp            : Forager_Count := 5;
      Ngh            : Non_Negative  := 0.5;
      Max_Iterations : Natural       := 500;
      Seed           : Natural       := 1) return Config
     with Global => null;

   function Config_Is_Valid (Cfg : Config) return Boolean
     with Global => null;
   --  True iff 1 ≤ E ≤ M ≤ N (and all fields in their subtypes).

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible BA
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
   -- Colony core: Init / Rank / Patch_Search / Step
   ---------------------------------------------------------------------------

   procedure Init_Colony
     (C         : in out Colony;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then C.Capacity >= 1,
          Global => null;
   --  Fill Capacity scout bees: x ~ U(box), evaluate costs.
   --  Sets C.Size and C.Dim.

   procedure Rank_Colony (C : in out Colony)
     with Pre => C.Size >= 1, Global => null;
   --  Ascending sort by Cost (ties keep relative order via stable-ish
   --  insertion: first among equals stays first). Index 1 = best.

   function Patch_Search
     (Center    : Bee;
      Ngh       : Non_Negative;
      N_Foragers : Forager_Count;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State) return Bee
     with Pre => Center.Dim >= 1
            and then Natural (Center.Dim) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Neighbourhood search: sample N_Foragers points uniformly in the
   --  box [center_d − Ngh, center_d + Ngh] ∩ [Lo_d, Hi_d]; return the
   --  best among those foragers and the center (minimization).

   procedure Step
     (C         : in out Colony;
      B         : Bounds;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => C.Size >= 1
            and then B'Length = Natural (C.Dim)
            and then B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then Config_Is_Valid (Cfg)
            and then Natural (Cfg.N) = C.Size,
          Global => null;
   --  One Pham educational iteration:
   --  rank; patch-search elite (Nep) and other best (Nsp); replace site
   --  if a forager improves; re-sample remaining (N−M) scouts globally.

   function Best_Index (C : Colony) return Positive
     with Pre => C.Size >= 1, Global => null;
   --  Index of bee with lowest Cost (ties: first).

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize_Box
     (Objective : Objective_Fn;
      B         : Bounds;
      Cfg       : Config) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Continuous bees algorithm on box [Lo,Hi]^n (n ≤ Max_Dim).
   --  Returns best after Max_Iterations Steps (plus initial evaluation).

end Bees_Algorithm;
