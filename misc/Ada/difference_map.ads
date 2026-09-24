--  Difference_Map — Ada 2023 educational package for Veit Elser's
--  difference-map algorithm: an iterative dynamical system built from
--  two projectors PA, PB onto constraint sets A and B. Fixed points of
--  the map encode solutions of the set-intersection problem x ∈ A ∩ B.
--  Incomplete CSP meta-algorithm (can verify solutions, cannot prove
--  none exist). Also includes alternating projections and a clean
--  Douglas–Rachford / averaged-projections contrast for teaching.
--  Primary source:
--  https://en.wikipedia.org/wiki/Difference-map_algorithm
--  Siblings (README links only — no package deps):
--  Ada-Min-Conflicts, Ada-Local-Search, Ada-DPLL.

pragma Ada_2022;

package Difference_Map
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   Max_Dim  : constant := 16;
   Max_Iter : constant := 10_000;
   --  Educational caps: Dim ≤ 16; documented iteration budget ≤ Max_Iter.

   subtype Dimension is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Iter_Budget is Natural range 0 .. Max_Iter;

   type Vector is array (Positive range <>) of Real;

   ---------------------------------------------------------------------------
   -- Parameters / result
   ---------------------------------------------------------------------------

   --  Beta    : Elser step parameter (β ≠ 0); β = 1 is the usual first guess
   --  Max_Iter: iteration budget
   --  Tol     : residual tolerance for declaring a fixed point / feasible
   type Parameters is record
      Beta     : Real        := 1.0;
      Max_Iter : Iter_Budget := 1_000;
      Tol      : Real        := 1.0E-8;
   end record;

   type Result is record
      X            : Vector (1 .. Max_Dim) := [others => 0.0];
      Feasible     : Vector (1 .. Max_Dim) := [others => 0.0];
      Dim          : Dimension             := 1;
      Iterations   : Natural               := 0;
      Residual     : Real                  := Real'Last;
      Converged    : Boolean               := False;
      Near_Feasible : Boolean              := False;
   end record;

   ---------------------------------------------------------------------------
   -- Constraint descriptors (dispatch Project)
   ---------------------------------------------------------------------------

   type Constraint_Kind is
     (Box_Constraint,
      Ball_Constraint,
      Sphere_Constraint,
      Orthant_Constraint,
      Hyperplane_Constraint);

   --  Fixed Max_Dim slots; only 1 .. Dim are used.
   --  Box:        Lo, Hi componentwise
   --  Ball:       Center, Radius — project into closed ball
   --  Sphere:     Center, Radius — project onto sphere surface
   --  Orthant:    nonnegative orthant (unused fields ignored)
   --  Hyperplane: Normal · x = Offset  (a · x = b)
   type Constraint is record
      Kind   : Constraint_Kind := Orthant_Constraint;
      Dim    : Dimension       := 1;
      Lo     : Vector (1 .. Max_Dim) := [others => 0.0];
      Hi     : Vector (1 .. Max_Dim) := [others => 1.0];
      Center : Vector (1 .. Max_Dim) := [others => 0.0];
      Radius : Real                  := 1.0;
      Normal : Vector (1 .. Max_Dim) := [others => 0.0];
      Offset : Real                  := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-12;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Parameters
     (Beta     : Real        := 1.0;
      Max_Iter : Iter_Budget := 1_000;
      Tol      : Real        := 1.0E-8) return Parameters
     with Pre => Beta /= 0.0 and then Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Vector primitives
   ---------------------------------------------------------------------------

   function Norm2 (X : Vector) return Real
     with Pre => X'Length >= 1, Global => null;

   function Dot (X, Y : Vector) return Real
     with Pre => X'Length = Y'Length and then X'Length >= 1, Global => null;

   function Add (X, Y : Vector) return Vector
     with Pre => X'Length = Y'Length and then X'Length >= 1,
          Post => Add'Result'Length = X'Length, Global => null;

   function Sub (X, Y : Vector) return Vector
     with Pre => X'Length = Y'Length and then X'Length >= 1,
          Post => Sub'Result'Length = X'Length, Global => null;

   function Scale (Alpha : Real; X : Vector) return Vector
     with Pre => X'Length >= 1,
          Post => Scale'Result'Length = X'Length, Global => null;

   function Distance (X, Y : Vector) return Real
     with Pre => X'Length = Y'Length and then X'Length >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Concrete projectors (required toys)
   ---------------------------------------------------------------------------

   --  Componentwise clamp into the axis-aligned box [Lo, Hi].
   function Project_Box (X, Lo, Hi : Vector) return Vector
     with Pre => X'Length = Lo'Length
                 and then X'Length = Hi'Length
                 and then X'Length >= 1
                 and then X'Length <= Max_Dim,
          Post => Project_Box'Result'Length = X'Length;

   --  Closed Euclidean ball: if ||X − C|| ≤ R keep X, else map to the
   --  boundary along the ray from Center.
   function Project_Ball
     (X : Vector; Radius : Real; Center : Vector) return Vector
     with Pre => X'Length = Center'Length
                 and then X'Length >= 1
                 and then X'Length <= Max_Dim
                 and then Radius >= 0.0,
          Post => Project_Ball'Result'Length = X'Length;

   --  Sphere surface of given radius (normalize; origin → arbitrary point
   --  on the sphere along e1 when X = Center).
   function Project_Sphere
     (X : Vector; Radius : Real; Center : Vector) return Vector
     with Pre => X'Length = Center'Length
                 and then X'Length >= 1
                 and then X'Length <= Max_Dim
                 and then Radius > 0.0,
          Post => Project_Sphere'Result'Length = X'Length;

   --  Nonnegative orthant: max(0, x_i) componentwise.
   function Project_Orthant (X : Vector) return Vector
     with Pre => X'Length >= 1 and then X'Length <= Max_Dim,
          Post => Project_Orthant'Result'Length = X'Length;

   --  Affine hyperplane a · x = b (Normal · X = Offset).
   function Project_Hyperplane
     (X : Vector; Normal : Vector; Offset : Real) return Vector
     with Pre => X'Length = Normal'Length
                 and then X'Length >= 1
                 and then X'Length <= Max_Dim,
          Post => Project_Hyperplane'Result'Length = X'Length;

   --  Dispatch on Constraint descriptor.
   function Project (C : Constraint; X : Vector) return Vector
     with Pre => X'Length = Natural (C.Dim)
                 and then X'Length >= 1
                 and then X'Length <= Max_Dim,
          Post => Project'Result'Length = X'Length;

   ---------------------------------------------------------------------------
   -- Elser difference map
   ---------------------------------------------------------------------------

   --  f_A(x) = P_A(x) − (1/β)(P_A(x) − x)
   --  f_B(x) = P_B(x) + (1/β)(P_B(x) − x)
   function F_A (X : Vector; A : Constraint; Beta : Real) return Vector
     with Pre => X'Length = Natural (A.Dim)
                 and then Beta /= 0.0
                 and then X'Length >= 1,
          Post => F_A'Result'Length = X'Length;

   function F_B (X : Vector; B : Constraint; Beta : Real) return Vector
     with Pre => X'Length = Natural (B.Dim)
                 and then Beta /= 0.0
                 and then X'Length >= 1,
          Post => F_B'Result'Length = X'Length;

   --  One Elser step:
   --  D(x) = x + β [ P_A(f_B(x)) − P_B(f_A(x)) ]
   --  For β = 1 this reduces to D(x) = x + P_A(2 P_B(x) − x) − P_B(x).
   function Difference_Map_Step
     (X : Vector; A, B : Constraint; Beta : Real) return Vector
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then Beta /= 0.0
                 and then X'Length >= 1,
          Post => Difference_Map_Step'Result'Length = X'Length;

   --  Fixed-point residual Δ = || P_A(f_B(x)) − P_B(f_A(x)) ||_2
   function Residual
     (X : Vector; A, B : Constraint; Beta : Real) return Real
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then Beta /= 0.0
                 and then X'Length >= 1;

   --  True when residual ≤ Tol (common point of A and B recovered).
   function Is_Near_Feasible
     (X : Vector; A, B : Constraint; Beta : Real; Tol : Real) return Boolean
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then Beta /= 0.0
                 and then Tol >= 0.0
                 and then X'Length >= 1;

   --  Candidate feasible point P_A(f_B(x)) (equals P_B(f_A(x)) at a
   --  fixed point).
   function Feasible_Candidate
     (X : Vector; A, B : Constraint; Beta : Real) return Vector
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then Beta /= 0.0
                 and then X'Length >= 1,
          Post => Feasible_Candidate'Result'Length = X'Length;

   function Iterate_Difference_Map
     (X0 : Vector; A, B : Constraint; Params : Parameters) return Result
     with Pre => X0'Length = Natural (A.Dim)
                 and then X0'Length = Natural (B.Dim)
                 and then Params.Beta /= 0.0
                 and then Params.Tol >= 0.0
                 and then X0'Length >= 1;

   ---------------------------------------------------------------------------
   -- Related maps (teaching / convex contrast)
   ---------------------------------------------------------------------------

   --  Alternating projections: x ← P_A(P_B(x))
   function Alternating_Projections_Step
     (X : Vector; A, B : Constraint) return Vector
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then X'Length >= 1,
          Post => Alternating_Projections_Step'Result'Length = X'Length;

   function Alternating_Projections
     (X0 : Vector; A, B : Constraint; Params : Parameters) return Result
     with Pre => X0'Length = Natural (A.Dim)
                 and then X0'Length = Natural (B.Dim)
                 and then Params.Tol >= 0.0
                 and then X0'Length >= 1;

   --  Reflection R_C = 2 P_C − I
   function Reflect (C : Constraint; X : Vector) return Vector
     with Pre => X'Length = Natural (C.Dim) and then X'Length >= 1,
          Post => Reflect'Result'Length = X'Length;

   --  Douglas–Rachford: x ← ½ (x + R_A(R_B(x)))
   function Douglas_Rachford_Step
     (X : Vector; A, B : Constraint) return Vector
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then X'Length >= 1,
          Post => Douglas_Rachford_Step'Result'Length = X'Length;

   function Iterate_Douglas_Rachford
     (X0 : Vector; A, B : Constraint; Params : Parameters) return Result
     with Pre => X0'Length = Natural (A.Dim)
                 and then X0'Length = Natural (B.Dim)
                 and then Params.Tol >= 0.0
                 and then X0'Length >= 1;

   --  Averaged projections: x ← ½ (P_A(x) + P_B(x))
   function Averaged_Projections_Step
     (X : Vector; A, B : Constraint) return Vector
     with Pre => X'Length = Natural (A.Dim)
                 and then X'Length = Natural (B.Dim)
                 and then X'Length >= 1,
          Post => Averaged_Projections_Step'Result'Length = X'Length;

   ---------------------------------------------------------------------------
   -- Constraint builders (demos)
   ---------------------------------------------------------------------------

   function Make_Box
     (Dim : Dimension; Lo_Val, Hi_Val : Real) return Constraint
     with Pre => Lo_Val <= Hi_Val;

   function Make_Box_Vec (Lo, Hi : Vector) return Constraint
     with Pre => Lo'Length = Hi'Length
                 and then Lo'Length >= 1
                 and then Lo'Length <= Max_Dim;

   function Make_Ball
     (Dim : Dimension; Radius : Real; Center_Val : Real := 0.0)
      return Constraint
     with Pre => Radius >= 0.0;

   function Make_Sphere
     (Dim : Dimension; Radius : Real; Center_Val : Real := 0.0)
      return Constraint
     with Pre => Radius > 0.0;

   function Make_Orthant (Dim : Dimension) return Constraint;

   function Make_Hyperplane
     (Normal : Vector; Offset : Real) return Constraint
     with Pre => Normal'Length >= 1 and then Normal'Length <= Max_Dim;

end Difference_Map;
