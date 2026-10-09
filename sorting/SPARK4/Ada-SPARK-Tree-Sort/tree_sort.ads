--  Tree_Sort — Ada/SPARK Level 4 educational package for classic
--  unbalanced tree sort (BST insert + in-order write-back) on an
--  Integer array. Average O(n log n); worst O(n²) on sorted /
--  reverse-sorted / all-equal input (no AVL). Fixed node pool; stable
--  when equals ride the right spine.
--
--  SPARK port of Ada-Tree-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling has Max_N = 4096 and raises on oversized n; this port takes
--  any A'First in 1 .. Max_N (the node pool stays 1 .. Max_N) and uses
--  Pre => In_Bounds (A). Sortedness and multiset equality
--  (Is_Perm) are both proved Level-4 postconditions.
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
       Post   =>
         In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending unbalanced tree sort (BST insert, then in-order dump).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the same values as before,
   --  each equally often (Is_Perm).

end Tree_Sort;
