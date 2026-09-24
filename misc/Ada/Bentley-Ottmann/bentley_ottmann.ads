--  Bentley_Ottmann — Ada 2023 educational package for the Bentley–Ottmann
--  sweep-line algorithm that reports all proper intersections among a set
--  of planar line segments. Extends the Shamos–Hoey detection idea (early
--  exit when any crossing exists). Primary source:
--  https://en.wikipedia.org/wiki/Bentley–Ottmann_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Sweep-And-Prune, Ada-Point-In-Polygon, Ada-Minimum-Bounding-Box,
--    Ada-Line-Segment-Intersection (survey, ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Bentley_Ottmann
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on input segments.
   Max_Segments : constant Positive := 32;

   --  Worst-case proper crossings among n segments is n(n−1)/2; pad a little.
   Max_Intersections : constant Positive :=
     Max_Segments * (Max_Segments - 1) / 2;

   --  Event-queue capacity: 2n endpoints + up to Max_Intersections crossings.
   Max_Events : constant Positive :=
     2 * Max_Segments + Max_Intersections;

   subtype Segment_Count is Natural range 0 .. Max_Segments;
   subtype Segment_Index is Positive range 1 .. Max_Segments;
   subtype Intersection_Count is Natural range 0 .. Max_Intersections;
   subtype Event_Count is Natural range 0 .. Max_Events;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Closed geometric segment from A to B (endpoints inclusive).
   --  Proper intersection reporting requires an interior crossing of the
   --  relative interiors; shared endpoints alone are not reported.
   type Segment is record
      A, B : Point := (X => 0.0, Y => 0.0);
   end record;

   type Segment_Array is array (Positive range <>) of Segment;

   --  Educational alias for an unordered finite segment set.
   subtype Segment_Set is Segment_Array;

   ---------------------------------------------------------------------------
   -- Intersection records / result lists
   ---------------------------------------------------------------------------

   --  One reported proper crossing: geometric point + the two segment
   --  indices in the caller's Segment_Set (1-based, I < J when possible).
   type Intersection is record
      Location : Point := (X => 0.0, Y => 0.0);
      Seg_I    : Segment_Index := 1;
      Seg_J    : Segment_Index := 1;
   end record;

   type Intersection_Array is array (Positive range <>) of Intersection;

   type Intersection_List is record
      Items : Intersection_Array (1 .. Max_Intersections) :=
        [others => (Location => (0.0, 0.0), Seg_I => 1, Seg_J => 1)];
      Count : Intersection_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Event / status vocabulary (educational exposure of the sweep sketch)
   ---------------------------------------------------------------------------

   type Event_Kind is (Left_Endpoint, Crossing, Right_Endpoint);

   --  One discrete sweep event. For endpoint events Seg_A is the segment
   --  and Seg_B is unused (set equal to Seg_A). For Crossing events both
   --  Seg_A and Seg_B identify the crossing pair (Seg_A < Seg_B).
   type Event is record
      Kind  : Event_Kind := Left_Endpoint;
      Loc    : Point := (X => 0.0, Y => 0.0);
      Seg_A : Segment_Index := 1;
      Seg_B : Segment_Index := 1;
   end record;

   type Event_Array is array (Positive range <>) of Event;

   type Event_Queue is record
      Items : Event_Array (1 .. Max_Events) :=
        [others =>
           (Kind  => Left_Endpoint,
            Loc    => (0.0, 0.0),
            Seg_A => 1,
            Seg_B => 1)];
      Count : Event_Count := 0;
   end record;

   --  Sweep-line status: active segments ordered by y at the current
   --  sweep abscissa. Educational: a dense array, not a balanced BST.
   type Status_Array is array (1 .. Max_Segments) of Segment_Index;

   type Sweep_Status is record
      Active : Status_Array := [others => 1];
      Count  : Segment_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Segments'Length < 1 or > Max_Segments.

   ---------------------------------------------------------------------------
   -- Numeric / geometric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist2 (A, B : Point) return Real
     with Global => null;
   --  Squared Euclidean distance (B − A)·(B − A).

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B−A)×(C−A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function Left_Of (S : Segment) return Point
     with Global => null;
   --  Endpoint of S with smaller X (ties broken by smaller Y).

   function Right_Of (S : Segment) return Point
     with Global => null;
   --  Endpoint of S with larger X (ties broken by larger Y).

   function Y_At_X (S : Segment; X : Real) return Real
     with Global => null;
   --  Y-coordinate where the supporting line of S meets the vertical
   --  line at abscissa X. For a near-vertical segment returns the mean
   --  of the endpoint Y values (educational fallback).

   function Event_Before (E1, E2 : Event) return Boolean
     with Global => null;
   --  Sweep event order: smaller X first; on X-tie smaller Y; on point
   --  tie Left_Endpoint < Crossing < Right_Endpoint; finally Seg_A, Seg_B.

   ---------------------------------------------------------------------------
   -- Proper segment intersection
   ---------------------------------------------------------------------------
   --  Two segments properly intersect when their relative interiors cross
   --  at a unique point (strict opposite orientations on both sides).
   --  Shared endpoints, T-junctions at an endpoint, and overlapping
   --  collinear overlaps are NOT reported as proper intersections —
   --  limited educational handling of those degeneracies (documented in
   --  the README; production kernels use exact predicates / perturbation).

   function Segments_Properly_Intersect (S, T : Segment) return Boolean
     with Global => null;

   function Intersection_Point (S, T : Segment) return Point
     with Global => null;
   --  Parametric intersection of the supporting lines of S and T.
   --  Meaningful when Segments_Properly_Intersect (S, T) is True; for
   --  near-parallel inputs falls back to the midpoint of the closest
   --  approach (educational).

   ---------------------------------------------------------------------------
   -- Bentley–Ottmann reporting
   ---------------------------------------------------------------------------
   --  Sweep-line sketch (Bentley & Ottmann 1979 / de Berg et al.):
   --    1. Event queue Q of left/right endpoints (and discovered crossings),
   --       ordered by Event_Before.
   --    2. Status T: active segments ordered by Y_At_X at the current
   --       sweep abscissa (dense array; Max_Segments ≤ 32).
   --    3. Process events left→right: insert / delete / swap adjacent
   --       pairs; enqueue future crossings of newly adjacent pairs that
   --       lie strictly to the right of the sweep.
   --  Asymptotic classroom claim: O((n+k) log n) with a balanced status
   --  tree; this sketch uses O(n) status scans so total time is O((n+k)n)
   --  — fine for Max_Segments = 32.

   function Find_Intersections (Segments : Segment_Set) return Intersection_List
     with Global => null;
   --  All proper intersection points among Segments, each labelled with
   --  the unordered index pair (Seg_I < Seg_J). Raises Invalid_Argument
   --  if Segments'Length < 1 or > Max_Segments. Duplicate geometric
   --  points from distinct pairs are kept as separate records.

   function Intersection_Count_Of
     (Segments : Segment_Set) return Intersection_Count
     with Global => null;
   --  Count of Find_Intersections (Segments). Same validation.

   ---------------------------------------------------------------------------
   -- Shamos–Hoey-style early-exit detection (educational cousin)
   ---------------------------------------------------------------------------
   --  Same sweep as Find_Intersections, but returns as soon as the first
   --  proper crossing is discovered (Shamos & Hoey 1976 detection idea;
   --  this sheet skips a standalone Shamos–Hoey package). Still raises
   --  Invalid_Argument on empty / oversized input.

   function Any_Intersection (Segments : Segment_Set) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Brute-force oracle (teaching contrast)
   ---------------------------------------------------------------------------

   function Brute_Force_Intersections
     (Segments : Segment_Set) return Intersection_List
     with Global => null;
   --  O(n²) all-pairs Segments_Properly_Intersect. Same Invalid_Argument
   --  policy. Used by tests as an oracle for Find_Intersections.

   function Same_Intersection_Set
     (Left, Right : Intersection_List; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff Left and Right contain the same multiset of (near) points
   --  with matching unordered segment-index pairs (order-independent).

   ---------------------------------------------------------------------------
   -- Accessors / constructors
   ---------------------------------------------------------------------------

   function Empty_Intersection_List return Intersection_List
     with Global => null;

   function Make_Segment (Ax, Ay, Bx, By : Real) return Segment
     with Global => null;

   function Make_Point (X, Y : Real) return Point
     with Global => null;

end Bentley_Ottmann;
