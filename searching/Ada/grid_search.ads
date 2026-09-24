--  Grid_Search — Ada 2023 educational package for Wikipedia
--  "Hyperparameter optimization" § Grid search: exhaustive Cartesian
--  product over manually discretized axes; evaluate an objective on every
--  tuple; return the best (min or max). Classic parameter sweep for
--  tuning (e.g. SVM C and γ on a finite grid). Suffers from the curse of
--  dimensionality; embarrassingly parallel when evaluations are independent.
--  Primary source:
--  https://en.wikipedia.org/wiki/Hyperparameter_optimization#Grid_search
--  Sibling: Ada-Random-Search (budgeted random sampling baseline).

pragma Ada_2022;

package Grid_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Dim              : constant := 6;
   Max_Points_Per_Axis  : constant := 16;

   subtype Dim_Count is Natural range 0 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Axis_Size is Natural range 0 .. Max_Points_Per_Axis;
   subtype Axis_Index is Positive range 1 .. Max_Points_Per_Axis;

   type Point is array (Dim_Index range <>) of Real;

   --  Sorted unique discrete values along one hyperparameter axis.
   type Value_Array is array (Axis_Index range <>) of Real;

   type Axis is record
      Values : Value_Array (1 .. Max_Points_Per_Axis) := [others => 0.0];
      Count  : Axis_Size := 0;
   end record;

   type Axis_Array is array (Dim_Index range <>) of Axis;

   --  Product grid: up to Max_Dim axes, each with ≤ Max_Points_Per_Axis pts.
   type Grid is record
      Axes : Axis_Array (1 .. Max_Dim) := [others => <>];
      Dim  : Dim_Count := 0;
   end record;

   type Sense is (Minimize_Sense, Maximize_Sense);

   --  Sense_Flag : minimize or maximize the objective over the grid.
   type Config is record
      Sense_Flag : Sense := Minimize_Sense;
   end record;

   type Result is record
      Best_X      : Point (1 .. Max_Dim) := [others => 0.0];
      Best_F      : Real      := 0.0;
      Dim         : Dim_Count := 0;
      Evaluations : Natural   := 0;
      Best_Rank   : Natural   := 0;  -- 1-based lexicographic index of best
   end record;

   type Objective_Fn is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Sense_Flag : Sense := Minimize_Sense) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Axis / grid construction
   ---------------------------------------------------------------------------

   function Build_Axis (Raw : Value_Array) return Axis
     with Pre => Raw'Length >= 1
            and then Raw'Length <= Max_Points_Per_Axis,
          Global => null;
   --  Sort ascending and drop near-duplicates (Near / Epsilon_Tol).
   --  Raises Invalid_Argument if the result would be empty (should not).

   function Build_Linspace_Axis
     (Lo, Hi : Real; N : Axis_Index) return Axis
     with Pre => Lo <= Hi, Global => null;
   --  N equally spaced samples on [Lo, Hi] inclusive (N = 1 → {Lo}).
   --  Endpoints are exactly Lo and Hi when N ≥ 2.

   function Make_Grid (Axes : Axis_Array) return Grid
     with Pre => Axes'Length >= 1
            and then Axes'Length <= Max_Dim,
          Global => null;
   --  Copy axes into a Grid; raises Invalid_Argument if any Count = 0.

   function Axis_Length (A : Axis) return Axis_Size
     with Global => null;

   function Get_Value (A : Axis; I : Axis_Index) return Real
     with Pre => I <= A.Count, Global => null;

   ---------------------------------------------------------------------------
   -- Cardinality / enumeration
   ---------------------------------------------------------------------------

   function Cardinality (G : Grid) return Natural
     with Global => null;
   --  Product of axis sizes. Returns 0 if Dim = 0 or any Count = 0.

   function Point_At (G : Grid; Rank : Positive) return Point
     with Pre => G.Dim >= 1
            and then Rank <= Cardinality (G),
          Global => null;
   --  Lexicographic tuple at 1-based Rank (fastest-varying = last axis).

   generic
      with procedure Visit
        (X : Point; Rank : Positive; Stop : in out Boolean);
   procedure Enumerate (G : Grid);
   --  Call Visit for every grid point in lex order. Visit may set Stop.
   --  Raises Invalid_Argument if Dim = 0 or any Count = 0.
   --  Nested instantiation is the intended form of nested iteration.

   ---------------------------------------------------------------------------
   -- Built-in test / demo objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Multimodal_1D (X : Point) return Real
     with Global => null;
   --  f(x) = (x−0.2)²(x−0.8)² − 0.05·(x−0.5)² using first coordinate.
   --  Two basins; global min among typical linspace samples near 0.2 or 0.8.

   function Neg_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = −Σ x_i²; unique max 0 at the origin (Maximize demo).

   function SVM_Toy_Score (X : Point) return Real
     with Global => null;
   --  Toy soft-margin SVM validation score on (C, γ) = (X₁, X₂):
   --  score = −(log10 C − 2)² − 4·(log10 γ + 1)²  (peak near C=100, γ=0.1).
   --  Requires Dim ≥ 2; Maximize over a discrete (C,γ) grid.

   function Shifted_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   ---------------------------------------------------------------------------
   -- Search drivers
   ---------------------------------------------------------------------------

   function Search
     (Objective : Objective_Fn;
      G         : Grid;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null, Global => null;
   --  Exhaustive evaluation of Objective on every grid point.
   --  Raises Invalid_Argument if Dim = 0 or any empty axis.

   function Minimize
     (Objective : Objective_Fn; G : Grid) return Result
     with Pre => Objective /= null, Global => null;
   --  Search with Minimize_Sense.

   function Maximize
     (Objective : Objective_Fn; G : Grid) return Result
     with Pre => Objective /= null, Global => null;
   --  Search with Maximize_Sense.

end Grid_Search;
