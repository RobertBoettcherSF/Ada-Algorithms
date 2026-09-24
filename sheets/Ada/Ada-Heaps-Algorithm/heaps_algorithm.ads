--  Heaps_Algorithm — Ada 2023 educational package for Heap's algorithm
--  (permutation generation by B. R. Heap, 1963). Generates all n!
--  permutations of {1 .. n} so that consecutive permutations differ by
--  a single transposition (not necessarily adjacent). This is NOT
--  heapsort — despite the name, Heap's algorithm enumerates permutations.
--  Reference:
--  https://en.wikipedia.org/wiki/Heap%27s_algorithm

pragma Ada_2022;

package Heaps_Algorithm
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
   -- Algorithm sketch (classic recursive Heap, 1-based)
   ---------------------------------------------------------------------------
   --  procedure Generate (K):
   --    if K = 1 then
   --       Visit (A);
   --    else
   --       Generate (K - 1);
   --       for I in 1 .. K - 1 loop
   --          if K is even then
   --             swap A(I) and A(K);
   --          else
   --             swap A(1) and A(K);
   --          end if;
   --          Generate (K - 1);
   --       end loop;
   --    end if;
   --
   --  Each recursive block of (K-1)! permutations is followed by a single
   --  swap that brings a new element into position K (or cycles the prefix
   --  when K is even). The produced sequence has length n! and each step
   --  is exactly one transposition.

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
   --  Stream all N! permutations of {1 .. N} in Heap order. Each Visit
   --  call receives a Permutation with bounds 1 .. N. Raises
   --  Invalid_Argument when N = 0 or N > Max_N.
   --  Does not store the full table — suitable for Max_N and beyond if
   --  Max_N were raised, as long as the visitor does not buffer everything.

   ---------------------------------------------------------------------------
   -- Helpers (useful for tests and teaching)
   ---------------------------------------------------------------------------

   function Is_Permutation (P : Permutation) return Boolean;
   --  True iff P contains each of 1 .. P'Length exactly once.
   --  Empty arrays return False (N ≥ 1 for permutations here).

   function Differs_By_Single_Swap
     (A, B : Permutation) return Boolean;
   --  True iff A and B have the same length N ≥ 2 and differ by exactly
   --  one transposition of two (not necessarily adjacent) positions.
   --  False when lengths differ, N < 2, or the Hamming pattern is not a
   --  single swap.

end Heaps_Algorithm;
