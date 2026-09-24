with Ada.Numerics.Float_Random;

package Fair_Share_Scheduler is

   -- Variants mentioned in the literature for implementing Fair-Share Scheduling
   type Algorithm_Type is
     (Traditional_Unix_FSS,          -- Adjusts priorities based on CPU usage decay
      Completely_Fair_Scheduler_CFS, -- Proportional share via Virtual Runtime
      Lottery_Scheduling);           -- Probabilistic ticket-based distribution

   type Process_ID is new Natural;
   Null_Process : constant Process_ID := 0;

   type User_ID is new Natural;
   Null_User : constant User_ID := 0;

   Max_Processes : constant := 1024;
   Max_Users     : constant := 256;

   -- Record tracking state of an individual process
   type Process_Record is record
      ID               : Process_ID := Null_Process;
      Owner            : User_ID := Null_User;
      Is_Active        : Boolean := False;
      
      Base_Priority    : Float := 0.0;
      Dynamic_Priority : Float := 0.0;   -- Used by Traditional FSS
      CPU_Usage        : Float := 0.0;   -- Used by Traditional FSS
      Virtual_Runtime  : Float := 0.0;   -- Used by CFS
      Tickets          : Natural := 0;   -- Used if explicit lottery tickets are assigned
   end record;

   -- Record tracking fair-share groupings (e.g. users or control groups)
   type User_Record is record
      ID               : User_ID := Null_User;
      Is_Active        : Boolean := False;
      Shares           : Float := 1.0;   -- Proportional weight/target for fair sharing
      CPU_Usage        : Float := 0.0;   -- Cumulative usage of all user's processes
   end record;

   type Process_Array is array (1 .. Max_Processes) of Process_Record;
   type User_Array is array (1 .. Max_Users) of User_Record;

   -- The Scheduler engine configured with a specific algorithmic variant
   type Scheduler (Algorithm : Algorithm_Type) is tagged limited record
      Processes       : Process_Array;
      Users           : User_Array;
      Current_Process : Process_ID := Null_Process;
      RNG             : Ada.Numerics.Float_Random.Generator;
   end record;

   -- Bootstraps the scheduler and PRNG
   procedure Initialize (Self : in out Scheduler);

   -- Registers a user with their allocated CPU shares
   procedure Add_User (Self   : in out Scheduler;
                       ID     : User_ID;
                       Shares : Float);

   -- Registers a process belonging to a specific user
   procedure Add_Process (Self          : in out Scheduler;
                          ID            : Process_ID;
                          Owner         : User_ID;
                          Base_Priority : Float := 10.0;
                          Tickets       : Natural := 0);

   -- Kills or suspends a process
   procedure Remove_Process (Self : in out Scheduler; ID : Process_ID);

   -- The core logic: Uses the selected algorithm to find the next active process
   function Select_Next_Process (Self : in out Scheduler) return Process_ID;

   -- Simulates the selected process consuming CPU time for `Time_Slice`
   procedure Tick (Self : in out Scheduler; Time_Slice : Float);

   -- Required for Traditional FSS: Called periodically (e.g., 1x per second) to decay usage memory
   procedure Decay_Usage (Self : in out Scheduler);

private

   -- Internal helpers
   function Get_User_Index (Self : Scheduler; ID : User_ID) return Integer;
   function Count_User_Processes (Self : Scheduler; ID : User_ID) return Float;

end Fair_Share_Scheduler;
