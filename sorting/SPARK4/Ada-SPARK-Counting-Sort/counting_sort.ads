--  Counting_Sort — Ada/SPARK Level 4 educational package for classic
--  counting sort on a bounded-key Element array. Time O(n + k) with
--  k = Max_Key + 1. Reconstruction emit over a fixed count table.
--
--  SPARK port of Ada-Counting-Sort: hard Max_N bound, fixed count table
--  over 0 .. Max_Key (no dynamic min/max span), no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary Integer keys, Max_Range = 100_000, and
--  arbitrary A'First; this port takes any A'First (A'Length <= Max_N), Element in
--  0 .. Max_Key, and uses Pre => In_Bounds (A). Sortedness and
--  multiset equality (Is_Perm) are both proved Level-4 postconditions.
--
--  Reference: https://en.wikipedia.org/wiki/Counting_sort

package Counting_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / key-domain bounds (classroom; static count table)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Inclusive upper bound on Element values. Count table is
   --  array (0 .. Max_Key) — size 256. Sibling uses dynamic
   --  Max_Range = 100_000 over arbitrary Integer min..max.
   Max_Key : constant Natural := 255;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Positions 1 .. N (N = A'Length <= Max_N) at any origin: position
   --  K is A (A'First + (K - 1)).
   subtype Index is Natural range 0 .. Max_N;

   --  Educational keys: fixed span so the count table is a static array.
   subtype Element is Natural range 0 .. Max_Key;

   type Element_Array is array (Positive range <>) of Element;

   subtype Count_Index is Element;
   type Count_Array is array (Count_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N)
   with Global => null;
   --  Shape guard used by every entry point: a length bound, any origin.
   --  Element subtype already enforces keys in 0 .. Max_Key.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'Range => (if I < A'Last then A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic counting sort / Wikipedia reconstruction)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Keys live in 0 .. Max_Key.
   --  1. Histogram: Hist (K) := occurrences of key K in A.
   --  2. Emit: for K in 0 .. Max_Key, write Hist (K) copies of K into A
   --     left-to-right (CDF expansion / reconstruction).
   --  When Element is the key, equal keys are identical so content-level
   --  stability is vacuous; the non-SPARK sibling uses reverse-scan place
   --  for satellite stability. Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Permutation (multiset) model, used by the Post of Sort
   ---------------------------------------------------------------------------

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               =>
       Occ'Result <= Last
       and then (if Last < A'First then Occ'Result = 0
                 else Occ'Result <= Last - A'First + 1),
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
   --  Ascending classic counting sort (histogram → emit by ascending key).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the same values as before,
   --  each equally often (Is_Perm).

end Counting_Sort;
