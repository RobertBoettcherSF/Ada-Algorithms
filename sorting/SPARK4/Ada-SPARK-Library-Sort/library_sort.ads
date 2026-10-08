--  Library_Sort — Ada/SPARK Level 4 educational package for library sort
--  (gapped insertion sort, Bender–Farach-Colton–Mosteiro) on an Integer
--  array. Keeps the values in a working array of capacity (1+ε)·n with
--  ε = 1 ⇒ Cap = 2·n and free slots between them; binary-search insert
--  plus a shift to the nearest free slot; spread out again after 1, 2,
--  4, .. insertions; pack the occupied slots back into A. Average
--  O(n log n) w.h.p. for suitable ε; auxiliary Θ((1+ε)n) space.
--
--  SPARK port of Ada-Library-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_N = 8192, allows arbitrary A'First, and raises on
--  oversized n; this port requires A'First = 1 and uses a fixed working
--  array of size Max_Cap = 2·Max_N. Sortedness is proved for the library
--  phase itself (the occupied slots stay in order and are counted), with
--  no final fallback sort. Full multiset / permutation equality is
--  verified by tests rather than claimed as a Level-4 postcondition.
--
--  Reference: https://en.wikipedia.org/wiki/Library_sort

package Library_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 8_192) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Gap factor ε = 1 ⇒ Cap(n) = (1+ε)·n = 2·n. Static working array
   --  is sized for the largest Cap: Max_Cap = 2·Max_N = 128.
   Max_Cap : constant Positive := 2 * Max_N;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia library sort / gapped insertion)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Cap := 2·n (ε = 1). Working array
   --  W(1 .. Max_Cap) of slots (occupied flag + value); use W(1 .. Cap).
   --  Place A(1); then for each remaining x:
   --    After 1, 2, 4, … insertions, rebalance: gather the occupied values
   --      in slot order and spread them to slots 1, 3, 5, … (one free slot
   --      after each).
   --    Binary-search W, skipping free slots, for the first slot whose
   --      value is greater than x.
   --    Put x there if it is free; otherwise shift the values up to the
   --      nearest free slot on the right by one place (or, if none, the
   --      values down to the nearest free slot on the left) and put x in
   --      the opened slot.
   --  Pack the occupied slots of W left-to-right back into A.
   --  The occupied slots of W stay nondecreasing and there are exactly as
   --  many as values inserted; that proves Is_Sorted. Empty and singleton
   --  arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending library sort (ε = 1, Cap = 2·n).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Library_Sort;
