pragma SPARK_Mode (On);

package Earliest_Deadline_First_Scheduling is
   Max_Jobs : constant := 4;
   subtype Job_Id is Positive range 1 .. Max_Jobs;
   subtype Deadline is Positive range 1 .. 100;
   type Deadline_Array is array (Job_Id) of Deadline;

   function Select_Earliest (Deadlines : Deadline_Array) return Job_Id;
end Earliest_Deadline_First_Scheduling;
