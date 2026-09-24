--  Library_Sort — Ada 2023 educational package for library sort
--  (gapped insertion sort, Bender–Farach-Colton–Mosteiro 2004/2006)
--  on Integer arrays with a bounded length.
--  Maintains a working array of capacity (1+ε)·n with evenly spaced
--  gaps; inserts via binary search and local shifts into a gap;
--  rebalances (redistributes gaps) on doubling rounds and on congestion;
--  finally packs the dense sorted result back into A.
--  Reference: https://en.wikipedia.org/wiki/Library_sort

pragma Ada_2022;

package Library_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Working buffer size is (1+ε)·n with ε = 1, so ~2·Max_N slots.
   --  Keep Max_N educational so the auxiliary buffer stays modest.
   Max_N : constant Positive := 8_192;

   --  Gap factor ε = 1 ⇒ capacity ≈ (1+ε)·n = 2·n.
   --  Average O(n log n) with high probability for suitable ε (paper);
   --  without random permutation of the input, some adversarial orders
   --  can force more rebalances / shifts (closer to insertion sort).
   Epsilon_Numerator   : constant Positive := 1;
   Epsilon_Denominator : constant Positive := 1;
   --  Cap(n) = n + (Epsilon_Numerator * n) / Epsilon_Denominator = 2·n.

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia library sort / gapped insertion sort)
   ---------------------------------------------------------------------------
   --  Librarian analogy: books on a shelf with blank spaces between
   --  letters make room for a new book without sliding every volume
   --  from the insertion point to the far end — only until the next gap.
   --
   --  1. Allocate a working array W of length Cap = (1+ε)·n, all gaps.
   --  2. Insert elements of A one by one:
   --       * binary-search the occupied prefix of W (skipping gaps at mid)
   --         to find an insertion index;
   --       * place into a gap, or shift occupied slots right until a gap;
   --       * on doubling rounds (and if a local region has no gap),
   --         rebalance: pack occupied values then re-space them evenly.
   --  3. Pack occupied slots of W left-to-right back into A.
   --
   --  Comparison sort; not stable; not adaptive in the usual sense
   --  (binary search + optional shuffle in the paper). This body does
   --  not shuffle — educational clarity over the high-probability bound.
   --  Do not `with` sibling Ada-* packages. No unbounded recursion.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending library sort (gapped insertion sort, ε = 1).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Library_Sort;
