package EDF_Scheduling is

   type Time_Unit is new Natural;
   type Task_ID is new Positive;

   type Task_Type is (Aperiodic, Periodic);
   type Criticality_Level is (Low, High);
   type Scheduling_Variant is (Standard_Preemptive, Standard_Non_Preemptive, EDF_VD);

   -- Definition of a single task's parameters
   type Task_Config is record
      ID               : Task_ID;
      Type_Of_Task     : Task_Type;
      Criticality      : Criticality_Level;
      Release_Time     : Time_Unit;
      Computation_Time : Time_Unit;
      Deadline         : Time_Unit; -- Relative deadline from release
      Period           : Time_Unit; -- Relevant only if Type_Of_Task = Periodic
   end record;

   Max_Tasks : constant := 32;

   -- Initializes the scheduler and clears the queue
   procedure Initialize (Variant : Scheduling_Variant);

   -- Adds a new task to the system configuration
   procedure Add_Task (Config : Task_Config);

   -- Validates the schedulability bound (Sum of C_i / T_i <= 1)
   -- Valid primarily for standard periodic EDF scenarios.
   function Is_Schedulable return Boolean;

   -- Runs the scheduler simulation for a specified number of time units (Ticks)
   procedure Run_Simulation (Ticks : Time_Unit);

end EDF_Scheduling;
