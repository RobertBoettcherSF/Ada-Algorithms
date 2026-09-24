--  Jump_Point_Search — Ada 2023 educational package for Jump Point Search
--  (JPS), an A* optimisation for uniform-cost 8-connected grids (Harabor &
--  Grastien). Symmetric path segments are pruned so the search expands
--  only "jump points" reached by long straight or diagonal runs, while
--  preserving A* optimality. This package also ships a plain A* oracle
--  (A_Star_Grid) for cost comparison on small grids.
--  Reference: https://en.wikipedia.org/wiki/Jump_point_search
--  Primary papers: Harabor & Grastien, SoCS 2011 / 2012 / 2014.

pragma Ada_2022;

package Jump_Point_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational fixed bounds — no heap beyond package locals)
   ---------------------------------------------------------------------------

   --  Maximum grid width and height (inclusive coordinate span).
   Max_Width  : constant Positive := 128;
   Max_Height : constant Positive := 128;

   --  Longest path that Find_Path / A_Star_Grid may write (cell-by-cell).
   Max_Path_Length : constant Positive := Max_Width * Max_Height;

   ---------------------------------------------------------------------------
   -- Geometry
   ---------------------------------------------------------------------------

   --  Grid cell coordinates. **0-based**: valid cells are
   --  X in 0 .. Width(G)-1 and Y in 0 .. Height(G)-1.
   type Point is record
      X, Y : Natural := 0;
   end record;

   type Path_Array is array (Positive range <>) of Point;

   --  Octile move costs (uniform grid). Cardinal step cost is 1;
   --  diagonal step cost is Sqrt(2). Used by JPS, A*, Path_Cost, and
   --  Octile_Heuristic.
   Cardinal_Cost : constant Float := 1.0;
   Diagonal_Cost : constant Float := 1.41421356237;  -- Sqrt(2)

   ---------------------------------------------------------------------------
   -- Occupancy grid
   ---------------------------------------------------------------------------

   type Grid is private;

   Invalid_Argument : exception;
   --  Raised when Width/Height are out of range, coordinates are outside
   --  the grid, Start/Goal are out of bounds, or Path'Length < Max_Path.

   procedure Clear
     (G      : in out Grid;
      Width  : Positive;
      Height : Positive)
     with Global => null;
   --  Create an empty (all free) Width x Height occupancy grid.
   --  Raises Invalid_Argument if Width > Max_Width or Height > Max_Height.

   procedure Set_Blocked
     (G       : in out Grid;
      P       : Point;
      Blocked : Boolean := True)
     with Global => null;
   --  Mark cell P blocked (True) or free (False).
   --  Raises Invalid_Argument if P is outside the grid.

   function Is_Blocked (G : Grid; P : Point) return Boolean
     with Global => null;
   --  True iff P is blocked. Raises Invalid_Argument if P is OOB.

   function Width  (G : Grid) return Natural with Global => null;
   function Height (G : Grid) return Natural with Global => null;

   function In_Bounds (G : Grid; P : Point) return Boolean
     with Global => null;
   --  True iff P lies in 0 .. Width-1, 0 .. Height-1 (does not raise).

   ---------------------------------------------------------------------------
   -- Movement model (documented corner-cutting policy)
   ---------------------------------------------------------------------------
   --  8-connected uniform-cost grid. Diagonal steps are allowed only when
   --  BOTH adjacent orthogonal cells are free (corner-cutting DISALLOWED).
   --  That matches Harabor & Grastien's 2012 "no corner-cutting" pruning
   --  rules and common game / robotics agents with positive footprint.
   --  Cardinal step: target free. Diagonal step: target free AND the two
   --  orthogonally adjacent cells on the move free.

   function Can_Step
     (G : Grid; From, Too : Point) return Boolean
     with Global => null;
   --  True if a single 8-connected step From -> Too is legal under the
   --  no-corner-cutting rule. Raises Invalid_Argument if From is OOB.
   --  (Too may be OOB → False.)

   function Octile_Heuristic (A, B : Point) return Float
     with Global => null;
   --  Admissible octile distance:
   --  max(dx,dy)*Cardinal + min(dx,dy)*(Diagonal-Cardinal).

   function Path_Cost
     (G : Grid; Path : Path_Array; Length : Natural) return Float
     with Global => null;
   --  Sum of legal step costs along Path(1 .. Length). Raises
   --  Invalid_Argument if Length > Path'Length, Length = 0 is allowed
   --  (cost 0), or any consecutive pair is an illegal step.

   ---------------------------------------------------------------------------
   -- Jump Point Search
   ---------------------------------------------------------------------------

   function Find_Path
     (G      : Grid;
      Start  : Point;
      Goal   : Point;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Optimal 8-connected path from Start to Goal via Jump Point Search
   --  (Harabor & Grastien) with the octile heuristic.
   --  On success: returns True, writes the cell-by-cell path into
   --  Path(Path'First .. Path'First+Length-1) with Path(Path'First)=Start
   --  and the last cell = Goal, Length >= 1.
   --  On failure (no path, or Start/Goal blocked): returns False, Length = 0.
   --  Start = Goal (free): True, Length = 1, Path = [Start].
   --  Raises Invalid_Argument if Start or Goal is out of bounds, or if
   --  Path'Length < Max_Path_Length.

   ---------------------------------------------------------------------------
   -- A* oracle (same movement / costs — for tests)
   ---------------------------------------------------------------------------

   function A_Star_Grid
     (G      : Grid;
      Start  : Point;
      Goal   : Point;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
     with Global => null;
   --  Classic A* on the same 8-connected no-corner-cutting graph and
   --  octile heuristic. Same success / failure / exception contract as
   --  Find_Path (including False when Start/Goal is blocked). Intended
   --  as a small-grid oracle: optimal path *cost* must match Find_Path
   --  (the concrete path may differ among optima).

private

   type Cell_Matrix is
     array (0 .. Max_Width - 1, 0 .. Max_Height - 1) of Boolean;

   type Grid is record
      Blocked : Cell_Matrix := [others => [others => False]];
      W       : Natural     := 0;
      H       : Natural     := 0;
   end record;

end Jump_Point_Search;
