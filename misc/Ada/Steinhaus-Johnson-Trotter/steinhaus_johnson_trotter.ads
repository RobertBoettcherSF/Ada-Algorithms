--  Steinhaus_Johnson_Trotter — Ada 2023 educational package for the
--  Steinhaus–Johnson–Trotter algorithm (plain changes / adjacent-
--  transposition permutations). Generates all n! permutations of
--  {1 .. n} so that consecutive permutations differ by swapping two
--  adjacent elements. Uses the classic iterative “mobile integer”
--  formulation (directions on values; swap largest mobile; reverse
--  directions of all larger values).
--  Reference:
--  https://en.wikipedia.org/wiki/Steinhaus%E2%80%93Johnson%E2%80%93Trotter_algorithm

pragma Ada_2022;

package Steinhaus_Johnson_Trotter
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; n! grows fast)
   ---------------------------------------------------------------------------

   --  Maximum n accepted by Generate / Count / Factorial (for n > 0).
   --  7! = 5040 fits comfortably in memory for collect-style tests;
   --  8! = 40320 is fine for streaming visitors but heavier to store.
   Max_N : constant Positive := 7;

   --  7! — handy upper bound when allocating visitor-side buffers.
   Max_Count : constant Positive := 5_040;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  A permutation of the integers 1 .. N (N = P'Length). Index bounds
   --  are always 1 .. N in values produced by Generate; callers may use
   --  other Positive ranges when writing helpers.
   type Permutation is array (Positive range <>) of Positive;

   Invalid_Argument : exception;
   --  Raised when:
   --    * N = 0; or
   --    * N > Max_N
   --  for Count / Generate / Factorial (Factorial also rejects N > Max_N).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (mobile-integer / Even-style directions)
   ---------------------------------------------------------------------------
   --  1. Start with the identity π = (1 2 … n); every element faces LEFT.
   --  2. An element is *mobile* when it is strictly larger than the
   --     neighbour it faces (and that neighbour exists).
   --  3. While a mobile element exists:
   --       a. Choose the largest mobile value k; swap it with the
   --          neighbour it faces (an adjacent transposition).
   --       b. Reverse the direction of every value strictly larger than k.
   --  4. When no mobile element remains, all n! permutations have been
   --     emitted. Average work per permutation is O(1) with Even’s
   --     bookkeeping refinements; this educational code is O(n) per step.

   ---------------------------------------------------------------------------
   -- Core API
   ---------------------------------------------------------------------------

   function Factorial (N : Natural) return Natural;
   --  N! for 0 ≤ N ≤ Max_N (0! = 1). Raises Invalid_Argument when N > Max_N.

   function Count (N : Natural) return Natural;
   --  Number of permutations generated for size N, equal to N!.
   --  Raises Invalid_Argument when N = 0 or N > Max_N.

   procedure Generate
     (N     : Natural;
      Visit : not null access procedure (P : Permutation));
   --  Stream all N! permutations of {1 .. N} in Steinhaus–Johnson–Trotter
   --  (plain-change) order. Each Visit call receives a Permutation with
   --  bounds 1 .. N. Raises Invalid_Argument when N = 0 or N > Max_N.
   --  Does not store the full table — suitable for Max_N and beyond if
   --  Max_N were raised, as long as the visitor does not buffer everything.

   ---------------------------------------------------------------------------
   -- Helpers (useful for tests and teaching)
   ---------------------------------------------------------------------------

   function Is_Permutation (P : Permutation) return Boolean;
   --  True iff P contains each of 1 .. P'Length exactly once.
   --  Empty arrays return False (N ≥ 1 for permutations here).

   function Differs_By_Adjacent_Transposition
     (A, B : Permutation) return Boolean;
   --  True iff A and B have the same length N ≥ 2 and differ by exactly
   --  one swap of two adjacent positions (plain change). False when
   --  lengths differ, N < 2, or the Hamming pattern is not a single
   --  adjacent transposition.

end Steinhaus_Johnson_Trotter;
