--  Coin_Graph — Ada 2023 educational package for coin graphs (circle
--  packing contact graphs). A circle packing is a finite collection of
--  disks whose interiors are pairwise disjoint (touching is allowed).
--  The coin graph (intersection / contact graph) has one vertex per disk
--  and an undirected edge whenever two disks are externally tangent.
--  By the Koebe–Andreev–Thurston circle packing theorem, the coin graphs
--  are exactly the finite connected simple planar graphs. This sheet
--  extracts the contact graph from a given list of disks; it does not
--  construct a packing for an abstract planar graph.
--  Reference: https://en.wikipedia.org/wiki/Circle_packing_theorem
--  Sibling sheets (README only — do not `with`): Force-Based Algorithms,
--  Euclidean Minimum Spanning Tree, Delaunay Triangulation —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Coin_Graph
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of disks / coins (indices 1 .. Max_Circles).
   Max_Circles : constant Positive := 256;

   --  Maximum undirected contact edges (complete-graph upper bound).
   Max_Edges : constant Positive := Max_Circles * (Max_Circles - 1) / 2;

   ---------------------------------------------------------------------------
   -- Circles, indices, contact edges
   ---------------------------------------------------------------------------

   --  Disk with integer center (X, Y) and positive integer radius R.
   --  Integer geometry keeps classroom tests reproducible; Euclidean
   --  distance checks use Long_Float with a fixed absolute tolerance so
   --  near-tangencies from floating residual still count as contacts.
   type Circle is record
      X, Y : Integer := 0;
      R    : Integer := 1;
   end record;

   type Circle_Index is range 1 .. Max_Circles;

   --  One undirected contact edge between circle indices U and V.
   type Edge_Record is record
      U, V : Circle_Index;
   end record;

   --  Caller-supplied buffer for contact edges (need capacity >= binom(N,2)
   --  in the worst case; educational callers typically size to Max_Edges
   --  or N*(N-1)/2 for the current N).
   type Edge_List is array (Positive range <>) of Edge_Record;

   --  Absolute Euclidean tolerance for tangency / overlap tests:
   --    |d − (r_i + r_j)| ≤ Epsilon  ⇒ externally tangent (contact edge)
   --    d + Epsilon < r_i + r_j      ⇒ interiors overlap (invalid packing)
   Epsilon : constant Long_Float := 1.0E-6;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Add_Circle when radius R ≤ 0 or capacity would exceed
   --  Max_Circles; for Get_Circle / Are_Tangent when an index is outside
   --  1 .. Circle_Count; for Build_Contact_Graph / Contact_Edges when
   --  Edges'First /= 1 or Edges'Last is too small to hold the result
   --  (needs Last ≥ binom(N,2) for safety, or at least the actual contact
   --  count — this sheet requires Last ≥ N*(N-1)/2 when N ≥ 2, and
   --  Last ≥ 0 when N < 2); for Add_Equal_Radius_Grid when Rows/Cols are
   --  zero, Radius ≤ 0, or the grid would overflow Max_Circles.

   ---------------------------------------------------------------------------
   -- Circle packing (disk collection)
   ---------------------------------------------------------------------------

   type Packing is limited private;

   procedure Clear (P : in out Packing)
     with Global => null;
   --  Reset P to the empty packing (Circle_Count = 0).

   procedure Add_Circle (P : in out Packing; C : Circle)
     with Global => null;
   --  Append disk C (1-based index = new Circle_Count). Raises
   --  Invalid_Argument when C.R ≤ 0 or Circle_Count would exceed
   --  Max_Circles.

   function Circle_Count (P : Packing) return Natural
     with Global => null;
   --  Number of disks currently stored (0 .. Max_Circles).

   function Get_Circle (P : Packing; Index : Circle_Index) return Circle
     with Global => null;
   --  Disk at Index. Raises Invalid_Argument when Index > Circle_Count(P).

   ---------------------------------------------------------------------------
   -- Geometry helpers
   ---------------------------------------------------------------------------

   function Euclidean_Distance (A, B : Circle) return Long_Float
     with Global => null;
   --  sqrt((A.X−B.X)^2 + (A.Y−B.Y)^2) as Long_Float.

   function Sum_Of_Radii (A, B : Circle) return Long_Float
     with Global => null;
   --  Long_Float (A.R) + Long_Float (B.R).

   function Are_Externally_Tangent (A, B : Circle) return Boolean
     with Global => null;
   --  True iff |Euclidean_Distance(A,B) − Sum_Of_Radii(A,B)| ≤ Epsilon.

   function Interiors_Overlap (A, B : Circle) return Boolean
     with Global => null;
   --  True iff Euclidean_Distance(A,B) + Epsilon < Sum_Of_Radii(A,B).

   ---------------------------------------------------------------------------
   -- Validity, tangency queries, contact graph
   ---------------------------------------------------------------------------

   function Is_Valid_Packing (P : Packing) return Boolean
     with Global => null;
   --  True iff every pair of disks has disjoint interiors (touching is
   --  allowed). Vacuously True when Circle_Count < 2.

   function Are_Tangent (P : Packing; I, J : Circle_Index) return Boolean
     with Global => null;
   --  True iff disks I and J are externally tangent within Epsilon.
   --  Raises Invalid_Argument when I or J is outside 1 .. Circle_Count,
   --  or when I = J.

   procedure Build_Contact_Graph
     (P     : Packing;
      Edges : in out Edge_List;
      Count : out Natural)
     with Global => null;
   --  Write every unordered contact edge {U,V} (U < V) into
   --  Edges(1 .. Count). Count may be 0. Raises Invalid_Argument when
   --  Edges'First /= 1 or Edges'Last < N*(N-1)/2 for N = Circle_Count
   --  (when N ≥ 2); for N < 2 requires First = 1 and Last ≥ 0.

   procedure Contact_Edges
     (P     : Packing;
      Edges : in out Edge_List;
      Count : out Natural)
     with Global => null;
   --  Synonym for Build_Contact_Graph.

   ---------------------------------------------------------------------------
   -- Optional equal-radius grid packing helper
   ---------------------------------------------------------------------------

   procedure Add_Equal_Radius_Grid
     (P      : in out Packing;
      Rows   : Positive;
      Cols   : Positive;
      Radius : Positive;
      Origin_X : Integer := 0;
      Origin_Y : Integer := 0)
     with Global => null;
   --  Append a Rows × Cols lattice of equal-radius disks centered at
   --  (Origin_X + (C-1)*2*Radius, Origin_Y + (R-1)*2*Radius) so that
   --  horizontally / vertically adjacent coins are exactly tangent.
   --  Raises Invalid_Argument when Radius ≤ 0 (caught by Positive) is
   --  impossible, or when appending would exceed Max_Circles.

private

   type Circle_Array is array (1 .. Max_Circles) of Circle;

   type Packing is limited record
      N       : Natural := 0;
      Circles : Circle_Array;
   end record;

end Coin_Graph;
