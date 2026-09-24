--  Nelder_Mead — Ada 2023 educational package for Wikipedia
--  "Nelder–Mead method" (downhill simplex / amoeba method; Nelder &
--  Mead 1965): derivative-free direct search that maintains an
--  n+1-vertex simplex in R^n and replaces the worst vertex by
--  reflection, expansion, contraction, or shrink toward the best.
--  Primary source: https://en.wikipedia.org/wiki/Nelder–Mead_method
--  Siblings: Ada-Simulated-Annealing / Ada-Random-Search /
--  Ada-Stochastic-Tunneling (README links).

pragma Ada_2022;

package Nelder_Mead
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Dim : constant := 8;
   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   --  A simplex in R^n has n+1 vertices; index vertices 1 .. n+1.
   subtype Vertex_Count is Positive range 2 .. Max_Dim + 1;
   subtype Vertex_Index is Positive range 1 .. Max_Dim + 1;

   type Point is array (Dim_Index range <>) of Real;

   type Vertex is record
      X : Point (1 .. Max_Dim) := [others => 0.0];
      F : Real := 0.0;
   end record;

   type Simplex is array (Vertex_Index range <>) of Vertex;

   --  Classic coefficients (Nelder & Mead / Wikipedia defaults):
   --  Alpha  : reflection  (α = 1)
   --  Gamma  : expansion   (γ = 2)
   --  Rho    : contraction (ρ = 1/2)
   --  Sigma  : shrink      (σ = 1/2)
   --  Step   : initial simplex offset along each axis
   --  Max_Iters : hard iteration budget
   --  Size_Tol  : stop when simplex diameter ≤ Size_Tol
   --  F_Tol     : stop when f_worst − f_best ≤ F_Tol
   type Config is record
      Alpha     : Positive_Real := 1.0;
      Gamma     : Positive_Real := 2.0;
      Rho       : Positive_Real := 0.5;
      Sigma     : Positive_Real := 0.5;
      Step      : Positive_Real := 1.0;
      Max_Iters : Positive      := 5_000;
      Size_Tol  : Non_Negative  := 1.0E-10;
      F_Tol     : Non_Negative  := 1.0E-12;
   end record;

   type Result is record
      Best_X     : Point (1 .. Max_Dim) := [others => 0.0];
      Best_F     : Real    := 0.0;
      Dim        : Dim_Count := 1;
      Iters      : Natural := 0;
      Evals      : Natural := 0;
      Converged  : Boolean := False;
      Final_Size : Non_Negative := 0.0;
   end record;

   --  Access to an N-D objective f : R^n → R to minimize.
   type Objective_Fn is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Point_Near
     (A, B : Point; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Norm2 (X : Point) return Non_Negative
     with Global => null;

   function Dot (A, B : Point) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Add (A, B : Point) return Point
     with Pre => A'Length = B'Length, Global => null;

   function Sub (A, B : Point) return Point
     with Pre => A'Length = B'Length, Global => null;

   function Scale (C : Real; X : Point) return Point
     with Global => null;

   ---------------------------------------------------------------------------
   -- Simplex geometry / Wikipedia ops (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Centroid_Excluding_Worst
     (S : Simplex; Dim : Dim_Count) return Point
     with Pre => S'Length = Dim + 1, Global => null;
   --  Mean of the best n vertices (exclude the last / worst).

   function Reflect
     (Centroid, Worst : Point; Alpha : Positive_Real) return Point
     with Pre => Centroid'Length = Worst'Length, Global => null;
   --  x_r = x_o + α (x_o − x_worst)

   function Expand
     (Centroid, Reflected : Point; Gamma : Positive_Real) return Point
     with Pre => Centroid'Length = Reflected'Length, Global => null;
   --  x_e = x_o + γ (x_r − x_o)

   function Contract_Outside
     (Centroid, Reflected : Point; Rho : Positive_Real) return Point
     with Pre => Centroid'Length = Reflected'Length, Global => null;
   --  x_c = x_o + ρ (x_r − x_o)

   function Contract_Inside
     (Centroid, Worst : Point; Rho : Positive_Real) return Point
     with Pre => Centroid'Length = Worst'Length, Global => null;
   --  x_c = x_o + ρ (x_worst − x_o)

   function Shrink_Toward_Best
     (Best, Other : Point; Sigma : Positive_Real) return Point
     with Pre => Best'Length = Other'Length, Global => null;
   --  x' = x_1 + σ (x − x_1)

   function Simplex_Size (S : Simplex; Dim : Dim_Count) return Non_Negative
     with Pre => S'Length = Dim + 1, Global => null;
   --  Max Euclidean distance from the best vertex to any other.

   function F_Spread (S : Simplex) return Non_Negative
     with Global => null;
   --  f_worst − f_best (assumes S ordered best → worst).

   procedure Order_Vertices (S : in out Simplex)
     with Global => null;
   --  Sort vertices by ascending f (best first, worst last).

   function Initial_Simplex
     (X0   : Point;
      Step : Positive_Real;
      Obj  : Objective_Fn) return Simplex
     with Pre => X0'Length >= 1
            and then X0'Length <= Max_Dim
            and then Obj /= null,
          Global => null;
   --  x_1 = X0; x_{1+i} = X0 + Step·e_i  (axis-aligned offsets).

   ---------------------------------------------------------------------------
   -- Built-in test objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y) = (a−x)² + b(y−x²)² with a=1, b=100.
   --  Global min 0 at (1,1). Uses first two coordinates.

   function Himmelblau (X : Point) return Real
     with Global => null;
   --  f(x,y)=(x²+y−11)²+(x+y²−7)²; four global minima with f=0.
   --  Uses first two coordinates.

   function Quadratic_1D (X : Point) return Real
     with Global => null;
   --  f(x) = (x₁ − 2)²; unique min 0 at x₁ = 2 (1-D / 2-vertex simplex).

   function Shifted_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Cfg       : Config := (others => <>)) return Result
     with Pre => X0'Length >= 1
            and then X0'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Classic Nelder–Mead downhill simplex minimization of Objective
   --  starting from an axis-offset initial simplex around X0.

end Nelder_Mead;
