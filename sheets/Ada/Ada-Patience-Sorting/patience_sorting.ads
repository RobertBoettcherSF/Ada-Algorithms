--  Patience_Sorting — Ada 2023 educational package for patience sorting
--  (card-game inspired sorting) on Integer arrays with a bounded length.
--  Deal each element onto piles (leftmost pile whose top >= element, else
--  a new pile), then recover sorted order by repeatedly taking the
--  minimum among pile tops (k-way merge). Number of piles equals the
--  length of a longest increasing subsequence (classic rule).
--  Reference: https://en.wikipedia.org/wiki/Patience_sorting

pragma Ada_2022;

package Patience_Sorting
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  The body uses a fixed node pool of Max_N stack nodes plus an array
   --  of at most Max_N pile tops (no unbounded heap). Worst-case merge
   --  is O(n²) when there are Θ(n) piles, so keep Max_N educational.
   Max_N : constant Positive := 8_192;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia patience sorting)
   ---------------------------------------------------------------------------
   --  Phase 1 — Deal (patience card game):
   --    Initially there are no piles. Each element X is placed on the
   --    *leftmost* existing pile whose top value is >= X; if no such
   --    pile exists, start a new pile to the right. By construction the
   --    pile tops form a strictly increasing left-to-right sequence, so
   --    the target pile can be found by binary search.
   --    Placement rule used here (Wikipedia overview / Aldous–Diaconis):
   --      place on leftmost pile with top >= X
   --    (not the strict-top > X variant of some pseudocode listings).
   --    Within each pile, newer tops are <= older tops, so reading a
   --    pile from top to bottom yields a nondecreasing sequence.
   --
   --  Phase 2 — Recover sorted order:
   --    Repeatedly take the minimum among the current pile tops and pop
   --    that pile (k-way merge of the piles). Empty piles are discarded.
   --
   --  LIS connection: under the classic >= placement rule, the number of
   --  piles equals the length of a longest *strictly increasing*
   --  subsequence of the input.
   --
   --  Storage: fixed pool of Max_N linked-list nodes (one per element)
   --  forming the pile stacks; no unbounded heap allocation.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending patience sort (deal onto piles, then merge tops).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Patience_Sorting;
