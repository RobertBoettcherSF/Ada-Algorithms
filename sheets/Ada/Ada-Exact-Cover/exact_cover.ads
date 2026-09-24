--  Exact_Cover — Ada 2023 educational survey of the exact cover problem:
--  definitions, incidence-matrix framing, verification helpers, and a
--  naive/backtracking bitset solver for tiny instances. Taxonomy points
--  to Algorithm X / DLX / ILP siblings (README links only — no deps).
--  Primary source:
--  https://en.wikipedia.org/wiki/Exact_cover
--  Also: Knuth's Algorithm X, Dancing Links.
--  Siblings (README links only — no package deps):
--  Ada-Algorithm-X, Ada-Dancing-Links.

pragma Ada_2022;

with Interfaces;

package Exact_Cover
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain  (|X| ≤ 64, #subsets ≤ 64)
   ---------------------------------------------------------------------------

   Max_Universe_Size   : constant := 64;
   Max_Subset_Count    : constant := 64;
   Max_Solutions       : constant := 64;
   Max_Solution_Length : constant := 64;

   subtype Element_Count is Natural range 0 .. Max_Universe_Size;
   subtype Subset_Count  is Natural range 0 .. Max_Subset_Count;
   subtype Element_Id    is Positive range 1 .. Max_Universe_Size;
   subtype Subset_Id     is Positive range 1 .. Max_Subset_Count;

   --  Bit i-1 set ⇔ element i (or subset i) is present.
   subtype Bit_Set is Interfaces.Unsigned_64;

   type Bool_Matrix is array (Positive range <>, Positive range <>) of Boolean;

   type Row_Bits is array (1 .. Max_Subset_Count) of Bit_Set;

   --  Exact-cover instance: universe {1..Num_Elements}, collection of
   --  Num_Subsets subsets encoded as bit masks in Rows (1-based).
   type Instance is record
      Num_Elements : Element_Count := 0;
      Num_Subsets  : Subset_Count  := 0;
      Rows         : Row_Bits      := [others => 0];
   end record;

   type Subset_Id_List is array (1 .. Max_Solution_Length) of Subset_Id;

   --  A selection of subset indices (a candidate cover).
   type Selection is record
      Length : Natural := 0;
      Ids    : Subset_Id_List := [others => 1];
   end record;

   type Selection_Array is array (1 .. Max_Solutions) of Selection;

   ---------------------------------------------------------------------------
   -- Method taxonomy (survey)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Naive_Backtrack, Algorithm_X, Dancing_Links, Integer_LP);

   type Method_Status is (Implemented, Forthcoming);

   type Method_Info is record
      Kind        : Method_Kind;
      Status      : Method_Status;
      Implemented : Boolean;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Bit helpers
   ---------------------------------------------------------------------------

   function Element_Bit (E : Element_Id) return Bit_Set
     with Global => null;
   --  2**(E-1).

   function Subset_Bit (S : Subset_Id) return Bit_Set
     with Global => null;
   --  2**(S-1).

   function Universe_Mask (Num_Elements : Element_Count) return Bit_Set
     with Global => null;
   --  Bits 0 .. Num_Elements-1 set (empty → 0).

   function Popcount (M : Bit_Set) return Natural
     with Global => null;

   function Bit_Is_Set (M : Bit_Set; E : Element_Id) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (Inst : out Instance)
     with Global => null;
   --  Empty universe, no subsets — one trivial empty cover.

   procedure From_Incidence_Matrix
     (Inst   : out Instance;
      Matrix : Bool_Matrix)
     with Global => null;
   --  Rows = subsets, columns = elements. Matrix (r,c) True ⇒ subset r
   --  contains element c. Bounds: rows ≤ 64, cols ≤ 64.

   procedure Add_Subset
     (Inst : in out Instance;
      Mask : Bit_Set)
     with Global => null;
   --  Append one subset (bits outside 0 .. Num_Elements-1 ignored).
   --  Raises Capacity_Exceeded if already at Max_Subset_Count.
   --  If Num_Elements = 0 and Mask /= 0, raises Invalid_Argument.

   procedure Set_Universe
     (Inst         : in out Instance;
      Num_Elements : Element_Count)
     with Global => null;
   --  Set |X|; clears existing subsets.

   ---------------------------------------------------------------------------
   -- Classic tiny examples
   ---------------------------------------------------------------------------

   procedure Build_Knuth_Example (Inst : out Instance)
     with Global => null;
   --  Wikipedia / Knuth: X={1..7}, six sets A..F; unique cover {B,D,F}
   --  = subset indices {2,4,6}.

   procedure Build_NOPE_Example (Inst : out Instance)
     with Global => null;
   --  Wikipedia basic: X={1,2,3,4}, S={N,O,P,E} with N={}, O={1,3},
   --  P={1,2,3}, E={2,4}. Exact covers: {O,E} and {N,O,E}.

   procedure Build_Partition_Toy (Inst : out Instance)
     with Global => null;
   --  X={1,2,3}; subsets {{1},{2},{3},{1,2},{1,3},{2,3},{1,2,3}}.
   --  Several exact covers (set partitions of a 3-set).

   ---------------------------------------------------------------------------
   -- Verification helpers
   ---------------------------------------------------------------------------

   function Conflicts (A, B : Bit_Set) return Boolean
     with Global => null;
   --  True iff A ∩ B ≠ ∅.

   function Selection_Mask
     (Inst : Instance;
      Sel  : Selection) return Bit_Set
     with Global => null;
   --  Bitmask of selected subset indices (bits 0-based on Subset_Id).

   function Covered_Elements
     (Inst : Instance;
      Sel  : Selection) return Bit_Set
     with Global => null;
   --  Union of selected subset masks (bits outside universe cleared).

   function Is_Partial_Cover
     (Inst : Instance;
      Sel  : Selection) return Boolean
     with Global => null;
   --  Selected subsets are pairwise disjoint (no element covered twice).
   --  Empty selection is a partial cover. Does not require full coverage.

   function Is_Exact_Cover
     (Inst : Instance;
      Sel  : Selection) return Boolean
     with Global => null;
   --  Pairwise disjoint and union equals the full universe mask.

   function Cover_Count_Of
     (Inst : Instance;
      Sel  : Selection;
      E    : Element_Id) return Natural
     with Global => null;
   --  How many selected subsets contain element E (0 if E out of range).

   ---------------------------------------------------------------------------
   -- Naive / backtracking solver (educational; tiny instances)
   ---------------------------------------------------------------------------

   procedure Solve_Backtrack
     (Inst    : Instance;
      Found   : out Selection;
      Success : out Boolean;
      Use_MRV : Boolean := True)
     with Global => null;
   --  Depth-first exact cover. Optional MRV: cover an uncovered element
   --  with fewest remaining candidate subsets first. Restores nothing
   --  (Instance is in-mode). Success False if unsatisfiable.

   procedure Solve_All
     (Inst      : Instance;
      Solutions : out Selection_Array;
      Count     : out Natural;
      Cap       : Natural := Max_Solutions;
      Use_MRV   : Boolean := True)
     with Global => null;
   --  Collect up to Cap solutions (capped at Max_Solutions).

   function Count_Covers
     (Inst    : Instance;
      Cap     : Natural := 256;
      Use_MRV : Boolean := True) return Natural
     with Global => null;
   --  Number of exact covers found up to Cap (does not store them).

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify (Kind : Method_Kind) return Method_Info
     with Global => null;
   --  Only Naive_Backtrack is Implemented here; others Forthcoming
   --  (see Ada-Algorithm-X / Ada-Dancing-Links / ILP survey siblings).

   function Method_Name (Kind : Method_Kind) return String
     with Global => null;

   function Implemented (Kind : Method_Kind) return Boolean
     with Global => null;

   function Forthcoming (Kind : Method_Kind) return Boolean
     with Global => null;

   function Method_Count return Natural
     with Global => null;
   --  Number of Method_Kind values (= 4).

   ---------------------------------------------------------------------------
   -- Convenience wrappers for textbook examples
   ---------------------------------------------------------------------------

   function Knuth_Example_Cover_Count return Natural
     with Global => null;
   --  Expected: 1.

   function NOPE_Example_Cover_Count return Natural
     with Global => null;
   --  Expected: 2 ({O,E} and {N,O,E}).

end Exact_Cover;
