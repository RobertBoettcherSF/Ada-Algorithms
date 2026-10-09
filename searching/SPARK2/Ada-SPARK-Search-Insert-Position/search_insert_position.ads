pragma Ada_2022;

package Search_Insert_Position with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 100;
   subtype Insertion_Index is Positive range 1 .. Length + 1;
   type Value_Array is array (Index) of Value;
   subtype Sorted_Array is Value_Array
     with Dynamic_Predicate =>
       (for all I in 1 .. Length - 1 => Sorted_Array (I) <= Sorted_Array (I + 1));

   subtype Probe_Count is Natural range 0 .. Length;
   type Search_Result is record
      Position : Insertion_Index;   --  where Target goes
      Probes   : Probe_Count;       --  elements of Data read
   end record;

   function Position (Data : Sorted_Array; Target : Value) return Search_Result
     with Global => null;
end Search_Insert_Position;
