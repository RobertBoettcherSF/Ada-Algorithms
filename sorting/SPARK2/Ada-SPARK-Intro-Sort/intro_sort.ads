pragma Ada_2022;

package Intro_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   --  Slices of this length or shorter are insertion-sorted. The cutoff
   --  stays 2 so a longer slice is partitioned, or heapsorted when the
   --  remaining depth is 0.
   Insertion_Cutoff : constant Positive := 2;

   --  2 * floor(log2(8)). Sort computes this once from the full length
   --  and passes it down; a recursive call receives that value minus one
   --  and does not recompute 2 * log2 of its own slice.
   Depth_Limit : constant Natural := 6;

   --  How many of A (1 .. Last) equal V. Last = 0 counts nothing.
   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => Last <= Index'Last,
     Post               => Occ'Result <= Last,
     Subprogram_Variant => (Decreases => Last);

   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural is
     (if Last = 0 then 0
      else Occ (A, V, Last - 1)
           + (if A (Index (Last)) = V then 1 else 0));

   function Is_Perm (A, B : Input_Array) return Boolean is
     (for all V in Value => Occ (A, V, Index'Last) = Occ (B, V, Index'Last))
   with Global => null;

   function Is_Sorted (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1))
   with Global => null;

   --  Max-heap on the whole array of length 8. Parent I is >= child 2*I
   --  and, when that child exists, child 2*I+1:
   --  1 >= 2 and 3; 2 >= 4 and 5; 3 >= 6 and 7; 4 >= 8.
   function Is_Max_Heap (A : Input_Array) return Boolean is
     (A (1) >= A (2) and then A (1) >= A (3)
      and then A (2) >= A (4) and then A (2) >= A (5)
      and then A (3) >= A (6) and then A (3) >= A (7)
      and then A (4) >= A (8))
   with Global => null;

   --  One Lomuto partition of the whole array. The pivot is the last
   --  element. Pivot_Index is where that pivot ends: every value before
   --  it is <= the pivot, and every value after it is >= the pivot.
   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   with Global => null;

   --  Floyd build: sift down from the last parent (Index'Last / 2) to the
   --  root so the array is a max-heap. The length stays Index (1 .. 8).
   procedure Heapify (A : in out Input_Array)
   with
     Global => null,
     Post   => Is_Max_Heap (A) and then Is_Perm (A, A'Old);

   --  Heapsort the slice Lo .. Hi in place. Cells outside that slice stay
   --  put. The depth-0 fallback of Sort_Range uses this.
   procedure Heap_Sort_Range (A : in out Input_Array; Lo, Hi : Index)
   with
     Global => null,
     Pre    => Lo <= Hi,
     Post   =>
       (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K));

   --  Introsort with an explicit depth budget. Sort passes Depth_Limit.
   --  Depth 0 heapsorts the whole array, so the fallback can be forced.
   --  Used_Heap is True when some slice took that heapsort fallback.
   --  Heap_Was_Unsorted is True when such a slice's heap was not already
   --  sorted (a compare-exchange Heapify does not leave it that way).
   procedure Sort_Limited
     (Input             : Input_Array;
      Depth             : Natural;
      Output            : out Input_Array;
      Used_Heap         : out Boolean;
      Heap_Was_Unsorted : out Boolean)
   with Global => null;

   --  Introsort of the whole array. The depth budget is computed once
   --  here (Depth_Limit, 6) and then only decremented.
   function Sort (Input : Input_Array) return Input_Array
   with Global => null;
end Intro_Sort;
