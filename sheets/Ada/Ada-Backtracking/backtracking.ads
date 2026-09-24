--  Backtracking — Ada 2023 educational package for Wikipedia
--  "Backtracking": incrementally build candidates and abandon
--  ("backtrack") a partial candidate as soon as it cannot be
--  completed to a valid solution. Demonstrations: N-Queens,
--  subset sum with pruning, and graph colouring on small graphs.
--  Contrast: brute-force exhaustive search without pruning.
--  Reference: https://en.wikipedia.org/wiki/Backtracking
--  Sibling sheets (README only — do not `with`): Brute_Force_Search,
--  Branch_And_Bound, Breadth_First_Search, Depth_First_Search.

pragma Ada_2022;

package Backtracking
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational capacity bounds (raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum board size for N-Queens. Counting solutions for N = 14
   --  is still a light educational workload (~3.6·10^5 solutions).
   Max_N : constant Positive := 14;

   --  Maximum length for Subset_Sum. With pruning (reject when partial
   --  sum exceeds Target or remaining capacity cannot reach Target)
   --  larger n is fine; still capped for demos.
   Max_Subset_N : constant Positive := 40;

   --  Graph colouring: vertices and colours.
   Max_Vertices : constant Positive := 16;
   Max_Colors   : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Placement (I) = column of the queen in row I (1 .. N).
   type Queen_Array is array (Positive range <>) of Natural;

   type Element_Array is array (Positive range <>) of Integer;
   type Boolean_Array is array (Positive range <>) of Boolean;

   --  Symmetric adjacency matrix; Adj (I, J) = True iff edge I—J.
   type Adjacency_Matrix is
     array (Positive range <>, Positive range <>) of Boolean;

   --  Colors (V) ∈ 1 .. K_Colors when coloured; 0 when unset.
   type Color_Array is array (Positive range <>) of Natural;

   Invalid_Argument : exception;
   --  Raised when N > Max_N, A'Length > Max_Subset_N, array lengths
   --  mismatch, graph dimensions inconsistent, or K_Colors out of range.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia backtrack meta-procedure)
   ---------------------------------------------------------------------------
   --  root(P)     — empty / root partial candidate
   --  reject(P,c) — True only if c cannot possibly extend to a solution
   --  accept(P,c) — True if c is a complete valid solution
   --  first(P,c)  — first one-step extension of c
   --  next(P,s)   — next sibling extension after s
   --  output(P,c) — report solution c
   --
   --  procedure backtrack(P, c) is
   --     if reject(P, c) then return
   --     if accept(P, c) then output(P, c)
   --     s ← first(P, c)
   --     while s ≠ NULL do
   --        backtrack(P, s)
   --        s ← next(P, s)
   --
   --  If reject always returns False, the search is equivalent to
   --  brute-force enumeration of the potential search tree.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- 1. N-Queens (Wikipedia classic textbook example)
   ---------------------------------------------------------------------------

   function Solve_N_Queens
     (N         : Positive;
      Placement : out Queen_Array) return Boolean
     with Global => null;
   --  Place N queens on an N×N board so that no two share a row, column,
   --  or diagonal. Writes one solution into Placement (1-based columns
   --  for rows 1 .. N) and returns True; returns False if none exists
   --  (N = 2, 3). Placement'Length must equal N; Placement'First = 1.
   --  Raises Invalid_Argument when N > Max_N or Placement bounds wrong.
   --  Partial candidates: k queens in the first k rows, distinct columns.
   --  reject: any two mutually attacking among the k placed queens.

   function Count_N_Queens (N : Positive) return Natural
     with Global => null;
   --  Count all solutions of the N-Queens problem (fundamental sequence:
   --  N=4 → 2, N=8 → 92, …). Raises Invalid_Argument when N > Max_N.
   --  Time dominated by the size of the pruned search tree (far smaller
   --  than N^N brute force).

   function Is_Safe_Placement
     (Placement : Queen_Array;
      N         : Positive) return Boolean
     with Global => null;
   --  True iff Placement (1 .. N) is a complete non-attacking placement
   --  (each entry in 1 .. N, all columns distinct, no diagonal clash).
   --  Raises Invalid_Argument when N > Max_N or Placement'Last < N
   --  or Placement'First /= 1.

   ---------------------------------------------------------------------------
   -- 2. Subset sum (backtracking with prune vs brute-force 2^n)
   ---------------------------------------------------------------------------

   function Subset_Sum
     (A      : Element_Array;
      Target : Integer;
      Chosen : out Boolean_Array) return Boolean
     with Global => null;
   --  Decide whether a subset of A sums to Target. On success, Chosen (I)
   --  is True iff A (I) is in the found subset; on failure Chosen is all
   --  False. Empty subset sums to 0. Elements may be negative; pruning
   --  uses remaining positive/negative capacity when possible.
   --  Raises Invalid_Argument when A'Length > Max_Subset_N, lengths
   --  mismatch, or A'First /= Chosen'First.
   --  Contrast: Brute_Force_Search.Subset_Sum_Exists enumerates all 2^n
   --  masks with no prune.

   function Subset_Sum_Exists
     (A      : Element_Array;
      Target : Integer) return Boolean
     with Global => null;
   --  Same decision problem without writing Chosen.
   --  Raises Invalid_Argument when A'Length > Max_Subset_N.

   ---------------------------------------------------------------------------
   -- 3. Graph colouring (constraint satisfaction on small graphs)
   ---------------------------------------------------------------------------

   function Color_Graph
     (Adj      : Adjacency_Matrix;
      K_Colors : Positive;
      Colors   : out Color_Array) return Boolean
     with Global => null;
   --  Assign each vertex a colour in 1 .. K_Colors so adjacent vertices
   --  differ. Vertices are Adj'Range (1); Adj must be square with the
   --  same bounds on both dimensions; Colors'Length must equal vertex
   --  count. On success Colors holds a valid colouring; on failure all
   --  zeros. Raises Invalid_Argument when vertex count > Max_Vertices,
   --  K_Colors > Max_Colors, or bounds inconsistent.
   --  Partial candidates: colours for vertices 1 .. k; reject when the
   --  newest colour conflicts with an earlier neighbour.

   function Is_Valid_Colouring
     (Adj    : Adjacency_Matrix;
      Colors : Color_Array;
      K      : Positive) return Boolean
     with Global => null;
   --  True iff Colors is a proper K-colouring of Adj (every colour in
   --  1 .. K, adjacent vertices differ). Raises Invalid_Argument on
   --  dimension / capacity violations.

end Backtracking;
