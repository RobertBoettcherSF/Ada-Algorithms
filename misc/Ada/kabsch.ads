--  Kabsch — Ada 2023 educational package for the Kabsch / Kabsch–Umeyama
--  algorithm: optimal rotation (and rigid superimposition) minimizing RMSD
--  between two paired 3-D point clouds. Self-contained 3×3 SVD via Jacobi
--  eigen-decomposition of HᵀH. Based on Wikipedia "Kabsch algorithm".

pragma Ada_2022;

package Kabsch
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   --  Educational dense bound (point clouds up to Max_N points).
   Max_N : constant Positive := 256;

   subtype Dim_N is Natural range 0 .. Max_N;
   subtype Index_N is Positive range 1 .. Max_N;

   --  3-D Cartesian vector (X, Y, Z).
   type Vec3 is array (1 .. 3) of Real;

   --  Point cloud: N points in R^3 (design-matrix view is N × 3).
   type Point_Cloud is array (Index_N range <>) of Vec3;

   --  Dense 3 × 3 matrix stored as A (I, J), 1-based.
   type Mat3 is array (1 .. 3, 1 .. 3) of Real;

   --  Optional 2-D helpers (XY plane).
   type Vec2 is array (1 .. 2) of Real;
   type Mat2 is array (1 .. 2, 1 .. 2) of Real;
   type Point_Cloud_2D is array (Index_N range <>) of Vec2;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Degenerate       : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;
   Jacobi_Tol  : constant Real := 1.0E-14;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Vec3 (A, B : Vec3; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Mat3 (A, B : Mat3; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dot (A, B : Vec3) return Real
     with Global => null;

   function Norm2 (V : Vec3) return Non_Negative
     with Global => null;

   function Norm (V : Vec3) return Non_Negative
     with Global => null;

   function Cross (A, B : Vec3) return Vec3
     with Global => null;

   ---------------------------------------------------------------------------
   -- Matrix helpers
   ---------------------------------------------------------------------------

   function Zero_Mat3 return Mat3
     with Global => null;

   function Identity_Mat3 return Mat3
     with Global => null;

   function Mat3_Transpose (A : Mat3) return Mat3
     with Global => null;

   function Mat3_Mul (A, B : Mat3) return Mat3
     with Global => null;

   function Mat3_Vec (A : Mat3; V : Vec3) return Vec3
     with Global => null;

   function Mat3_Det (A : Mat3) return Real
     with Global => null;

   function Mat3_Trace (A : Mat3) return Real
     with Global => null;

   function Mat3_Frobenius (A : Mat3) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Centroid / centering / covariance
   ---------------------------------------------------------------------------

   function Centroid (P : Point_Cloud) return Vec3
     with Pre => P'Length >= 1, Global => null;

   function Translate_To_Origin (P : Point_Cloud) return Point_Cloud
     with Pre => P'Length >= 1, Global => null;
   --  Subtract the cloud centroid from every point.

   function Translate_By (P : Point_Cloud; T : Vec3) return Point_Cloud
     with Pre => P'Length >= 1, Global => null;
   --  Add T to every point.

   function Covariance_H (P, Q : Point_Cloud) return Mat3
     with Pre => P'Length = Q'Length
                 and then P'Length >= 1,
          Global => null;
   --  H = Pᵀ Q for *already centered* clouds (cross-covariance, 3 × 3).

   ---------------------------------------------------------------------------
   -- 3 × 3 SVD (Jacobi on AᵀA)
   ---------------------------------------------------------------------------

   type Singular_Values is array (1 .. 3) of Non_Negative;

   procedure SVD_3x3
     (A  : Mat3;
      U  : out Mat3;
      S  : out Singular_Values;
      Vt : out Mat3)
     with Global => null;
   --  Factor A = U diag(S) Vt with U, Vt orthogonal (Vt = Vᵀ).
   --  Singular values sorted descending. Self-contained Jacobi eigen of AᵀA.

   ---------------------------------------------------------------------------
   -- Kabsch rotation / RMSD / superimpose
   ---------------------------------------------------------------------------

   function Kabsch_Rotation (P, Q : Point_Cloud) return Mat3
     with Pre => P'Length = Q'Length
                 and then P'Length >= 1,
          Global => null;
   --  Optimal rotation R mapping centered Q onto centered P:
   --  R = U S Vᵀ from SVD(H), H = PᵀQ, S = diag(1,1,d) with d = ±1 so
   --  det(R) = +1 (proper rotation; reflection corrected).

   function Apply_Rotation (R : Mat3; P : Point_Cloud) return Point_Cloud
     with Pre => P'Length >= 1, Global => null;

   function Apply_Rotation_Vec (R : Mat3; V : Vec3) return Vec3
     with Global => null;

   function RMSD (P, Q : Point_Cloud) return Non_Negative
     with Pre => P'Length = Q'Length
                 and then P'Length >= 1,
          Global => null;
   --  Root-mean-square deviation of paired points (no alignment).

   type Superimpose_Result is record
      R           : Mat3 := Identity_Mat3;
      Translation : Vec3 := [0.0, 0.0, 0.0];
      --  Rigid map: q ↦ R q + Translation  (Translation = cP − R cQ).
      RMSD        : Non_Negative := 0.0;
      Centroid_P  : Vec3 := [0.0, 0.0, 0.0];
      Centroid_Q  : Vec3 := [0.0, 0.0, 0.0];
   end record;

   function Superimpose (P, Q : Point_Cloud) return Superimpose_Result
     with Pre => P'Length = Q'Length
                 and then P'Length >= 1,
          Global => null;
   --  Full rigid alignment of Q onto P: centers, Kabsch rotation, RMSD.

   function Transformed_Cloud
     (Q : Point_Cloud; Res : Superimpose_Result) return Point_Cloud
     with Pre => Q'Length >= 1, Global => null;
   --  Apply Res.R and Res.Translation to every point of Q.

   ---------------------------------------------------------------------------
   -- Optional 2-D Kabsch (XY)
   ---------------------------------------------------------------------------

   function Centroid_2D (P : Point_Cloud_2D) return Vec2
     with Pre => P'Length >= 1, Global => null;

   function Kabsch_Rotation_2D (P, Q : Point_Cloud_2D) return Mat2
     with Pre => P'Length = Q'Length
                 and then P'Length >= 1,
          Global => null;
   --  Optimal 2-D rotation (det = +1) mapping centered Q onto centered P.

   function Mat2_Det (A : Mat2) return Real
     with Global => null;

   function Mat2_Mul_Vec (A : Mat2; V : Vec2) return Vec2
     with Global => null;

   function Identity_Mat2 return Mat2
     with Global => null;

   function RMSD_2D (P, Q : Point_Cloud_2D) return Non_Negative
     with Pre => P'Length = Q'Length
                 and then P'Length >= 1,
          Global => null;

end Kabsch;
