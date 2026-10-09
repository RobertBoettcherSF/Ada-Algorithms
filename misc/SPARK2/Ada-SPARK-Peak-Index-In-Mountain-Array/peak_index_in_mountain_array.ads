pragma Ada_2022;

package Peak_Index_In_Mountain_Array with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1000 .. 1000;
   type Mountain_Array is array (Index) of Value;

   subtype Probe_Count is Natural range 0 .. Length;
   type Search_Result is record
      Position : Index;         --  index of the peak
      Probes   : Probe_Count;   --  comparisons of two elements
   end record;

   function Peak_Index (Input : Mountain_Array) return Search_Result
     with Global => null;
end Peak_Index_In_Mountain_Array;
