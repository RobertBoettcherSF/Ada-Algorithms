pragma Ada_2022;

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

   subtype Probe_Count is Natural range 0 .. Length;
   type Search_Result is record
      Position : Result_Index;   --  the upper bound
      Probes   : Probe_Count;    --  elements of Input read
   end record;

   function Find (Input : Input_Array; Target : Target_Value) return Search_Result
     with Global => null;
end Binary_Search_Upper_Bound;
