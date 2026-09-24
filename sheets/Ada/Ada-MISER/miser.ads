--  Miser — Ada 2023 educational package for the MISER algorithm
--  (recursive stratified Monte Carlo integration; Press & Farrar 1990).
--  Bisects a hyper-rectangle along a coordinate chosen to minimize the
--  combined variance estimate; allocates remaining samples proportional
--  to subregion standard deviations; recurses to a leaf plain-MC estimate.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Monte_Carlo_integration
--  https://en.wikipedia.org/wiki/MISER_algorithm
--  Press, W. H.; Farrar, G. R. (1990). Computers in Physics 4 (2): 190.
--  Siblings (Monte Carlo survey, forthcoming): Ada-Metropolis-Hastings,
--  Ada-Wang-Landau, Ada-VEGAS, etc. (README links).

pragma Ada_2022;

package Miser
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Fraction is Real range 0.0 .. 1.0;

   --  Educational dimension cap (hyper-rectangle in D <= 4).
   Max_Dimension : constant Positive := 4;
   subtype Dimension_Count is Positive range 1 .. Max_Dimension;

   --  Point in D-space; callers pass slices / arrays of length D.
   type Point is array (Positive range <>) of Real;

   --  Axis-aligned hyper-rectangle [Lo_i, Hi_i] in each coordinate.
   type Bounds (D : Dimension_Count) is record
      Lo : Point (1 .. D);
      Hi : Point (1 .. D);
   end record;

   --  Integrand f : R^D → R evaluated at a point of length D.
   type Integrand is access function (X : Point) return Real;

   --  N_Points   : total sample budget for this integration call
   --  Dither     : fraction of points used to estimate subregion variance
   --               (Press/Farrar PFAC-style exploration fraction; 0 < D < 1)
   --  Min_Points : minimum samples in a leaf (plain MC) region
   --  Max_Depth  : maximum recursion depth before forcing plain MC
   --  Seed       : RNG seed for reproducibility (Ada.Numerics.Float_Random)
   type Config is record
      N_Points   : Positive      := 2_000;
      Dither     : Unit_Fraction := 0.1;
      Min_Points : Positive      := 15;
      Max_Depth  : Natural       := 12;
      Seed       : Integer       := 42;
   end record;

   type Result is record
      Estimate          : Real := 0.0;
      Variance_Estimate : Real := 0.0;
      Std_Error         : Real := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-12;

   --  Hyper-rectangle volume ∏ (Hi_i − Lo_i); raises if any edge ≤ 0.
   function Volume (B : Bounds) return Real
     with Global => null;

   --  True iff Lo_i < Hi_i for every coordinate.
   function Bounds_Valid (B : Bounds) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core algorithms
   ---------------------------------------------------------------------------

   --  Plain (crude) Monte Carlo: uniform samples, estimate = V ⟨f⟩,
   --  variance of the integral estimate ≈ V² Var(f) / N.
   function Plain_Monte_Carlo
     (F   : Integrand;
      B   : Bounds;
      Cfg : Config := (others => <>)) return Result
     with Pre => F /= null;

   --  MISER: recursive stratified sampling (Press & Farrar).
   --  Bisects along the coordinate that minimizes the combined variance
   --  estimate; allocates remaining points with
   --    N_a / (N_a + N_b) = σ_a / (σ_a + σ_b);
   --  combines leaf plain-MC estimates upward.
   function Integrate_Miser
     (F   : Integrand;
      B   : Bounds;
      Cfg : Config := (others => <>)) return Result
     with Pre => F /= null;

   ---------------------------------------------------------------------------
   -- Educational sample integrands (library-level for 'Access in tests)
   ---------------------------------------------------------------------------

   function Constant_One (X : Point) return Real;
   --  f ≡ 1; integral equals volume.

   function Constant_Three (X : Point) return Real;
   --  f ≡ 3.

   function Quarter_Circle (X : Point) return Real;
   --  Indicator of unit disk on [0,1]² → ∫ = π/4 (uses X(1), X(2)).

   function Poly_X_Squared (X : Point) return Real;
   --  x² on 1D; ∫_0^1 x² dx = 1/3.

   function Poly_Linear_1D (X : Point) return Real;
   --  2x on 1D; ∫_0^1 2x dx = 1.

   function Product_XY (X : Point) return Real;
   --  x·y on 2D; ∫_{[0,1]²} xy = 1/4.

   function Separable_Peak (X : Point) return Real;
   --  exp(−10(x−0.5)²) on 1D (mild peak near 0.5).

end Miser;
