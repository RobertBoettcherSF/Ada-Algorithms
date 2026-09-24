--  Sutherland_Hodgman — Ada 2023 educational implementation of the
--  Sutherland–Hodgman polygon clipping algorithm.
--  Clips a subject polygon by a convex clip polygon in 2-D by iteratively
--  clipping against each extended clip edge; keeps the visible half-plane
--  and inserts intersections when subject edges cross the clip line.
--  Based on Wikipedia "Sutherland–Hodgman algorithm" and
--  Sutherland & Hodgman, CACM 17(1):32–42, 1974.
--  Contrast: Weiler–Atherton can return multiple pieces for concave clips;
--  SH always yields a single polygon (possibly with coincident edges).

pragma Ada_2022;

package Sutherland_Hodgman
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

   --  Bounded educational polygons.
   Max_Vertices : constant Positive := 64;
   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index) of Vec2;
   type Vertex3_Array is array (Vertex_Index) of Vec3;

   type Polygon is record
      Verts : Vertex_Array := [others => (0.0, 0.0)];
      Count : Vertex_Count := 0;
   end record;

   type Polygon3 is record
      Verts : Vertex3_Array := [others => (0.0, 0.0, 0.0)];
      Count : Vertex_Count := 0;
   end record;

   --  Directed clip edge A → B (infinite line for intersection).
   type Edge is record
      A, B : Vec2 := (0.0, 0.0);
   end record;

   --  Plane N·X + D = 0; positive half-space is N·X + D >= 0.
   type Plane3 is record
      Normal : Vec3 := (0.0, 0.0, 1.0);
      D      : Real := 0.0;
   end record;

   type Orientation is (Clockwise, Counter_Clockwise);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;
   Non_Convex_Clip     : exception;

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

   function Distance (A, B : Vec2) return Non_Negative
     with Global => null;

   function "-" (A, B : Vec3) return Vec3
     with Global => null;

   function "+" (A, B : Vec3) return Vec3
     with Global => null;

   function "*" (S : Real; V : Vec3) return Vec3
     with Global => null;

   function Dot3 (A, B : Vec3) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- 8. Polygon helpers: Make_Rectangle / Make_Triangle / Signed_Area / Orient
   ---------------------------------------------------------------------------

   function Vertex_Count_Of (P : Polygon) return Vertex_Count
     with Global => null;

   function Polygon_Copy (P : Polygon) return Polygon
     with Post => Polygon_Copy'Result.Count = P.Count, Global => null;

   function Make_Rectangle
     (Min_X, Min_Y, Max_X, Max_Y : Real;
      Orient : Orientation := Counter_Clockwise) return Polygon
     with Pre    => Max_X > Min_X and then Max_Y > Min_Y,
          Post   => Make_Rectangle'Result.Count = 4,
          Global => null;
   --  Axis-aligned rectangle; default CCW (SH inside = left of edges).

   function Make_Triangle
     (A, B, C : Vec2;
      Orient  : Orientation := Counter_Clockwise) return Polygon
     with Pre    => abs (Cross_Z (B - A, C - A)) > Epsilon,
          Post   => Make_Triangle'Result.Count = 3,
          Global => null;

   function Same_Polygon
     (A, B : Polygon; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Signed_Area (P : Polygon) return Real
     with Pre => P.Count >= 3, Global => null;
   --  Shoelace: positive ⇒ counter-clockwise, negative ⇒ clockwise.

   function Polygon_Orientation (P : Polygon) return Orientation
     with Pre => P.Count >= 3, Global => null;

   function Orient_Clockwise (P : Polygon) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Orient_Clockwise'Result.Count = P.Count,
          Global => null;

   function Orient_Counter_Clockwise (P : Polygon) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Orient_Counter_Clockwise'Result.Count = P.Count,
          Global => null;

   function Ensure_Orientation
     (P : Polygon; Wanted : Orientation) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Ensure_Orientation'Result.Count = P.Count,
          Global => null;

   function Absolute_Area (P : Polygon) return Non_Negative
     with Pre => P.Count >= 3, Global => null;

   ---------------------------------------------------------------------------
   -- 7. Is_Convex_Polygon — precondition helper for clip polygon
   ---------------------------------------------------------------------------

   function Is_Convex_Polygon (P : Polygon) return Boolean
     with Pre => P.Count >= 3, Global => null;
   --  True when all turns have the same sign (allowing near-collinear).

   ---------------------------------------------------------------------------
   -- 1. Inside_HalfPlane / Clip_Against_Edge
   ---------------------------------------------------------------------------

   function Inside_HalfPlane
     (P           : Vec2;
      Clip_Edge   : Edge;
      Inside_Left : Boolean := True) return Boolean
     with Global => null;
   --  Inside_Left = True: left of directed edge A→B is visible (CCW clip).
   --  Inside_Left = False: right side is visible (CW clip).
   --  Points on the line (within Epsilon) count as inside.

   function Clip_Against_Edge
     (Subject     : Polygon;
      Clip_Edge   : Edge;
      Inside_Left : Boolean := True) return Polygon
     with Pre    => Subject.Count >= 0,
          Global => null;
   --  One SH pass: keep vertices on the visible side; insert intersections
   --  when a subject edge crosses the infinite clip line.
   --  Empty or fewer than 3 vertices may be returned.

   ---------------------------------------------------------------------------
   -- 2. Compute_Intersection — subject edge vs infinite clip edge line
   ---------------------------------------------------------------------------

   function Compute_Intersection
     (P0, P1    : Vec2;
      Clip_Edge : Edge) return Vec2
     with Global => null;
   --  Intersection of infinite line P0→P1 with infinite line Clip_Edge.
   --  Raises Degenerate_Geometry when lines are parallel / coincident.

   ---------------------------------------------------------------------------
   -- 3. Sutherland_Hodgman_Clip — full iterative convex clip
   ---------------------------------------------------------------------------

   function Sutherland_Hodgman_Clip
     (Subject, Clip : Polygon) return Polygon
     with Pre    => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;
   --  Iteratively Clip_Against_Edge for each clip edge.
   --  Clip must be convex (raises Non_Convex_Clip otherwise).
   --  Clip orientation is detected; subject may be concave.
   --  Result is a single polygon (Count < 3 means empty / fully clipped).

   ---------------------------------------------------------------------------
   -- 4. Clip_Against_Rect — axis-aligned / convex rect convenience
   ---------------------------------------------------------------------------

   function Clip_Against_Rect
     (Subject                  : Polygon;
      Min_X, Min_Y, Max_X, Max_Y : Real) return Polygon
     with Pre    => Subject.Count >= 3
                    and then Max_X > Min_X
                    and then Max_Y > Min_Y,
          Global => null;

   ---------------------------------------------------------------------------
   -- 5. Clip_Against_Frustum_2D — convex viewing window (SH alias)
   ---------------------------------------------------------------------------

   function Clip_Against_Frustum_2D
     (Subject, Window : Polygon) return Polygon
     with Pre    => Subject.Count >= 3 and then Window.Count >= 3,
          Global => null;
   --  Educational alias of Sutherland_Hodgman_Clip for a convex window.

   ---------------------------------------------------------------------------
   -- 6. Clip_Polygon_Against_Plane_3D_Lite — one-plane 3-D extension
   ---------------------------------------------------------------------------

   function Plane_Signed_Distance (P : Vec3; Plane : Plane3) return Real
     with Global => null;
   --  N·P + D; positive ⇒ keep side.

   function Clip_Polygon_Against_Plane_3D_Lite
     (Subject : Polygon3;
      Plane   : Plane3) return Polygon3
     with Pre    => Subject.Count >= 3,
          Global => null;
   --  Educational 3-D SH step: clip a 3-D polygon against one plane,
   --  keeping the positive half-space (N·X + D >= 0).

   function Make_Polygon3
     (A, B, C : Vec3) return Polygon3
     with Post => Make_Polygon3'Result.Count = 3, Global => null;

   function Make_Polygon3
     (A, B, C, D : Vec3) return Polygon3
     with Post => Make_Polygon3'Result.Count = 4, Global => null;

end Sutherland_Hodgman;
