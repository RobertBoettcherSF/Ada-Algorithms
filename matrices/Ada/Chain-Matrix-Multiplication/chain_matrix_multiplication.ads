--  Chain_Matrix_Multiplication — Ada 2023 educational package for
--  Wikipedia "Matrix chain multiplication" (matrix chain ordering):
--  classic dynamic-programming optimal parenthesization. Given dimensions
--  p0..pn for matrices A1..An (Ai is p_{i-1} × p_i), fill cost table m
--  and split table s; reconstruct a parenthesization string. Caps keep
--  tables educational (n ≤ 32 matrices). Verification helpers compare
--  DP cost against a given split / left- or right-associative order.
--  Primary source:
--  https://en.wikipedia.org/wiki/Matrix_chain_multiplication
--  Sibling (README link only — no package dep):
--  Ada-Dynamic-Programming
--  https://github.com/RobertBoettcherSF/Ada-Dynamic-Programming

pragma Ada_2022;

package Chain_Matrix_Multiplication
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain
   ---------------------------------------------------------------------------

   --  Number of matrices in a chain (dimension array length = n+1).
   Max_Matrices : constant := 32;

   subtype Matrix_Count is Natural range 0 .. Max_Matrices;
   subtype Matrix_Index is Positive range 1 .. Max_Matrices;

   --  Dimension chain p0, p1, ..., pn. Length = n+1 for n matrices.
   --  Matrix Ai has size Dims(Dims'First + i - 1) × Dims(Dims'First + i)
   --  for i in 1 .. n (relative to Dims'First), matching textbook p_{i-1}×p_i.
   type Dimensions is array (Positive range <>) of Positive;

   --  m[i,j] = min scalar multiplications to compute Ai..Aj (1-based).
   --  Diagonal and unused entries are 0.
   type Cost_Table is
     array (Matrix_Index, Matrix_Index) of Natural;

   --  s[i,j] = k means optimal last multiply is (Ai..Ak)×(Ak+1..Aj).
   --  Diagonal unused (0).
   type Split_Table is
     array (Matrix_Index, Matrix_Index) of Natural;

   type DP_Result is record
      N        : Matrix_Count := 0;  -- number of matrices
      Min_Cost : Natural := 0;
      Cost     : Cost_Table := [others => [others => 0]];
      Split    : Split_Table := [others => [others => 0]];
      Success  : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Core DP
   ---------------------------------------------------------------------------

   function Optimal_Cost (Dims : Dimensions) return Natural
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Minimum number of scalar multiplications for the chain.
   --  One matrix (Dims'Length = 2) → 0.

   function Optimal_Order (Dims : Dimensions) return DP_Result
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Full bottom-up DP: Min_Cost, Cost table, Split table.

   function Compute_DP (Dims : Dimensions) return DP_Result
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Alias for Optimal_Order (explicit "fill both tables" name).

   ---------------------------------------------------------------------------
   -- Parenthesization / formatting
   ---------------------------------------------------------------------------

   function Parenthesize
     (Split : Split_Table;
      N     : Matrix_Count;
      I, J  : Matrix_Index) return String
     with Pre =>
       N >= 1
       and then I <= J
       and then J <= N,
          Global => null;
   --  Reconstruct parenthesization of Ai..Aj from Split.
   --  Single matrix → "A1"; product → "(Left*Right)" with nested parens.

   function Format_Order (R : DP_Result) return String
     with Pre => R.Success and then R.N >= 1,
          Global => null;
   --  Parenthesize (R.Split, R.N, 1, R.N).

   ---------------------------------------------------------------------------
   -- Verification / associativity helpers
   ---------------------------------------------------------------------------

   function Cost_Of_Split
     (Dims  : Dimensions;
      Split : Split_Table;
      I, J  : Matrix_Index) return Natural
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices
       and then I <= J
       and then J <= Dims'Length - 1,
          Global => null;
   --  Cost of multiplying Ai..Aj following Split (recursive).

   function Cost_Of_Split
     (Dims  : Dimensions;
      Split : Split_Table) return Natural
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Full-chain Cost_Of_Split (Dims, Split, 1, n).

   function Left_Associative_Cost (Dims : Dimensions) return Natural
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Cost of (...((A1 A2) A3) ... An) — multiply left-to-right.

   function Right_Associative_Cost (Dims : Dimensions) return Natural
     with Pre =>
       Dims'Length >= 2
       and then Dims'Length - 1 <= Max_Matrices,
          Global => null;
   --  Cost of (A1 (A2 (... (A_{n-1} An)...))) — multiply right-to-left.

   function Matrix_Count_Of (Dims : Dimensions) return Matrix_Count
     with Pre => Dims'Length >= 1,
          Global => null;
   --  Dims'Length - 1 (number of matrices).

end Chain_Matrix_Multiplication;
