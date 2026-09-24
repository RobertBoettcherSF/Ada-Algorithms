--  Cone_Algorithm — Ada 2023 educational package for the 3-D cone
--  algorithm that identifies surface particles in a discrete cluster.
--  Primary sources:
--    https://en.wikipedia.org/wiki/Cone_algorithm
--    Yanting Wang, S. Teitel, and Christoph Dellago (2005),
--    J. Chem. Phys. 122, 214722.
--  Sibling packages (README only; do not `with`):
--    Ada-Barnes-Hut, Ada-Bowyer-Watson, Ada-Geometric-Hashing,
--    Ada-Chans-Algorithm — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Cone_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on particle positions.
   Max_Points : constant Positive := 64;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   --  3-D particle position.
   type Point is record
      X, Y, Z : Real := 0.0;
   end record;

   --  Dense unordered particle set (length = 'Length).
   type Point_Array is array (Positive range <>) of Point;

   --  Educational alias.
   subtype Particle_Set is Point_Array;

   --  Per-particle surface / bulk mask aligned with a Point_Array slice.
   type Boolean_Array is array (Positive range <>) of Boolean;

   --  Indices of surface particles (1-based into the input array bounds).
   type Index_Array is array (Positive range <>) of Positive;

   --  π and π/2 for half-angle validation / classroom defaults.
   Pi     : constant Real := 3.141_592_653_589_793;
   Half_Pi : constant Real := Pi / 2.0;

   --  Suggested classroom defaults (unit-spacing lattices).
   Default_Cutoff     : constant Real := 1.8;
   Default_Half_Angle : constant Real := Pi / 4.0;  -- 45°

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when the point set is empty, length > Max_Points, Index is
   --  outside Points'Range, Cutoff ≤ 0, or Half_Angle ∉ (0, π/2].

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
   --  Squared Euclidean distance ‖B − A‖₂².

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance ‖B − A‖₂.

   function Dot (A, B : Point) return Real
     with Global => null;
   --  Dot product A · B.

   function Cross (A, B : Point) return Point
     with Global => null;
   --  Cross product A × B.

   function Norm2 (V : Point) return Real
     with Global => null;
   --  ‖V‖₂².

   function Norm (V : Point) return Real
     with Global => null;
   --  ‖V‖₂.

   function Normalize (V : Point) return Point
     with Global => null;
   --  Unit vector V / ‖V‖. Returns (0,0,0) if ‖V‖ < Epsilon.

   function Sub (A, B : Point) return Point
     with Global => null;
   --  A − B.

   function Add (A, B : Point) return Point
     with Global => null;
   --  A + B.

   function Scale (V : Point; S : Real) return Point
     with Global => null;
   --  S · V.

   ---------------------------------------------------------------------------
   -- Cone algorithm (3-D empty-cone surface test)
   ---------------------------------------------------------------------------
   --  A particle i is a *surface* particle if there exists a unit direction
   --  û such that every neighbor j with 0 < ‖p_j − p_i‖ ≤ Cutoff lies
   --  *outside* the cone of half-angle θ = Half_Angle about û:
   --
   --      û · u_j  <  cos(θ)    for all neighbor unit vectors u_j.
   --
   --  Equivalently: an empty (hollow) cone of side length Cutoff and
   --  opening half-angle θ points from i into free space. Particles with
   --  no neighbors inside the cutoff are surface by definition.
   --
   --  Classroom direction search (Max_Points ≤ 64): try the outward mean
   --  −normalize(∑ u_j), −u_j for each neighbor, −normalize(u_a+u_b) for
   --  neighbor pairs, and a fixed set of 26 cube-axis / face-diagonal /
   --  space-diagonal sample directions.

   function Is_Surface_Particle
     (Points     : Point_Array;
      Index      : Positive;
      Cutoff     : Real;
      Half_Angle : Real) return Boolean
     with Global => null;
   --  True iff particle Points(Index) is a surface particle under the
   --  empty-cone test. Raises Invalid_Argument on empty / oversized sets,
   --  Index ∉ Points'Range, Cutoff ≤ 0, or Half_Angle ∉ (0, π/2].

   function Surface_Mask
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Boolean_Array
     with Global => null;
   --  Boolean mask M with M'Range = Points'Range; M(I) = True iff
   --  Is_Surface_Particle (Points, I, Cutoff, Half_Angle). Same validation.

   function Count_Surface
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Point_Count
     with Global => null;
   --  Number of surface particles. Same validation.

   function Extract_Surface
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Point_Array
     with Global => null;
   --  Positions of surface particles, in input order. Same validation.

   function Extract_Surface_Indices
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Index_Array
     with Global => null;
   --  Indices (into Points'Range) of surface particles, in ascending
   --  order. Same validation.

   ---------------------------------------------------------------------------
   -- Teaching oracle — neighbor-asymmetry surface proxy
   ---------------------------------------------------------------------------
   --  Optional classroom alternative (documented in the README): mark a
   --  particle as surface when the magnitude of the sum of unit vectors
   --  to neighbors exceeds Asymmetry_Threshold (asymmetric neighborhood
   --  ⇒ exposed). Particles with no neighbors are surface. Not used by
   --  the primary empty-cone API; exposed for comparison / labs.

   function Is_Surface_By_Asymmetry
     (Points              : Point_Array;
      Index               : Positive;
      Cutoff              : Real;
      Asymmetry_Threshold : Real) return Boolean
     with Global => null;
   --  Raises Invalid_Argument on empty / oversized sets, bad Index,
   --  Cutoff ≤ 0, or Asymmetry_Threshold < 0.

end Cone_Algorithm;
