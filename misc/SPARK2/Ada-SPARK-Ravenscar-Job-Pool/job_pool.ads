pragma Ada_2022;

--  Fixed carrier worker pool + protected job queue.
--  Spawn is goroutine-shaped enqueue (NOT dynamic Ada task creation).
--  Pattern is Ravenscar-compatible: fixed task set, protected objects, no select.
package Job_Pool
  with SPARK_Mode => On
is
   Max_Jobs     : constant := 16;
   Worker_Count : constant := 4;

   type Job_Id is range 0 .. Max_Jobs;
   --  0 = No_Job (sentinel / invalid)
   subtype Valid_Job_Id is Job_Id range 1 .. Job_Id'Last;

   --  Closed set of work kinds (enum + data slots over access-to-subprogram
   --  so clients stay SPARK-friendly). Handlers live in Demo_Jobs.
   type Job_Kind is (Nop, Increment_Counter, Ping_Channel);

   type Job_Request is record
      Kind : Job_Kind := Nop;
      Arg  : Integer  := 0;
   end record;

   function Free_Slots return Natural
     with Global => null,
          Post   => Free_Slots'Result <= Max_Jobs;

   --  Enqueue work onto the ready queue. Returns a Job_Id for Await.
   procedure Spawn (Request : Job_Request; Id : out Valid_Job_Id)
     with Global => null,
          Pre    => Request.Kind /= Nop and then Free_Slots > 0;

   --  Block until the job has finished (protected Future barrier).
   procedure Await (Id : Valid_Job_Id)
     with Global => null;

   --  Wait until every currently outstanding job is done.
   procedure Sync
     with Global => null;

   --  Ask workers to exit cleanly (for tests).
   procedure Shutdown
     with Global => null;

   function Is_Shutdown return Boolean
     with Global => null;

end Job_Pool;
