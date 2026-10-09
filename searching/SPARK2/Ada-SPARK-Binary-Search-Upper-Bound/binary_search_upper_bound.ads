--  PLACEHOLDER: unrolled linear scan of six fixed positions; no halving; see tools/vv/hidden_stub.csv
pragma Ada_2022;

--  Binary search upper bound: in a sorted array, the first position whose
--  value is > Target (Length + 1 if there is none), found by halving
--  the candidate range.
package Binary_Search_Upper_Bound with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Result_Index is Positive range 1 .. Length + 1;
   subtype Value is Integer range -100 .. 100;
   subtype Target_Value is Integer range -100 .. 100;
   type Value_Array is array (Index) of Value;
   subtype Input_Array is Value_Array
     with Dynamic_Predicate =>
       (for all I in 1 .. Length - 1 => Input_Array (I) <= Input_Array (I + 1));

   --  33 candidate positions: at most floor (log2 33) + 1 = 6 reads.
   subtype Probe_Count is Natural range 0 .. 6;
   type Search_Result is record
      Position : Result_Index;   --  the upper bound
      Probes   : Probe_Count;    --  elements of Input read
   end record;

   function Find (Input : Input_Array; Target : Target_Value) return Search_Result
   with
     Global => null,
     Post   =>
       (for all I in Index =>
          (if I < Find'Result.Position then Input (I) <= Target
           else Input (I) > Target));
end Binary_Search_Upper_Bound;
