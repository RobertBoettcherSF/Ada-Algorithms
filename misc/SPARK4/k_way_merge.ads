--  K_Way_Merge — Ada/SPARK Level 4 educational package for the k-way
--  merge algorithm: combine k sorted ascending Integer sequences into
--  one sorted sequence. Uses a linear scan of the k live heads each
--  step (educational O(N·k) simplification of the classic binary
--  min-heap of heads from Wikipedia). Static storage only — no access
--  types, no exceptions.
--
--  SPARK port of Ada-K-Way-Merge: hard Max_K / Max_Len / Max_Total
--  bounds, no exceptions, In_Bounds / Is_Sorted / List_Is_Sorted
--  contracts replace Invalid_Argument and access-constant Vector lists.
--  Non-SPARK sibling uses Max_K = 64, Max_Len = 10_000, Max_Total =
--  100_000, access constant Vector, a binary min-heap of heads
--  (O(N log k)), and raises Invalid_Argument. This port trades those
--  for classroom bounds (8 / 32 / 64), a flattened List_Store, and a
--  linear min-of-heads scan so Level 4 can discharge sortedness of the
--  merge result when inputs are sorted (no Bubble_Finish fallback).
--  Full multiset / permutation equality is verified by tests rather
--  than claimed as a Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/K-way_merge_algorithm

package K_Way_Merge
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Maximum number of input lists. Sibling uses 64.
   Max_K : constant Positive := 8;

   --  Maximum length of any single input list. Sibling uses 10_000.
   Max_Len : constant Positive := 32;

   --  Maximum total elements across all lists (also Output capacity).
   --  Sibling uses 100_000.
   Max_Total : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   subtype Index_K is Positive range 1 .. Max_K;
   subtype Len_Value is Natural range 0 .. Max_Len;
   subtype Total_Value is Natural range 0 .. Max_Total;

   --  Live indices are 1 .. N with N ≤ Max_Total. Empty arrays use Last = 0.
   type Element_Array is array (Positive range <>) of Integer;

   --  Per-list lengths for the first K slots of List_Store.
   type Len_Array is array (1 .. Max_K) of Len_Value;

   --  Static store: list I occupies Store (I, 1 .. Lens (I)).
   type List_Store is array (1 .. Max_K, 1 .. Max_Len) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_Total)
   with Global => null;
   --  Shape guard for 1-based arrays up to Max_Total (inputs ≤ Max_Len
   --  and the Output buffer of length Max_Total).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous).

   function List_Is_Sorted
     (Store : List_Store;
      I     : Index_K;
      Len   : Len_Value) return Boolean
   is
     (Len <= 1
      or else
        (for all J in 1 .. Len - 1 => Store (I, J) <= Store (I, J + 1)))
   with Global => null;
   --  True iff Store (I, 1 .. Len) is adjacent-nondecreasing.

   function All_Lists_Sorted
     (Store : List_Store;
      Lens  : Len_Array;
      K     : Index_K) return Boolean
   is
     (for all I in 1 .. K => List_Is_Sorted (Store, I, Lens (I)))
   with Global => null;

   --  Sum of Lens (1 .. K). Case expression keeps Pre/Post SMT-friendly.
   function Total_Length (Lens : Len_Array; K : Index_K) return Natural is
     (case K is
         when 1 => Natural (Lens (1)),
         when 2 => Natural (Lens (1)) + Natural (Lens (2)),
         when 3 =>
           Natural (Lens (1)) + Natural (Lens (2)) + Natural (Lens (3)),
         when 4 =>
           Natural (Lens (1)) + Natural (Lens (2)) + Natural (Lens (3))
             + Natural (Lens (4)),
         when 5 =>
           Natural (Lens (1)) + Natural (Lens (2)) + Natural (Lens (3))
             + Natural (Lens (4)) + Natural (Lens (5)),
         when 6 =>
           Natural (Lens (1)) + Natural (Lens (2)) + Natural (Lens (3))
             + Natural (Lens (4)) + Natural (Lens (5)) + Natural (Lens (6)),
         when 7 =>
           Natural (Lens (1)) + Natural (Lens (2)) + Natural (Lens (3))
             + Natural (Lens (4)) + Natural (Lens (5)) + Natural (Lens (6))
             + Natural (Lens (7)),
         when 8 =>
           Natural (Lens (1)) + Natural (Lens (2)) + Natural (Lens (3))
             + Natural (Lens (4)) + Natural (Lens (5)) + Natural (Lens (6))
             + Natural (Lens (7)) + Natural (Lens (8)))
   with
     Global => null,
     Post   => Total_Length'Result <= Natural (K) * Max_Len;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (linear scan of k heads)
   ---------------------------------------------------------------------------
   --  1. Preconditions: K in 1 .. Max_K, each Lens (I) ≤ Max_Len, each
   --     list Store (I, 1 .. Lens (I)) is sorted ascending, and
   --     Total_Length (Lens, K) ≤ Max_Total.
   --  2. Keep a cursor Pos (I) into each list (1 .. Lens (I)+1; exhausted
   --     when Pos (I) > Lens (I)).
   --  3. While any element remains: scan the K live heads, pick the
   --     minimum, append it to Output, advance that list's cursor.
   --  4. Loop invariant: Output (1 .. OI) is sorted and every live head
   --     is ≥ Output (OI) (vacuous when OI = 0). Because each input list
   --     is sorted, advancing preserves the head ≥ last property, so the
   --     merge result is sorted — proved at Level 4 without Bubble_Finish.
   --  Time O(N · k) with N = Total_Length, k ≤ Max_K. The Wikipedia
   --  heap-of-heads variant is O(N log k); the linear scan is the
   --  educational simplification chosen so SPARK Level 4 discharges
   --  sortedness cleanly (same spirit as Patience_Sorting's linear
   --  min-top merge, but here inputs are already sorted so the merge
   --  postcondition is Is_Sorted).
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Merge
   ---------------------------------------------------------------------------

   procedure Merge_K
     (Store  : List_Store;
      Lens   : Len_Array;
      K      : Index_K;
      Output : out Element_Array;
      Last   : out Natural)
   with
     Global => null,
     Pre    =>
       Output'First = 1
       and then Output'Last = Max_Total
       and then All_Lists_Sorted (Store, Lens, K)
       and then Total_Length (Lens, K) <= Max_Total,
     Post   =>
       Last = Total_Length (Lens, K)
       and then Last <= Max_Total
       and then In_Bounds (Output (1 .. Last))
       and then Is_Sorted (Output (1 .. Last));
   --  K-way merge of Store (1 .. K) with lengths Lens into Output.
   --  Writes the merged sequence into Output (1 .. Last); remaining
   --  Output slots are zeroed. Empty lists (Lens (I) = 0) contribute
   --  nothing. Post proves sortedness; multiset equality is checked by
   --  the test suite (not claimed here at Level 4).

   procedure Merge
     (A, B   : Element_Array;
      Output : out Element_Array;
      Last   : out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then In_Bounds (B)
       and then A'Last <= Max_Len
       and then B'Last <= Max_Len
       and then Is_Sorted (A)
       and then Is_Sorted (B)
       and then Natural (A'Last) + Natural (B'Last) <= Max_Total
       and then Output'First = 1
       and then Output'Last = Max_Total,
     Post   =>
       Last = Natural (A'Last) + Natural (B'Last)
       and then Last <= Max_Total
       and then In_Bounds (Output (1 .. Last))
       and then Is_Sorted (Output (1 .. Last));
   --  Educational 2-way merge (special case of k = 2 without a k-scan).
   --  Direct two-pointer scan; prefers A when A (IA) ≤ B (IB).

end K_Way_Merge;
