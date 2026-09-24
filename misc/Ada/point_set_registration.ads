--  Point_Set_Registration — Ada 2023 educational package for rigid
--  point-set / point-cloud registration in 2-D: known-correspondence
--  Kabsch-style closed-form fit (SVD-free via atan2 of cross/dot
--  covariance sums) and a small ICP sketch with nearest-neighbour
--  correspondences. Primary source:
--  https://en.wikipedia.org/wiki/Point_set_registration
--  Sibling packages (README only; do not `with`):
--    Ada-Kabsch, Ada-Shoelace-Algorithm, Ada-Rotating-Calipers /
--    Ada-Point-In-Polygon (ahead) — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Point_Set_Registration
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on points in a cloud.
   Max_Points : constant Positive := 64;

   --  Soft classroom limit on ICP outer iterations.
   Max_Iters : constant Positive := 16;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;
   subtype Iter_Count  is Natural range 0 .. Max_Iters;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Ordered point cloud (dense indices; length ='Length).
   type Point_Array is array (Point_Index range <>) of Point;

   --  Educational alias.
   subtype Point_Cloud is Point_Array;

   --  2×2 matrix stored as M (Row, Col), 1-based.
   type Mat2 is array (1 .. 2, 1 .. 2) of Real;

   --  Rigid transform in SE(2): p ↦ R p + T.
   --  Angle (radians) is the educational primary parametrization;
   --  Rotation is the equivalent SO(2) matrix [[c,-s],[s,c]].
   type Rigid_Transform is record
      Angle      : Real := 0.0;
      Translation : Point := (X => 0.0, Y => 0.0);
      Rotation    : Mat2 :=
        [1 => [1.0, 0.0],
         2 => [0.0, 1.0]];
   end record;

   --  Result of a correspondence-based or ICP registration.
   type Registration_Result is record
      Transform : Rigid_Transform;
      RMSE      : Real := 0.0;
      Residual  : Real := 0.0;  --  sum of squared errors (SSE)
      Iters     : Iter_Count := 0;
      N         : Point_Count := 0;
   end record;

   --  Correspondence index: Target (I) ↔ Source (Correspondences (I)).
   --  For Register_Correspondences, identity pairing is assumed
   --  (Source (I) ↔ Target (I)). For ICP, Correspondences (I) is the
   --  nearest-neighbour index in Target for transformed Source (I).
   type Index_Array is array (Point_Index range <>) of Point_Index;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when a point set is empty, lengths exceed Max_Points, source
   --  and target lengths mismatch for correspondence registration, or
   --  Max_Iters / capacity bounds are violated.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist2 (A, B : Point) return Real
     with Global => null;
   --  Squared Euclidean distance (B − A)·(B − A).

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance ‖B − A‖₂.

   ---------------------------------------------------------------------------
   -- Geometry building blocks
   ---------------------------------------------------------------------------

   function Centroid (Cloud : Point_Array) return Point
     with Global => null;
   --  Arithmetic mean of the points.
   --  Raises Invalid_Argument if Cloud'Length = 0 or > Max_Points.

   function Identity_Transform return Rigid_Transform
     with Global => null;
   --  Angle = 0, Translation = (0,0), Rotation = I₂.

   function Make_Transform (Angle : Real; Translation : Point)
     return Rigid_Transform
     with Global => null;
   --  Build SE(2) from angle (radians) and translation; fills Rotation.

   function Apply_Transform
     (T : Rigid_Transform; P : Point) return Point
     with Global => null;
   --  p ↦ R p + Translation.

   function Apply_Transform
     (T : Rigid_Transform; Cloud : Point_Array) return Point_Array
     with Global => null;
   --  Apply to every point. Raises Invalid_Argument if length = 0 or
   --  > Max_Points.

   function Rotation_Of (Angle : Real) return Mat2
     with Global => null;
   --  SO(2) matrix [[cos θ, −sin θ], [sin θ, cos θ]].

   function Mat2_Vec (M : Mat2; P : Point) return Point
     with Global => null;
   --  2×2 matrix–vector product.

   ---------------------------------------------------------------------------
   -- Residuals
   ---------------------------------------------------------------------------

   function Sum_Squared_Error
     (Source, Target : Point_Array) return Real
     with Global => null;
   --  Σ ‖Source(I) − Target(I)‖² for paired clouds of equal length.
   --  Raises Invalid_Argument on empty, overflow, or length mismatch.

   function RMSE (Source, Target : Point_Array) return Real
     with Global => null;
   --  √(SSE / N). Same validation as Sum_Squared_Error.

   function Sum_Squared_Error
     (Source, Target : Point_Array; T : Rigid_Transform) return Real
     with Global => null;
   --  Σ ‖T(Source(I)) − Target(I)‖².

   function RMSE
     (Source, Target : Point_Array; T : Rigid_Transform) return Real
     with Global => null;
   --  √(SSE(T) / N).

   ---------------------------------------------------------------------------
   -- Known-correspondence rigid registration (2-D Kabsch-style)
   ---------------------------------------------------------------------------
   --  Given paired clouds Source(I) ↔ Target(I), estimate the rigid map
   --  T that best aligns Source onto Target in the least-squares sense:
   --
   --    1. μ_S = Centroid(Source), μ_T = Centroid(Target)
   --    2. Center: s'_i = s_i − μ_S, t'_i = t_i − μ_T
   --    3. Covariance sums (SVD-free 2-D closed form):
   --         Dot   = Σ (s'_x t'_x + s'_y t'_y)
   --         Cross = Σ (s'_x t'_y − s'_y t'_x)
   --         θ     = atan2(Cross, Dot)
   --    4. R = Rotation_Of(θ),  Translation = μ_T − R μ_S
   --
   --  Equivalent to the Kabsch / orthogonal Procrustes solution on SO(2)
   --  (proper rotations only; no reflection / Umeyama scale in this sketch).

   function Register_Correspondences
     (Source, Target : Point_Array) return Registration_Result
     with Global => null;
   --  Raises Invalid_Argument if either cloud is empty, length >
   --  Max_Points, or Source'Length ≠ Target'Length.

   ---------------------------------------------------------------------------
   -- ICP sketch (nearest-neighbour + iterated rigid fit)
   ---------------------------------------------------------------------------
   --  Educational ICP (Besl & McKay style):
   --    for k = 1 .. Max_Steps:
   --      for each transformed source point, find nearest target point
   --      fit Register_Correspondences on those pairs
   --      compose / apply the incremental rigid map
   --      stop early if RMSE improvement < Tol
   --  Works best when Source is already roughly posed near Target.
   --  Max_Points ≤ 64; Max_Steps ≤ Max_Iters (default small).

   function Nearest_Index
     (Query : Point; Cloud : Point_Array) return Point_Index
     with Global => null;
   --  Index of the closest point in Cloud to Query (first on ties).
   --  Raises Invalid_Argument if Cloud is empty or > Max_Points.

   function Register_ICP
     (Source, Target : Point_Array;
      Max_Steps      : Positive := 8;
      Tol            : Real := 1.0E-6) return Registration_Result
     with Global => null;
   --  ICP with centroid-alignment warm-start (then identity rotation).
   --  Raises Invalid_Argument if either cloud is empty, length >
   --  Max_Points, or Max_Steps > Max_Iters. Source and Target need not
   --  have equal length (classic ICP).

end Point_Set_Registration;
