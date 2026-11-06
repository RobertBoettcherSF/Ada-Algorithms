pragma Ada_2022;

package Intro_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   --  Musser depth budget for an array of length 8: 2 * floor(log2(8)).
   --  Each recursive call drops the pivot, and a slice of length at most 2
   --  is ordered in place, so this budget is never exhausted. Sort_Limited
   --  with a smaller budget is what runs the heapsort fallback.
   subtype Depth is Natural range 0 .. 6;
   Depth_Budget : constant Depth := 6;

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
   --  and, when that child exists, child 2*I+1.
   function Is_Max_Heap (A : Input_Array) return Boolean is
     (A (1) >= A (2) and then A (1) >= A (3)
      and then A (2) >= A (4) and then A (2) >= A (5)
      and then A (3) >= A (6) and then A (3) >= A (7)
      and then A (4) >= A (8))
   with Global => null;

   --  Lomuto partition of A (Lo .. Hi). The pivot is A (Hi). The introsort
   --  recursion calls this procedure.
   procedure Partition_Range (A : in out Input_Array; Lo, Hi : Index; P : out Index)
   with
     Global => null,
     Pre    => Lo < Hi,
     Post   =>
       P in Lo .. Hi
       and then (for all K in Lo .. Hi =>
                   (if K < P then A (K) <= A (P)
                    elsif K > P then A (K) >= A (P)))
       and then (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K));

   --  Whole-array Lomuto step. Thin call to Partition_Range.
   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   with Global => null;

   --  Floyd build of a max-heap on the whole array. The heapsort fallback
   --  calls this, then sifts the root out to the end.
   procedure Heapify (A : in out Input_Array)
   with
     Global => null,
     Post   => Is_Max_Heap (A) and then Is_Perm (A, A'Old);

   --  Introsort with an explicit depth budget. Max_Depth = 0 heapsorts.
   --  Max_Depth = Depth_Budget does not: the budget is not exhausted.
   procedure Sort_Limited
     (Input : Input_Array; Max_Depth : Depth; Output : out Input_Array;
      Heap_Fallbacks : out Natural)
   with Global => null;

   function Sort (Input : Input_Array) return Input_Array
   with Global => null;
end Intro_Sort;
