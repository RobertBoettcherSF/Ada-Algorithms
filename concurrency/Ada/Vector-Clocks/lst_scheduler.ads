-- lst_scheduler.ads
-- Specification for the Least Slack Time (LST) Scheduler

package LST_Scheduler is

   type Job_Category is (Periodic, Sporadic);
   
   -- LST variants discussed: Strict LST (Preemptive) vs Uninterruptible
   type Scheduling_Mode is (Preemptive, Non_Preemptive);

   type Task_ID is new Natural;

   type Task_Record is record
      ID             : Task_ID;
      Category       : Job_Category;
      Arrival_Time   : Natural;
      Burst_Time     : Natural;
      Remaining_Time : Natural;
      Deadline       : Natural;  -- Absolute deadline
      Is_Completed   : Boolean := False;
   end record;

   type Task_Array is array (Positive range <>) of Task_Record;

   type Scheduler (Max_Tasks : Positive) is tagged private;

   -- Initializes the scheduler
   procedure Init (Self : in out Scheduler);

   -- Acceptance test for sporadic jobs with a hard deadline
   -- Checks if the amount of slack time between release time and deadline is valid
   function Acceptance_Test (Arrival, Burst, Deadline : Natural) return Boolean;

   -- Add a new task to the scheduler
   procedure Add_Task (Self     : in out Scheduler;
                       ID       : Task_ID;
                       Category : Job_Category;
                       Arrival  : Natural;
                       Burst    : Natural;
                       Deadline : Natural);

   -- Run the scheduler simulation using LST algorithm
   procedure Run_Simulation (Self       : in out Scheduler;
                             Mode       : Scheduling_Mode;
                             Total_Time : Natural);

   -- Built-in demonstration to show the algorithm and variants working
   procedure Demo;

private
   type Scheduler (Max_Tasks : Positive) is tagged record
      Tasks : Task_Array (1 .. Max_Tasks);
      Count : Natural := 0;
   end record;

end LST_Scheduler;
