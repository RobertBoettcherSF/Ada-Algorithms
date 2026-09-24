--  False_Nearest_Neighbor — Ada 2023 educational package for Wikipedia
--  "False nearest neighbor" / Kennel–Brown–Abarbanel (1992) criterion for
--  estimating delay-embedding dimension from a scalar time series.
--  Delay vectors y_n = (x_n, x_{n+τ}, …, x_{n+(m−1)τ}); a nearest neighbor
--  in ℝ^m is false if the (m+1)-st coordinate opens the pair beyond R_tol
--  or the absolute distance exceeds A_tol · σ_x (Kennel et al. 1992;
--  Rhodes & Morari 1997 overview; Hegger & Kantz 1999 refinements).
--  Related: Takens embedding theorem, phase-space reconstruction.

pragma Ada_2022;

package False_Nearest_Neighbor
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12 for stable distance / fraction arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Series : constant Positive := 4096;
   Max_Dim    : constant Positive := 16;

   subtype Series_Count is Natural  range 0 .. Max_Series;
   subtype Series_Index is Positive range 1 .. Max_Series;
   subtype Dim_Count    is Natural  range 0 .. Max_Dim;
   subtype Dim_Index    is Positive range 1 .. Max_Dim;

   --  Scalar time series x[1 .. N].
   type Series is array (Series_Index range <>) of Real;

   --  FNN(m) fractions indexed by embedding dimension m = 1 .. Max_Dim.
   type Fraction_Array is array (Dim_Index range <>) of Real;

   type FNN_Config is record
      Tau                    : Positive := 1;
      R_Tol                  : Real     := 15.0;
      A_Tol                  : Real     := 2.0;
      Theiler                : Natural  := 0;
      Max_Dim                : Dim_Index := 10;
      Use_Absolute_Criterion : Boolean  := True;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Distances below this are treated as zero for ratio tests.
   Distance_Eps : constant Real := 1.0E-12;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Mean (Data : Series) return Real
     with Pre => Data'Length >= 1, Global => null;
   --  Raises Invalid_Argument if Length = 0.

   function Std_Dev (Data : Series) return Real
     with Pre => Data'Length >= 2, Global => null;
   --  Sample standard deviation (N−1). Raises Invalid_Argument if Length < 2
   --  or Degenerate_Geometry if the series is constant (σ = 0).

   ---------------------------------------------------------------------------
   -- Configuration
   ---------------------------------------------------------------------------

   function Make_Config
     (Tau                    : Positive  := 1;
      R_Tol                  : Real      := 15.0;
      A_Tol                  : Real      := 2.0;
      Theiler                : Natural   := 0;
      Max_Dim                : Dim_Index := 10;
      Use_Absolute_Criterion : Boolean   := True) return FNN_Config
     with Pre => R_Tol > 0.0 and then A_Tol > 0.0,
          Global => null;
   --  Raises Invalid_Argument if R_Tol or A_Tol is non-positive.

   ---------------------------------------------------------------------------
   -- Embedding geometry
   ---------------------------------------------------------------------------

   function Embedding_Distance_Sq
     (Data : Series;
      N1   : Series_Index;
      N2   : Series_Index;
      M    : Dim_Index;
      Tau  : Positive) return Non_Negative
     with Pre => Data'Length >= 1
       and then N1 in Data'Range
       and then N2 in Data'Range
       and then Natural (N1) + (Natural (M) - 1) * Tau <= Natural (Data'Last)
       and then Natural (N2) + (Natural (M) - 1) * Tau <= Natural (Data'Last),
          Global => null;
   --  Squared Euclidean distance between delay vectors of dimension M:
   --  Σ_{k=0}^{M−1} (x[N1+kτ] − x[N2+kτ])².

   function Nearest_Neighbor_Index
     (Data    : Series;
      N       : Series_Index;
      M       : Dim_Index;
      Tau     : Positive;
      Theiler : Natural := 0) return Series_Index
     with Pre => Data'Length >= 2
       and then N in Data'Range
       and then Natural (N) + (Natural (M) - 1) * Tau
                  <= Natural (Data'Last),
          Global => null;
   --  Index N' ≠ N of the nearest delay vector under Embedding_Distance_Sq,
   --  excluding temporal neighbours |N−N'| ≤ Theiler. Both indices must be
   --  valid for dimension M. Raises Degenerate_Geometry if no eligible
   --  neighbour exists; Invalid_Argument for short / invalid inputs.

   function Is_False_Neighbor
     (Data    : Series;
      N       : Series_Index;
      Np      : Series_Index;
      M       : Dim_Index;
      Config  : FNN_Config;
      Sigma   : Real) return Boolean
     with Pre => Data'Length >= 1
       and then N in Data'Range
       and then Np in Data'Range
       and then Sigma >= 0.0
       and then Config.R_Tol > 0.0
       and then Config.A_Tol > 0.0,
          Global => null;
   --  Kennel criteria at dimension M → M+1 for the pair (N, Np):
   --    (1) |x[N+Mτ] − x[Np+Mτ]| / R_m > R_Tol
   --    (2) optional: R_{m+1} / σ_x > A_Tol
   --  Raises Invalid_Argument if indices are not valid for M+1.

   ---------------------------------------------------------------------------
   -- FNN statistics
   ---------------------------------------------------------------------------

   function False_Neighbor_Fraction
     (Data   : Series;
      M      : Dim_Index;
      Config : FNN_Config) return Unit_Interval
     with Pre => Data'Length >= 1
       and then Config.Tau >= 1
       and then Config.R_Tol > 0.0
       and then Config.A_Tol > 0.0,
          Global => null;
   --  Fraction of tested reference points whose nearest neighbour is false
   --  when lifting from M to M+1. Raises Invalid_Argument / Capacity_Exceeded /
   --  Degenerate_Geometry as appropriate.

   function FNN_Profile
     (Data   : Series;
      Config : FNN_Config) return Fraction_Array
     with Pre => Data'Length >= 1
       and then Config.Max_Dim >= 1
       and then Config.Max_Dim <= Max_Dim
       and then Config.R_Tol > 0.0
       and then Config.A_Tol > 0.0,
          Global => null;
   --  FNN(m) for m = 1 .. Config.Max_Dim.

   function Estimate_Embedding_Dimension
     (Data      : Series;
      Config    : FNN_Config;
      Threshold : Real := 0.1) return Natural
     with Pre => Data'Length >= 1
       and then Threshold >= 0.0
       and then Threshold <= 1.0
       and then Config.Max_Dim >= 1
       and then Config.R_Tol > 0.0
       and then Config.A_Tol > 0.0,
          Global => null;
   --  Smallest m in 1 .. Config.Max_Dim with FNN(m) ≤ Threshold.
   --  Returns 0 if no such m exists.

end False_Nearest_Neighbor;
