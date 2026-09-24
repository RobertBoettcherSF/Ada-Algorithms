--  Euclidean_Minimum_Spanning_Tree — Ada 2023 educational package for the
--  Euclidean minimum spanning tree (EMST) of a finite 2-D point set.
--  Connects the points by line segments of minimum total Euclidean length.
--  Equivalent to the MST of the complete graph on the points with edge
--  weights equal to (rounded) Euclidean distances.
--  Implementation: build the complete geometric graph in fixed arrays,
--  then run self-contained dense Prim and Kruskal (do NOT `with` MST /
--  Prim / Kruskal sibling packages). Documented relationship: an EMST is
--  always a subgraph of the Delaunay triangulation (this sheet does not
--  implement Delaunay; see sibling Ada-Delaunay-Triangulation).
--  Reference: https://en.wikipedia.org/wiki/Euclidean_minimum_spanning_tree
--  Sibling sheets (README only — do not `with`): Minimum Spanning Tree,
--  Prim, Kruskal, Delaunay Triangulation — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Euclidean_Minimum_Spanning_Tree
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of 2-D points (indices 1 .. Max_Points).
   --  Complete-graph edge count is N*(N-1)/2; educational O(N^2) storage.
   Max_Points : constant Positive := 256;

   --  Maximum undirected edges of the complete geometric graph.
   Max_Edges : constant Positive := Max_Points * (Max_Points - 1) / 2;

   ---------------------------------------------------------------------------
   -- Points, indices, rounded Euclidean lengths
   ---------------------------------------------------------------------------

   --  Integer coordinates for reproducible classroom tests. Squared
   --  differences are computed in Long_Integer; callers should keep
   --  coordinates modest enough that (dx)^2+(dy)^2 fits in Long_Integer.
   type Point is record
      X, Y : Integer := 0;
   end record;

   type Point_Index is range 1 .. Max_Points;

   --  Rounded Euclidean distance: round(sqrt(dx^2 + dy^2)) to nearest
   --  integer (half away from zero via Long_Float'Rounding).
   type Length_Type is range 0 .. 2**31 - 1;

   --  Sum of kept tree edge lengths (wide educational accumulator).
   type Length_Sum is range 0 .. 2**63 - 1;

   --  One undirected tree edge between point indices U and V, with the
   --  rounded Euclidean Length used as the MST weight.
   type Edge_Record is record
      U, V   : Point_Index;
      Length : Length_Type;
   end record;

   --  Caller-supplied buffer for EMST edges (need capacity >= N-1).
   type Edge_List is array (Positive range <>) of Edge_Record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Add_Point capacity overflow, Compute / EMST / Prim /
   --  Kruskal when Point_Count < 2 (too few points for a spanning tree
   --  with edges), or Tree_Edges bounds that cannot hold the result
   --  (First /= 1 or Last < N-1 when N >= 2).

   ---------------------------------------------------------------------------
   -- Point set API
   ---------------------------------------------------------------------------

   type Point_Set is limited private;

   procedure Clear (S : in out Point_Set)
     with Global => null;
   --  Reset S to the empty point set (Point_Count = 0).

   procedure Add_Point (S : in out Point_Set; P : Point)
     with Global => null;
   --  Append point P (1-based index = new Point_Count). Raises
   --  Invalid_Argument when Point_Count would exceed Max_Points.
   --  Duplicate coordinates are permitted (zero-length edges may appear
   --  in the complete graph; MST still well-defined).

   function Point_Count (S : Point_Set) return Natural
     with Global => null;
   --  Number of points currently stored (0 .. Max_Points).

   function Get_Point (S : Point_Set; Index : Point_Index) return Point
     with Global => null;
   --  Point at Index. Raises Invalid_Argument when Index > Point_Count(S).

   function Rounded_Euclidean (A, B : Point) return Length_Type
     with Global => null;
   --  round(sqrt((A.X-B.X)^2 + (A.Y-B.Y)^2)) as Length_Type.

   ---------------------------------------------------------------------------
   -- EMST algorithms (complete graph + Prim / Kruskal)
   ---------------------------------------------------------------------------
   --  Build the complete undirected graph on the points with edge weight
   --  = Rounded_Euclidean, then compute an MST. Both Prim and Kruskal
   --  agree on Total_Length (and edge count N-1); edge sets may differ
   --  when equal rounded lengths create alternate optima.
   --  Dense Prim: O(N^2) array scan over cut keys (natural for K_N).
   --  Kruskal: insertion-sort edges + Union–Find; educational O(E^2).
   --  Compute / EMST are synonyms that call Prim.

   procedure Prim
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
     with Global => null;
   --  Dense Prim EMST of S. Writes Tree_Count = N-1 edges to
   --  Tree_Edges(1 .. Tree_Count) and Total_Length = sum of lengths.
   --  Raises Invalid_Argument when N < 2 or Tree_Edges'First /= 1 or
   --  Tree_Edges'Last < N-1.

   procedure Kruskal
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
     with Global => null;
   --  Kruskal EMST of S (same contracts as Prim).

   procedure Compute
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
     with Global => null;
   --  Primary entry: EMST via dense Prim (same contracts as Prim).

   procedure EMST
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
     with Global => null;
   --  Synonym for Compute.

private

   type Point_Array is array (1 .. Max_Points) of Point;

   type Point_Set is limited record
      N      : Natural := 0;
      Points : Point_Array;
   end record;

end Euclidean_Minimum_Spanning_Tree;
