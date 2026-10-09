pragma Ada_2022;

--  Search insert position: in a sorted array, find where Target is or
--  would be inserted, the first position whose value is >= Target
--  (Length + 1 if there is none), by halving the candidate range.
package Search_Insert_Position with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   subtype Insertion_Index is Positive range 1 .. Length + 1;
   type Value_Array is array (Index) of Value;
   subtype Sorted_Array is Value_Array
     with Dynamic_Predicate =>
       (for all I in 1 .. Length - 1 => Sorted_Array (I) <= Sorted_Array (I + 1));

   --  33 insertion points: at most floor (log2 33) + 1 = 6 reads.
   subtype Probe_Count is Natural range 0 .. 6;
   type Search_Result is record
      Position : Insertion_Index;   --  where Target goes
      Probes   : Probe_Count;       --  elements of Data read
   end record;

   function Position (Data : Sorted_Array; Target : Value) return Search_Result
   with
     Global => null,
     Post   =>
       (for all I in Index =>
          (if I < Position'Result.Position then Data (I) < Target
           else Data (I) >= Target));
end Search_Insert_Position;
