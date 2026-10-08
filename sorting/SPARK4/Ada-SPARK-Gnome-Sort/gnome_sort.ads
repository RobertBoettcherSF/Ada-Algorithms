--  Gnome_Sort — Ada/SPARK Level 4 educational package for classic
--  gnome sort (stupid sort) on an Integer array: garden-gnome adjacent
--  compare / swap / step. Equivalent to insertion sort but moving
--  elements by adjacent swaps. Best O(n), average/worst O(n²), O(1)
--  extra space; stable-ish when advancing on >= (equals not swapped back).
--
--  SPARK port of Ada-Gnome-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First and raises on oversized n; this port
--  requires A'First = 1 and uses Pre => In_Bounds (A). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Gnome_sort

package Gnome_Sort
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
   -- Algorithm sketch (classic gnome / stupid sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Build a sorted prefix from left to right.
   --  For each index I from 2 through A'Last (the new "pot"):
   --    Let Pos := I. While Pos > 1 and A(Pos) < A(Pos-1):
   --      swap A(Pos) with A(Pos-1); Pos := Pos - 1.
   --    (Otherwise advance — equals use `>=` / do not swap back.)
   --  After the outer step for I, the prefix A(1 .. I) is sorted.
   --  This is insertion sort via adjacent swaps (garden-gnome steps).
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
   --  Ascending classic in-place gnome (stupid) sort via adjacent swaps.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Gnome_Sort;
