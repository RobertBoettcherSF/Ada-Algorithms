--  PLACEHOLDER: one counting-sort pass (Base 256 = key range, so digit = key), not a multi-pass radix sort; see H144
--  Radix_Sort — Ada/SPARK Level 4 educational package for LSD (least-
--  significant-digit) radix sort with a counting-sort digit pass on a
--  bounded-key Element array. Fixed byte Base = 256; keys in
--  0 .. Max_Key with Max_Key = 255 so a single digit covers every key.
--  Time O(n + Base) with a static count table / reconstruction emit.
--
--  SPARK port of Ada-Radix-Sort: hard Max_N bound, fixed Base = 256 (no
--  Sort_Base), keys capped to 0 .. Max_Key, no exceptions, In_Bounds /
--  Is_Sorted contracts replace Invalid_Argument. Non-SPARK sibling allows
--  arbitrary nonnegative Integer keys, Max_Length = 100_000, optional
--  base 2 .. 256 with multi-pass LSD; this port takes any A'First in
--  1 .. Max_N, Element in 0 .. Max_Key, and uses
--  Pre => In_Bounds (A). Sortedness and multiset equality
--  (Is_Perm) are both proved Level-4 postconditions.
--
--  Closest SPARK sort sibling that shares the same array shape and key
--  cap: Ada-SPARK-Counting-Sort. README links only — do not `with`
--  sibling packages here.
--
--  Reference: https://en.wikipedia.org/wiki/Radix_sort

package Radix_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / key-domain / radix bounds (classroom; static buffers)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Inclusive upper bound on Element values. With Base = 256 and
   --  Max_Key = 255, one LSD digit pass covers the whole key
   --  (digit = key). Sibling accepts up to Integer'Last with many passes.
   Max_Key : constant Natural := 255;

   --  Fixed byte radix for classroom SPARK (sibling offers Sort_Base
   --  with 2 .. 256 and multi-pass decimal LSD). Count table is
   --  array (0 .. Base - 1) — here equal to 0 .. Max_Key.
   Base : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Educational keys: fixed span so the digit / count table is static.
   subtype Element is Natural range 0 .. Max_Key;

   --  Live slots; the index subtype carries the 1 .. Max_N origin range,
   --  In_Bounds adds the length.
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Element;

   --  Digit domain equals the key domain when Base = Max_Key + 1.
   subtype Digit_Index is Element;
   type Count_Array is array (Digit_Index) of Natural;

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
   --  Element subtype already enforces keys in 0 .. Max_Key.

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (LSD + counting-sort digit pass / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Keys live in 0 .. Max_Key; Base = 256 fixed.
   --  1. Digit of key at Exp = 1: d = (key / 1) mod Base = key
   --     (since key ≤ Max_Key = Base - 1).
   --  2. Counting-sort by that digit via histogram → reconstruction emit
   --     (write Hist (D) copies of key-value D left-to-right). Equal keys
   --     are identical so content-level stability is vacuous; the non-SPARK
   --     sibling uses reverse-scan place for satellite stability across
   --     multiple passes.
   --  Empty and singleton arrays are no-ops.
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
   --  Ascending LSD radix sort with fixed Base = 256 (one digit pass).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the same values as before,
   --  each equally often (Is_Perm).

end Radix_Sort;
