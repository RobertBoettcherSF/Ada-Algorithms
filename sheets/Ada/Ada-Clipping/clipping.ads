--  Clipping — Ada 2023 educational survey of computer-graphics clipping.
--  Umbrella package for the Wikipedia "Clipping (computer graphics)" topic:
--  2-D window/viewport clip regions, composite user ∩ device clip,
--  embedded Liang–Barsky line clip, Sutherland–Hodgman polygon clip,
--  educational 2-D view-frustum (convex quad) clip, near/far Z clip (lite),
--  and segment visibility classification. Dedicated sibling repos treat
--  individual algorithms in more depth.
--  Based on Wikipedia "Clipping (computer graphics)" and classic textbooks
--  (Newman & Sproull; Foley / van Dam; Hearn & Baker).
--  Related: Line clipping, Cohen–Sutherland, Liang–Barsky, Cyrus–Beck,
--  Sutherland–Hodgman, Weiler–Atherton, Vatti, Nicholl–Lee–Nicholl.

pragma Ada_2022;

package Clipping
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

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Point3 is Vec3;

   type Segment is record
      P0, P1 : Vec2 := (0.0, 0.0);
   end record;

   type Segment3 is record
      P0, P1 : Vec3 := (0.0, 0.0, 0.0);
   end record;

   --  Bounded educational polygons.
   Max_Vertices : constant Positive := 64;
   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index) of Vec2;

   type Polygon is record
      Verts : Vertex_Array := [others => (0.0, 0.0)];
      Count : Vertex_Count := 0;
   end record;

   --  Axis-aligned rectangular clip region (2-D window / viewport).
   type Clip_Rect is record
      X_Min, Y_Min, X_Max, Y_Max : Real := 0.0;
   end record;

   type Clip_Status is (Clip_Accept, Clip_Reject);

   type Clip_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
   end record;

   type Clip_Result3 is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment3 := ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0));
   end record;

   type Polygon_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Polygon;
   end record;

   --  Composite (user ∩ device) intersection of two AA rects.
   type Intersect_Result is record
      Overlaps : Boolean := False;
      Region   : Clip_Rect;
   end record;

   --  Educational 2-D view frustum: convex quad (typically a trapezoid).
   type Frustum_Vertex_Index is range 1 .. 4;
   type Frustum_Verts is array (Frustum_Vertex_Index) of Vec2;

   type View_Frustum_2D is record
      Verts : Frustum_Verts := [others => (0.0, 0.0)];
   end record;

   --  Segment vs rect visibility (clipping vs culling terminology).
   type Visibility is (Fully_Visible, Partially_Visible, Invisible);

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

   function Near_Point3 (A, B : Vec3; Tol : Real := Epsilon) return Boolean
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

   function "-" (A, B : Vec3) return Vec3
     with Global => null;

   function "+" (A, B : Vec3) return Vec3
     with Global => null;

   function "*" (S : Real; V : Vec3) return Vec3
     with Global => null;

   function Dot3 (A, B : Vec3) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- 9. Make_Segment / Make_Segment3 / Make_Polygon / Length helpers
   ---------------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment
     with Post => Make_Segment'Result.P0 = P0
                  and then Make_Segment'Result.P1 = P1,
          Global => null;

   function Make_Segment3 (P0, P1 : Vec3) return Segment3
     with Post => Make_Segment3'Result.P0 = P0
                  and then Make_Segment3'Result.P1 = P1,
          Global => null;

   function Length (S : Segment) return Non_Negative
     with Global => null;

   function Length3 (S : Segment3) return Non_Negative
     with Global => null;

   function Make_Polygon (Verts : Vertex_Array; Count : Vertex_Count)
     return Polygon
     with Pre    => Count <= Max_Vertices,
          Post   => Make_Polygon'Result.Count = Count,
          Global => null;

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True if A and B represent the same undirected clipped segment.

   ---------------------------------------------------------------------------
   -- 1. Clip_Rect / Make_Rect / Point_In_Rect
   ---------------------------------------------------------------------------

   function Make_Rect
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Rect
     with Pre    => X_Max > X_Min and then Y_Max > Y_Min,
          Post   => Is_Valid_Rect (Make_Rect'Result),
          Global => null;

   function Is_Valid_Rect (R : Clip_Rect) return Boolean
     with Global => null;
   --  True when X_Max > X_Min and Y_Max > Y_Min.

   function Point_In_Rect (P : Vec2; R : Clip_Rect) return Boolean
     with Pre => Is_Valid_Rect (R), Global => null;
   --  Inclusive of the boundary (within Epsilon).

   function Rect_To_Polygon (R : Clip_Rect) return Polygon
     with Pre => Is_Valid_Rect (R), Global => null;
   --  CCW rectangle as a 4-vertex polygon.

   ---------------------------------------------------------------------------
   -- 2. Clip_Point — accept / reject a point against a rect
   ---------------------------------------------------------------------------

   function Clip_Point (P : Vec2; R : Clip_Rect) return Clip_Status
     with Pre => Is_Valid_Rect (R), Global => null;

   ---------------------------------------------------------------------------
   -- 3. Clip_Line_Liang_Barsky — embedded compact parametric line clip
   ---------------------------------------------------------------------------

   function Clip_Line_Liang_Barsky
     (S : Segment; R : Clip_Rect) return Clip_Result
     with Pre => Is_Valid_Rect (R), Global => null;
   --  Compact Liang–Barsky against an axis-aligned rectangle.
   --  See Ada-Liang-Barsky for a deeper treatment.

   ---------------------------------------------------------------------------
   -- 4. Clip_Polygon_Sutherland_Hodgman — embedded compact SH clip
   ---------------------------------------------------------------------------

   function Clip_Polygon_Sutherland_Hodgman
     (Subject : Polygon; Clip : Polygon) return Polygon_Result
     with Pre => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;
   --  Compact Sutherland–Hodgman against a convex clip polygon.
   --  See Ada-Sutherland-Hodgman for a deeper treatment.

   function Clip_Polygon_To_Rect
     (Subject : Polygon; R : Clip_Rect) return Polygon_Result
     with Pre => Subject.Count >= 3 and then Is_Valid_Rect (R),
          Global => null;
   --  Convenience: SH against an axis-aligned Clip_Rect.

   ---------------------------------------------------------------------------
   -- 5. Intersect_Clip_Regions — composite user ∩ device AA rects
   ---------------------------------------------------------------------------

   function Intersect_Clip_Regions
     (User, Device : Clip_Rect) return Intersect_Result
     with Pre => Is_Valid_Rect (User) and then Is_Valid_Rect (Device),
          Global => null;
   --  Final clip region = intersection of application "user clip" and
   --  system "device clip". Overlaps = False when the intersection is empty.

   ---------------------------------------------------------------------------
   -- 6. View_Frustum_2D / Clip_Against_Frustum
   ---------------------------------------------------------------------------

   function Make_Frustum_2D (Verts : Frustum_Verts) return View_Frustum_2D
     with Global => null;
   --  Educational 2-D frustum as a convex quad (caller supplies CCW verts).

   function Is_Valid_Frustum (F : View_Frustum_2D) return Boolean
     with Global => null;
   --  True when the quad is strictly convex (positive area, consistent turns).

   function Point_In_Frustum
     (P : Vec2; F : View_Frustum_2D) return Boolean
     with Pre => Is_Valid_Frustum (F), Global => null;

   function Clip_Against_Frustum
     (P : Vec2; F : View_Frustum_2D) return Clip_Status
     with Pre => Is_Valid_Frustum (F), Global => null;
   --  Point accept / reject vs the educational 2-D frustum.

   function Clip_Against_Frustum
     (S : Segment; F : View_Frustum_2D) return Clip_Result
     with Pre => Is_Valid_Frustum (F), Global => null;
   --  Line clip vs convex frustum (successive half-plane / Cyrus–Beck style).

   ---------------------------------------------------------------------------
   -- 7. Near_Far_Clip_3D_Lite — clip 3-D segment against near/far Z
   ---------------------------------------------------------------------------

   function Near_Far_Clip_3D_Lite
     (S : Segment3; Near_Z, Far_Z : Real) return Clip_Result3
     with Pre => Far_Z > Near_Z, Global => null;
   --  Axis-aligned depth clip: retain the portion of S with Z in
   --  [Near_Z, Far_Z]. Educational lite of near/far (Z) clipping;
   --  not a full view-frustum / GPU clip-space pipeline.

   ---------------------------------------------------------------------------
   -- 8. Classify_Visibility — Fully / Partially / Invisible
   ---------------------------------------------------------------------------

   function Classify_Visibility
     (S : Segment; R : Clip_Rect) return Visibility
     with Pre => Is_Valid_Rect (R), Global => null;
   --  Fully_Visible: both endpoints inside (inclusive).
   --  Invisible: no intersection with R (trivial reject).
   --  Partially_Visible: intersects R but not fully inside.
   --  Distinguishes clipping (geometry trim) from culling (discard).

end Clipping;
