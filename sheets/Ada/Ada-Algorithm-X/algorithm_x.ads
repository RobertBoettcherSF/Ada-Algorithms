--  Algorithm_X — Ada 2023 educational package for Knuth's Algorithm X
--  (exact cover search) on a dense 0-1 incidence matrix with active
--  row/column masks. Contrast to the sparse DLX sibling (dancing links).
--  Primary source:
--  https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X
--  Also: Exact cover, Dancing Links.
--  Siblings (README links only — no package deps):
--  Ada-Dancing-Links, Ada-Exact-Cover (when published).

pragma Ada_2022;

package Algorithm_X
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain
   ---------------------------------------------------------------------------

   Max_Rows            : constant := 64;
   Max_Columns         : constant := 64;
   Max_Solutions       : constant := 64;
   Max_Solution_Length : constant := 64;
   Max_Queens_N        : constant := 6;

   subtype Row_Count is Natural range 0 .. Max_Rows;
   subtype Column_Count is Natural range 0 .. Max_Columns;
   subtype Row_Id is Natural range 0 .. Max_Rows;
   subtype Column_Id is Natural range 0 .. Max_Columns;
   subtype Solution_Index is Natural range 0 .. Max_Solutions;
   subtype Queens_N is Positive range 1 .. Max_Queens_N;

   type Bool_Matrix is array (Positive range <>, Positive range <>) of Boolean;

   type Row_Id_List is array (1 .. Max_Solution_Length) of Row_Id;

   type Solution is record
      Length : Natural := 0;
      Rows   : Row_Id_List := [others => 0];
   end record;

   type Solution_Array is array (1 .. Max_Solutions) of Solution;

   type Row_Active_Array is array (1 .. Max_Rows) of Boolean;
   type Col_Active_Array is array (1 .. Max_Columns) of Boolean;

   --  Snapshot of which rows/columns are still in the reduced matrix.
   type Active_State is record
      Rows : Row_Active_Array := [others => False];
      Cols : Col_Active_Array := [others => False];
   end record;

   type Incidence is array (1 .. Max_Rows, 1 .. Max_Columns) of Boolean;

   type Solver is record
      Matrix      : Incidence := [others => [others => False]];
      Num_Rows    : Row_Count := 0;
      Num_Columns : Column_Count := 0;
      Num_Primary : Column_Count := 0;
      Active_Row  : Row_Active_Array := [others => False];
      Active_Col  : Col_Active_Array := [others => False];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (S : out Solver)
     with Global => null;
   --  Empty solver (0 rows, 0 columns) — one trivial empty solution.

   procedure Build_From_Matrix
     (S             : out Solver;
      Matrix        : Bool_Matrix;
      Primary_Count : Column_Count := 0)
     with Global => null;
   --  Build from a 0-1 matrix Matrix (R, C). Columns are 1 .. C'Length.
   --  If Primary_Count = 0, every column is primary. Otherwise columns
   --  1 .. Primary_Count are primary and Primary_Count+1 .. C are
   --  secondary (covered when selected, never chosen by Search).

   procedure Build_From_Row_Sets
     (S             : out Solver;
      Num_Columns   : Column_Count;
      Row_Sets      : Bool_Matrix;
      Primary_Count : Column_Count := 0)
     with Global => null;
   --  Same as Build_From_Matrix; Row_Sets (row, col) True means a 1.
   --  Num_Columns must equal Row_Sets'Length (2).

   ---------------------------------------------------------------------------
   -- Structure helpers (educational / tests)
   ---------------------------------------------------------------------------

   function Active_Primary_Count (S : Solver) return Natural
     with Global => null;
   --  How many primary columns are still active.

   function Active_Row_Count (S : Solver) return Natural
     with Global => null;

   function Column_Ones (S : Solver; C : Column_Id) return Natural
     with Global => null;
   --  Number of active rows that still have a 1 in active column C.

   function State_Fingerprint (S : Solver) return Natural
     with Global => null;
   --  Deterministic checksum of Matrix dims + Active_Row/Active_Col —
   --  used to prove Select_Row / Restore round-trips.

   function Snapshot (S : Solver) return Active_State
     with Global => null;

   procedure Restore (S : in out Solver; St : Active_State)
     with Global => null;
   --  Replace Active_Row / Active_Col with a previously saved snapshot.

   ---------------------------------------------------------------------------
   -- Knuth primitives (dense-matrix form)
   ---------------------------------------------------------------------------

   function Choose_Column (S : Solver) return Column_Id
     with Global => null;
   --  MRV: active primary column with fewest active 1s (ties: lowest id).
   --  Returns 0 if no active primary columns remain.

   procedure Select_Row (S : in out Solver; R : Row_Id)
     with Global => null;
   --  Include row R: for each active column j with Matrix(R,j), delete
   --  every active row i with Matrix(i,j), then delete column j.
   --  Also deactivates R. Caller should Snapshot before and Restore after.

   ---------------------------------------------------------------------------
   -- Search / solve
   ---------------------------------------------------------------------------

   procedure Solve
     (S       : in out Solver;
      Found   : out Solution;
      Success : out Boolean)
     with Global => null;
   --  Find one solution (depth-first Algorithm X). Success False if none.
   --  Restores active masks before return.

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
   -- N-queens via exact cover (tiny; secondary diagonals)
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
   -- Small textbook helper
   ---------------------------------------------------------------------------

   procedure Build_Knuth_Example (S : out Solver)
     with Global => null;
   --  Classic Wikipedia Algorithm X 7-column / 6-row matrix
   --  (unique solution rows {2, 4, 6} = {B, D, F}).

   function Knuth_Example_Solution_Count return Natural
     with Global => null;

end Algorithm_X;
