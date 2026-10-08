--  Heapsort — Ada/SPARK educational package for classic in-place
--  heapsort on a binary max-heap (Floyd bottom-up heapify +
--  extract-max). Guarantees O(n log n) comparisons/swaps; in-place;
--  not stable.
--
--  SPARK port of Ada-Heapsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Child
--  indexes use the general First-relative form (any A'First = Lo):
--
--      Has_Left (I)  <=>  I - Lo <= (Hi - Lo - 1) / 2
--      Left (I)      =    Lo + 2 * (I - Lo) + 1
--      Parent (I)    =    Lo + (I - Lo - 1) / 2   (I > Lo)
--
--  Guarding Has_Left before computing Left avoids overflow near
--  Index'Last. Full multiset / permutation equality is verified by
--  tests rather than claimed as a postcondition (sortedness is proved
--  at Silver).
--
--  Reference: https://en.wikipedia.org/wiki/Heapsort

package Heapsort
  with SPARK_Mode => On
is

   Max_N : constant Positive := 64;

   subtype Index is Natural range 0 .. Max_N;
   --  Live heap slots sit in 1 .. Max_N (any origin inside that band).
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;
   --  At most Max_N elements; any origin with First in 1 .. Max_N
   --  (empty arrays use Last = First - 1, possibly 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);

   --  Assume In_Bounds (A). With Lo = A'First, Hi = Heap_Last:
   --    Parent(I) = Lo + (I-Lo-1)/2, Left(I) = Lo + 2*(I-Lo)+1
   --    (only when Has_Left: I-Lo <= (Hi-Lo-1)/2).
   --  1. Heapify: sift every non-leaf from last-parent down to Lo.
   --  2. Extract-max: swap A(Lo) with A(Heap_Last); sift A(Lo).

   procedure Sift_Down
     (A         : in out Element_Array;
      Root      : Index;
      Heap_Last : Index)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Heap_Last in A'Range
       and then Root in A'First .. Heap_Last,
     Post   =>
       In_Bounds (A)
       and then
         (for all K in Heap_Last + 1 .. A'Last => A (K) = A'Old (K));

   procedure Heapify (A : in out Element_Array)
   with
     Global => null,
     Pre    => In_Bounds (A),
     Post   => In_Bounds (A);

   procedure Sort (A : in out Element_Array)
   with
     Global => null,
     Pre    => In_Bounds (A),
     Post   => In_Bounds (A) and then Is_Sorted (A);

end Heapsort;
