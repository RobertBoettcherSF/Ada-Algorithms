--  Ellipsoid_Method — Ada 2023 educational package for Wikipedia
--  "Ellipsoid method" (Khachiyan / Shor–Nemirovski–Yudin): maintain a
--  shrinking ellipsoid that contains a convex feasible set, cut with a
--  separation oracle (central or deep), until a feasible point is found
--  or the volume is too small (empty / inconclusive). Cap n ≤ 8.
--  Primary source:
--  https://en.wikipedia.org/wiki/Ellipsoid_method
--  Siblings: Ada-Simplex-Algorithm, Ada-Karmarkars-Algorithm,
--  Ada-Interior-Point-Method, Ada-Linear-Programming.

pragma Ada_2022;

package Ellipsoid_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim : constant := 8;

   subtype Dimension is Natural range 0 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   --  Ellipsoid E = { x | (x − c)^T P^{-1} (x − c) ≤ 1 } with P ≻ 0.
   --  Shape stores the full dense n×n matrix P (not P^{-1}).
   type Ellipsoid is record
      N      : Dimension := 0;
      Center : Vector (1 .. Max_Dim) := [others => 0.0];
      Shape  : Matrix (1 .. Max_Dim, 1 .. Max_Dim) :=
                 [others => [others => 0.0]];
   end record;

   --  Halfspace a · x ≤ b  (polytope constraint / separating cut data).
   type Halfspace is record
      N      : Dimension := 0;
      Normal : Vector (1 .. Max_Dim) := [others => 0.0];
      Offset : Real := 0.0;
   end record;

   type Halfspace_List is array (Positive range <>) of Halfspace;

   --  Cut direction g for the half-ellipsoid { z | g · (z − c) ≤ −α ‖…‖ }.
   --  Central cut: Depth = 0. Deep cut: Depth = α ∈ [0, 1).
   --  Depth ≥ 1 is a feasibility-loop sentinel (ellipsoid ∩ cut = empty).
   type Cut is record
      N      : Dimension := 0;
      Grad   : Vector (1 .. Max_Dim) := [others => 0.0];
      Depth  : Real := 0.0;  --  α (normalized); 0 ⇒ central; ≥1 ⇒ empty
      Valid  : Boolean := False;
   end record;

   type Status is
     (Feasible, Infeasible, Iteration_Limit, Volume_Too_Small, Ill_Started);

   --  Max_Iters      : outer ellipsoid iterations
   --  Tol            : numerical zero / feasibility slack
   --  Min_Log_Vol    : stop when Log_Volume_Proxy ≤ this (empty proxy)
   --  Use_Deep_Cuts  : deep vs central cuts from violated halfspaces
   type Config is record
      Max_Iters     : Positive      := 500;
      Tol           : Positive_Real := 1.0E-8;
      Min_Log_Vol   : Real          := -80.0;
      Use_Deep_Cuts : Boolean       := True;
   end record;

   type Result is record
      Stat       : Status := Ill_Started;
      Point      : Vector (1 .. Max_Dim) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Final_Ell  : Ellipsoid;
      Success    : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-9;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Dot (U, V : Vector) return Real
     with Pre => U'Length = V'Length, Global => null;

   function Norm2 (V : Vector) return Real
     with Global => null;

   function Normalize (V : Vector) return Vector
     with Pre => V'Length >= 1, Global => null;
   --  Euclidean unit vector; raises Invalid_Argument if ‖V‖ ≈ 0.

   function Scale (V : Vector; S : Real) return Vector
     with Global => null;

   function Add (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   function Sub (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   function Mat_Vec (M : Matrix; V : Vector) return Vector
     with Pre => M'Length (2) = V'Length
            and then M'Length (1) = M'Length (2),
          Global => null;

   function Mat_Mul (A, B : Matrix) return Matrix
     with Pre => A'Length (2) = B'Length (1)
            and then A'Length (1) = A'Length (2)
            and then B'Length (1) = B'Length (2),
          Global => null;

   function Transpose (M : Matrix) return Matrix
     with Pre => M'Length (1) = M'Length (2), Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Symmetric_Part (M : Matrix) return Matrix
     with Pre => M'Length (1) = M'Length (2), Global => null;
   --  (M + M^T) / 2 — keeps Shape numerically symmetric after updates.

   function Determinant_2x2 (M : Matrix) return Real
     with Pre => M'Length (1) = 2 and then M'Length (2) = 2,
          Global => null;

   function Determinant_3x3 (M : Matrix) return Real
     with Pre => M'Length (1) = 3 and then M'Length (2) = 3,
          Global => null;

   function Determinant (M : Matrix) return Real
     with Pre => M'Length (1) = M'Length (2)
            and then M'Length (1) >= 1
            and then M'Length (1) <= Max_Dim,
          Global => null;
   --  Dense GE with partial pivoting; educational Float accuracy.

   function Is_Symmetric
     (M : Matrix; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => M'Length (1) = M'Length (2) and then Tol >= 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Ellipsoid construction & volume proxies
   ---------------------------------------------------------------------------

   function Init_Ball
     (Center : Vector;
      Radius : Positive_Real) return Ellipsoid
     with Pre => Center'Length >= 1
            and then Center'Length <= Max_Dim;
   --  Ball of Euclidean radius R: P = R² I, center = Center.

   function Volume_Proxy (E : Ellipsoid) return Real
     with Pre => E.N >= 1, Global => null;
   --  det(P); proportional to (vol E)². Decreases under valid cuts.

   function Log_Volume_Proxy (E : Ellipsoid) return Real
     with Pre => E.N >= 1, Global => null;
   --  0.5 * log(det(P)) — log-volume up to additive constant (unit ball).

   function Contains_Point
     (E : Ellipsoid; X : Vector; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => E.N >= 1
            and then X'Length = E.N
            and then Tol >= 0.0;
   --  (x−c)^T P^{-1} (x−c) ≤ 1 + Tol via solving P y = (x−c).

   function Quadratic_Form
     (E : Ellipsoid; X : Vector) return Real
     with Pre => E.N >= 1 and then X'Length = E.N;
   --  (x−c)^T P^{-1} (x−c); raises Invalid_Argument if P is singular.

   ---------------------------------------------------------------------------
   -- Cuts
   ---------------------------------------------------------------------------

   function Make_Cut
     (Grad : Vector; Depth : Real := 0.0) return Cut
     with Pre => Grad'Length >= 1
            and then Grad'Length <= Max_Dim
            and then Depth >= 0.0
            and then Depth < 1.0,
          Global => null;

   function Halfspace_Violation
     (H : Halfspace; X : Vector) return Real
     with Pre => H.N >= 1 and then X'Length = H.N, Global => null;
   --  a · x − b; positive ⇒ violated.

   function Cut_From_Halfspace
     (H      : Halfspace;
      E      : Ellipsoid;
      Deep   : Boolean := True;
      Tol    : Real := Epsilon_Tol) return Cut
     with Pre => H.N = E.N and then H.N >= 1 and then Tol >= 0.0;
   --  Separating cut for violated a·x ≤ b at center. Central if not Deep
   --  or α≈0; deep with α = (a·c − b) / sqrt(a^T P a) clipped to [0, 1).

   procedure Apply_Central_Cut
     (E : in out Ellipsoid;
      G : Vector)
     with Pre => E.N >= 1 and then G'Length = E.N;
   --  Minimal-volume ellipsoid over the central half { g·(z−c) ≤ 0 }.

   procedure Apply_Deep_Cut
     (E     : in out Ellipsoid;
      G     : Vector;
      Alpha : Real)
     with Pre => E.N >= 1
            and then G'Length = E.N
            and then Alpha >= 0.0
            and then Alpha < 1.0;
   --  Deep-cut update with normalized depth α; α=0 reduces to central.

   procedure Apply_Cut
     (E : in out Ellipsoid;
      C : Cut)
     with Pre => E.N >= 1 and then C.Valid and then C.N = E.N;

   ---------------------------------------------------------------------------
   -- Feasibility (polytope / separation)
   ---------------------------------------------------------------------------

   function First_Violated
     (Hs  : Halfspace_List;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Natural
     with Pre => X'Length >= 1 and then Tol >= 0.0, Global => null;
   --  Smallest index with a·x > b + Tol; 0 if feasible.

   function Is_Feasible
     (Hs  : Halfspace_List;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
     with Pre => X'Length >= 1 and then Tol >= 0.0, Global => null;

   function Feasibility_Ellipsoid
     (Hs     : Halfspace_List;
      Initial : Ellipsoid;
      Cfg    : Config := (others => <>)) return Result
     with Pre => Initial.N >= 1
            and then Hs'Length >= 1
            and then (for all H of Hs => H.N = Initial.N);
   --  Loop: if center feasible → Feasible; else cut with violated
   --  halfspace; stop on Max_Iters, tiny volume (Infeasible proxy), or
   --  ill-conditioned update.

   function Feasibility_Box
     (Lo, Hi  : Vector;
      Radius  : Positive_Real := 10.0;
      Cfg     : Config := (others => <>)) return Result
     with Pre => Lo'Length = Hi'Length
            and then Lo'Length >= 1
            and then Lo'Length <= Max_Dim;
   --  Find a point in the axis-aligned box [Lo, Hi] starting from a ball
   --  at the box midpoint with the given radius (must cover the box).

   function Maximize_Linear_Feasibility
     (Hs      : Halfspace_List;
      Obj     : Vector;
      Lo, Hi  : Real;
      Initial : Ellipsoid;
      Cfg     : Config := (others => <>);
      Binary_Steps : Positive := 20) return Result
     with Pre => Initial.N >= 1
            and then Obj'Length = Initial.N
            and then Hs'Length >= 1
            and then (for all H of Hs => H.N = Initial.N)
            and then Hi >= Lo;
   --  Educational LP sketch: binary search on γ for feasibility of
   --  Ax ≤ b and c·x ≥ γ (maximize). Returns best feasible point found.

end Ellipsoid_Method;
