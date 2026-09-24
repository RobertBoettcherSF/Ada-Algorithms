--  Closest_Pair_Problem — Ada 2023 educational package for the 2D
--  Euclidean closest-pair-of-points problem: O(n²) brute force and the
--  classic O(n log n) Shamos / Bentley–Shamos divide-and-conquer
--  (presort by X and Y, strip of width 2δ, ≤7 higher-Y neighbors).
--  Primary source:
--  https://en.wikipedia.org/wiki/Closest_pair_of_points_problem
--  Sibling packages (README only; do not `with`):
--    Ada-Nearest-Neighbor-Search, Ada-Collision-Detection,
--    Ada-Bentley-Ottmann, Ada-Graham-Scan, Ada-Quickhull —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Closest_Pair_Problem
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on input points.
   Max_Points : constant Positive := 64;

   subtype Point_Count is Natural  range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Unordered finite point set. Closest-pair routines copy into a dense
   --  1 .. n buffer (preserving encounter order for returned indices).
   type Point_Array is array (Positive range <>) of Point;

   --  Educational alias.
   subtype Point_Set is Point_Array;

   --  Closest-pair answer: 1-based indices into the dense 1 .. n copy of
   --  Points in encounter order (Points'First maps to 1), with Index_A <
   --  Index_B, plus Euclidean distance.
   type Pair_Result is record
      Index_A  : Point_Index := 1;
      Index_B  : Point_Index := 1;
      Distance : Real        := 0.0;
   end record;

   type Method_Kind is (Brute, Divide_Conquer);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Points'Length < 2 or > Max_Points.

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
   --  Squared Euclidean distance (B − A)·(B − A). Prefer for comparisons.

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance √Dist2 (A, B).

   ---------------------------------------------------------------------------
   -- Closest pair (2D Euclidean)
   ---------------------------------------------------------------------------
   --  Classical planar closest pair (Preparata–Shamos / Bentley–Shamos):
   --    1. Brute_Force: check all C(n,2) pairs — O(n²).
   --    2. Divide_And_Conquer: presort by X and Y; recurse left/right;
   --       δ = min(δL, δR); strip of width 2δ about the midline; for each
   --       strip point check the next ≤7 higher-Y neighbors (packing
   --       argument). Overall O(n log n).
   --  Both return a Pair_Result with Index_A < Index_B. Duplicate points
   --  yield Distance = 0. Educational floating arithmetic — adequate for
   --  well-separated classroom examples, not a production exact kernel.

   function Brute_Force (Points : Point_Array) return Pair_Result
     with Global => null;
   --  O(n²) all-pairs closest pair.
   --  Raises Invalid_Argument if Points'Length < 2 or > Max_Points.

   function Divide_And_Conquer (Points : Point_Array) return Pair_Result
     with Global => null;
   --  O(n log n) Shamos-style divide-and-conquer closest pair.
   --  Raises Invalid_Argument if Points'Length < 2 or > Max_Points.

   function Closest_Pair (Points : Point_Array) return Pair_Result
     with Global => null;
   --  Default entry: Divide_And_Conquer (Points).
   --  Raises Invalid_Argument if Points'Length < 2 or > Max_Points.

   function Closest_Pair
     (Points : Point_Array; Method : Method_Kind) return Pair_Result
     with Global => null;
   --  Explicit method dispatch.
   --  Raises Invalid_Argument if Points'Length < 2 or > Max_Points.

end Closest_Pair_Problem;
