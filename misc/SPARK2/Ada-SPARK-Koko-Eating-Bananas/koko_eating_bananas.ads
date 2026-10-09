pragma Ada_2022;

package Koko_Eating_Bananas with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Pile_Size is Positive range 1 .. 100;
   subtype Speed is Positive range 1 .. 100;
   subtype Hour_Count is Positive range Length .. 100;
   type Pile_Array is array (Index) of Pile_Size;

   subtype Probe_Count is Natural range 0 .. Speed'Last;
   type Speed_Result is record
      Minimum : Speed;         --  slowest speed that finishes in time
      Probes  : Probe_Count;   --  speeds tried (each costs a pass over Piles)
   end record;

   function Minimum_Speed
     (Piles : Pile_Array; Hours : Hour_Count) return Speed_Result
     with Global => null;
end Koko_Eating_Bananas;
