--  PLACEHOLDER: adjacent compare-exchange passes (bubble sort) under a binary-insertion-sort name; see tools/vv/hidden_stub.csv
pragma Ada_2022;

--  Binary insertion sort: insert each element into the sorted prefix
--  before it, finding its place by binary search.
package Binary_Insertion_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   function Is_Sorted (A : Input_Array) return Boolean is
     (for all K in Index'First .. Index'Last - 1 => A (K) <= A (K + 1));

   --  Occurrences of V in A (1 .. N).
   function Occ (A : Input_Array; V : Value; N : Natural) return Natural
   with
     Ghost,
     Pre                => N <= Index'Last,
     Post               => Occ'Result <= N,
     Subprogram_Variant => (Decreases => N);

   --  Inserting the I-th element searches I insertion points: at most
   --  floor (log2 (I - 1)) + 1 comparisons; 17 in all for 8 elements.
   subtype Probe_Count is Natural range 0 .. 17;
   type Sort_Result is record
      Sorted : Input_Array;
      Probes : Probe_Count;   --  comparisons of two values
   end record;

   function Sort (Input : Input_Array) return Sort_Result
   with
     Global => null,
     Post   => Is_Sorted (Sort'Result.Sorted)
               and then (for all V in Value =>
                           Occ (Sort'Result.Sorted, V, Index'Last) = Occ (Input, V, Index'Last));

private
   function Occ (A : Input_Array; V : Value; N : Natural) return Natural is
     (if N = 0 then 0 else Occ (A, V, N - 1) + (if A (N) = V then 1 else 0));
end Binary_Insertion_Sort;
