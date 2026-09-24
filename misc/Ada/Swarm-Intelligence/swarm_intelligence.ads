--  Swarm_Intelligence — Ada 2023 educational survey package for Wikipedia
--  "Swarm intelligence": collective behaviour of decentralised,
--  self-organised agents (boids / metaheuristics). Includes a compact
--  Reynolds-style flocking sketch (separation / alignment / cohesion),
--  a PSO-lite one-step velocity helper, and an ACO-style pheromone
--  evaporation helper. Taxonomy flags Particle_Swarm / Ant_Colony /
--  Bees / Harmony_Search / Flocking_Boids (full solvers are sibling
--  repos — README links only; no package deps).
--  Primary source: https://en.wikipedia.org/wiki/Swarm_intelligence
--  Educational limits: flock size ≤ 32, 2D agents only.

pragma Ada_2022;

package Swarm_Intelligence
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Boids : constant := 32;
   subtype Boid_Count is Positive range 1 .. Max_Boids;
   subtype Boid_Index is Positive range 1 .. Max_Boids;

   --  2D continuous agent state (Reynolds boids).
   type Vec2 is record
      X : Real := 0.0;
      Y : Real := 0.0;
   end record;

   type Boid is record
      Pos : Vec2 := (0.0, 0.0);
      Vel : Vec2 := (0.0, 0.0);
   end record;

   type Flock is array (Boid_Index range <>) of Boid;

   --  Flocking controls (weights + perception / speed caps).
   --  Separation_W / Alignment_W / Cohesion_W : Reynolds rule gains
   --  Perception   : neighbourhood radius
   --  Max_Speed    : speed clamp after integration
   --  Max_Force    : per-steering force clamp
   --  Dt           : integration step
   type Config is record
      Separation_W : Non_Negative  := 1.5;
      Alignment_W  : Non_Negative  := 1.0;
      Cohesion_W   : Non_Negative  := 1.0;
      Perception   : Positive_Real := 5.0;
      Max_Speed    : Positive_Real := 2.0;
      Max_Force    : Positive_Real := 0.1;
      Dt           : Positive_Real := 1.0;
   end record;

   Default_Config : constant Config := (others => <>);

   type Result is record
      Mean_Speed   : Non_Negative := 0.0;
      Mean_Spacing : Non_Negative := 0.0;
      Steps        : Natural      := 0;
      Size         : Natural      := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Method taxonomy (Wikipedia SI models / metaheuristics)
   -- Full PSO / ACO / Bees / Harmony solvers = sibling packages.
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Particle_Swarm,
      Ant_Colony,
      Bees,
      Harmony_Search,
      Flocking_Boids);

   type Method_Info is record
      Kind              : Method_Kind;
      Implemented       : Boolean;  -- True only for flocking sketch here
      Stochastic        : Boolean;
      Continuous_Agents : Boolean;  -- continuous space vs discrete/combinatorial
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vec2; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Make_Config
     (Separation_W : Non_Negative  := 1.5;
      Alignment_W  : Non_Negative  := 1.0;
      Cohesion_W   : Non_Negative  := 1.0;
      Perception   : Positive_Real := 5.0;
      Max_Speed    : Positive_Real := 2.0;
      Max_Force    : Positive_Real := 0.1;
      Dt           : Positive_Real := 1.0) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- 2D vector helpers
   ---------------------------------------------------------------------------

   function Zero_Vec return Vec2
     with Global => null;

   function Add (A, B : Vec2) return Vec2
     with Global => null;

   function Sub (A, B : Vec2) return Vec2
     with Global => null;

   function Scale (C : Real; V : Vec2) return Vec2
     with Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   function Norm2 (V : Vec2) return Non_Negative
     with Global => null;

   function Distance (A, B : Vec2) return Non_Negative
     with Global => null;

   function Normalize (V : Vec2) return Vec2
     with Global => null;
   --  Unit vector; Zero_Vec if ‖V‖ ≈ 0.

   function Limit (V : Vec2; Max_Mag : Non_Negative) return Vec2
     with Global => null;
   --  Clamp magnitude to Max_Mag (identity if Max_Mag = 0 or ‖V‖ ≤ Max_Mag).

   ---------------------------------------------------------------------------
   -- PSO-lite: one-step velocity update (not a full PSO package)
   --   v ← ω v + c1 r1 (p − x) + c2 r2 (g − x)
   ---------------------------------------------------------------------------

   function PSO_Velocity_Step
     (V, X, P, G : Vec2;
      Omega, C1, C2, R1, R2 : Real) return Vec2
     with Pre => R1 >= 0.0 and then R1 <= 1.0
            and then R2 >= 0.0 and then R2 <= 1.0,
          Global => null;

   function PSO_Position_Step (X, V : Vec2) return Vec2
     with Global => null;
   --  x ← x + v

   ---------------------------------------------------------------------------
   -- ACO spirit: pheromone evaporation τ ← (1 − ρ) τ
   ---------------------------------------------------------------------------

   function Evaporate_Pheromone
     (Tau : Non_Negative; Rho : Unit_Interval) return Non_Negative
     with Global => null;

   function Deposit_Pheromone
     (Tau : Non_Negative; Amount : Non_Negative) return Non_Negative
     with Global => null;
   --  τ ← τ + Amount (Δτ) (non-negative clamp).

   ---------------------------------------------------------------------------
   -- Reynolds boids steering (per-agent, neighbourhood within Perception)
   ---------------------------------------------------------------------------

   function Separation
     (Self : Boid; Peers : Flock; Perception : Positive_Real) return Vec2
     with Pre => Peers'Length >= 1
            and then Peers'Length <= Max_Boids,
          Global => null;
   --  Steer to avoid crowding: average of −(neighbour − self) / d²
   --  over neighbours within Perception (excludes Self by position identity
   --  when the same slot appears — callers pass full flock; Self is skipped
   --  by index via Separation_At).

   function Alignment
     (Self : Boid; Peers : Flock; Perception : Positive_Real) return Vec2
     with Pre => Peers'Length >= 1
            and then Peers'Length <= Max_Boids,
          Global => null;
   --  Steer toward average neighbour velocity.

   function Cohesion
     (Self : Boid; Peers : Flock; Perception : Positive_Real) return Vec2
     with Pre => Peers'Length >= 1
            and then Peers'Length <= Max_Boids,
          Global => null;
   --  Steer toward average neighbour position (centre of mass).

   function Separation_At
     (F : Flock; Index : Boid_Index; Perception : Positive_Real) return Vec2
     with Pre => Index in F'Range
            and then F'Length >= 1
            and then F'Length <= Max_Boids,
          Global => null;

   function Alignment_At
     (F : Flock; Index : Boid_Index; Perception : Positive_Real) return Vec2
     with Pre => Index in F'Range
            and then F'Length >= 1
            and then F'Length <= Max_Boids,
          Global => null;

   function Cohesion_At
     (F : Flock; Index : Boid_Index; Perception : Positive_Real) return Vec2
     with Pre => Index in F'Range
            and then F'Length >= 1
            and then F'Length <= Max_Boids,
          Global => null;

   function Combined_Steer
     (F : Flock; Index : Boid_Index; Cfg : Config) return Vec2
     with Pre => Index in F'Range
            and then F'Length >= 1
            and then F'Length <= Max_Boids,
          Global => null;
   --  Weighted sum of separation / alignment / cohesion, each force-limited.

   ---------------------------------------------------------------------------
   -- Flock integration
   ---------------------------------------------------------------------------

   procedure Step_Boid
     (F     : in out Flock;
      Index : Boid_Index;
      Cfg   : Config)
     with Pre => Index in F'Range
            and then F'Length >= 1
            and then F'Length <= Max_Boids,
          Global => null;
   --  One Euler step for a single agent using Combined_Steer.

   procedure Step_Flock (F : in out Flock; Cfg : Config)
     with Pre => F'Length >= 1 and then F'Length <= Max_Boids,
          Global => null;
   --  Simultaneous Euler update: compute all steers, then integrate.

   function Simulate_Flock
     (Initial : Flock;
      Cfg     : Config;
      Steps   : Natural) return Result
     with Pre => Initial'Length >= 1
            and then Initial'Length <= Max_Boids,
          Global => null;
   --  Run Steps flock updates; return mean speed / mean nearest-neighbour
   --  spacing statistics over the final configuration.

   function Mean_Speed (F : Flock) return Non_Negative
     with Pre => F'Length >= 1, Global => null;

   function Mean_Nearest_Spacing (F : Flock) return Non_Negative
     with Pre => F'Length >= 1, Global => null;

   function Make_Grid_Flock
     (Rows, Cols : Positive;
      Spacing    : Positive_Real := 1.0;
      Speed      : Real := 0.0) return Flock
     with Pre => Rows * Cols <= Max_Boids,
          Global => null;
   --  Axis-aligned grid of boids with optional uniform +X velocity.

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Method_Implemented (Kind : Method_Kind) return Boolean
     with Global => null;

   function Method_Count return Positive
     with Global => null;

end Swarm_Intelligence;
