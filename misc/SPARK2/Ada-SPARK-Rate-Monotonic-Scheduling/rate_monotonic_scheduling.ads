pragma SPARK_Mode (On);

package Rate_Monotonic_Scheduling is
   Max_Tasks : constant := 4;
   subtype Task_Id is Positive range 1 .. Max_Tasks;
   subtype Period is Positive range 1 .. 100;
   type Period_Array is array (Task_Id) of Period;

   function Highest_Priority (Periods : Period_Array) return Task_Id;
end Rate_Monotonic_Scheduling;
