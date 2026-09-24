--  Vatti — Ada 2023 educational implementation of the Vatti polygon
--  clipping algorithm (boolean ops via a sweep-inspired pipeline).
--  Clips any number of subject polygons by any number of clip polygons
--  with Intersection, Union, Difference, and Exclusive_Or.
--  Based on Wikipedia "Vatti clipping algorithm" and
--  Bala R. Vatti, CACM 35(7):56–63, 1992.
--  Limitations: correct for simple (non-self-intersecting) polygons;
--  full self-intersecting / hole support is documented but omitted.

pragma Ada_2022;

package Vatti
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

   --  Multi-polygon subject / clip / result set.
   type Polygon_Set is record
      Polys : Polygon_Array;
      Count : Polygon_Count := 0;
   end record;

   type Orientation is (Clockwise, Counter_Clockwise);

   type Boolean_Operation is (Intersection, Union, Difference, Exclusive_Or);

   type Overlap_Class is (A_In_B, B_In_A, Disjoint, Overlapping);

   type Seg_Intersect_Result is record
      Found : Boolean := False;
      Point : Vec2 := (0.0, 0.0);
      T     : Real := 0.0;
      U     : Real := 0.0;
   end record;

   --  Edge–edge intersection record (educational / sweep output).
   type Intersection_Record is record
      Point  : Vec2 := (0.0, 0.0);
      Edge_A : Natural := 0;
      Edge_B : Natural := 0;
      Alpha_A : Real := 0.0;
      Alpha_B : Real := 0.0;
   end record;

   Max_Intersections : constant Positive := 64;
   subtype Intersection_Count is Natural range 0 .. Max_Intersections;
   subtype Intersection_Index is Positive range 1 .. Max_Intersections;
   type Intersection_Array is array (Intersection_Index) of Intersection_Record;

   type Intersection_List is record
      Items : Intersection_Array;
      Count : Intersection_Count := 0;
   end record;

   --  Scanline Y event list (Vatti / Bentley–Ottmann style).
   Max_Scanlines : constant Positive := 128;
   subtype Scanline_Count is Natural range 0 .. Max_Scanlines;
   subtype Scanline_Index is Positive range 1 .. Max_Scanlines;
   type Scanline_Y_Array is array (Scanline_Index) of Real;

   type Scanline_List is record
      Ys    : Scanline_Y_Array := [others => 0.0];
      Count : Scanline_Count := 0;
   end record;

   type Scanbeam is record
      Y_Bot : Real := 0.0;
      Y_Top : Real := 0.0;
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

   function Distance (A, B : Vec2) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Polygon helpers: Make_Rectangle, Make_Triangle, Orient, …
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

   function Make_Triangle
     (A, B, C : Vec2;
      Orient  : Orientation := Clockwise) return Polygon
     with Pre    => abs (Cross_Z (B - A, C - A)) > Epsilon,
          Post   => Make_Triangle'Result.Count = 3,
          Global => null;

   function Same_Polygon
     (A, B : Polygon; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Signed_Area (P : Polygon) return Real
     with Pre => P.Count >= 3, Global => null;

   function Polygon_Orientation (P : Polygon) return Orientation
     with Pre => P.Count >= 3, Global => null;

   function Orient_Clockwise (P : Polygon) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Orient_Clockwise'Result.Count = P.Count,
          Global => null;

   function Ensure_Orientation
     (P : Polygon; Wanted : Orientation) return Polygon
     with Pre    => P.Count >= 3,
          Post   => Ensure_Orientation'Result.Count = P.Count,
          Global => null;

   function Absolute_Area (P : Polygon) return Non_Negative
     with Pre => P.Count >= 3, Global => null;

   function Set_Absolute_Area (S : Polygon_Set) return Non_Negative
     with Global => null;

   function Singleton (P : Polygon) return Polygon_Set
     with Pre    => P.Count >= 3,
          Post   => Singleton'Result.Count = 1,
          Global => null;

   function Make_Set (A, B : Polygon) return Polygon_Set
     with Pre    => A.Count >= 3 and then B.Count >= 3,
          Post   => Make_Set'Result.Count = 2,
          Global => null;

   ---------------------------------------------------------------------------
   -- Point_In_Polygon / Segment_Intersection
   ---------------------------------------------------------------------------

   function Point_In_Polygon (Q : Vec2; Poly : Polygon) return Boolean
     with Pre => Poly.Count >= 3, Global => null;

   function Point_On_Boundary
     (Q : Vec2; Poly : Polygon; Tol : Real := Epsilon) return Boolean
     with Pre => Poly.Count >= 3 and then Tol >= 0.0, Global => null;

   function Point_In_Set (Q : Vec2; S : Polygon_Set) return Boolean
     with Pre => S.Count >= 1, Global => null;

   function Segment_Intersection
     (P0, P1, Q0, Q1 : Vec2) return Seg_Intersect_Result
     with Global => null;

   function Find_All_Intersections
     (A, B : Polygon) return Intersection_List
     with Pre    => A.Count >= 3 and then B.Count >= 3,
          Global => null;

   function Classify_No_Intersection
     (A, B : Polygon) return Overlap_Class
     with Pre    => A.Count >= 3 and then B.Count >= 3,
          Global => null;

   ---------------------------------------------------------------------------
   -- Sweep-line scaffolding (Vatti scanbeams / local minima)
   ---------------------------------------------------------------------------

   function Collect_Scanline_Ys
     (Subject, Clip : Polygon_Set) return Scanline_List
     with Pre    => Subject.Count >= 1 and then Clip.Count >= 1,
          Global => null;
   --  Unique vertex Y coordinates sorted ascending (scanline events).

   function Build_Local_Minima
     (Subject, Clip : Polygon_Set) return Scanline_List
     with Pre    => Subject.Count >= 1 and then Clip.Count >= 1,
          Global => null;
   --  Educational alias: local-minima Y events = Collect_Scanline_Ys
   --  for simple polygons (full Vatti LML omitted).

   function Sweep_Process_Scanbeam
     (Subject, Clip : Polygon;
      Beam          : Scanbeam) return Intersection_List
     with Pre    => Subject.Count >= 3
                    and then Clip.Count >= 3
                    and then Beam.Y_Top > Beam.Y_Bot,
          Global => null;
   --  Intersections whose Y lies in (Y_Bot, Y_Top] for one scanbeam.

   ---------------------------------------------------------------------------
   -- Vatti_Clip and boolean convenience wrappers
   ---------------------------------------------------------------------------

   function Vatti_Clip
     (Subject, Clip : Polygon_Set;
      Op            : Boolean_Operation) return Polygon_Set
     with Pre    => Subject.Count >= 1 and then Clip.Count >= 1,
          Global => null;
   --  Boolean clip of subject set by clip set. Simple polygons only.

   function Vatti_Clip
     (Subject, Clip : Polygon;
      Op            : Boolean_Operation) return Polygon_Set
     with Pre    => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;

   function Vatti_Intersection
     (Subject, Clip : Polygon) return Polygon_Set
     with Pre    => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;

   function Vatti_Union
     (Subject, Clip : Polygon) return Polygon_Set
     with Pre    => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;

   function Vatti_Difference
     (Subject, Clip : Polygon) return Polygon_Set
     with Pre    => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;

   function Vatti_Xor
     (Subject, Clip : Polygon) return Polygon_Set
     with Pre    => Subject.Count >= 3 and then Clip.Count >= 3,
          Global => null;

   function Vatti_Intersection
     (Subject, Clip : Polygon_Set) return Polygon_Set
     with Pre => Subject.Count >= 1 and then Clip.Count >= 1, Global => null;

   function Vatti_Union
     (Subject, Clip : Polygon_Set) return Polygon_Set
     with Pre => Subject.Count >= 1 and then Clip.Count >= 1, Global => null;

   function Vatti_Difference
     (Subject, Clip : Polygon_Set) return Polygon_Set
     with Pre => Subject.Count >= 1 and then Clip.Count >= 1, Global => null;

   function Vatti_Xor
     (Subject, Clip : Polygon_Set) return Polygon_Set
     with Pre => Subject.Count >= 1 and then Clip.Count >= 1, Global => null;

end Vatti;
