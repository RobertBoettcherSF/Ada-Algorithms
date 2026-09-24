--  Binary_Space_Partitioning — Ada 2023 educational BSP for computer graphics.
--  Recursive hyperplane partitioning, Fuchs-style auto BSP generation,
--  painter's-algorithm back-to-front / front-to-back traversal, polygon
--  splitting, point classification, and lite spatial / collision queries.
--  Based on Wikipedia "Binary space partitioning" and Fuchs / Kedem / Naylor
--  (SIGGRAPH 1980), Naylor, Thibault & Naylor (CSG).
--  Related (not dependencies): k-d trees, quadtrees, octrees.

pragma Ada_2022;

package Binary_Space_Partitioning
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

   type Segment is record
      P0, P1 : Vec2 := (0.0, 0.0);
   end record;

   --  Bounded educational polygons.
   Max_Vertices : constant Positive := 32;
   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index) of Vec2;

   type Polygon is record
      Verts : Vertex_Array := [others => (0.0, 0.0)];
      Count : Vertex_Count := 0;
      Tag   : Natural := 0;  -- optional caller identity retained through splits
   end record;

   --  2-D hyperplane (line): points P satisfying Dot (Normal, P) + Offset = 0.
   type Plane2 is record
      Normal : Vec2 := (1.0, 0.0);
      Offset : Real := 0.0;
   end record;

   type Side is (Front, Back, On_Plane);

   type Split_Segment_Result is record
      Front_Count : Natural := 0;
      Back_Count  : Natural := 0;
      On_Count    : Natural := 0;
      Front_Seg   : Segment;
      Back_Seg    : Segment;
      On_Seg      : Segment;
   end record;

   type Split_Polygon_Result is record
      Front : Polygon;
      Back  : Polygon;
      On    : Polygon;  -- coplanar remnant (may be empty)
   end record;

   ---------------------------------------------------------------------------
   -- Fixed-capacity BSP tree (educational; no unbounded heap)
   ---------------------------------------------------------------------------

   Max_Nodes            : constant Positive := 256;
   Max_Polygons         : constant Positive := 512;
   Max_Polys_Per_Node   : constant Positive := 16;
   Max_Input_Polygons   : constant Positive := 64;
   Max_Traversal_Output : constant Positive := 512;

   subtype Node_Index is Natural range 0 .. Max_Nodes;
   --  0 denotes "no child" / empty root.

   subtype Poly_Pool_Index is Positive range 1 .. Max_Polygons;
   subtype Poly_Pool_Count is Natural range 0 .. Max_Polygons;

   type Node_Poly_Slots is array (1 .. Max_Polys_Per_Node) of Poly_Pool_Index;

   type BSP_Node is record
      Plane      : Plane2;
      Has_Plane  : Boolean := False;
      Front      : Node_Index := 0;
      Back       : Node_Index := 0;
      Polys      : Node_Poly_Slots := [others => 1];
      Poly_Count : Natural := 0;
      Is_Solid   : Boolean := False;  -- educational solid-leaf flag
   end record;

   type Node_Array is array (1 .. Max_Nodes) of BSP_Node;
   type Polygon_Pool is array (Poly_Pool_Index) of Polygon;

   type BSP_Tree is record
      Nodes      : Node_Array;
      Node_Count : Node_Index := 0;
      Polys      : Polygon_Pool;
      Poly_Count : Poly_Pool_Count := 0;
      Root       : Node_Index := 0;
   end record;

   type Traversal_Order is (Back_To_Front, Front_To_Back);

   type Traversal_Entry is record
      Poly_Id : Poly_Pool_Index := 1;
      Node_Id : Node_Index := 0;
   end record;

   type Traversal_Array is
     array (1 .. Max_Traversal_Output) of Traversal_Entry;

   type Traversal_Result is record
      Entries : Traversal_Array;
      Count   : Natural := 0;
   end record;

   type Ray_Hit is record
      Hit      : Boolean := False;
      Point    : Vec2 := (0.0, 0.0);
      T        : Real := 0.0;  -- parameter along segment [0,1]
      Poly_Id  : Poly_Pool_Index := 1;
      Distance : Non_Negative := 0.0;
   end record;

   type Splitter_Heuristic is (First_Polygon, Least_Split);

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

   function Norm (V : Vec2) return Non_Negative
     with Global => null;

   function Normalize (V : Vec2) return Vec2
     with Global => null;
   --  Raises Degenerate_Geometry when ||V|| ≈ 0.

   ---------------------------------------------------------------------------
   -- Constructors / helpers
   ---------------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment
     with Post => Make_Segment'Result.P0 = P0
                  and then Make_Segment'Result.P1 = P1,
          Global => null;

   function Length (S : Segment) return Non_Negative
     with Global => null;

   function Make_Polygon
     (Verts : Vertex_Array;
      Count : Vertex_Count;
      Tag   : Natural := 0) return Polygon
     with Pre    => Count <= Max_Vertices,
          Post   => Make_Polygon'Result.Count = Count
                    and then Make_Polygon'Result.Tag = Tag,
          Global => null;

   function Make_Rect_Polygon
     (X0, Y0, X1, Y1 : Real; Tag : Natural := 0) return Polygon
     with Pre    => X1 > X0 and then Y1 > Y0,
          Post   => Make_Rect_Polygon'Result.Count = 4,
          Global => null;
   --  CCW axis-aligned rectangle as a 4-gon.

   function Make_Plane_From_Points (A, B : Vec2) return Plane2
     with Global => null;
   --  Line through A→B; Normal is leftward unit perpendicular (CCW).
   --  Raises Degenerate_Geometry when A ≈ B.

   function Make_Plane_From_Polygon (P : Polygon) return Plane2
     with Pre => P.Count >= 2, Global => null;
   --  Uses first edge (Verts 1→2). Raises Degenerate_Geometry if degenerate.

   function Make_Axis_Aligned_Plane
     (Vertical : Boolean; Coord : Real) return Plane2
     with Global => null;
   --  Vertical=True → plane X = Coord (Normal = (1,0));
   --  Vertical=False → plane Y = Coord (Normal = (0,1)).

   function Signed_Distance (P : Vec2; Plane : Plane2) return Real
     with Global => null;

   function Is_Empty_Tree (T : BSP_Tree) return Boolean
     with Global => null;

   function Node_Count (T : BSP_Tree) return Natural
     with Global => null;

   function Polygon_Count (T : BSP_Tree) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Classification & splitting (Fuchs-style polygon cut)
   ---------------------------------------------------------------------------

   function Classify_Point (P : Vec2; Plane : Plane2) return Side
     with Global => null;

   function Classify_Polygon (Poly : Polygon; Plane : Plane2) return Side
     with Pre => Poly.Count >= 1, Global => null;
   --  Front/Back if all vertices strictly on that side; On_Plane if all on;
   --  otherwise straddling is reported as On_Plane only when ALL on — for
   --  straddling use Split_Polygon. Convenience: returns Front if mixed with
   --  majority front is NOT done; straddling returns On_Plane with no verts?
   --  Actually: if any front and any back → treated specially via Split.
   --  This helper returns Front / Back / On_Plane when unanimous; for
   --  straddling returns On_Plane and callers should Split. Prefer
   --  Polygon_Relation below for clarity.

   type Polygon_Relation is (Wholly_Front, Wholly_Back, Coplanar, Straddling);

   function Relate_Polygon
     (Poly : Polygon; Plane : Plane2) return Polygon_Relation
     with Pre => Poly.Count >= 1, Global => null;

   function Split_Segment
     (S : Segment; Plane : Plane2) return Split_Segment_Result
     with Global => null;
   --  Cuts S against Plane. Front/Back pieces when straddling; On when
   --  coplanar; single-sided when wholly on one side.

   function Split_Polygon
     (Poly : Polygon; Plane : Plane2) return Split_Polygon_Result
     with Pre => Poly.Count >= 3, Global => null;
   --  Fuchs-style cut: straddling polygons are divided into Front and Back
   --  pieces; coplanar vertices collect into On.

   ---------------------------------------------------------------------------
   -- Build BSP (auto generation / Fuchs et al. preprocessing)
   ---------------------------------------------------------------------------

   type Polygon_List is array (1 .. Max_Input_Polygons) of Polygon;
   subtype Input_Count is Natural range 0 .. Max_Input_Polygons;

   function Build_BSP
     (Polys      : Polygon_List;
      Count      : Input_Count;
      Heuristic  : Splitter_Heuristic := Least_Split) return BSP_Tree
     with Pre => Count <= Max_Input_Polygons, Global => null;
   --  Auto BSP generation: choose splitting polygon, partition remaining
   --  into front / back / coplanar (splitting straddlers), recurse.
   --  Raises Capacity_Exceeded when the fixed node/polygon pool overflows.
   --  Raises Invalid_Argument when Count = 0 (returns empty tree instead —
   --  empty input yields Is_Empty_Tree).

   function Build_KD_Style
     (Polys : Polygon_List;
      Count : Input_Count) return BSP_Tree
     with Pre => Count <= Max_Input_Polygons, Global => null;
   --  Educational axis-aligned special case: splitters are horizontal or
   --  vertical only (alternating). Demonstrates that BSP generalizes k-d
   --  trees (arbitrary hyperplane orientations vs axis-aligned).

   ---------------------------------------------------------------------------
   -- Traversal (painter's algorithm ordering)
   ---------------------------------------------------------------------------

   function Traverse
     (T     : BSP_Tree;
      Eye   : Vec2;
      Order : Traversal_Order) return Traversal_Result
     with Global => null;
   --  Back_To_Front: painter's algorithm (far → near).
   --  Front_To_Back: early-Z / visibility style (near → far).
   --  Emits coplanar/node polygons at each visited node in tree order.

   function Traverse_Back_To_Front
     (T : BSP_Tree; Eye : Vec2) return Traversal_Result
     with Global => null;

   function Traverse_Front_To_Back
     (T : BSP_Tree; Eye : Vec2) return Traversal_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Queries (spatial / collision lite)
   ---------------------------------------------------------------------------

   function Point_In_Solid (T : BSP_Tree; P : Vec2) return Boolean
     with Global => null;
   --  Walk to a leaf following Classify_Point; return that leaf's Is_Solid.
   --  For Fuchs rendering trees without solid flags, typically False unless
   --  Build marked solid leaves. Empty tree → False.

   function Classify_Point_In_Tree (T : BSP_Tree; P : Vec2) return Side
     with Global => null;
   --  Side of the deepest splitting plane reached (On_Plane if empty tree
   --  or exact plane hit during descent with no preferred child).

   function Ray_Cast_2D (T : BSP_Tree; Ray : Segment) return Ray_Hit
     with Global => null;
   --  Educational segment–tree collision: traverse near-to-far, report the
   --  first intersection with a stored polygon edge.

   function Segment_Hits_Tree
     (T : BSP_Tree; S : Segment) return Boolean
     with Global => null;

end Binary_Space_Partitioning;
