--  Min_Conflicts — Ada 2023 educational package for the min-conflicts
--  hill-climbing heuristic (Minton et al.) for constraint satisfaction
--  problems (CSPs). Flagship demo: N-queens local search with optional
--  random restarts. Also a tiny map-coloring binary CSP sketch.
--  Primary source: https://en.wikipedia.org/wiki/Min-conflicts_algorithm
--  Also: Constraint satisfaction problem, Local search (optimization).
--  Siblings (README links only — no package deps):
--  Ada-Dancing-Links, Ada-Algorithm-X, Ada-Local-Search.

pragma Ada_2022;

package Min_Conflicts
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain (N-queens)
   ---------------------------------------------------------------------------

   Max_N : constant := 32;
   --  Educational cap; tests focus on N <= 16.

   subtype Queens_N is Positive range 1 .. Max_N;
   subtype Column_Index is Positive range 1 .. Max_N;
   subtype Row_Index is Positive range 1 .. Max_N;

   --  Complete assignment: Board (Row) = column of the queen in that row.
   --  Valid boards use indices 1 .. N with values in 1 .. N.
   type Board is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Parameters / result
   ---------------------------------------------------------------------------

   --  Max_Steps : inner hill-climb budget per restart
   --  Seed      : LCG seed for reproducible random choices
   --  Restarts  : additional full restarts after the first attempt (0 = one try)
   type Parameters is record
      Max_Steps : Natural := 1_000;
      Seed      : Natural := 1;
      Restarts  : Natural := 0;
   end record;

   type Solve_Result is record
      Solved           : Boolean := False;
      Steps_Used       : Natural := 0;
      Restarts_Used    : Natural := 0;
      Final_Conflicts  : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible tie-breaks / restarts
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Defaults / builders
   ---------------------------------------------------------------------------

   function Default_Parameters
     (Max_Steps : Natural := 1_000;
      Seed      : Natural := 1;
      Restarts  : Natural := 0) return Parameters
     with Global => null;

   procedure Random_Board
     (B     : out Board;
      N     : Queens_N;
      State : in out RNG_State)
     with Pre => B'First = 1 and then B'Last = N, Global => null;
   --  Uniform random column in 1 .. N for each row.

   procedure Greedy_Board
     (B     : out Board;
      N     : Queens_N;
      State : in out RNG_State)
     with Pre => B'First = 1 and then B'Last = N, Global => null;
   --  Place queens row-by-row choosing a min-conflict column (ties random).

   ---------------------------------------------------------------------------
   -- Conflict counting (N-queens)
   ---------------------------------------------------------------------------

   function Variable_Conflicts (B : Board; Row : Positive) return Natural
     with Pre =>
       Row in B'Range
       and then (for all R in B'Range => B (R) in 1 .. B'Length),
       Global => null;
   --  Number of other queens attacking the queen in Row
   --  (same column or same diagonal).

   function Conflict_Count (B : Board) return Natural
     with Pre => (for all R in B'Range => B (R) in 1 .. B'Length),
          Global => null;
   --  Number of attacking pairs (= sum Variable_Conflicts / 2).

   function Is_Solved (B : Board) return Boolean
     with Pre => (for all R in B'Range => B (R) in 1 .. B'Length),
          Global => null;

   ---------------------------------------------------------------------------
   -- Core min-conflicts operators
   ---------------------------------------------------------------------------

   function Min_Conflict_Value
     (B     : Board;
      Row   : Positive;
      State : in out RNG_State) return Column_Index
     with Pre =>
       Row in B'Range
       and then (for all R in B'Range => B (R) in 1 .. B'Length),
       Global => null;
   --  Column in 1 .. N that minimizes Variable_Conflicts for Row
   --  (ties broken uniformly at random).

   function Pick_Conflicted_Variable
     (B     : Board;
      State : in out RNG_State) return Natural
     with Pre => (for all R in B'Range => B (R) in 1 .. B'Length),
          Global => null;
   --  Uniform random row among those with Variable_Conflicts > 0.
   --  Returns 0 if none (already solved).

   procedure Step
     (B     : in out Board;
      State : in out RNG_State;
      Moved : out Boolean)
     with Pre => (for all R in B'Range => B (R) in 1 .. B'Length),
          Global => null;
   --  One min-conflicts repair: pick a conflicted variable and reassign
   --  it to a min-conflict value. Moved is False if already solved.

   ---------------------------------------------------------------------------
   -- Solvers
   ---------------------------------------------------------------------------

   procedure Minimize_Conflicts
     (B      : in out Board;
      Params : Parameters;
      Result : out Solve_Result)
     with Pre =>
       B'First = 1
       and then B'Last in Queens_N
       and then (for all R in B'Range => B (R) in 1 .. B'Length),
       Global => null;
   --  Hill-climb from the given complete assignment (no automatic restart
   --  of the board; Params.Restarts is ignored — use Solve_N_Queens).

   procedure Solve_N_Queens
     (N      : Queens_N;
      Params : Parameters;
      B      : out Board;
      Result : out Solve_Result)
     with Pre => B'First = 1 and then B'Last = N, Global => null;
   --  Greedy randomised initial board, then min-conflicts with optional
   --  restarts. Each restart draws a fresh Greedy_Board.

   ---------------------------------------------------------------------------
   -- Tiny map-coloring binary CSP sketch (optional educational demo)
   ---------------------------------------------------------------------------

   Max_Regions : constant := 8;
   Max_Colors  : constant := 4;
   Max_Edges   : constant := 32;

   subtype Region_Count is Natural range 0 .. Max_Regions;
   subtype Color_Count  is Natural range 0 .. Max_Colors;
   subtype Edge_Count   is Natural range 0 .. Max_Edges;
   subtype Region_Index is Positive range 1 .. Max_Regions;
   subtype Color_Index  is Positive range 1 .. Max_Colors;

   type Color_Assignment is array (Region_Index range <>) of Natural;

   type Edge is record
      A, B : Region_Index := 1;
   end record;

   type Edge_List is array (1 .. Max_Edges) of Edge;

   type Map_CSP is record
      Num_Regions : Region_Count := 0;
      Num_Colors  : Color_Count  := 0;
      Num_Edges   : Edge_Count   := 0;
      Edges       : Edge_List    := [others => (1, 1)];
   end record;

   procedure Build_Four_Region_Map (CSP : out Map_CSP)
     with Global => null;
   --  Classic tiny map: 4 regions, 3 colors, cycle+diagonal edges
   --  (regions 1-2-3-4 cycle plus 1-3).

   function Map_Variable_Conflicts
     (CSP : Map_CSP; Colors : Color_Assignment; R : Region_Index)
      return Natural
     with Pre =>
       R <= CSP.Num_Regions
       and then Colors'First = 1
       and then Colors'Last = CSP.Num_Regions
       and then (for all I in Colors'Range =>
                   Colors (I) in 1 .. CSP.Num_Colors),
       Global => null;

   function Map_Conflict_Count
     (CSP : Map_CSP; Colors : Color_Assignment) return Natural
     with Pre =>
       Colors'First = 1
       and then Colors'Last = CSP.Num_Regions
       and then (for all I in Colors'Range =>
                   Colors (I) in 1 .. CSP.Num_Colors),
       Global => null;

   function Map_Is_Solved
     (CSP : Map_CSP; Colors : Color_Assignment) return Boolean
     with Pre =>
       Colors'First = 1
       and then Colors'Last = CSP.Num_Regions
       and then (for all I in Colors'Range =>
                   Colors (I) in 1 .. CSP.Num_Colors),
       Global => null;

   procedure Solve_Map_Coloring
     (CSP    : Map_CSP;
      Params : Parameters;
      Colors : out Color_Assignment;
      Result : out Solve_Result)
     with Pre =>
       CSP.Num_Regions > 0
       and then CSP.Num_Colors > 0
       and then Colors'First = 1
       and then Colors'Last = CSP.Num_Regions,
       Global => null;

end Min_Conflicts;
