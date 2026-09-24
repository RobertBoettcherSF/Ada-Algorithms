package Task_Scheduling
  with Preelaborate
is
   type Task_Id is new Positive;
   type Time_Unit is new Natural;

   type Task_Record is record
      Id       : Task_Id;
      Arrival  : Time_Unit;
      Burst    : Time_Unit;
      Deadline : Time_Unit;
   end record;

   type Task_Array is array (Positive range <>) of Task_Record;

   type Schedule_Event is record
      Id         : Task_Id;
      Start_Time : Time_Unit;
      End_Time   : Time_Unit;
   end record;

   type Schedule_Array is array (Positive range <>) of Schedule_Event;

   Empty_Task_List : exception;
   Invalid_Tasks   : exception;

   -- Validates if task array has valid attributes (Burst > 0)
   function Is_Valid (Tasks : Task_Array) return Boolean
     with Global => null;

   -- FCFS (Non-preemptive, First-Come-First-Served)
   function Schedule_FCFS (Tasks : Task_Array) return Schedule_Array
     with Global => null;

   -- SJN (Non-preemptive, Shortest-Job-Next)
   function Schedule_SJN (Tasks : Task_Array) return Schedule_Array
     with Global => null;

   -- SRTF (Preemptive, Shortest-Remaining-Time-First)
   function Schedule_SRTF (Tasks : Task_Array) return Schedule_Array
     with Global => null;

   -- EDF (Preemptive, Earliest-Deadline-First)
   function Schedule_EDF (Tasks : Task_Array) return Schedule_Array
     with Global => null;

end Task_Scheduling;
