--  Constraint_Algorithm — Ada 2023 educational MD constraint solvers
--  (SHAKE & RATTLE) for holonomic distance constraints
--    g = |r_i - r_j|^2 - d^2 = 0.
--  This is the molecular-dynamics constraint-algorithm family
--  (computational chemistry), not generic CSP constraint satisfaction.
--  Based on Wikipedia "Constraint algorithm" (Constraint (computational chemistry)).

pragma Ada_2022;

package Constraint_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Particles   : constant Positive := 64;
   Max_Constraints : constant Positive := 128;

   subtype Particle_Count   is Natural range 0 .. Max_Particles;
   subtype Constraint_Count is Natural range 0 .. Max_Constraints;
   subtype Particle_Index   is Positive range 1 .. Max_Particles;
   subtype Constraint_Index is Positive range 1 .. Max_Constraints;

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   type Particle is record
      Mass : Positive_Real := 1.0;
      Pos  : Vec3 := (0.0, 0.0, 0.0);
      Vel  : Vec3 := (0.0, 0.0, 0.0);
   end record;

   type Particle_Array is array (Particle_Index range <>) of Particle;

   --  Distance constraint between particles I and J with rest length D:
   --  g = |r_I - r_J|^2 - D^2 = 0.
   type Distance_Constraint is record
      I, J : Particle_Index := 1;
      D    : Positive_Real  := 1.0;
   end record;

   type Constraint_Array is
     array (Constraint_Index range <>) of Distance_Constraint;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument       : exception;
   Capacity_Exceeded      : exception;
   Constraint_Not_Converged : exception;
   Empty_System           : exception;

   ---------------------------------------------------------------------------
   -- Solver configuration
   ---------------------------------------------------------------------------

   type Solver_Config is record
      Tol          : Positive_Real := 1.0E-10;
      Max_Iters    : Positive       := 500;
      Use_Reference : Boolean      := True;
      --  Classic SHAKE uses the bond vector at the start of the correction
      --  (unconstrained positions) as the Lagrange-gradient direction.
   end record;

   function Default_Config return Solver_Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Numeric / vector helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Add (A, B : Vec3) return Vec3
     with Global => null;

   function Vec_Sub (A, B : Vec3) return Vec3
     with Global => null;

   function Vec_Scale (V : Vec3; S : Real) return Vec3
     with Global => null;

   function Dot (A, B : Vec3) return Real
     with Global => null;

   function Norm2 (V : Vec3) return Non_Negative
     with Global => null;
   --  |V|^2

   function Norm (V : Vec3) return Non_Negative
     with Global => null;
   --  |V|

   function Distance (A, B : Vec3) return Non_Negative
     with Global => null;

   function Bond_Length
     (Particles : Particle_Array;
      C         : Distance_Constraint) return Non_Negative
     with Pre => C.I in Particles'Range and then C.J in Particles'Range,
          Global => null;

   ---------------------------------------------------------------------------
   -- Constraint evaluation
   ---------------------------------------------------------------------------

   function Constraint_Value
     (Particles : Particle_Array;
      C         : Distance_Constraint) return Real
     with Pre => C.I in Particles'Range and then C.J in Particles'Range,
          Global => null;
   --  g = |r_i - r_j|^2 - d^2

   function Constraint_Dot
     (Particles : Particle_Array;
      C         : Distance_Constraint) return Real
     with Pre => C.I in Particles'Range and then C.J in Particles'Range,
          Global => null;
   --  (1/2) g_dot = (r_i - r_j) · (v_i - v_j); zero when RATTLE is satisfied.

   function Constraint_Violation_Max
     (Particles   : Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count) return Non_Negative
     with Pre => N_Part <= Particles'Length
                 and then N_Cons <= Constraints'Length,
          Global => null;
   --  max_k |g_k|

   function Velocity_Violation_Max
     (Particles   : Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count) return Non_Negative
     with Pre => N_Part <= Particles'Length
                 and then N_Cons <= Constraints'Length,
          Global => null;
   --  max_k |(r_i-r_j)·(v_i-v_j)|  (absolute stretch rate)

   ---------------------------------------------------------------------------
   -- Momentum helpers (isolated corrections roughly preserve Σ m v)
   ---------------------------------------------------------------------------

   function Linear_Momentum
     (Particles : Particle_Array; N_Part : Particle_Count) return Vec3
     with Pre => N_Part <= Particles'Length, Global => null;

   function Total_Mass
     (Particles : Particle_Array; N_Part : Particle_Count) return Non_Negative
     with Pre => N_Part <= Particles'Length, Global => null;

   ---------------------------------------------------------------------------
   -- SHAKE — position constraints via iterative Lagrange multipliers
   ---------------------------------------------------------------------------

   type Shake_Result is record
      Converged   : Boolean := False;
      Iterations  : Natural := 0;
      Final_Max_G : Non_Negative := 0.0;
   end record;

   procedure Shake_Positions
     (Particles   : in out Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count;
      Config      : Solver_Config;
      Result      : out Shake_Result)
     with Pre => N_Part <= Particles'Length
                 and then N_Cons <= Constraints'Length;
   --  Classic SHAKE: after an unconstrained position update, iteratively
   --  correct positions with mass-weighted Lagrange multipliers until
   --  max |g_k| <= Tol (or Max_Iters). Does not modify velocities.

   ---------------------------------------------------------------------------
   -- RATTLE — velocity constraints so g_dot = 0
   ---------------------------------------------------------------------------

   type Rattle_Result is record
      Converged       : Boolean := False;
      Iterations      : Natural := 0;
      Final_Max_GDot  : Non_Negative := 0.0;
   end record;

   procedure Rattle_Velocities
     (Particles   : in out Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count;
      Config      : Solver_Config;
      Result      : out Rattle_Result)
     with Pre => N_Part <= Particles'Length
                 and then N_Cons <= Constraints'Length;
   --  Andersen RATTLE velocity step: project velocities so relative
   --  velocity along each bond is zero (no stretch rate). Positions fixed.

   ---------------------------------------------------------------------------
   -- Simple Velocity-Verlet + SHAKE/RATTLE step (zero external force demo)
   ---------------------------------------------------------------------------

   type Step_Result is record
      Shake  : Shake_Result;
      Rattle : Rattle_Result;
   end record;

   procedure Velocity_Verlet_Constrained_Step
     (Particles   : in out Particle_Array;
      Constraints : Constraint_Array;
      N_Part      : Particle_Count;
      N_Cons      : Constraint_Count;
      Dt          : Positive_Real;
      Config      : Solver_Config;
      Result      : out Step_Result)
     with Pre => N_Part <= Particles'Length
                 and then N_Cons <= Constraints'Length;
   --  Free-flight Velocity-Verlet half-step (a = 0), SHAKE positions,
   --  rebuild mid velocities from displacement, then RATTLE. Educational
   --  demo for isolated rigid molecules (no force field).

   ---------------------------------------------------------------------------
   -- Demo system builders
   ---------------------------------------------------------------------------

   procedure Make_Diatomic
     (Mass_A, Mass_B : Positive_Real;
      Bond_Length    : Positive_Real;
      Particles      : out Particle_Array;
      N_Part         : out Particle_Count;
      Constraints    : out Constraint_Array;
      N_Cons         : out Constraint_Count)
     with Pre => Particles'Length >= 2 and then Constraints'Length >= 1;
   --  Two particles on the x-axis at distance Bond_Length, rest velocities.

   procedure Make_Water_Like
     (Bond_OH, Bond_HH : Positive_Real;
      Particles        : out Particle_Array;
      N_Part           : out Particle_Count;
      Constraints      : out Constraint_Array;
      N_Cons           : out Constraint_Count)
     with Pre => Particles'Length >= 3 and then Constraints'Length >= 3;
   --  Rigid 3-site (TIP3P-style geometry): O at origin, H1/H2 in xy-plane
   --  with OH and HH distance constraints (3 constraints = rigid triangle).

   procedure Make_Two_Bond_Chain
     (Bond_Length : Positive_Real;
      Particles   : out Particle_Array;
      N_Part      : out Particle_Count;
      Constraints : out Constraint_Array;
      N_Cons      : out Constraint_Count)
     with Pre => Particles'Length >= 3 and then Constraints'Length >= 2;
   --  Three equal-mass beads along x with two consecutive bond constraints.

   procedure Perturb_Positions
     (Particles : in out Particle_Array;
      N_Part    : Particle_Count;
      Scale     : Real;
      Seed      : Natural := 1)
     with Pre => N_Part <= Particles'Length;
   --  Add a deterministic pseudo-random offset of magnitude ~ Scale to each
   --  coordinate (educational RNG; not cryptographic).

end Constraint_Algorithm;
