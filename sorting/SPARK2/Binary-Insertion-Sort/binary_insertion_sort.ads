pragma Ada_2022;

package Binary_Insertion_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   type Sort_Result is record
      Sorted : Input_Array;
      Probes : Natural;   --  comparisons of two values
   end record;

   function Sort (Input : Input_Array) return Sort_Result
     with Global => null;
end Binary_Insertion_Sort;
