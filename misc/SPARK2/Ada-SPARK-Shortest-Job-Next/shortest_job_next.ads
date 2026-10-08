pragma SPARK_Mode (On);

package Shortest_Job_Next is
   Max_Jobs : constant := 4;
   subtype Job_Id is Positive range 1 .. Max_Jobs;
   subtype Burst_Time is Positive range 1 .. 100;
   type Burst_Array is array (Job_Id) of Burst_Time;

   function Select_Shortest (Bursts : Burst_Array) return Job_Id;
end Shortest_Job_Next;
