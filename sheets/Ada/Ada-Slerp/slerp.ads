--  Slerp: Spherical Linear Interpolation and Variants
--  Specification according to ISO/IEC 8652:2023 (Ada 2023)

with Ada.Numerics.Generic_Elementary_Functions;

package Slerp is

   type Real is digits 15;

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   --  Interpolation factor constrained to unit interval [0.0, 1.0]
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  3D Vector type for geometric slerp and Cartesian operations
   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   --  Unit Quaternion type (w + x*i + y*j + z*k) representing 3D rotations
   type Quaternion is record
      W : Real := 1.0;
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   --  Array of quaternions for cubic spline interpolation (Squad)
   type Quaternion_Array is array (Positive range <>) of Quaternion;

   --  Exceptions
   Degenerate_Vector_Error : exception;
   Degenerate_Quaternion_Error : exception;
   Zero_Angle_Division_Error : exception;
   Invalid_Argument_Error : exception;

   --  Tolerance for float comparisons and zero-checks
   Epsilon : constant Real := 1.0e-7;

   ----------------------------------------------------------------------
   -- Vector Operations & Predicates
   ----------------------------------------------------------------------

   function Dot (U, V : Vector_3D) return Real with
     Global => null;

   function Norm_Squared (V : Vector_3D) return Real with
     Global => null;

   function Norm (V : Vector_3D) return Real with
     Global => null,
     Post => Norm'Result >= 0.0;

   function Is_Normalized (V : Vector_3D; Tol : Real := 1.0e-5) return Boolean with
     Global => null;

   function Normalize (V : Vector_3D) return Vector_3D with
     Global => null,
     Pre  => Norm_Squared (V) > 0.0,
     Post => Is_Normalized (Normalize'Result);

   ----------------------------------------------------------------------
   -- Quaternion Operations & Predicates
   ----------------------------------------------------------------------

   function Dot (P, Q : Quaternion) return Real with
     Global => null;

   function Norm_Squared (Q : Quaternion) return Real with
     Global => null;

   function Norm (Q : Quaternion) return Real with
     Global => null,
     Post => Norm'Result >= 0.0;

   function Is_Normalized (Q : Quaternion; Tol : Real := 1.0e-5) return Boolean with
     Global => null;

   function Normalize (Q : Quaternion) return Quaternion with
     Global => null,
     Pre  => Norm_Squared (Q) > 0.0,
     Post => Is_Normalized (Normalize'Result);

   function Conjugate (Q : Quaternion) return Quaternion with
     Global => null;

   function Inverse (Q : Quaternion) return Quaternion with
     Global => null,
     Pre  => Norm_Squared (Q) > 0.0;

   function Multiply (P, Q : Quaternion) return Quaternion with
     Global => null;

   function Log (Q : Quaternion) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (Q);

   function Exp (Q : Quaternion) return Quaternion with
     Global => null;

   function Power (Q : Quaternion; T : Real) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (Q);

   ----------------------------------------------------------------------
   -- Geometric Slerp (Generic N-D / 3D Unit Vectors)
   ----------------------------------------------------------------------

   --  Standard geometric Slerp between two unit vectors:
   --  Slerp(p0, p1; t) = (sin((1-t)*omega)/sin(omega))*p0 + (sin(t*omega)/sin(omega))*p1
   function Geometric_Slerp
     (P0, P1 : Vector_3D;
      T      : Unit_Interval) return Vector_3D with
     Global => null,
     Pre  => Is_Normalized (P0) and then Is_Normalized (P1),
     Post => Is_Normalized (Geometric_Slerp'Result);

   ----------------------------------------------------------------------
   -- Quaternion Slerp Variants
   ----------------------------------------------------------------------

   --  Basic (unclamped angle) Quaternion Slerp without shortest-path inversion
   function Raw_Quaternion_Slerp
     (Q0, Q1 : Quaternion;
      T      : Unit_Interval) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (Q0) and then Is_Normalized (Q1),
     Post => Is_Normalized (Raw_Quaternion_Slerp'Result);

   --  Shortest-path Quaternion Slerp: inverts Q1 if Dot(Q0, Q1) < 0 to
   --  traverse the acute arc on SO(3).
   function Shortest_Path_Slerp
     (Q0, Q1 : Quaternion;
      T      : Unit_Interval) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (Q0) and then Is_Normalized (Q1),
     Post => Is_Normalized (Shortest_Path_Slerp'Result);

   --  Normalized Linear Interpolation (Nlerp): faster approximation
   --  Shortest-path variant ensuring constant sign.
   function Nlerp
     (Q0, Q1 : Quaternion;
      T      : Unit_Interval) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (Q0) and then Is_Normalized (Q1),
     Post => Is_Normalized (Nlerp'Result);

   ----------------------------------------------------------------------
   -- Spherical Quadrangle (Squad) for C1 Continuous Splines
   ----------------------------------------------------------------------

   --  Computes intermediate control point s_i given q_{i-1}, q_i, q_{i+1}
   function Compute_Squad_Intermediate
     (Q_Prev, Q_Curr, Q_Next : Quaternion) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (Q_Prev) and then
             Is_Normalized (Q_Curr) and then
             Is_Normalized (Q_Next),
     Post => Is_Normalized (Compute_Squad_Intermediate'Result);

   --  Squad interpolation step:
   --  Squad(p, a, b, q; t) = Slerp(Slerp(p, q; t), Slerp(a, b; t); 2t(1-t))
   function Squad
     (P, A, B, Q : Quaternion;
      T          : Unit_Interval) return Quaternion with
     Global => null,
     Pre  => Is_Normalized (P) and then
             Is_Normalized (A) and then
             Is_Normalized (B) and then
             Is_Normalized (Q),
     Post => Is_Normalized (Squad'Result);

end Slerp;
