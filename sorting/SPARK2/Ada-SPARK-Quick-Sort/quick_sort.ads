pragma Ada_2022;

package Quick_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   --  One Lomuto partition of the whole array. The pivot is the last
   --  element. Pivot_Index is where that pivot ends: every value before
   --  it is <= the pivot, and every value after it is >= the pivot.
   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   with Global => null;

   --  Quicksort: partition the live slice around its last element and
   --  recurse on both sides. The array length stays Index (1 .. 8).
   function Sort (Input : Input_Array) return Input_Array
     with Global => null;
end Quick_Sort;
