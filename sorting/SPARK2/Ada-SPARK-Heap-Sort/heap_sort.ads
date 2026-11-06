pragma Ada_2022;

package Heap_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

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

   --  Floyd build: sift down from the last parent (Index'Last / 2) to the
   --  root so the array is a max-heap. The length stays Index (1 .. 8).
   procedure Heapify (A : in out Input_Array)
   with
     Global => null,
     Post   => Is_Max_Heap (A) and then Is_Perm (A, A'Old);

   --  Copy the input, Heapify, then swap the root with the last live slot
   --  and sift down until the array is nondecreasing.
   function Sort (Input : Input_Array) return Input_Array
   with
     Global => null,
     Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Heap_Sort;
