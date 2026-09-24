--  Dynamic_Programming — Ada 2023 educational survey / classic-examples
--  package for Wikipedia "Dynamic programming" (Bellman): optimal
--  substructure + overlapping subproblems; memoization vs tabulation.
--  Classic bounded Integer demos: Fibonacci, 0/1 knapsack, unbounded
--  coin change, LCS, Levenshtein edit distance, matrix-chain order,
--  unique grid paths, and rod cutting. Caps keep tables educational
--  (n ≤ 64, capacity ≤ 256, string length ≤ 64).
--  Primary source:
--  https://en.wikipedia.org/wiki/Dynamic_programming
--  Siblings (README links only — no package deps):
--  Ada-Chain-Matrix-Multiplication, Ada-Ellipsoid-Method,
--  Ada-Branch-and-Bound, Ada-Combinatorial-Optimization,
--  Ada-Integer-Linear-Programming.

pragma Ada_2022;

package Dynamic_Programming
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain
   ---------------------------------------------------------------------------

   --  Fibonacci index: Fib(92) fits in signed 64-bit; Fib(93) overflows.
   Max_Fib_N : constant := 92;

   Max_Items      : constant := 64;
   Max_Capacity   : constant := 256;
   Max_Coin_Kinds : constant := 32;
   Max_Amount     : constant := 256;
   Max_String_Len : constant := 64;
   Max_Matrices   : constant := 32;  -- number of matrices in a chain
   Max_Grid       : constant := 32;
   Max_Rod_Len    : constant := 64;

   subtype Fib_Index is Natural range 0 .. Max_Fib_N;
   subtype Item_Count is Natural range 0 .. Max_Items;
   subtype Capacity_Range is Natural range 0 .. Max_Capacity;
   subtype Amount_Range is Natural range 0 .. Max_Amount;
   subtype String_Len is Natural range 0 .. Max_String_Len;
   subtype Matrix_Count is Natural range 0 .. Max_Matrices;
   subtype Grid_Size is Natural range 0 .. Max_Grid;
   subtype Rod_Len is Natural range 0 .. Max_Rod_Len;

   type Weight_Array is array (Positive range <>) of Natural;
   type Value_Array  is array (Positive range <>) of Natural;
   type Coin_Array   is array (Positive range <>) of Positive;
   type Dim_Array    is array (Positive range <>) of Positive;
   --  Dims for p matrices: length p+1 (rows/cols chain d0,d1,...,dp).
   type Price_Array  is array (Positive range <>) of Natural;
   type Bool_Array   is array (Positive range <>) of Boolean;
   type Index_Array  is array (Positive range <>) of Natural;

   type Fib_Value is range 0 .. 7_540_113_804_746_346_429;
   --  Fib(92) = 7_540_113_804_746_346_429.

   ---------------------------------------------------------------------------
   -- Taxonomy (survey tags)
   ---------------------------------------------------------------------------

   type Problem_Kind is
     (Fibonacci_Seq,
      Knapsack_01,
      Coin_Change_Min,
      Coin_Change_Ways,
      Longest_Common_Subseq,
      Edit_Distance,
      Matrix_Chain,
      Unique_Grid_Paths,
      Rod_Cutting);

   type Fill_Strategy is (Tabulation, Memoization);

   type Problem_Info is record
      Kind                       : Problem_Kind;
      Uses_Optimal_Substructure  : Boolean;
      Uses_Overlapping_Subproblems : Boolean;
      Default_Strategy           : Fill_Strategy;
      Typical_Table_Dims         : Natural;  -- educational hint (1 or 2)
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Impossible       : exception;  -- e.g. coin change with no solution

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify (Kind : Problem_Kind) return Problem_Info
     with Global => null;

   function Problem_Name (Kind : Problem_Kind) return String
     with Global => null;

   function Strategy_Name (S : Fill_Strategy) return String
     with Global => null;

   function Uses_Optimal_Substructure (Kind : Problem_Kind) return Boolean
     with Global => null;

   function Uses_Overlapping_Subproblems (Kind : Problem_Kind) return Boolean
     with Global => null;

   function Problem_Count return Natural
     with Global => null;
   --  Number of Problem_Kind values.

   ---------------------------------------------------------------------------
   -- 1. Fibonacci — F(0)=0, F(1)=1, F(n)=F(n-1)+F(n-2)
   ---------------------------------------------------------------------------

   function Fibonacci (N : Fib_Index) return Fib_Value
     with Global => null;
   --  Bottom-up tabulation; O(N) time, O(1) extra space.

   function Fibonacci_Memo (N : Fib_Index) return Fib_Value
     with Global => null;
   --  Top-down recursion with an explicit memo table; same values as
   --  Fibonacci. Educational: memoization vs tabulation.

   ---------------------------------------------------------------------------
   -- 2. 0/1 Knapsack — each item at most once
   ---------------------------------------------------------------------------

   type Knapsack_Result is record
      Max_Value : Natural := 0;
      Capacity  : Capacity_Range := 0;
      N_Items   : Item_Count := 0;
      Selected  : Bool_Array (1 .. Max_Items) := [others => False];
      Success   : Boolean := False;
   end record;

   function Knapsack_01
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Capacity_Range) return Natural
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1,
          Global => null;
   --  Maximum total value; does not reconstruct selection.

   function Knapsack_01_With_Selection
     (Weights  : Weight_Array;
      Values   : Value_Array;
      Capacity : Capacity_Range) return Knapsack_Result
     with Pre =>
       Weights'Length = Values'Length
       and then Weights'Length <= Max_Items
       and then Weights'Length >= 1,
          Global => null;
   --  Max value plus Selected(i) for items in Weights'Range (1-based
   --  into the result's Selected using relative index 1 .. N).

   ---------------------------------------------------------------------------
   -- 3. Unbounded coin change
   ---------------------------------------------------------------------------

   function Min_Coins
     (Coins  : Coin_Array;
      Amount : Amount_Range) return Integer
     with Pre => Coins'Length >= 1 and then Coins'Length <= Max_Coin_Kinds,
          Global => null;
   --  Fewest coins to make Amount (unlimited supply of each denomination).
   --  Returns −1 if impossible. Amount = 0 → 0.

   function Coin_Combinations
     (Coins  : Coin_Array;
      Amount : Amount_Range) return Natural
     with Pre => Coins'Length >= 1 and then Coins'Length <= Max_Coin_Kinds,
          Global => null;
   --  Number of unordered combinations that sum to Amount (classic
   --  "coin change II" / order-independent). Amount = 0 → 1 (empty).

   ---------------------------------------------------------------------------
   -- 4. Longest common subsequence (LCS)
   ---------------------------------------------------------------------------

   function LCS_Length (A, B : String) return Natural
     with Pre => A'Length <= Max_String_Len and then B'Length <= Max_String_Len,
          Global => null;

   function LCS_String (A, B : String) return String
     with Pre => A'Length <= Max_String_Len and then B'Length <= Max_String_Len,
          Global => null;
   --  One LCS (not necessarily unique); length equals LCS_Length(A, B).

   ---------------------------------------------------------------------------
   -- 5. Edit distance (Levenshtein) — insert/delete/substitute cost 1
   ---------------------------------------------------------------------------

   function Edit_Distance (A, B : String) return Natural
     with Pre => A'Length <= Max_String_Len and then B'Length <= Max_String_Len,
          Global => null;

   ---------------------------------------------------------------------------
   -- 6. Matrix-chain order — min scalar multiplications
   ---------------------------------------------------------------------------

   type Split_Table is
     array (1 .. Max_Matrices, 1 .. Max_Matrices) of Natural;

   type Matrix_Chain_Result is record
      Min_Cost : Natural := 0;
      N        : Matrix_Count := 0;  -- number of matrices
      --  Split(i,j) = k means optimal last multiply is Ai..Ak × Ak+1..Aj
      --  (1-based matrix indices). Diagonal unused (0).
      Split    : Split_Table := [others => [others => 0]];
      Success  : Boolean := False;
   end record;

   function Matrix_Chain_Cost (Dims : Dim_Array) return Natural
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Dims has length p+1 for p matrices of sizes
   --  Dims(i)×Dims(i+1). Returns min scalar multiplications.

   function Matrix_Chain_Order (Dims : Dim_Array) return Matrix_Chain_Result
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Cost plus Split table for reconstruction.

   ---------------------------------------------------------------------------
   -- 7. Unique paths in an m×n grid / rod cutting
   ---------------------------------------------------------------------------

   function Unique_Paths (M, N : Grid_Size) return Natural
     with Pre => M >= 1 and then N >= 1, Global => null;
   --  Paths from top-left to bottom-right moving only right or down.
   --  Unique_Paths(1, *) = Unique_Paths(*, 1) = 1.

   function Rod_Cutting
     (Prices : Price_Array;
      Length : Rod_Len) return Natural
     with Pre =>
       Prices'Length >= 1
       and then Prices'Length <= Max_Rod_Len
       and then Length <= Prices'Length,
          Global => null;
   --  Prices(Prices'First + i - 1) = price of a piece of length i
   --  (i = 1 .. Prices'Length). Returns max revenue for a rod of
   --  given Length (unbounded cuts).

end Dynamic_Programming;
