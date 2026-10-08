--  Tree_Sort — Ada/SPARK Level 4 educational package for classic
--  unbalanced tree sort (BST insert + in-order write-back) on an
--  Integer array. Average O(n log n); worst O(n²) on sorted /
--  reverse-sorted / all-equal input (no AVL). Fixed node pool; stable
--  when equals ride the right spine.
--
--  SPARK port of Ada-Tree-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First, Max_N = 4096, and raises on
--  oversized n; this port requires A'First = 1 and uses
--  Pre => In_Bounds (A). Full multiset / permutation equality is
--  verified by tests rather than claimed as a Level-4 postcondition
--  (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Tree_sort

package Tree_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / BST VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length / node pool. Smaller than the non-SPARK
   --  sibling (Max_N = 4_096) so Level 4 can discharge array / tree VCs.
   Max_N : constant Positive := 64;

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
   -- Algorithm sketch (BST insert + in-order dump / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Fixed node pool of Max_N BST nodes (index
   --  0 = null). Insert each A(I) into an unbalanced BST:
   --    left < node <= right (equals go right → stable equal-key order).
   --  Write-back extracts successive minima from the live pool (same
   --  multiset / order as BST in-order; Level 4 avoids deep recursive
   --  in-order BST VCs). Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending unbalanced tree sort (BST insert, then in-order dump).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Tree_Sort;
