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
--  base 2 .. 256 with multi-pass LSD, and arbitrary A'First; this port
--  requires A'First = 1, Element in 0 .. Max_Key, and uses
--  Pre => In_Bounds (A). Full multiset / permutation equality is verified
--  by tests rather than claimed as a Level-4 postcondition (sortedness
--  is proved).
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

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Educational keys: fixed span so the digit / count table is static.
   subtype Element is Natural range 0 .. Max_Key;

   type Element_Array is array (Positive range <>) of Element;

   --  Digit domain equals the key domain when Base = Max_Key + 1.
   subtype Digit_Index is Element;
   type Count_Array is array (Digit_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).
   --  Element subtype already enforces keys in 0 .. Max_Key.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
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
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending LSD radix sort with fixed Base = 256 (one digit pass).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Radix_Sort;
