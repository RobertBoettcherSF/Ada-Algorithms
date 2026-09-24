--  Cyrus_Beck — Ada 2023 educational implementation of the
--  Cyrus–Beck line clipping algorithm.
--  Clips a line segment against a convex polygon (2-D) or a convex
--  polyhedron given as outward planes (3-D lite) using the parametric
--  form p(t) = (1-t)p0 + t p1, 0 ≤ t ≤ 1. For each clip edge/plane with
--  outward normal n and point PE: n · (p(t) − PE) = 0 at the intersection.
--  Entering vs leaving is classified by the sign of n · D (D = p1 − p0);
--  t_enter = max of entering parameters, t_leave = min of leaving;
--  accept iff t_enter ≤ t_leave. Liang–Barsky is the rectangular
--  specialisation of Cyrus–Beck.
--  Based on Wikipedia "Cyrus–Beck algorithm" and
--  Cyrus & Beck, Computers & Graphics 1978.
--  Related: Liang–Barsky, Cohen–Sutherland, Nicholl–Lee–Nicholl.

pragma Ada_2022;

package Cyrus_Beck
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;

   --  Parametric line parameter on the closed unit interval.
   subtype Parameter is Real range 0.0 .. 1.0;

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

   Max_Vertices : constant Positive := 32;
   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index) of Vec2;

   --  Convex clip polygon; vertices in CCW order (interior on the left).
   type Convex_Clip_Polygon is record
      Count : Vertex_Count := 0;
      V     : Vertex_Array := [others => (0.0, 0.0)];
   end record;

   subtype Polygon is Convex_Clip_Polygon;

   --  Axis-aligned rectangular window (Liang–Barsky style convenience).
   type Clip_Window is record
      X_Min, Y_Min, X_Max, Y_Max : Real := 0.0;
   end record;

   --  Infinite plane in 3-D: outward normal N and a point PE on the plane.
   type Plane3 is record
      N  : Vec3 := (0.0, 0.0, 1.0);
      PE : Vec3 := (0.0, 0.0, 0.0);
   end record;

   Max_Planes : constant Positive := 16;
   subtype Plane_Count is Natural range 0 .. Max_Planes;
   subtype Plane_Index is Positive range 1 .. Max_Planes;
   type Plane_Array is array (Plane_Index) of Plane3;

   --  Bounded list of outward planes describing a convex polyhedron.
   type Polyhedron_Planes is record
      Count : Plane_Count := 0;
      P     : Plane_Array := [others => ((0.0, 0.0, 1.0), (0.0, 0.0, 0.0))];
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

   --  Clip plus retained parametric bounds.
   type Clip_Params_Result is record
      Status  : Clip_Status := Clip_Reject;
      Clipped : Segment := ((0.0, 0.0), (0.0, 0.0));
      T0, T1  : Parameter := 0.0;
   end record;

   --  Half-plane classification of a point vs an outward edge/plane.
   type Dot_Class is (Dot_Inside, Dot_On_Plane, Dot_Outside);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;

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
   --  2-D cross product z-component: Ax*By − Ay*Bx.

   function "-" (A, B : Vec3) return Vec3
     with Global => null;

   function "+" (A, B : Vec3) return Vec3
     with Global => null;

   function "*" (S : Real; V : Vec3) return Vec3
     with Global => null;

   function Dot3 (A, B : Vec3) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- 9. Make_Segment / Length / Point_Inside_Convex
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

   function Point_Inside_Convex
     (P : Vec2; Poly : Convex_Clip_Polygon) return Boolean
     with Pre => Is_Convex_Polygon (Poly), Global => null;
   --  Inclusive of the boundary (within Epsilon). Requires CCW convex poly.

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- 1. Convex_Clip_Polygon / Make_Convex_Rect / Edge_Normal
   ---------------------------------------------------------------------------

   function Make_Convex_Polygon
     (Verts : Vertex_Array; Count : Vertex_Count) return Convex_Clip_Polygon
     with Pre    => Count >= 3,
          Post   => Make_Convex_Polygon'Result.Count = Count,
          Global => null;
   --  Copies the first Count vertices. Raises Invalid_Argument if not convex
   --  (strictly same-turn) or if Count < 3.

   function Make_Convex_Rect
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Convex_Clip_Polygon
     with Pre    => X_Max > X_Min and then Y_Max > Y_Min,
          Post   => Make_Convex_Rect'Result.Count = 4
                    and then Is_Convex_Polygon (Make_Convex_Rect'Result),
          Global => null;
   --  CCW rectangle: BL → BR → TR → TL.

   function Edge_Normal
     (Poly : Convex_Clip_Polygon; Edge : Vertex_Index) return Vec2
     with Pre => Is_Convex_Polygon (Poly)
                 and then Edge <= Poly.Count,
          Global => null;
   --  Outward unit-ish normal for edge V(Edge) → V(Edge mod N + 1).
   --  For CCW polygons: (Dy, −Dx) of the edge direction (points right/out).

   function Is_Valid_Window (W : Clip_Window) return Boolean
     with Global => null;

   function Make_Window
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Window
     with Pre    => X_Max > X_Min and then Y_Max > Y_Min,
          Post   => Is_Valid_Window (Make_Window'Result),
          Global => null;

   ---------------------------------------------------------------------------
   -- 2. Is_Convex_Polygon
   ---------------------------------------------------------------------------

   function Is_Convex_Polygon (Poly : Convex_Clip_Polygon) return Boolean
     with Global => null;
   --  True when Count ≥ 3, no zero-length edges, and all consecutive edge
   --  cross products share a strictly positive sign (CCW convex).

   ---------------------------------------------------------------------------
   -- 3. Plane_Dot_Classification
   ---------------------------------------------------------------------------

   function Plane_Dot_Classification
     (P    : Vec2;
      Poly : Convex_Clip_Polygon;
      Edge : Vertex_Index) return Dot_Class
     with Pre => Is_Convex_Polygon (Poly)
                 and then Edge <= Poly.Count,
          Global => null;
   --  Classify P vs the outward half-plane of Edge: Inside / On / Outside.

   function Plane_Dot_Classification3
     (P : Vec3; Pl : Plane3) return Dot_Class
     with Global => null;

   ---------------------------------------------------------------------------
   -- Point_At_Parameter
   ---------------------------------------------------------------------------

   function Point_At_Parameter
     (S : Segment; T : Parameter) return Vec2
     with Global => null;

   function Point_At_Parameter3
     (S : Segment3; T : Parameter) return Vec3
     with Global => null;

   ---------------------------------------------------------------------------
   -- 4. Cyrus_Beck_Clip — clip segment against convex polygon
   ---------------------------------------------------------------------------

   function Cyrus_Beck_Clip
     (S : Segment; Poly : Convex_Clip_Polygon) return Clip_Result
     with Pre => Is_Convex_Polygon (Poly), Global => null;

   ---------------------------------------------------------------------------
   -- 5. Cyrus_Beck_Clip_Params — also return t_enter, t_leave
   ---------------------------------------------------------------------------

   function Cyrus_Beck_Clip_Params
     (S : Segment; Poly : Convex_Clip_Polygon) return Clip_Params_Result
     with Pre => Is_Convex_Polygon (Poly), Global => null;

   ---------------------------------------------------------------------------
   -- 6. Cyrus_Beck_Clip_Rect — convenience rectangular window
   ---------------------------------------------------------------------------

   function Cyrus_Beck_Clip_Rect
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;
   --  Builds Make_Convex_Rect and clips; should agree with Liang–Barsky.

   ---------------------------------------------------------------------------
   -- 7. Liang_Barsky_Clip_Lite — rectangular reference for cross-check
   ---------------------------------------------------------------------------

   function Liang_Barsky_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
     with Pre => Is_Valid_Window (W), Global => null;

   ---------------------------------------------------------------------------
   -- 8. Cyrus_Beck_Clip_3D_Lite — educational 3-D plane-set clip
   ---------------------------------------------------------------------------

   function Make_Axis_Aligned_Box_Planes
     (X_Min, Y_Min, Z_Min, X_Max, Y_Max, Z_Max : Real)
      return Polyhedron_Planes
     with Pre => X_Max > X_Min
                 and then Y_Max > Y_Min
                 and then Z_Max > Z_Min,
          Global => null;
   --  Six outward planes of an axis-aligned box.

   function Cyrus_Beck_Clip_3D_Lite
     (S : Segment3; Planes : Polyhedron_Planes) return Clip_Result3
     with Pre => Planes.Count >= 1, Global => null;
   --  Clip a 3-D segment against a convex polyhedron given as outward planes.

end Cyrus_Beck;
