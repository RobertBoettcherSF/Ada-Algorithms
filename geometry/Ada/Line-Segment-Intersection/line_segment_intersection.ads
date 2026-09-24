--  Line_Segment_Intersection — Ada 2023 educational survey of planar
--  line-segment intersection: Orient2D classification of proper /
--  improper / collinear-overlap cases, unique intersection points,
--  O(n²) all-pairs reporting, and a thin Bentley–Ottmann-style Find_All
--  for tiny classroom sets (Max_Segments ≤ 32). Primary sources:
--  https://en.wikipedia.org/wiki/Line_segment_intersection
--  https://en.wikipedia.org/wiki/Line–line_intersection
--  Sibling packages (README only; do not `with`):
--    Ada-Bentley-Ottmann, Ada-Sweep-And-Prune, Ada-Point-In-Polygon,
--    Ada-Minimum-Bounding-Box —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Line_Segment_Intersection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on input segments.
   Max_Segments : constant Positive := 32;

   --  Worst-case intersecting pairs among n segments is n(n−1)/2.
   Max_Intersections : constant Positive :=
     Max_Segments * (Max_Segments - 1) / 2;

   subtype Segment_Count is Natural range 0 .. Max_Segments;
   subtype Segment_Index is Positive range 1 .. Max_Segments;
   subtype Intersection_Count is Natural range 0 .. Max_Intersections;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Closed geometric segment from A to B (endpoints inclusive).
   type Segment is record
      A, B : Point := (X => 0.0, Y => 0.0);
   end record;

   type Segment_Array is array (Positive range <>) of Segment;

   --  Educational alias for an unordered finite segment set.
   subtype Segment_Set is Segment_Array;

   ---------------------------------------------------------------------------
   -- Classification vocabulary
   ---------------------------------------------------------------------------

   --  How two closed segments meet (educational taxonomy):
   --    None               — empty intersection
   --    Proper             — relative interiors cross at a unique interior
   --                         point (strict opposite Orient2D on both sides)
   --    Improper           — intersection is a unique point that involves
   --                         at least one endpoint (shared endpoint or
   --                         T-junction / endpoint-on-interior)
   --    Collinear_Overlap  — supporting lines coincide and the closed
   --                         segments share a positive-length interval
   type Intersection_Kind is
     (None, Proper, Improper, Collinear_Overlap);

   --  One reported intersecting pair: geometric representative + indices
   --  + classification. For Proper / Improper, Location is the unique
   --  meeting point; for Collinear_Overlap it is the midpoint of the
   --  overlap interval (educational representative).
   type Intersection is record
      Location : Point := (X => 0.0, Y => 0.0);
      Seg_I    : Segment_Index := 1;
      Seg_J    : Segment_Index := 1;
      Kind     : Intersection_Kind := None;
   end record;

   type Intersection_Array is array (Positive range <>) of Intersection;

   type Intersection_List is record
      Items : Intersection_Array (1 .. Max_Intersections) :=
        [others =>
           (Location => (0.0, 0.0),
            Seg_I    => 1,
            Seg_J    => 1,
            Kind     => None)];
      Count : Intersection_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Segments'Length < 1 or > Max_Segments, when a segment
   --  is near-degenerate (A ≈ B), or when Intersection_Point is asked
   --  for a pair that does not meet at a unique point.

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

   function On_Segment (P : Point; S : Segment) return Boolean
     with Global => null;
   --  True iff P lies on the closed segment S (within Epsilon of the
   --  supporting line and inside the axis-aligned bounding box of S,
   --  padded by Epsilon).

   function Is_Degenerate (S : Segment) return Boolean
     with Global => null;
   --  True iff endpoints of S coincide within Epsilon.

   ---------------------------------------------------------------------------
   -- Pair predicates / classification
   ---------------------------------------------------------------------------

   function Classify_Intersection (S, T : Segment) return Intersection_Kind
     with Global => null;
   --  Educational Orient2D classifier (see Intersection_Kind). Raises
   --  Invalid_Argument if either segment is near-degenerate.

   function Segments_Intersect (S, T : Segment) return Boolean
     with Global => null;
   --  True iff Classify_Intersection (S, T) /= None. Same validation.

   function Has_Unique_Intersection_Point (S, T : Segment) return Boolean
     with Global => null;
   --  True iff the intersection is a single point (Proper or Improper).

   function Intersection_Point (S, T : Segment) return Point
     with Global => null;
   --  Unique meeting point when Has_Unique_Intersection_Point is True
   --  (parametric Cramer's-rule intersection of the supporting lines).
   --  Raises Invalid_Argument when the meeting set is empty or a
   --  positive-length overlap, or when either segment is degenerate.

   function Overlap_Representative (S, T : Segment) return Point
     with Global => null;
   --  Midpoint of the overlap interval when Classify = Collinear_Overlap;
   --  raises Invalid_Argument otherwise (or on degeneracy).

   ---------------------------------------------------------------------------
   -- Multi-segment reporting
   ---------------------------------------------------------------------------
   --  Brute_Force_Find_All: O(n²) all-pairs Classify_Intersection; reports
   --  every pair with Kind /= None (Proper, Improper, Collinear_Overlap).
   --  Find_All: thin Bentley–Ottmann-style sweep that reports Proper
   --  crossings only (educational; dense status array, Max_Segments ≤ 32).
   --  Both raise Invalid_Argument if n < 1 or n > Max_Segments, or if any
   --  input segment is near-degenerate.

   function Brute_Force_Find_All
     (Segments : Segment_Set) return Intersection_List
     with Global => null;

   function Find_All (Segments : Segment_Set) return Intersection_List
     with Global => null;
   --  Proper crossings only (thin BO sketch). Compare against the Proper
   --  subset of Brute_Force_Find_All in tests.

   function Intersection_Count_Of
     (Segments : Segment_Set) return Intersection_Count
     with Global => null;
   --  Count of Find_All (Segments). Same validation.

   function Same_Intersection_Set
     (Left, Right : Intersection_List; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Order-independent multiset compare on (near Location, Seg_I, Seg_J,
   --  Kind).

   function Filter_By_Kind
     (List : Intersection_List; Kind : Intersection_Kind)
      return Intersection_List
     with Global => null;
   --  Sub-list of entries whose Kind matches (educational oracle helper).

   ---------------------------------------------------------------------------
   -- Accessors / constructors
   ---------------------------------------------------------------------------

   function Empty_Intersection_List return Intersection_List
     with Global => null;

   function Make_Segment (Ax, Ay, Bx, By : Real) return Segment
     with Global => null;

   function Make_Point (X, Y : Real) return Point
     with Global => null;

end Line_Segment_Intersection;
