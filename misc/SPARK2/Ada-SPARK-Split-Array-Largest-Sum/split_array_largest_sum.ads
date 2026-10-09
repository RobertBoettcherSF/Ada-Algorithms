pragma Ada_2022;

package Split_Array_Largest_Sum with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Element is Positive range 1 .. 100;
   subtype Limit is Positive range 1 .. 800;
   subtype Part_Count is Positive range 1 .. Length;
   type Input_Array is array (Index) of Element;

   subtype Probe_Count is Natural range 0 .. Limit'Last;
   type Sum_Result is record
      Largest : Limit;         --  smallest possible largest part sum
      Probes  : Probe_Count;   --  limits tried (each costs a pass over Input)
   end record;

   function Largest_Sum
     (Input : Input_Array; Parts : Part_Count) return Sum_Result
     with Global => null;
end Split_Array_Largest_Sum;
