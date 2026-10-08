with Ada.Text_IO;

procedure Bakery is
   
   N : constant := 5;
   type Thread_Id is range 1 .. N;

   -- =========================================================================
   -- SHARED MEMORY ARRAYS
   -- =========================================================================
   
   -- "Entering" array: True if the thread is currently taking a ticket.
   -- Variant handling: `pragma Atomic_Components` enforces memory barriers 
   -- so modern weak-memory CPUs don't re-order the doorway steps.
   Entering : array (Thread_Id) of Boolean := (others => False);
   pragma Atomic_Components (Entering);

   -- "Number" array: Holds the ticket number for each thread.
   -- Note on Overflow Variant: In theory, ticket numbers can grow infinitely 
   -- and overflow. In Ada, 'Natural' goes up to 2^31-1 or 2^63-1, which takes 
   -- decades to overflow, but Lamport proposed bounding variants if needed.
   Number : array (Thread_Id) of Natural := (others => 0);
   pragma Atomic_Components (Number);

   -- A shared resource to demonstrate mutual exclusion
   Shared_Counter : Natural := 0;


   -- =========================================================================
   -- BAKERY ALGORITHM IMPLEMENTATION
   -- =========================================================================

   procedure Lock (Id : Thread_Id) is
      Max_Num : Natural := 0;
   begin
      -- Step 1: Doorway phase
      Entering (Id) := True;

      -- Find the maximum ticket number currently handed out
      for J in Thread_Id loop
         if Number (J) > Max_Num then
            Max_Num := Number (J);
         end if;
      end loop;

      Number (Id) := Max_Num + 1;
      Entering (Id) := False;

      -- Step 2: Waiting phase
      for J in Thread_Id loop
         if J /= Id then
            -- Wait until thread J finishes receiving its ticket
            while Entering (J) loop
               delay 0.0001; -- Yield to prevent 100% CPU busy-wait burn
            end loop;

            -- Wait until all threads with smaller numbers (or same number 
            -- but higher priority/smaller ID) finish their critical sections.
            while Number (J) /= 0 and then
                  (Number (J) < Number (Id) or else
                  (Number (J) = Number (Id) and then J < Id)) loop
               delay 0.0001;
            end loop;
         end if;
      end loop;
   end Lock;

   procedure Unlock (Id : Thread_Id) is
   begin
      -- Leave the critical section by resetting the ticket to 0
      Number (Id) := 0;
   end Unlock;


   -- =========================================================================
   -- THREAD WORKERS
   -- =========================================================================

   task type Worker_Task (Id : Thread_Id);

   task body Worker_Task is
   begin
      -- Each thread will try to enter the critical section 5 times
      for Iteration in 1 .. 5 loop
         Ada.Text_IO.Put_Line ("Thread" & Thread_Id'Image (Id) & " requesting lock...");
         Lock (Id);

         -- ---------------------------------------------------------
         -- START CRITICAL SECTION
         -- ---------------------------------------------------------
         Ada.Text_IO.Put_Line ("  -> Thread" & Thread_Id'Image (Id) & " ENTERED Critical Section.");
         
         -- Safely increment the shared counter
         Shared_Counter := Shared_Counter + 1;
         
         -- Simulate some processing time inside the critical section
         delay 0.05; 
         
         Ada.Text_IO.Put_Line ("  <- Thread" & Thread_Id'Image (Id) & " EXITING Critical Section. Counter: " & Natural'Image(Shared_Counter));
         -- ---------------------------------------------------------
         -- END CRITICAL SECTION
         -- ---------------------------------------------------------
         
         Unlock (Id);

         -- Simulate time spent in non-critical section
         delay 0.1;
      end loop;
   end Worker_Task;

   -- Spawn the workers. They will start running immediately.
   W1 : Worker_Task (1);
   W2 : Worker_Task (2);
   W3 : Worker_Task (3);
   W4 : Worker_Task (4);
   W5 : Worker_Task (5);

begin
   -- The main environment task will implicitly pause here and wait for
   -- all dependent worker tasks to terminate before exiting the program.
   null;
end Bakery;
