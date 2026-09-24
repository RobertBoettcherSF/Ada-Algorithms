--  dekker.adb
--
--  Implementation of Dekker's algorithm and the variants discussed in the
--  Wikipedia article:
--  1. Naive_Turn_Taking: Strict alternation (fails if one process halts).
--  2. Starvation_Susceptible: Actions performed without checking turn.
--  3. Full_Dekker: The correct and complete algorithm.

with Ada.Text_IO;
with Ada.Real_Time;

procedure Dekker is
   use Ada.Text_IO;
   use Ada.Real_Time;

   type Algorithm_Variant is 
     (Naive_Turn_Taking, 
      Starvation_Susceptible, 
      Full_Dekker);

   Current_Variant : Algorithm_Variant;

   --  Process IDs for the two processes
   type Process_Id is (P0, P1);

   --  Flags indicating if a process wants to enter the critical section.
   --  pragma Atomic_Components acts as a memory barrier and prevents loop 
   --  invariant code motion optimizations, matching the Wiki notes.
   type Boolean_Array is array (Process_Id) of Boolean;
   pragma Atomic_Components (Boolean_Array);
   
   Wants_To_Enter : Boolean_Array := (False, False);

   --  Turn indicates which process has priority to resolve ties.
   Turn : Process_Id := P0;
   pragma Atomic (Turn);

   --  Shared resource to protect (the Critical Section payload)
   Shared_Counter : Integer := 0;

   --  Task type representing our concurrent threads
   task type Worker (ID : Process_Id);

   task body Worker is
      Other : Process_Id;
   begin
      --  Determine the ID of the opposing process
      if ID = P0 then
         Other := P1;
      else
         Other := P0;
      end if;

      for I in 1 .. 5 loop
         case Current_Variant is
            
            when Naive_Turn_Taking =>
               --  Variant 1: Strict alternation algorithm
               while Turn /= ID loop
                  delay 0.0; -- Yield to prevent CPU hogging
               end loop;
               
               --  === CRITICAL SECTION ===
               Shared_Counter := Shared_Counter + 1;
               Put_Line ("Process " & Process_Id'Image(ID) & " entering CS (Naive).");
               
               --  === REMAINDER SECTION ===
               Turn := Other;

            when Starvation_Susceptible =>
               --  Variant 2: Performs the back-off actions without checking 
               --  if turn = ID, leading to potential starvation.
               Wants_To_Enter (ID) := True;
               while Wants_To_Enter (Other) loop
                  --  Missing the 'if Turn /= ID' check!
                  Wants_To_Enter (ID) := False;
                  while Turn /= ID loop
                     delay 0.0;
                  end loop;
                  Wants_To_Enter (ID) := True;
               end loop;
               
               --  === CRITICAL SECTION ===
               Shared_Counter := Shared_Counter + 1;
               Put_Line ("Process " & Process_Id'Image(ID) & " entering CS (Starvation).");
               
               --  === REMAINDER SECTION ===
               Turn := Other;
               Wants_To_Enter (ID) := False;

            when Full_Dekker =>
               --  Variant 3: The complete and correct Dekker's algorithm
               Wants_To_Enter (ID) := True;
               while Wants_To_Enter (Other) loop
                  if Turn /= ID then
                     Wants_To_Enter (ID) := False;
                     while Turn /= ID loop
                        delay 0.0;
                     end loop;
                     Wants_To_Enter (ID) := True;
                  end if;
               end loop;
               
               --  === CRITICAL SECTION ===
               Shared_Counter := Shared_Counter + 1;
               Put_Line ("Process " & Process_Id'Image(ID) & " entering CS (Full Dekker).");
               
               --  === REMAINDER SECTION ===
               Turn := Other;
               Wants_To_Enter (ID) := False;

         end case;
         
         --  Simulate work outside of the critical section
         delay To_Duration (Milliseconds (50));
      end loop;
   end Worker;

begin
   Put_Line ("=== Dekker's Algorithm Demonstration ===");

   for V in Algorithm_Variant loop
      Put_Line ("");
      Put_Line ("--- Testing Variant: " & Algorithm_Variant'Image (V) & " ---");
      
      --  Initialize shared state for the upcoming run
      Current_Variant := V;
      Shared_Counter := 0;
      Wants_To_Enter := (False, False);
      Turn := P0;
      
      declare
         --  Tasks start automatically once the declarative block completes.
         W0 : Worker (P0);
         W1 : Worker (P1);
      begin
         --  The main thread inherently blocks here until W0 and W1 terminate.
         null;
      end;
      
      Put_Line ("--- Final Counter for " & Algorithm_Variant'Image(V) & 
                ": " & Integer'Image(Shared_Counter) & " (Expected: 10) ---");
   end loop;

   Put_Line ("");
   Put_Line ("=== Demonstration Finished ===");
end Dekker;
