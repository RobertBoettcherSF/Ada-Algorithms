with Ada.Containers.Doubly_Linked_Lists;

package MLFQ is

   type Process_ID is new Natural;

   type Process_State is (Ready, Running, Blocked, Finished);

   -- Represents a simulated task/job
   type Process_Record is record
      ID                 : Process_ID;
      State              : Process_State := Ready;
      Priority           : Natural := 1; -- 1 is the highest priority queue
      CPU_Time_Needed    : Natural := 0;
      CPU_Time_Used      : Natural := 0;
      Allotment_Left     : Natural := 0; -- Time quantum remaining at current level
      
      -- I/O simulation fields
      IO_Frequency       : Natural := 0; -- Yields CPU every N ticks (0 = pure CPU bound)
      IO_Duration        : Natural := 0; -- Stays blocked for N ticks
      Current_IO_Wait    : Natural := 0; 
      Ticks_Since_Yield  : Natural := 0;
   end record;

   package Process_Lists is new Ada.Containers.Doubly_Linked_Lists (Process_Record);

   -- Maximum number of queues supported
   Max_Queues : constant Positive := 10;

   -- Array types for queues and quantums
   type Queue_Array is array (1 .. Max_Queues) of Process_Lists.List;
   type Quantum_Array is array (1 .. Max_Queues) of Natural;

   -- The Scheduler record
   type Scheduler is tagged record
      Num_Queues        : Positive := 3; -- Actual number of queues to use
      Queues            : Queue_Array;
      Quantums          : Quantum_Array;
      Blocked_List      : Process_Lists.List;
      Finished_List     : Process_Lists.List;
      Aging_Interval    : Natural := 0;
      Ticks_Since_Aging : Natural := 0;
      Clock             : Natural := 0;
      Is_Idle           : Boolean := True;
      Running_Proc      : Process_Record;
   end record;

   -- Configures the scheduler
   procedure Initialize (S              : in out Scheduler;
                         Quantums       : in Quantum_Array;
                         Aging_Interval : in Natural);

   -- Adds a new job to the top queue (Rule 3)
   procedure Add_Process (S            : in out Scheduler;
                          ID           : Process_ID;
                          CPU_Time     : Natural;
                          IO_Frequency : Natural := 0;
                          IO_Duration  : Natural := 0);

   -- Advances the simulation by 1 time unit
   procedure Tick (S : in out Scheduler);

   -- Checks if all processes are finished
   function All_Finished (S : Scheduler) return Boolean;

   -- Runs the full simulation to completion
   procedure Run_Simulation (S : in out Scheduler);
   
   -- Creates a pre-configured scenario to demonstrate the MLFQ
   procedure Setup_And_Run_Example;

end MLFQ;
