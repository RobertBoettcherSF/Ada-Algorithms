pragma SPARK_Mode (On);

package Shortest_Remaining_Time is
   Max_Jobs : constant := 4;
   subtype Job_Id is Positive range 1 .. Max_Jobs;
   subtype Remaining_Time is Natural range 0 .. 100;
   type Remaining_Array is array (Job_Id) of Remaining_Time;

   function Select_Shortest (Remaining : Remaining_Array) return Job_Id;

   procedure Run_One_Tick (Remaining : in out Remaining_Time)
     with Post => (if Remaining'Old > 0
                   then Remaining = Remaining'Old - 1
                   else Remaining = 0);
end Shortest_Remaining_Time;
