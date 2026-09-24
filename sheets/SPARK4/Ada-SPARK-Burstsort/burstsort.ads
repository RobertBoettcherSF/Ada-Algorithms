--  Burstsort — Ada/SPARK Level 4 educational package for Wikipedia
--  "Burstsort": a cache-friendly MSD radix / burst-trie hybrid for
--  strings. Shared prefixes are refined by character depth; unsorted
--  suffixes live in buckets; buckets larger than Burst_Threshold are
--  "burst" (redistributed at the next depth). Small buckets are finished
--  with insertion sort. A final gap-1 bubble finish proves Is_Sorted.
--
--  SPARK port of Ada-Burstsort: hard Max_N / Max_String_Len bounds, no
--  Unchecked_Deallocation / heap trie pointers (static work buffers only),
--  no exceptions, In_Bounds / Is_Sorted contracts replace Invalid_Argument.
--  Non-SPARK sibling uses a heap node pool, Max_N = 256, Max_String_Len =
--  64, Burst_Threshold = 8, Alphabet_Size = 256, and arbitrary A'First;
--  this port requires A'First = 1, uses an educational MSD-bucket
--  approximation of the burst trie (same emit order: Ended, then
--  character buckets 0 .. Alphabet_Size-1), and proves sortedness via
--  Bubble_Finish. Full multiset / permutation equality is verified by
--  tests rather than claimed as a Level-4 postcondition.
--
--  Reference: https://en.wikipedia.org/wiki/Burstsort

package Burstsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / alphabet / burst bounds (classroom; static buffers)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 256) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 32;

   --  Maximum character length of any single Bounded_String.
   Max_String_Len : constant Positive := 16;

   --  Bucket size that triggers a burst into the next character depth.
   --  Kept small so educational demos burst often.
   Burst_Threshold : constant Positive := 4;

   --  Full 8-bit Character alphabet (Latin-1 / Ada Character).
   Alphabet_Size : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Bounded_String is record
      Length : Natural range 0 .. Max_String_Len := 0;
      Data   : String (1 .. Max_String_Len) := [others => ' '];
   end record;

   type String_Array is array (Positive range <>) of Bounded_String;

   ---------------------------------------------------------------------------
   -- Construction / conversion / ordering
   ---------------------------------------------------------------------------

   function Make (S : String) return Bounded_String
     with
       Global => null,
       Pre    => S'Length <= Max_String_Len,
       Post   =>
         Make'Result.Length = S'Length
         and then
           (if S'Length > 0 then
              Make'Result.Data (1 .. S'Length) = S);
   --  Copy S into a Bounded_String. Pre replaces Invalid_Argument.

   function To_String (B : Bounded_String) return String
     with
       Global => null,
       Post   =>
         To_String'Result'Length = B.Length
         and then To_String'Result'First = 1
         and then
           (if B.Length > 0 then
              To_String'Result = B.Data (1 .. B.Length));
   --  Return B.Data (1 .. B.Length) as a 1-based String.

   function "<" (Left, Right : Bounded_String) return Boolean
     with Global => null;
   --  Lexicographic strict order (Ada String rules: after a common
   --  prefix the shorter string is smaller).

   function "<=" (Left, Right : Bounded_String) return Boolean is
     (not (Right < Left))
   with Global => null;
   --  Lexicographic non-strict order.

   function ">" (Left, Right : Bounded_String) return Boolean is
     (Right < Left)
   with Global => null;
   --  Strict greater-than (used by Bubble_Pass).

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : String_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).
   --  Length subtype already enforces 0 .. Max_String_Len per element.

   function Is_Sorted (A : String_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing under "<=" (empty / singleton
   --  vacuous).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (MSD burst buckets + insertion + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Copy A into a fixed Work buffer (1 .. Max_N).
   --  Educational burst-trie approximation (MSD by character depth):
   --    On a slice at Depth, if |slice| ≤ Burst_Threshold, insertion-sort
   --    the slice (small bucket finish). Else partition: strings with
   --    Length = Depth go to Ended (emit first); remaining strings are
   --    bucketed by Data (Depth+1). Buckets with count > Burst_Threshold
   --    are "burst" (recurse at Depth+1); small char-buckets are
   --    insertion-sorted. Emit order matches a burst-trie in-order walk.
   --  Copy Work back into A.
   --  After the burst phase, a final gap-1 bubble finish (shrinking
   --  unsorted suffix + early exit) establishes Is_Sorted — same proof
   --  role as Strand_Sort / Comb_Sort / Odd_Even_Sort.
   --  Burst/insert/collect prove only In_Bounds / RTE; sortedness is
   --  discharged by Bubble_Finish.
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out String_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Lexicographic ascending educational burstsort + bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Burstsort;
