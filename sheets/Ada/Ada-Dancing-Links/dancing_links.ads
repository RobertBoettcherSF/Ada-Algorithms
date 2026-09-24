--  Dancing_Links — Ada 2023 educational package for Knuth DLX /
--  Algorithm X exact cover (sparse circular doubly-linked "dancing"
--  links). Fixed node pool; primary + optional secondary columns;
--  MRV column choice; N-queens exact-cover demo.
--  Primary source:
--  https://en.wikipedia.org/wiki/Dancing_Links
--  Also: Algorithm X, Exact cover.
--  Siblings (README links only — no package deps):
--  Ada-Exact-Cover, Algorithm X sibling (when published).

pragma Ada_2022;

package Dancing_Links
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain
   ---------------------------------------------------------------------------

   Max_Columns         : constant := 64;
   Max_Nodes           : constant := 2048;
   Max_Matrix_Rows     : constant := 512;
   Max_Solutions       : constant := 64;
   Max_Solution_Length : constant := 64;
   Max_Queens_N        : constant := 8;

   subtype Column_Count is Natural range 0 .. Max_Columns;
   subtype Node_Id is Natural range 0 .. Max_Nodes;
   subtype Row_Id is Natural range 0 .. Max_Matrix_Rows;
   subtype Solution_Index is Natural range 0 .. Max_Solutions;
   subtype Queens_N is Positive range 1 .. Max_Queens_N;

   --  Root header is always node 0. Column headers occupy 1 .. Num_Columns.
   Root_Id : constant Node_Id := 0;

   type Bool_Matrix is array (Positive range <>, Positive range <>) of Boolean;

   type Row_Id_List is array (1 .. Max_Solution_Length) of Row_Id;

   type Solution is record
      Length : Natural := 0;
      Rows   : Row_Id_List := [others => 0];
   end record;

   type Solution_Array is array (1 .. Max_Solutions) of Solution;

   type Node is record
      L, R, U, D : Node_Id := 0;
      Col        : Node_Id := 0;  -- column header for data; self for header
      Size       : Natural := 0;  -- meaningful on column headers
      Row        : Row_Id := 0;   -- matrix row id on data nodes
   end record;

   type Node_Pool is array (Node_Id) of Node;

   type Solver is record
      Nodes       : Node_Pool := [others => <>];
      Num_Columns : Column_Count := 0;
      Num_Primary : Column_Count := 0;
      Last_Node   : Node_Id := 0;  -- highest allocated node index
      Num_Rows    : Row_Id := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (S : out Solver)
     with Global => null;
   --  Empty solver (0 columns, only Root).

   procedure Build_From_Matrix
     (S              : out Solver;
      Matrix         : Bool_Matrix;
      Primary_Count  : Column_Count := 0)
     with Global => null;
   --  Build DLX from a 0-1 matrix Matrix (R, C). Columns are 1 .. C'Last.
   --  If Primary_Count = 0, every column is primary. Otherwise columns
   --  1 .. Primary_Count are primary and Primary_Count+1 .. C are
   --  secondary (covered when selected, never chosen by Search).

   procedure Build_From_Row_Sets
     (S              : out Solver;
      Num_Columns    : Column_Count;
      Row_Sets       : Bool_Matrix;
      Primary_Count  : Column_Count := 0)
     with Global => null;
   --  Same as Build_From_Matrix; Row_Sets (row, col) True means a 1.
   --  Num_Columns must equal Row_Sets'Length (2). Kept as an alias-style
   --  entry for API sketches that speak of "row column-sets".

   ---------------------------------------------------------------------------
   -- Structure helpers (educational / tests)
   ---------------------------------------------------------------------------

   function Header_Size (S : Solver; C : Node_Id) return Natural
     with Global => null;
   --  Size of column header C (1 .. Num_Columns).

   function Primary_Header_Count (S : Solver) return Natural
     with Global => null;
   --  How many primary headers are currently linked from Root.

   function Min_Primary_Size (S : Solver) return Natural
     with Global => null;
   --  Minimum Size among linked primary headers, or 0 if none.

   function Structure_Fingerprint (S : Solver) return Natural
     with Global => null;
   --  Deterministic checksum of L/R/U/D/Col/Size/Row over allocated
   --  nodes — used to prove Cover/Uncover restores structure.

   ---------------------------------------------------------------------------
   -- Knuth primitives
   ---------------------------------------------------------------------------

   function Choose_Column (S : Solver) return Node_Id
     with Global => null;
   --  MRV: linked primary header with smallest Size. Returns Root_Id
   --  if no primary columns remain.

   procedure Cover (S : in out Solver; C : Node_Id)
     with Global => null;
   --  Unlink column C and splice out every row that has a 1 in C.

   procedure Uncover (S : in out Solver; C : Node_Id)
     with Global => null;
   --  Exact reverse of Cover (links "dance" back).

   ---------------------------------------------------------------------------
   -- Search / solve
   ---------------------------------------------------------------------------

   procedure Solve
     (S       : in out Solver;
      Found   : out Solution;
      Success : out Boolean)
     with Global => null;
   --  Find one solution (depth-first Algorithm X). Success False if none.

   procedure Solve_All
     (S         : in out Solver;
      Solutions : out Solution_Array;
      Count     : out Natural;
      Cap       : Natural := Max_Solutions)
     with Global => null;
   --  Collect up to Cap solutions (Cap capped at Max_Solutions).

   function Count_Solutions
     (S   : in out Solver;
      Cap : Natural := 256) return Natural
     with Global => null;
   --  Number of solutions found up to Cap (does not store them).

   ---------------------------------------------------------------------------
   -- N-queens via exact cover
   ---------------------------------------------------------------------------

   function N_Queens_Column_Count (N : Queens_N) return Column_Count
     with Global => null;
   --  2N primary (rows+cols) + 2*(2N-1) secondary (diagonals) = 6N-2.

   procedure Build_N_Queens
     (S : out Solver;
      N : Queens_N)
     with Global => null;
   --  Exact-cover encoding: primary rows/cols; secondary diagonals.

   function N_Queens_Count
     (N   : Queens_N;
      Cap : Natural := 256) return Natural
     with Global => null;

   procedure N_Queens_Solve
     (N         : Queens_N;
      Solutions : out Solution_Array;
      Count     : out Natural;
      Cap       : Natural := Max_Solutions)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Small textbook / tiling helpers
   ---------------------------------------------------------------------------

   procedure Build_Knuth_Example (S : out Solver)
     with Global => null;
   --  Classic 7-column / 6-row exact-cover matrix (unique solution).

   function Knuth_Example_Solution_Count return Natural
     with Global => null;

end Dancing_Links;
