--  Weiler_Atherton — Ada 2023 educational implementation of the
--  Weiler–Atherton polygon clipping (and merging) algorithm.
--  Clips a subject polygon B by an arbitrarily shaped clip polygon A
--  in 2-D using circular vertex lists linked at intersections.
--  Based on Wikipedia "Weiler–Atherton clipping algorithm" and
--  Weiler & Atherton, Computer Graphics 11(2):214-222, 1977.

pragma Ada_2022;

package Weiler_Atherton
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   type Vec2 is record
      X, Y : Real := 0.0;
   end record;

   subtype Point2 is Vec2;

   --  Bounded educational polygons (vertices + inserted intersections).
   Max_Vertices : constant Positive := 64;
   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index) of Vec2;

   type Polygon is record
      Verts : Vertex_Array := [others => (0.0, 0.0)];
      Count : Vertex_Count := 0;
   end record;

   Max_Polygons : constant Positive := 8;
   subtype Polygon_Count is Natural range 0 .. Max_Polygons;
   subtype Polygon_Index is Positive range 1 .. Max_Polygons;
   type Polygon_Array is array (Polygon_Index) of Polygon;

   type Clip_Result is record
      Polys : Polygon_Array;
      Count : Polygon_Count := 0;
   end record;

   type Orientation is (Clockwise, Counter_Clockwise);

   type Intersection_Kind is (Inbound, Outbound, Unknown);

   type Overlap_Class is (A_In_B, B_In_A, Disjoint, Overlapping);

   --  One proper edge–edge intersection with parametric locations.
   type Intersection_Record is record
      Point  : Vec2 := (0.0, 0.0);
      Kind   : Intersection_Kind := Unknown;
      Edge_A : Natural := 0;   -- clip edge start vertex index (1-based)
      Edge_B : Natural := 0;   -- subject edge start vertex index
      Alpha_A : Real := 0.0;   -- param along clip edge in (0,1)
      Alpha_B : Real := 0.0;   -- param along subject edge in (0,1)
   end record;

   Max_Intersections : constant Positive := 64;
   subtype Intersection_Count is Natural range 0 .. Max_Intersections;
   subtype Intersection_Index is Positive range 1 .. Max_Intersections;
   type Intersection_Array is array (Intersection_Index) of Intersection_Record;

   type Intersection_List is record
      Items : Intersection_Array;
      Count : Intersection_Count := 0;
   end record;

   type Seg_Intersect_Result is record
      Found : Boolean := False;
      Point : Vec2 := (0.0, 0.0);
      T     : Real := 0.0;  -- param on segment P0→P1
      U     : Real := 0.0;  -- param on segment Q0→Q1
   end record;

   --  Circular linked-list node for Build_Linked_Polygon_Lists.
   Max_List_Nodes : constant Positive := 128;
   subtype List_Node_Count is Natural range 0 .. Max_List_Nodes;
   subtype List_Node_Index is Positive range 1 .. Max_List_Nodes;

   type Node_Source is (Original_Vertex, Intersection_Vertex);

   type List_Node is record
      Point       : Vec2 := (0.0, 0.0);
      Source      : Node_Source := Original_Vertex;
      Is_Inbound  : Boolean := False;
      Is_Outbound : Boolean := False;
      Visited     : Boolean := False;
      Link        : Natural := 0;  -- paired node index in the other list
      Next        : Natural := 0;  -- next clockwise index in this list
   end record;

   type List_Node_Array is array (List_Node_Index) of List_Node;

   type Linked_Polygon_Lists is record
      Clip         : List_Node_Array;
      Subject      : List_Node_Array;
      Clip_Count   : List_Node_Count := 0;
      Subject_Count : List_Node_Count := 0;
      Clip_Head    : Natural := 0;
      Subject_Head : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric / vector helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-5;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function "-" (A, B : Vec2) return Vec2
     with Global => null;

   function "+" (A, B : Vec2) return Vec2
     with Global => null;

   function "*" (S : Real; V : Vec2) return Vec2
     with Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   function Cross_Z (A, B : Vec2) return Real
     with Global => null;
   --  2-D cross product magnitude: Ax*By − Ay*Bx.

   function Distance (A, B : Vec2) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- 9. Polygon helpers: Make_Rectangle, Make_Triangle, Vertex_Count, Copy
   ---------------------------------------------------------------------------

   function Vertex_Count_Of (P : Polygon) return Vertex_Count
     with Global => null;

   function Polygon_Copy (P : Polygon) return Polygon
     with Post => Polygon_Copy'Result.Count = P.Count, Global => null;

   function Make_Rectangle
     (Min_X, Min_Y, Max_X, Max_Y : Real;
      Orient : Orientation := Clockwise) return Polygon
     with Pre    => Max_X > Min_X and then Max_Y > Min_Y,
          Post   => Make_Rectangle'Result.Count = 4,
          Global => null;
   --  Axis-aligned rectangle; vertices ordered per Orient.

   function Make_Triangle
     (A, B, C : Vec2;
      Orient  : Orientation := Clockwise) return Polygon
     with Pre    => abs (Cross_Z (B - A, C - A)) > Epsilon,
          Post   => Make_Triangle'Result.Count = 3,
          Global => null;

   function Same_Polygon
     (A, B : Polygon; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Same vertex count and Near_Point pairwise (order-sensitive).

   ---------------------------------------------------------------------------
   -- 1. Signed_Area / Orient_Clockwise / Ensure_Orientation
   ---------------------------------------------------------------------------

   function Signed_Area (P : Polygon) return Real
     with Pre    => P.Count >= 3,
          Global => null;
   --  Shoelace: positive ⇒ counter-clockwise, negative ⇒ clockwise.

   function Polygon_Orientation (P : Polygon) return Orientation
     with Pre => P.Count >= 3, Global => null;

   function Orient_Clockwise (P : Polygon) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Orient_Clockwise'Result.Count = P.Count,
          Global => null;
   --  Reverse vertex order when currently counter-clockwise.

   function Ensure_Orientation
     (P : Polygon; Wanted : Orientation) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Ensure_Orientation'Result.Count = P.Count,
          Global => null;

   ---------------------------------------------------------------------------
   -- 2. Point_In_Polygon (ray casting, even-odd)
   ---------------------------------------------------------------------------

   function Point_In_Polygon (Q : Vec2; Poly : Polygon) return Boolean
     with Pre => Poly.Count >= 3, Global => null;
   --  Strict interior (boundary treated as outside for labeling stability).

   function Point_On_Boundary
     (Q : Vec2; Poly : Polygon; Tol : Real := Epsilon) return Boolean
     with Pre => Poly.Count >= 3 and then Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- 3. Segment_Intersection / Find_All_Intersections
   ---------------------------------------------------------------------------

   function Segment_Intersection
     (P0, P1, Q0, Q1 : Vec2) return Seg_Intersect_Result
     with Global => null;
   --  Proper open-segment intersection (T,U in (0,1)); shared endpoints
   --  and collinear overlaps are rejected (Found = False).

   function Find_All_Intersections
     (Clip, Subject : Polygon) return Intersection_List
     with Pre    => Clip.Count >= 3 and then Subject.Count >= 3,
          Global => null;
   --  All proper edge intersections; Kind left Unknown (label later).

   ---------------------------------------------------------------------------
   -- 4. Build_Linked_Polygon_Lists
   ---------------------------------------------------------------------------

   function Build_Linked_Polygon_Lists
     (Clip, Subject : Polygon) return Linked_Polygon_Lists
     with Pre    => Clip.Count >= 3 and then Subject.Count >= 3,
          Global => null;
   --  Insert intersections into both circular lists, link pairs, and
   --  mark inbound / outbound on subject-side intersection nodes.

   ---------------------------------------------------------------------------
   -- 5. Collect_Inbound_Intersections / Collect_Outbound_Intersections
   ---------------------------------------------------------------------------

   function Collect_Inbound_Intersections
     (Lists : Linked_Polygon_Lists) return Intersection_List
     with Global => null;

   function Collect_Outbound_Intersections
     (Lists : Linked_Polygon_Lists) return Intersection_List
     with Global => null;

   ---------------------------------------------------------------------------
   -- 8. Classify_No_Intersection
   ---------------------------------------------------------------------------

   function Classify_No_Intersection
     (Clip, Subject : Polygon) return Overlap_Class
     with Pre    => Clip.Count >= 3 and then Subject.Count >= 3,
          Global => null;
   --  When Find_All_Intersections is empty: A_In_B, B_In_A, or Disjoint.
   --  If any intersection exists, returns Overlapping.

   ---------------------------------------------------------------------------
   -- 6. Weiler_Atherton_Clip — intersection (inbound starts)
   ---------------------------------------------------------------------------

   function Weiler_Atherton_Clip
     (Clip, Subject : Polygon) return Clip_Result
     with Pre    => Clip.Count >= 3 and then Subject.Count >= 3,
          Global => null;
   --  Preconditions (caller): clockwise, non-self-intersecting.
   --  Ensures clockwise orientation internally. One or more result
   --  polygons (concave clips may yield multiple pieces).

   ---------------------------------------------------------------------------
   -- 7. Weiler_Atherton_Merge — union starting at outbound
   ---------------------------------------------------------------------------

   function Weiler_Atherton_Merge
     (Clip, Subject : Polygon) return Clip_Result
     with Pre    => Clip.Count >= 3 and then Subject.Count >= 3,
          Global => null;
   --  Same linked-list walk as clip but starts at outbound intersections.
   --  No-intersection: A_In_B ⇒ Subject; B_In_A ⇒ Clip; Disjoint ⇒ both.

end Weiler_Atherton;
