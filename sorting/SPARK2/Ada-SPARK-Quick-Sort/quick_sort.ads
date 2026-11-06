pragma Ada_2022;

package Quick_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   --  Lomuto partition of A (Lo .. Hi). The pivot is A (Hi). Sort's
   --  recursive step calls this procedure; Partition below is only a
   --  wrapper for the whole array.
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

   --  One Lomuto partition of the whole array. Thin call to Partition_Range.
   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   with Global => null;

   --  Quicksort: partition the live slice around its last element and
   --  recurse on both sides. The array length stays Index (1 .. 8).
   function Sort (Input : Input_Array) return Input_Array
     with Global => null;
end Quick_Sort;
