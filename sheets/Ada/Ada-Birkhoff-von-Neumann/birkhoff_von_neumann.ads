--  Birkhoff_Von_Neumann — Ada 2023 educational package for Wikipedia
--  "Doubly stochastic matrix" / Birkhoff–von Neumann theorem: every
--  doubly stochastic matrix is a convex combination of permutation
--  matrices. Classroom Birkhoff algorithm via support perfect matching
--  (DFS/backtracking). Cap n ≤ 8; Long_Float matrices; zero tolerance.
--  Primary source:
--  https://en.wikipedia.org/wiki/Doubly_stochastic_matrix#Birkhoff%E2%80%93von_Neumann_theorem
--  Sibling (README only): Ada-Sinkhorn-Knopp (forthcoming). Series at
--  https://github.com/RobertBoettcherSF/

pragma Ada_2022;

package Birkhoff_Von_Neumann
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Long_Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 8;
   --  Enough for classroom demos; matching is O(n!) worst case.

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Real is new Long_Float;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   --  Permutation (I) = J means row I maps to column J (1-based).
   type Permutation is array (Positive range <>) of Natural;

   --  One term λ_k P_k in the Birkhoff–von Neumann decomposition.
   type Term is record
      Lambda : Real := 0.0;
      Perm   : Permutation (1 .. Max_N) := [others => 0];
      N      : Dimension := 0;
   end record;

   --  At most n² steps in the classical Birkhoff peeling (educational bound).
   Max_Terms : constant := Max_N * Max_N;

   type Term_List is array (Positive range <>) of Term;

   type Decomposition is record
      Terms   : Term_List (1 .. Max_Terms) := [others => <>];
      Count   : Natural := 0;
      N       : Dimension := 0;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Zero_Tol : constant Real := 1.0E-12;
   --  Entries |a| ≤ Zero_Tol are treated as zero in the support graph.
   Sum_Tol  : constant Real := 1.0E-9;
   --  Row/column sums must be within Sum_Tol of 1 for DS checks.
   Recon_Tol : constant Real := 1.0E-8;
   --  Default reconstruction comparison tolerance.

   ---------------------------------------------------------------------------
   -- Predicates / numeric helpers
   ---------------------------------------------------------------------------

   function Is_Square (A : Matrix) return Boolean
     with Global => null;
   --  True iff A'Length (1) = A'Length (2).

   function Near (X, Y : Real; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Entry_Near_Zero (X : Real; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Row_Sum (A : Matrix; I : Positive) return Real
     with Pre => I in A'Range (1), Global => null;

   function Col_Sum (A : Matrix; J : Positive) return Real
     with Pre => J in A'Range (2), Global => null;

   function Is_Nonnegative (A : Matrix; Tol : Real := Zero_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Every entry ≥ −Tol (tiny negatives from float noise allowed).

   function Is_Doubly_Stochastic
     (A : Matrix; Tol : Real := Sum_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Square, nonnegative, every row and column sums to ≈ 1 within Tol.
   --  Empty 0×0 is treated as doubly stochastic (vacuous).

   function Matrices_Near
     (A, B : Matrix; Tol : Real := Recon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Same shape and |A_ij − B_ij| ≤ Tol for all entries.

   function Frobenius_Distance (A, B : Matrix) return Real
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2),
          Global => null;

   function Is_Permutation (P : Permutation; N : Dimension) return Boolean
     with Pre => P'Length >= N, Global => null;
   --  P (P'First .. P'First + N − 1) is a bijection of 1 .. N (N = 0 OK).

   function Lambda_Sum (D : Decomposition) return Real
     with Global => null;
   --  Σ λ_k over D.Terms (1 .. D.Count).

   ---------------------------------------------------------------------------
   -- Constructors / builders
   ---------------------------------------------------------------------------

   function Zero_Matrix (N : Dimension) return Matrix
     with Pre => N <= Max_N, Global => null;
   --  N×N zeros; N = 0 yields empty matrix.

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Permutation matrix for the identity permutation.

   function Uniform (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  All entries equal to 1/N (centre of the Birkhoff polytope).

   function Identity_Permutation (N : Dimension) return Permutation
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   function Reverse_Permutation (N : Dimension) return Permutation
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  π(i) = N − i + 1.

   function Cycle_Permutation (N : Dimension; Shift : Natural := 1)
     return Permutation
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  π(i) = ((i − 1 + Shift) mod N) + 1.

   function Permutation_Matrix (P : Permutation; N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N
            and then P'Length >= N
            and then Is_Permutation (P, N),
          Global => null;
   --  Matrix with 1 at (i, P(i)) and 0 elsewhere (indices of P relative
   --  to P'First for the first N entries).

   function Scale (A : Matrix; S : Real) return Matrix
     with Global => null;

   function Add (A, B : Matrix) return Matrix
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2),
          Global => null;

   function Sub (A, B : Matrix) return Matrix
     with Pre => A'Length (1) = B'Length (1)
            and then A'Length (2) = B'Length (2),
          Global => null;

   --  Convex combination Σ λ_k P_k of known permutation matrices.
   --  Requires Σ λ = 1 (within Sum_Tol), each λ ≥ 0, matching N.
   function Convex_Combination
     (Lambdas : Term_List; Count : Natural; N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N
            and then Count >= 1
            and then Count <= Lambdas'Length,
          Global => null;
   --  Raises Invalid_Argument if lambdas invalid or a term is not a
   --  permutation of size N.

   --  Toy doubly stochastic matrix: convex combination of identity,
   --  reverse, and a cycle (weights depend on N). Always DS.
   function Make_Toy_DS (N : Dimension) return Matrix
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   --  Wikipedia / textbook 3×3 example (scaled by 1/12):
   --    (7 0 5; 2 6 4; 3 6 3) / 12
   function Wikipedia_Example_3x3 return Matrix
     with Global => null;

   ---------------------------------------------------------------------------
   -- Support matching (Hall / Birkhoff step)
   ---------------------------------------------------------------------------

   function Find_Support_Permutation
     (A : Matrix; Tol : Real := Zero_Tol) return Permutation
     with Pre => Is_Square (A)
            and then A'Length (1) <= Max_N
            and then Tol >= 0.0,
          Global => null;
   --  Perfect matching in the bipartite support graph of entries > Tol,
   --  via DFS/backtracking (classroom n). Raises Invalid_Argument if none
   --  exists or A is empty. Result length = N with 1-based indices.

   ---------------------------------------------------------------------------
   -- Birkhoff algorithm / decomposition
   ---------------------------------------------------------------------------

   function Decompose
     (A : Matrix; Tol : Real := Zero_Tol) return Decomposition
     with Pre => A'Length (1) <= Max_N
            and then A'Length (2) <= Max_N
            and then Tol >= 0.0;
   --  Birkhoff peeling: while residual ≉ 0, find support permutation π,
   --  θ := min_i A(i,π(i)), subtract θ P_π, accumulate (θ, π).
   --  Raises Invalid_Argument if A is not square, not doubly stochastic
   --  (within Sum_Tol), or matching fails. Empty → Success with Count = 0.

   function Birkhoff_Decomposition
     (A : Matrix; Tol : Real := Zero_Tol) return Decomposition
     with Pre => A'Length (1) <= Max_N
            and then A'Length (2) <= Max_N
            and then Tol >= 0.0;
   --  Alias of Decompose (same algorithm).

   function Reconstruct (D : Decomposition) return Matrix
     with Pre => D.Success and then D.N <= Max_N, Global => null;
   --  Σ_k λ_k P_k; empty N = 0 yields empty matrix.

   function Reconstruct_Near
     (A : Matrix; Tol : Real := Recon_Tol) return Boolean
     with Pre => A'Length (1) <= Max_N
            and then A'Length (2) <= Max_N
            and then Tol >= 0.0;
   --  Decompose then compare Reconstruct to A within Tol.
   --  False (no exception) when A is not DS / not square.

end Birkhoff_Von_Neumann;
