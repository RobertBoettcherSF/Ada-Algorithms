--  RANSAC — Ada 2023 educational package for Wikipedia
--  "Random sample consensus" (Fischler & Bolles, Comm. ACM, 1981):
--  robust model fitting in the presence of outliers via repeated minimal
--  random sampling, consensus counting, optional least-squares refit on
--  inliers, and an MSAC-inspired truncated residual score.
--  Primary model: 2-D line (ax+by+c=0). Also: 2-D circle (center+radius).
--  Related notes (not implemented as full deps): MSAC, MLESAC (Torr &
--  Zisserman), PROSAC, R-RANSAC.

pragma Ada_2022;

package RANSAC
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12 for stable geometric / residual arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points : constant Positive := 4096;
   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   type Point2 is record
      X : Real := 0.0;
      Y : Real := 0.0;
   end record;

   subtype Vec2 is Point2;

   type Point_Array is array (Point_Index range <>) of Point2;

   --  Geometric line ax + by + c = 0, preferably normalized so
   --  sqrt(a²+b²) = 1 (unsigned distance = |ax+by+c|).
   type Line2 is record
      A : Real := 0.0;
      B : Real := 0.0;
      C : Real := 0.0;
   end record;

   type Circle2 is record
      Center : Point2 := (0.0, 0.0);
      Radius : Non_Negative := 0.0;
   end record;

   --  Bounded inlier mask aligned with a Point_Array's index range usage
   --  via a dense Boolean vector over 1 .. Max_Points (unused slots False).
   type Inlier_Mask is array (Point_Index) of Boolean
     with Default_Component_Value => False;

   type Index_Array is array (Point_Index range <>) of Point_Index;

   type RANSAC_Config is record
      Max_Iterations     : Positive := 100;
      Distance_Threshold : Positive_Real := 0.5;  -- t
      Min_Inliers        : Natural := 0;            -- d (0 = any consensus)
      Confidence         : Real := 0.99;            -- p in (0,1)
      Seed               : Natural := 1;
      Refit_On_Inliers   : Boolean := True;
      Use_MSAC_Score     : Boolean := True;         -- MSAC-lite tie-break
      Adaptive_Stop      : Boolean := False;        -- shrink N from inlier ratio
   end record;

   type RANSAC_Line_Result is record
      Model           : Line2 := (0.0, 0.0, 0.0);
      Inlier_Count    : Natural := 0;
      Inliers         : Inlier_Mask;
      Iterations_Used : Natural := 0;
      Score           : Real := Real'Last;  -- lower better (MSAC / -count)
      Success         : Boolean := False;
   end record;

   type RANSAC_Circle_Result is record
      Model           : Circle2 := ((0.0, 0.0), 0.0);
      Inlier_Count    : Natural := 0;
      Inliers         : Inlier_Mask;
      Iterations_Used : Natural := 0;
      Score           : Real := Real'Last;
      Success         : Boolean := False;
   end record;

   --  Deterministic seeded RNG (xorshift32-style LCG hybrid).
   type Seeded_RNG is private;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;
   Did_Not_Converge    : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Points closer than this are treated as duplicates / degenerate.
   Degenerate_Dist : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist2 (P, Q : Point2) return Non_Negative
     with Global => null;
   --  Euclidean distance between two points.

   function Squared_Dist2 (P, Q : Point2) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG
   ---------------------------------------------------------------------------

   function Make_RNG (Seed : Natural) return Seeded_RNG
     with Global => null;
   --  Seed 0 is remapped to a non-zero internal state.

   procedure Next_Natural
     (Rng : in out Seeded_RNG; Value : out Natural)
     with Global => null;
   --  Uniform in 0 .. 2**31-1 (non-negative 31-bit).

   function Next_Index
     (Rng : in out Seeded_RNG; Lo, Hi : Point_Index) return Point_Index
     with Pre => Lo <= Hi, Global => null;
   --  Uniform index in Lo .. Hi inclusive.

   ---------------------------------------------------------------------------
   -- Config helpers
   ---------------------------------------------------------------------------

   function Make_Config
     (Max_Iterations     : Positive := 100;
      Distance_Threshold : Positive_Real := 0.5;
      Min_Inliers        : Natural := 0;
      Confidence         : Real := 0.99;
      Seed               : Natural := 1;
      Refit_On_Inliers   : Boolean := True;
      Use_MSAC_Score     : Boolean := True;
      Adaptive_Stop      : Boolean := False) return RANSAC_Config
     with Pre => Confidence > 0.0 and then Confidence < 1.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Line geometry
   ---------------------------------------------------------------------------

   function Normalize_Line (L : Line2) return Line2
     with Global => null;
   --  Scale so sqrt(A²+B²)=1; raises Degenerate_Geometry if ||(A,B)||≈0.

   function Fit_Line_From_Two_Points (P, Q : Point2) return Line2
     with Global => null;
   --  Unique line through P and Q (normalized). Raises Degenerate_Geometry
   --  if P and Q are nearly identical.

   function Fit_Line_Least_Squares (Points : Point_Array) return Line2
     with Pre => Points'Length >= 2, Global => null;
   --  Orthogonal / total LS via covariance PCA (best-fit geometric line).
   --  Fragile baseline: outliers pull the fit. Raises Invalid_Argument /
   --  Degenerate_Geometry as needed.

   function Point_Line_Distance (P : Point2; L : Line2) return Non_Negative
     with Global => null;
   --  Unsigned geometric distance |ax+by+c| / sqrt(a²+b²).

   function Is_Degenerate_Sample (P, Q : Point2) return Boolean
     with Global => null;
   --  True if Dist2(P,Q) < Degenerate_Dist.

   function Count_Line_Inliers
     (Points    : Point_Array;
      Model     : Line2;
      Threshold : Positive_Real) return Natural
     with Global => null;

   procedure Collect_Line_Inliers
     (Points    : Point_Array;
      Model     : Line2;
      Threshold : Positive_Real;
      Mask      : out Inlier_Mask;
      Count     : out Natural)
     with Global => null;

   function Line_MSAC_Score
     (Points    : Point_Array;
      Model     : Line2;
      Threshold : Positive_Real) return Real
     with Global => null;
   --  MSAC-lite: sum of min(dist², t²) over all points (lower is better).

   function Fit_Line_Least_Squares_Masked
     (Points : Point_Array; Mask : Inlier_Mask; Count : Natural) return Line2
     with Pre => Count >= 2, Global => null;
   --  LS refit using only masked inliers.

   ---------------------------------------------------------------------------
   -- Circle geometry
   ---------------------------------------------------------------------------

   function Fit_Circle_From_Three_Points
     (P, Q, R : Point2) return Circle2
     with Global => null;
   --  Circumcircle of triangle PQR. Raises Degenerate_Geometry if
   --  points are collinear / coincident.

   function Point_Circle_Distance
     (P : Point2; C : Circle2) return Non_Negative
     with Global => null;
   --  | ||P-Center|| − Radius |.

   function Count_Circle_Inliers
     (Points    : Point_Array;
      Model     : Circle2;
      Threshold : Positive_Real) return Natural
     with Global => null;

   procedure Collect_Circle_Inliers
     (Points    : Point_Array;
      Model     : Circle2;
      Threshold : Positive_Real;
      Mask      : out Inlier_Mask;
      Count     : out Natural)
     with Global => null;

   function Circle_MSAC_Score
     (Points    : Point_Array;
      Model     : Circle2;
      Threshold : Positive_Real) return Real
     with Global => null;

   function Fit_Circle_Least_Squares_Masked
     (Points : Point_Array; Mask : Inlier_Mask; Count : Natural) return Circle2
     with Pre => Count >= 3, Global => null;
   --  Algebraic circle fit (Kåsa) on masked inliers.

   ---------------------------------------------------------------------------
   -- Iteration estimate (Wikipedia)
   ---------------------------------------------------------------------------

   function Estimate_Iterations
     (Inlier_Ratio : Real;
      Sample_Size  : Positive;
      Confidence   : Real) return Natural
     with Pre => Inlier_Ratio >= 0.0
       and then Inlier_Ratio <= 1.0
       and then Confidence > 0.0
       and then Confidence < 1.0,
          Global => null;
   --  N = ceil( log(1-p) / log(1-w^s) ). Edge cases: w=1 → 1; w≈0 → large.

   ---------------------------------------------------------------------------
   -- RANSAC drivers
   ---------------------------------------------------------------------------

   function RANSAC_Fit_Line
     (Points : Point_Array; Config : RANSAC_Config) return RANSAC_Line_Result
     with Pre => Points'Length >= 2, Global => null;
   --  Classic RANSAC for 2-D lines (minimal sample = 2). Same Seed + Points
   --  ⇒ same result. Raises Invalid_Argument if Length < 2.

   function RANSAC_Fit_Circle
     (Points : Point_Array; Config : RANSAC_Config) return RANSAC_Circle_Result
     with Pre => Points'Length >= 3, Global => null;
   --  RANSAC for 2-D circles (minimal sample = 3 non-collinear).

private

   type U32 is mod 2 ** 32;

   type Seeded_RNG is record
      State : U32 := 1;
   end record;

end RANSAC;
