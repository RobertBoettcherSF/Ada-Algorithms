--  Collision_Detection — Ada 2023 educational survey of discrete 2-D
--  collision detection: narrow-phase tests (AABB, circle, SAT for convex
--  polygons, segment intersection) and broad-phase pairing (brute force,
--  sweep-and-prune on AABB X-projections). Primary source:
--  https://en.wikipedia.org/wiki/Collision_detection
--  Sibling packages (README only; do not `with`):
--    Ada-Gilbert-Johnson-Keerthi (GJK narrow phase),
--    Ada-Sweep-And-Prune, Ada-Bentley-Ottmann —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Collision_Detection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   Max_Objects  : constant Positive := 64;
   Max_Vertices : constant Positive := 32;
   Max_Pairs    : constant Positive := 2_048;

   subtype Object_Id    is Positive range 1 .. Max_Objects;
   subtype Object_Count is Natural  range 0 .. Max_Objects;
   subtype Vertex_Count is Natural  range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   subtype Pair_Count   is Natural  range 0 .. Max_Pairs;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Axis-aligned box: closed intervals [Min.X, Max.X] × [Min.Y, Max.Y].
   --  Touching edges/corners count as overlapping (closed convention).
   type AABB is record
      Min, Max : Point := (0.0, 0.0);
   end record;

   type Circle is record
      Center : Point := (0.0, 0.0);
      Radius : Real  := 0.0;
   end record;

   --  Convex polygon vertices in counterclockwise (CCW) order (open ring).
   type Point_Array is array (Vertex_Index range <>) of Point;
   subtype Polygon is Point_Array;

   type AABB_Array   is array (Object_Id range <>) of AABB;
   type Circle_Array is array (Object_Id range <>) of Circle;

   --  Unordered candidate pair with canonical A < B.
   type Pair is record
      A, B : Object_Id := 1;
   end record;

   type Pair_Array is array (1 .. Max_Pairs) of Pair;

   type Pair_List is record
      Items : Pair_Array := [others => (1, 1)];
      Count : Pair_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised on empty/oversized inputs, negative radius, Max < Min AABB,
   --  polygon n < 3 for SAT, degenerate segments, etc.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dot (A, B : Point) return Real
     with Global => null;

   function Cross (A, B : Point) return Real
     with Global => null;
   --  2D cross A.X·B.Y − A.Y·B.X.

   function Sub (A, B : Point) return Point
     with Global => null;

   function Dist2 (A, B : Point) return Real
     with Global => null;

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  (B−A)×(C−A); >0 ⇒ C left of AB (CCW).

   ---------------------------------------------------------------------------
   -- Validation / constructors
   ---------------------------------------------------------------------------

   function Is_Valid_AABB (Box : AABB) return Boolean
     with Inline, Global => null;
   --  True iff Min.X <= Max.X and Min.Y <= Max.Y.

   function Is_Valid_Circle (C : Circle) return Boolean
     with Inline, Global => null;
   --  True iff Radius >= 0.

   function Make_AABB (Min_X, Min_Y, Max_X, Max_Y : Real) return AABB;
   --  Raises Invalid_Argument if Max < Min on either axis.

   function Make_Circle (Cx, Cy, Radius : Real) return Circle;
   --  Raises Invalid_Argument if Radius < 0.

   function Empty_Pair_List return Pair_List
     with Post => Empty_Pair_List'Result.Count = 0;

   procedure Clear (P : in out Pair_List)
     with Post => P.Count = 0;

   function Make_Pair (A, B : Object_Id) return Pair
     with Pre => A /= B,
          Post => Make_Pair'Result.A < Make_Pair'Result.B;

   function Contains_Pair (P : Pair_List; A, B : Object_Id) return Boolean
     with Pre => A /= B;

   procedure Append_Pair (P : in out Pair_List; A, B : Object_Id)
     with Pre => A /= B;
   --  Raises Invalid_Argument if pair capacity exceeded.

   procedure Normalize_Pairs (P : in out Pair_List);
   --  Sort by (A, B) and drop duplicates.

   function Same_Pair_Set (Left, Right : Pair_List) return Boolean;

   ---------------------------------------------------------------------------
   -- Narrow phase
   ---------------------------------------------------------------------------

   function AABB_Overlap (A, B : AABB) return Boolean;
   --  Closed overlap on both axes. Raises Invalid_Argument if either
   --  box is invalid (Max < Min).

   function Circle_Overlap
     (C1 : Point; R1 : Real; C2 : Point; R2 : Real) return Boolean;
   --  True iff ‖C1−C2‖² ≤ (R1+R2)² (closed; touching counts).
   --  Raises Invalid_Argument if R1 < 0 or R2 < 0.

   function Circle_Overlap (A, B : Circle) return Boolean;
   --  Convenience overload using Circle records.

   function Convex_Polygons_Overlap (A, B : Polygon) return Boolean;
   --  Separating Axis Theorem for convex polygons (CCW vertex order).
   --  Closed projections: touching edges/vertices count as overlapping.
   --  Raises Invalid_Argument if either polygon has n < 3 or n > Max_Vertices.

   function Segments_Intersect
     (P1, Q1, P2, Q2 : Point) return Boolean;
   --  Proper or improper intersection of closed segments P1Q1 and P2Q2.
   --  Collinear overlapping segments count as intersecting.
   --  Raises Invalid_Argument on zero-length (degenerate) either segment.

   ---------------------------------------------------------------------------
   -- Broad phase
   ---------------------------------------------------------------------------

   function Brute_Force_Pairs (Boxes : AABB_Array) return Pair_List;
   --  O(n²) AABB candidate pairs. Raises Invalid_Argument if empty,
   --  oversized (> Max_Objects), or any box invalid.

   function Brute_Force_Pairs (Circles : Circle_Array) return Pair_List;
   --  O(n²) circle candidate pairs (narrow test embedded).
   --  Raises Invalid_Argument if empty, oversized, or negative radius.

   function Sweep_And_Prune_Pairs (Boxes : AABB_Array) return Pair_List;
   --  Sort AABB intervals on X, sweep active set, confirm Y overlap.
   --  Same closed-overlap convention as AABB_Overlap.
   --  Raises Invalid_Argument if empty, oversized, or any box invalid.

   function Find_Colliding_AABBs (Boxes : AABB_Array) return Pair_List;
   --  Narrow AABB pairs via brute force (index pairs into Boxes).

   function Find_Colliding_Circles (Circles : Circle_Array) return Pair_List;
   --  Narrow circle pairs via brute force.

end Collision_Detection;
