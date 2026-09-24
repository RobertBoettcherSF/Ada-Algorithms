--  Hungarian_Method — Ada 2023 educational package for Wikipedia
--  "Hungarian algorithm" / Kuhn–Munkres assignment: polynomial-time
--  minimum (or maximum) cost perfect matching on a complete bipartite
--  graph, equivalently a permutation of an n×n cost matrix minimizing
--  the sum of selected entries. Matrix / dual O(n³) formulation.
--  Cap n ≤ 16; Integer costs. Rectangular inputs may be padded to
--  square (documented helper).
--  Primary source:
--  https://en.wikipedia.org/wiki/Hungarian_algorithm
--  Siblings: Ada-Combinatorial-Optimization (forthcoming); series at
--  https://github.com/RobertBoettcherSF/

pragma Ada_2022;

package Hungarian_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   Max_N : constant := 16;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   --  Educational Integer costs (textbook / Wikipedia examples).
   type Cost is new Integer;
   type Cost_Matrix is array (Positive range <>, Positive range <>) of Cost;

   --  Assignment (I) = J means row I is matched to column J.
   --  Unassigned slots hold 0 (only for padded / partial views).
   type Assignment is array (Positive range <>) of Natural;

   type Result is record
      Total      : Cost := 0;
      Mapping    : Assignment (1 .. Max_N) := [others => 0];
      N          : Dimension := 0;
      Success    : Boolean := False;
   end record;

   Invalid_Argument : exception;

   --  Sentinel larger than any |cost| sum we accept for n ≤ 16.
   Large_Cost : constant Cost := 1_000_000_000;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Square (C : Cost_Matrix) return Boolean
     with Global => null;
   --  True iff C'Length (1) = C'Length (2).

   function Assignment_Cost
     (C : Cost_Matrix; A : Assignment) return Cost
     with Pre => Is_Square (C)
            and then A'First = C'First (1)
            and then A'Last  = C'Last (1),
          Global => null;
   --  Σ_i C(i, A(i)); raises Invalid_Argument if A is not a permutation
   --  of the column indices of C.

   function Is_Permutation
     (A : Assignment; N : Dimension) return Boolean
     with Pre => A'Length >= N, Global => null;
   --  A(1 .. N) is a permutation of 1 .. N (when N > 0).

   function Pad_To_Square
     (C    : Cost_Matrix;
      Fill : Cost := 0) return Cost_Matrix
     with Pre => C'Length (1) <= Max_N
            and then C'Length (2) <= Max_N,
          Global => null;
   --  Pad a (possibly rectangular) matrix to max(rows, cols) square by
   --  appending Fill entries. For minimization use Fill = 0 (dummy
   --  workers / jobs); for maximization pad after negation, or use a
   --  sufficiently negative Fill on the original scale. Result indices
   --  are always 1 .. K.

   function Negate (C : Cost_Matrix) return Cost_Matrix
     with Global => null;
   --  Entrywise −C (used to turn maximization into minimization).

   ---------------------------------------------------------------------------
   -- Solvers
   ---------------------------------------------------------------------------

   function Minimize_Assignment (C : Cost_Matrix) return Result
     with Pre => Is_Square (C)
            and then C'Length (1) <= Max_N,
          Global => null;
   --  Kuhn–Munkres / Hungarian: find a permutation π minimizing
   --  Σ_i C(i, π(i)). Empty (0×0) yields Success with Total = 0.
   --  Requires square input; pad rectangular matrices first.

   function Maximize_Assignment (C : Cost_Matrix) return Result
     with Pre => Is_Square (C)
            and then C'Length (1) <= Max_N,
          Global => null;
   --  Equivalent to Minimize_Assignment (Negate (C)) with Total
   --  restored to the original (positive) objective scale.

end Hungarian_Method;
