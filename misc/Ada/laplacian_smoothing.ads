--  Laplacian_Smoothing — Ada 2023 educational package for Laplacian
--  (umbrella) mesh vertex smoothing: each free vertex moves toward the
--  average of its neighbours with step λ ∈ (0, 1]. Optional Dirichlet
--  pinning of boundary vertices. Primary source:
--  https://en.wikipedia.org/wiki/Laplacian_smoothing
--  Sibling packages (README only; do not `with`):
--    Ada-Polygon-Triangulation, Ada-Bowyer-Watson, Ada-Catmull-Clark /
--    Ada-Loop-Subdivision (ahead) — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Laplacian_Smoothing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on mesh vertices.
   Max_Vertices : constant Positive := 64;

   --  Soft classroom limit on adjacency degree per vertex.
   Max_Degree : constant Positive := 16;

   --  Soft classroom limit on outer Smooth iterations.
   Max_Iters : constant Positive := 64;

   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   subtype Degree_Count is Natural range 0 .. Max_Degree;
   subtype Iter_Count   is Natural range 0 .. Max_Iters;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Dense vertex positions; indices align with Adjacency_Array /
   --  Fixed_Flags of the same bounds.
   type Point_Array is array (Vertex_Index range <>) of Point;

   --  Neighbour index list for one vertex (1-based into the vertex array
   --  relative to Vertices'First mapped to 1, or absolute Vertex_Index
   --  matching Vertices'Range — see Build_Adjacency).
   type Neighbor_List is array (1 .. Max_Degree) of Vertex_Index;

   type Adjacency is record
      Neighbors : Neighbor_List := [others => 1];
      Count     : Degree_Count  := 0;
   end record;

   type Adjacency_Array is array (Vertex_Index range <>) of Adjacency;

   --  Fixed (I) = True pins vertex I (Dirichlet / boundary); it is left
   --  unchanged by Smooth_Once / Smooth.
   type Fixed_Flags is array (Vertex_Index range <>) of Boolean;

   --  Undirected edge for building adjacency from an edge list.
   type Edge is record
      A, B : Vertex_Index := 1;
   end record;

   type Edge_Array is array (Positive range <>) of Edge;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when a vertex set is empty, lengths exceed Max_Vertices,
   --  Vertices / Adj / Fixed lengths or bounds mismatch, λ ∉ (0, 1],
   --  Iterations = 0 or > Max_Iters, an edge is a self-loop / out of
   --  range, or a vertex degree would exceed Max_Degree.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist2 (A, B : Point) return Real
     with Global => null;
   --  Squared Euclidean distance (B − A)·(B − A).

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance ‖B − A‖₂.

   function Lerp (A, B : Point; T : Real) return Point
     with Global => null;
   --  (1 − T)·A + T·B (no range check on T; Smooth validates λ).

   ---------------------------------------------------------------------------
   -- Adjacency construction
   ---------------------------------------------------------------------------

   function Empty_Adjacency return Adjacency
     with Global => null;
   --  Count = 0.

   function Has_Neighbor (Adj : Adjacency; V : Vertex_Index) return Boolean
     with Global => null;
   --  True if V already appears in Adj.Neighbors (1 .. Adj.Count).

   procedure Add_Neighbor (Adj : in out Adjacency; V : Vertex_Index)
     with Global => null;
   --  Append V if not already present. Raises Invalid_Argument if
   --  Adj.Count = Max_Degree and V is new.

   function Build_Adjacency
     (Num_Vertices : Vertex_Count;
      Edges        : Edge_Array) return Adjacency_Array
     with Global => null;
   --  Build undirected adjacency for vertices 1 .. Num_Vertices from an
   --  edge list (each edge adds both directions; duplicates ignored).
   --  Raises Invalid_Argument if Num_Vertices = 0, an endpoint is outside
   --  1 .. Num_Vertices, A = B (self-loop), or Max_Degree is exceeded.

   function All_Free (First, Last : Vertex_Index) return Fixed_Flags
     with Global => null;
   --  Fixed_Flags (First .. Last) filled with False.

   function Neighbor_Average
     (Vertices : Point_Array;
      Adj      : Adjacency) return Point
     with Global => null;
   --  Arithmetic mean of Vertices (Adj.Neighbors (K)) for K in 1 .. Count.
   --  Raises Invalid_Argument if Count = 0 or any neighbour index is
   --  outside Vertices'Range.

   ---------------------------------------------------------------------------
   -- Laplacian / umbrella smoothing
   ---------------------------------------------------------------------------
   --  For each free vertex i with neighbour set N(i):
   --
   --    x̄_i = (1 / |N(i)|) Σ_{j ∈ N(i)} x_j
   --    x_i  ← (1 − λ) x_i + λ x̄_i
   --
   --  Jacobi-style: all averages use the input positions; updates are
   --  written to a fresh array. Isolated free vertices (degree 0) and
   --  pinned vertices are left unchanged. λ ∈ (0, 1].

   function Smooth_Once
     (Vertices : Point_Array;
      Adj      : Adjacency_Array;
      Lambda   : Real;
      Fixed    : Fixed_Flags) return Point_Array
     with Global => null;
   --  One Jacobi Laplacian step. Raises Invalid_Argument if Vertices is
   --  empty, length > Max_Vertices, Adj / Fixed do not match
   --  Vertices'Range, or Lambda not in (0, 1].

   function Smooth_Once
     (Vertices : Point_Array;
      Adj      : Adjacency_Array;
      Lambda   : Real) return Point_Array
     with Global => null;
   --  Same as Smooth_Once with all vertices free.

   function Smooth
     (Vertices   : Point_Array;
      Adj        : Adjacency_Array;
      Lambda     : Real;
      Iterations : Positive;
      Fixed      : Fixed_Flags) return Point_Array
     with Global => null;
   --  Apply Smooth_Once Iterations times. Raises Invalid_Argument if
   --  Iterations > Max_Iters, or on the same validation as Smooth_Once.

   function Smooth
     (Vertices   : Point_Array;
      Adj        : Adjacency_Array;
      Lambda     : Real;
      Iterations : Positive) return Point_Array
     with Global => null;
   --  Same as Smooth with all vertices free.

   function Mean_Edge_Length
     (Vertices : Point_Array;
      Adj      : Adjacency_Array) return Real
     with Global => null;
   --  Mean of ‖x_i − x_j‖ over unique undirected edges (i < j neighbour).
   --  Raises Invalid_Argument if empty mesh or no edges.

end Laplacian_Smoothing;
