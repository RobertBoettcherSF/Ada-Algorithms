--  Cocktail_Shaker_Sort — Ada/SPARK Level 4 educational package for
--  cocktail shaker sort (bidirectional bubble / cocktail / shaker sort)
--  on an Integer array. Alternating forward (max to Hi) and backward
--  (min to Lo) adjacent-swap passes shrink a Lo..Hi window; early exit
--  on a clean (swap-free) pass. Best near O(n), average/worst O(n²),
--  O(1) extra space; stable when the swap predicate is strict `>`.
--
--  SPARK port of Ada-Cocktail-Shaker-Sort: hard Max_N bound, no
--  exceptions, In_Bounds / Is_Sorted contracts replace Invalid_Argument.
--  Non-SPARK sibling raises on oversized n and loops until the window
--  collapses; this port takes any A'First in 1 .. Max_N (the window
--  starts at A'First .. A'Last), uses Pre => In_Bounds (A), and proves sortedness of the shaker passes
--  themselves (window invariant; Hi - Lo is the loop variant). The Post also proves
--  that the result is a permutation of the input (Is_Perm).
--
--  Reference: https://en.wikipedia.org/wiki/Cocktail_shaker_sort

package Cocktail_Shaker_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 10_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Live slots; the index subtype carries the 1 .. Max_N origin range,
   --  In_Bounds adds the length.
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements, any
   --  origin with First in 1 .. Max_N (empty arrays use Last = First - 1).

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic cocktail / bidirectional bubble / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Maintain an active window [Lo .. Hi]
   --  (initially A'First .. A'Last). While Lo < Hi:
   --      Forward pass:  for I in Lo .. Hi-1, swap if A(I) > A(I+1);
   --                     then Hi := Hi - 1  (largest key bubbled to Hi).
   --      Backward pass: for I in reverse Lo+1 .. Hi, swap if A(I-1) > A(I);
   --                     then Lo := Lo + 1  (smallest key bubbled to Lo).
   --    Stop early when a pass performs no swaps (the window is sorted).
   --  Proof: A(A'First .. Lo-1) stays sorted and <= the rest, A(Hi+1 .. A'Last)
   --  stays sorted and >= the rest; Hi - Lo decreases every round. This
   --  proves Is_Sorted directly (no extra bubble sort at the end).
   --  Swap only when A(I) > A(I+1) (strict `>`; never `>=`) so equal
   --  keys keep relative order (stable).
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Permutation (multiset) model, used by the Post of Sort
   ---------------------------------------------------------------------------

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               => Occ'Result <= Last,
     Subprogram_Variant => (Decreases => Last);
   --  How many of A (A'First .. Last) equal V.

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);
   --  A and B have the same bounds and hold the same values, each equally
   --  often. A value found in neither array counts 0 in both, so comparing
   --  the counts of the values of A and of B covers every value.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending in-place cocktail shaker (bidirectional bubble) sort.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

end Cocktail_Shaker_Sort;
