--  Particle_Swarm — Ada 2023 educational package for Wikipedia
--  "Particle swarm optimization" (PSO; Kennedy & Eberhart, 1995):
--  population-based metaheuristic. A swarm of particles moves in the
--  search box with velocity updates driven by inertia, personal best,
--  and global best. No gradients required.
--  Primary source:
--  https://en.wikipedia.org/wiki/Particle_swarm_optimization
--  Siblings: Ada-Harmony-Search / Ada-Simulated-Annealing /
--  Ada-Random-Search (README links).

pragma Ada_2022;

package Particle_Swarm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim   : constant := 8;
   Max_Swarm : constant := 80;

   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Swarm_Count is Positive range 1 .. Max_Swarm;

   type Point is array (Dim_Index range <>) of Real;

   type Bound is record
      Lo : Real := -1.0;
      Hi : Real := 1.0;
   end record;

   type Bounds is array (Dim_Index range <>) of Bound;

   --  Swarm_Size     : number of particles S
   --  Max_Iterations : outer iteration budget (0 → init-only Result)
   --  Inertia        : inertia weight w (ω)
   --  C1             : cognitive coefficient φ_p (pull toward personal best)
   --  C2             : social coefficient φ_g (pull toward global best)
   --  Seed           : LCG seed for reproducibility
   type Config is record
      Swarm_Size     : Swarm_Count  := 20;
      Max_Iterations : Natural      := 500;
      Inertia        : Non_Negative := 0.729;
      C1             : Non_Negative := 1.49445;
      C2             : Non_Negative := 1.49445;
      Seed           : Natural      := 1;
   end record;

   type Result is record
      Best_Cost  : Real      := 0.0;
      Best_X     : Point (1 .. Max_Dim) := [others => 0.0];
      Dim        : Dim_Count := 1;
      Iterations : Natural   := 0;
      Swarm_Used : Natural   := 0;
   end record;

   type Objective_Fn is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Particle / swarm state
   ---------------------------------------------------------------------------

   type Particle is record
      X      : Point (1 .. Max_Dim) := [others => 0.0];
      V      : Point (1 .. Max_Dim) := [others => 0.0];
      P      : Point (1 .. Max_Dim) := [others => 0.0];
      P_Cost : Real                 := Real'Last;
      Dim    : Dim_Count            := 1;
   end record;

   type Particle_Array is array (Positive range <>) of Particle;

   type Swarm (Capacity : Positive) is record
      Particles : Particle_Array (1 .. Capacity) := [others => <>];
      Size      : Natural   := 0;
      Dim       : Dim_Count := 1;
      G         : Point (1 .. Max_Dim) := [others => 0.0];
      G_Cost    : Real := Real'Last;
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
     (Swarm_Size     : Swarm_Count  := 20;
      Max_Iterations : Natural      := 500;
      Inertia        : Non_Negative := 0.729;
      C1             : Non_Negative := 1.49445;
      C2             : Non_Negative := 1.49445;
      Seed           : Natural      := 1) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible PSO
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
   -- Swarm core: Init_Swarm / Step
   ---------------------------------------------------------------------------

   procedure Init_Swarm
     (S         : in out Swarm;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then S.Capacity >= 1,
          Global => null;
   --  Fill Capacity particles: x ~ U(box), p ← x, v ~ U(−span, span),
   --  evaluate costs, set global best g. Sets S.Size and S.Dim.

   procedure Step
     (S         : in out Swarm;
      B         : Bounds;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => S.Size >= 1
            and then B'Length = Natural (S.Dim)
            and then B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  One Kennedy–Eberhart iteration over all particles:
   --  v ← w v + c1 r1 (p−x) + c2 r2 (g−x); x ← x+v; clamp to box;
   --  update personal / global bests.

   function Best_Particle_Index (S : Swarm) return Positive
     with Pre => S.Size >= 1, Global => null;
   --  Index of particle with lowest personal-best cost (ties: first).

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
   --  Continuous PSO on box [Lo,Hi]^n (n ≤ Max_Dim). Returns global best
   --  after Max_Iterations Steps (plus initial swarm evaluation).

end Particle_Swarm;
