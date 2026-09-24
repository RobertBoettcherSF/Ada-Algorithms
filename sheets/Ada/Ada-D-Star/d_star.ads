--  D_Star — Ada 2023 educational package for D* Lite (Koenig & Likhachev),
--  the practical incremental heuristic search of the D* family. The package
--  is named D_Star to match the family; the algorithm implemented here is
--  specifically **D* Lite** (not original Stentz D* or Focused D*). Search
--  proceeds backward from the goal; cell-cost / blockage updates are repaired
--  incrementally via g/rhs values and a lexicographic key priority queue.
--  An A_Star_Replan oracle is provided for cost comparison on small grids.
--  Reference: https://en.wikipedia.org/wiki/D*
--  Primary paper: Koenig & Likhachev, AAAI 2002 / ICRA 2002.

pragma Ada_2022;

package D_Star
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational fixed bounds)
   ---------------------------------------------------------------------------

   Max_Width  : constant Positive := 64;
   Max_Height : constant Positive := 64;

   --  Longest path Get_Path / A_Star_Replan may write (cell-by-cell).
   Max_Path_Length : constant Positive := Max_Width * Max_Height;

   --  Sentinel larger than any finite path cost on a Max_Width x Max_Height
   --  grid with per-cell costs bounded by Max_Cell_Cost.
   Infinity : constant Float := 1.0E12;

   --  Maximum finite cell traversal cost accepted by Set_Cell_Cost.
   Max_Cell_Cost : constant Float := 1.0E6;

   ---------------------------------------------------------------------------
   -- Geometry (4-connected, Manhattan)
   ---------------------------------------------------------------------------

   --  Grid cell coordinates. **0-based**: valid cells are
   --  X in 0 .. Width-1 and Y in 0 .. Height-1.
   type Point is record
      X, Y : Natural := 0;
   end record;

   type Path_Array is array (Positive range <>) of Point;

   --  Cardinal step base multiplier. Actual edge cost of a step into cell V
   --  is Get_Cell_Cost(V) (1.0 by default). Blocked cells are untraversable.
   Cardinal_Cost : constant Float := 1.0;

   ---------------------------------------------------------------------------
   -- Occupancy / cost grid (static map; no search state)
   ---------------------------------------------------------------------------

   type Grid is private;

   Invalid_Argument : exception;
   --  Raised for oversize grids, OOB coordinates, non-positive cell costs,
   --  uninitialized planner use, or a path buffer shorter than Max_Path_Length.

   procedure Clear
     (G      : in out Grid;
      Width  : Positive;
      Height : Positive)
     with Global => null;
   --  Create a Width x Height grid of free cells with cost 1.0.
   --  Raises Invalid_Argument if Width > Max_Width or Height > Max_Height.

   procedure Set_Blocked
     (G       : in out Grid;
      P       : Point;
      Blocked : Boolean := True)
     with Global => null;
   --  Mark cell P blocked (untraversable) or free. Free restores the last
   --  finite cell cost (or 1.0). Raises Invalid_Argument if P is OOB.

   procedure Set_Cell_Cost
     (G    : in out Grid;
      P    : Point;
      Cost : Float)
     with Global => null;
   --  Set traversal cost of free cell P (must be in (0, Max_Cell_Cost]).
   --  Also clears the blocked flag. Raises Invalid_Argument if P is OOB or
   --  Cost is not strictly positive and finite within Max_Cell_Cost.

   function Is_Blocked (G : Grid; P : Point) return Boolean
     with Global => null;
   --  True iff P is blocked. Raises Invalid_Argument if P is OOB.

   function Get_Cell_Cost (G : Grid; P : Point) return Float
     with Global => null;
   --  Traversal cost of P, or Infinity if blocked.
   --  Raises Invalid_Argument if P is OOB.

   function Width  (G : Grid) return Natural with Global => null;
   function Height (G : Grid) return Natural with Global => null;

   function In_Bounds (G : Grid; P : Point) return Boolean
     with Global => null;
   --  True iff P lies in 0 .. Width-1, 0 .. Height-1 (does not raise).

   function Manhattan_Heuristic (A, B : Point) return Float
     with Global => null;
   --  Admissible 4-connected heuristic: (|dx| + |dy|) * Cardinal_Cost.

   function Path_Cost
     (G : Grid; Path : Path_Array; Length : Natural) return Float
     with Global => null;
   --  Sum of step costs along Path(1 .. Length): each step into V adds
   --  Get_Cell_Cost(V). Length 0 or 1 yields 0. Raises Invalid_Argument if
   --  Length > Path'Length or any consecutive pair is not a legal cardinal
   --  step onto a free cell.

   ---------------------------------------------------------------------------
   -- D* Lite planner (incremental; owns a mutable map copy)
   ---------------------------------------------------------------------------

   type Planner is limited private;

   procedure Initialize
     (Pl    : in out Planner;
      G     : Grid;
      Start : Point;
      Goal  : Point)
     with Global => null;
   --  Copy G into the planner, set Start/Goal, run D* Lite from Goal
   --  (backward search) to compute an initial shortest path under the
   --  freespace / cost map. Raises Invalid_Argument if Start or Goal is
   --  out of bounds for G.

   function Path_Exists (Pl : Planner) return Boolean
     with Global => null;
   --  True iff a finite path from Start to Goal is known.
   --  Raises Invalid_Argument if Pl was never Initialize'd.

   procedure Get_Path
     (Pl     : Planner;
      Path   : out Path_Array;
      Length : out Natural)
     with Global => null;
   --  Write the cell-by-cell path Start .. Goal into Path.
   --  If no path: Length = 0. If Start = Goal (free): Length = 1.
   --  Raises Invalid_Argument if not initialized or Path'Length < Max_Path_Length.

   function Path_Cost (Pl : Planner) return Float
     with Global => null;
   --  Cost of the current planned path, or Infinity if none.
   --  Raises Invalid_Argument if not initialized.

   function Expansion_Count (Pl : Planner) return Natural
     with Global => null;
   --  Vertices popped from the D* Lite priority queue during the most recent
   --  ComputeShortestPath (Initialize or Replan). Useful to show incremental
   --  repair expands fewer nodes than a full restart on local map changes.
   --  Raises Invalid_Argument if not initialized.

   function Start_Point (Pl : Planner) return Point
     with Global => null;
   function Goal_Point  (Pl : Planner) return Point
     with Global => null;
   --  Raise Invalid_Argument if not initialized.

   procedure Update_Cell_Cost
     (Pl   : in out Planner;
      P    : Point;
      Cost : Float)
     with Global => null;
   --  Change traversal cost of P inside the planner map and mark affected
   --  vertices inconsistent (does not search yet — call Replan).
   --  Raises Invalid_Argument if not initialized, P OOB, or Cost invalid.

   procedure Set_Blocked
     (Pl      : in out Planner;
      P       : Point;
      Blocked : Boolean := True)
     with Global => null;
   --  Block or unblock P inside the planner map and mark affected vertices
   --  inconsistent (call Replan afterward). Raises Invalid_Argument if not
   --  initialized or P OOB.

   procedure Replan (Pl : in out Planner)
     with Global => null;
   --  Run D* Lite ComputeShortestPath to repair the search after cost /
   --  blockage updates. Raises Invalid_Argument if not initialized.

   ---------------------------------------------------------------------------
   -- A* oracle (full restart — same 4-connected costs / Manhattan heuristic)
   ---------------------------------------------------------------------------

   function A_Star_Replan
     (G      : Grid;
      Start  : Point;
      Goal   : Point;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Classic A* from Start to Goal on G. Same success/failure contract as
   --  Get_Path after Initialize: True + path, or False / Length = 0.
   --  Optimal path *cost* must match D* Lite on unchanged maps (and after
   --  Replan on updated maps). Raises Invalid_Argument if Start/Goal OOB or
   --  Path'Length < Max_Path_Length.

private

   type Cost_Matrix is
     array (0 .. Max_Width - 1, 0 .. Max_Height - 1) of Float;
   type Flag_Matrix is
     array (0 .. Max_Width - 1, 0 .. Max_Height - 1) of Boolean;

   type Grid is record
      Cost    : Cost_Matrix := [others => [others => 1.0]];
      Blocked : Flag_Matrix := [others => [others => False]];
      W       : Natural     := 0;
      H       : Natural     := 0;
   end record;

   --  Priority-queue capacity: one slot per cell (lazy duplicate keys allowed).
   Heap_Cap : constant Positive := Max_Width * Max_Height * 4;

   type Key_Pair is record
      K1, K2 : Float := Infinity;
   end record;

   type Heap_Entry is record
      Key : Key_Pair;
      P   : Point;
   end record;

   type Heap_Store is array (1 .. Heap_Cap) of Heap_Entry;
   type Val_Matrix is
     array (0 .. Max_Width - 1, 0 .. Max_Height - 1) of Float;
   type Planner is limited record
      Map         : Grid;
      Start       : Point   := (0, 0);
      Goal        : Point   := (0, 0);
      Km          : Float   := 0.0;
      G_Val       : Val_Matrix := [others => [others => Infinity]];
      Rhs         : Val_Matrix := [others => [others => Infinity]];
      Heap        : Heap_Store;
      Heap_Size   : Natural := 0;
      Initialized : Boolean := False;
      Expansions  : Natural := 0;
   end record;

end D_Star;
