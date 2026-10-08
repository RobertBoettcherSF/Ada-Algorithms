--  Heaps_Algorithm — Ada/SPARK Level 4 educational package for Heap's
--  algorithm (permutation generation by B. R. Heap, 1963). Generates all
--  n! permutations of {1 .. n} so that consecutive permutations differ by
--  a single transposition (not necessarily adjacent). This is NOT heapsort
--  — despite the name, Heap's algorithm enumerates permutations.
--
--  SPARK port of Ada-Heaps-Algorithm: hard Max_N bound, no exceptions,
--  no access-procedure Visit callback. Generate fills a static Perm_Store
--  and returns Last = Factorial(N). Recursive Heap_Generate uses
--  Subprogram_Variant (Decreases => K). Full uniqueness / completeness of
--  the stored table is verified by tests rather than claimed as a Level-4
--  postcondition beyond Last = N! (and optional row-permutation posts when
--  they discharge).
--
--  Reference: https://en.wikipedia.org/wiki/Heap%27s_algorithm

package Heaps_Algorithm
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; n! grows fast)
   ---------------------------------------------------------------------------

   --  Maximum n accepted by Generate / Count / Factorial.
   --  7! = 5040 fits comfortably in the static store.
   Max_N : constant Positive := 7;

   --  7! — capacity of Perm_Store.
   Max_Count : constant Positive := 5_040;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  A permutation of the integers 1 .. N (N = P'Length). Live indices
   --  used by Generate are always 1 .. N with N ≤ Max_N.
   type Permutation is array (Positive range <>) of Positive;

   --  Static table of permutations. Row R holds a length-N permutation in
   --  columns 1 .. N (columns N+1 .. Max_N are unused padding).
   type Perm_Store is array (1 .. Max_Count, 1 .. Max_N) of Positive;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic recursive Heap, 1-based)
   ---------------------------------------------------------------------------
   --  procedure Heap_Generate (K):
   --    if K = 1 then
   --       store A; Last := Last + 1;
   --    else
   --       Heap_Generate (K - 1);
   --       for I in 1 .. K - 1 loop
   --          if K is even then swap A(I), A(K)
   --          else             swap A(1), A(K)
   --          end if;
   --          Heap_Generate (K - 1);
   --       end loop;
   --    end if;
   --
   --  Each recursive block of (K-1)! permutations is followed by a single
   --  swap that brings a new element into position K (or cycles the prefix
   --  when K is even). The produced sequence has length n!.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Core API
   ---------------------------------------------------------------------------

   function Factorial (N : Natural) return Natural is
     (case N is
         when 0 | 1 => 1,
         when 2     => 2,
         when 3     => 6,
         when 4     => 24,
         when 5     => 120,
         when 6     => 720,
         when 7     => Max_Count,
         when others => 1)
   with
     Global => null,
     Pre    => N <= Max_N,
     Post   =>
       Factorial'Result >= 1
       and then Factorial'Result <= Max_Count
       and then
         (case N is
             when 0 | 1 => Factorial'Result = 1,
             when 2     => Factorial'Result = 2,
             when 3     => Factorial'Result = 6,
             when 4     => Factorial'Result = 24,
             when 5     => Factorial'Result = 120,
             when 6     => Factorial'Result = 720,
             when 7     => Factorial'Result = Max_Count,
             when others => True);
   --  N! for 0 ≤ N ≤ Max_N (0! = 1). Explicit table keeps Level-4 VCs
   --  inside automated SMT reach (no recursive Post / variant needed).

   function Count (N : Positive) return Natural
     with
       Global => null,
       Pre    => N <= Max_N,
       Post   => Count'Result = Factorial (N);
   --  Number of permutations generated for size N, equal to N!.

   function Is_Permutation (P : Permutation) return Boolean is
     (P'First = 1
      and then P'Last in 1 .. Max_N
      and then (for all I in P'Range => P (I) in 1 .. P'Last)
      and then
        (for all I in P'Range =>
           (for all J in P'Range =>
              (if I /= J then P (I) /= P (J)))))
   with Global => null;
   --  True iff P'First = 1, P'Last in 1 .. Max_N, and P contains each of
   --  1 .. P'Last exactly once. Empty / malformed shapes return False.

   function Row_Is_Permutation
     (Store : Perm_Store;
      R     : Positive;
      N     : Positive) return Boolean
   is
     ((for all I in 1 .. N => Store (R, I) in 1 .. N)
      and then
        (for all I in 1 .. N =>
           (for all J in 1 .. N =>
              (if I /= J then Store (R, I) /= Store (R, J)))))
   with
     Global => null,
     Pre    => R in 1 .. Max_Count and then N in 1 .. Max_N;
   --  True iff Store(R, 1 .. N) is a permutation of 1 .. N.

   procedure Generate
     (N     : Positive;
      Store : out Perm_Store;
      Last  : out Natural)
     with
       Global => null,
       Pre    => N in 1 .. Max_N,
       Post   =>
         Last = Factorial (N)
         and then Last in 1 .. Max_Count
         and then
           (for all R in 1 .. Last =>
              Row_Is_Permutation (Store, R, N));
   --  Fill Store with all N! permutations of {1 .. N} in classic Heap
   --  order. Last is the number of rows written (= N!). Unused columns
   --  N+1 .. Max_N and unused rows Last+1 .. Max_Count are set to 1.

   ---------------------------------------------------------------------------
   -- Helpers (useful for tests and teaching)
   ---------------------------------------------------------------------------

   function Differs_By_Single_Swap
     (A, B : Permutation) return Boolean
     with Global => null;
   --  True iff A and B have the same length N ≥ 2 and differ by exactly
   --  one transposition of two (not necessarily adjacent) positions.

end Heaps_Algorithm;
