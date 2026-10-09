pragma Ada_2022;

package Find_Peak_Element with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1000 .. 1000;
   type Input_Array is array (Index) of Value;

   subtype Probe_Count is Natural range 0 .. Length;
   type Search_Result is record
      Position : Index;         --  a peak
      Probes   : Probe_Count;   --  comparisons of two elements
   end record;

   function Find_Peak (Input : Input_Array) return Search_Result
     with Global => null;
end Find_Peak_Element;
