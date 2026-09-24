with Ada.Text_IO; use Ada.Text_IO;

package body MLFQ is

   procedure Initialize (S              : in out Scheduler;
                         Quantums       : in Quantum_Array;
                         Aging_Interval : in Natural) is
   begin
      -- Clear any existing state
      for I in 1 .. S.Num_Queues loop
         S.Queues(I).Clear;
      end loop;
      S.Blocked_List.Clear;
      S.Finished_List.Clear;
      
      -- Load quantums
      for I in 1 .. S.Num_Queues loop
         S.Quantums(I) := Quantums(I);
      end loop;
      
      S.Aging_Interval := Aging_Interval;
      S.Ticks_Since_Aging := 0;
      S.Clock := 0;
      S.Is_Idle := True;
   end Initialize;

   procedure Add_Process (S            : in out Scheduler;
                          ID           : Process_ID;
                          CPU_Time     : Natural;
                          IO_Frequency : Natural := 0;
                          IO_Duration  : Natural := 0) is
      P : Process_Record;
   begin
      P.ID := ID;
      P.State := Ready;
      P.Priority := 1; -- Rule 3: Enter at highest priority (queue 1)
      P.CPU_Time_Needed := CPU_Time;
      P.CPU_Time_Used := 0;
      P.Allotment_Left := S.Quantums(1);
      P.IO_Frequency := IO_Frequency;
      P.IO_Duration := IO_Duration;
      P.Current_IO_Wait := 0;
      P.Ticks_Since_Yield := 0;

      S.Queues(1).Append (P);
   end Add_Process;

   procedure Tick (S : in out Scheduler) is
      use Process_Lists;
      C, Next_C : Cursor;
   begin
      -- 1. Aging / Starvation Prevention (Rule 5)
      S.Ticks_Since_Aging := S.Ticks_Since_Aging + 1;
      if S.Aging_Interval > 0 and then S.Ticks_Since_Aging >= S.Aging_Interval then
         S.Ticks_Since_Aging := 0;
         Put_Line ("--- AGING TRIGGERED: Boosting all processes to Queue 1 ---");

         -- Preempt running process
         if not S.Is_Idle then
            S.Running_Proc.Priority := 1;
            S.Running_Proc.Allotment_Left := S.Quantums(1);
            S.Running_Proc.State := Ready;
            S.Queues(1).Append (S.Running_Proc);
            S.Is_Idle := True;
         end if;

         -- Elevate all lower queue processes to Priority 1
         for Q in 2 .. S.Num_Queues loop
            while not S.Queues(Q).Is_Empty loop
               declare
                  P : Process_Record := S.Queues(Q).First_Element;
               begin
                  S.Queues(Q).Delete_First;
                  P.Priority := 1;
                  P.Allotment_Left := S.Quantums(1);
                  S.Queues(1).Append (P);
               end;
            end loop;
         end loop;

         -- Update priority of blocked processes (they stay blocked, but priority is boosted)
         C := S.Blocked_List.First;
         while Has_Element (C) loop
            declare
               P : Process_Record := Element (C);
            begin
               P.Priority := 1;
               P.Allotment_Left := S.Quantums(1);
               S.Blocked_List.Replace_Element (C, P);
            end;
            C := Next (C);
         end loop;
      end if;

      -- 2. I/O Completion (Process moves back to Ready Queue)
      C := S.Blocked_List.First;
      while Has_Element (C) loop
         Next_C := Next (C);
         declare
            P : Process_Record := Element (C);
         begin
            P.Current_IO_Wait := P.Current_IO_Wait - 1;
            if P.Current_IO_Wait = 0 then
               P.State := Ready;
               S.Queues(P.Priority).Append (P);
               S.Blocked_List.Delete (C);
               Put_Line ("  -> Process" & Process_ID'Image(P.ID) & " woke up from I/O.");
            else
               S.Blocked_List.Replace_Element (C, P);
            end if;
         end;
         C := Next_C;
      end loop;

      -- 3. Strict Priority Preemption (Rule 1)
      -- If a higher priority queue got a job, preempt the current running job
      if not S.Is_Idle then
         declare
            Highest_Ready : Integer := -1;
         begin
            for Q in 1 .. S.Num_Queues loop
               if not S.Queues(Q).Is_Empty then
                  Highest_Ready := Q;
                  exit;
               end if;
            end loop;

            if Highest_Ready /= -1 and then Highest_Ready < S.Running_Proc.Priority then
               S.Running_Proc.State := Ready;
               -- Preempt and push back to front of its own queue
               S.Queues(S.Running_Proc.Priority).Prepend (S.Running_Proc);
               S.Is_Idle := True;
            end if;
         end;
      end if;

      -- 4. Select New Process if CPU is idle
      if S.Is_Idle then
         for Q in 1 .. S.Num_Queues loop
            if not S.Queues(Q).Is_Empty then
               S.Running_Proc := S.Queues(Q).First_Element;
               S.Queues(Q).Delete_First;
               S.Running_Proc.State := Running;
               S.Is_Idle := False;
               exit;
            end if;
         end loop;
      end if;

      -- 5. Execute Running Process
      if not S.Is_Idle then
         S.Running_Proc.CPU_Time_Used := S.Running_Proc.CPU_Time_Used + 1;
         if S.Running_Proc.Allotment_Left > 0 then
            S.Running_Proc.Allotment_Left := S.Running_Proc.Allotment_Left - 1;
         end if;
         S.Running_Proc.Ticks_Since_Yield := S.Running_Proc.Ticks_Since_Yield + 1;

         Put_Line ("Tick:" & Natural'Image(S.Clock) & 
                   " | Proc:" & Process_ID'Image(S.Running_Proc.ID) &
                   " | Q:" & Natural'Image(S.Running_Proc.Priority) &
                   " | CPU Need:" & Natural'Image(S.Running_Proc.CPU_Time_Needed - S.Running_Proc.CPU_Time_Used) &
                   " | Allotment:" & Natural'Image(S.Running_Proc.Allotment_Left));

         -- A) Job is fully completed
         if S.Running_Proc.CPU_Time_Used >= S.Running_Proc.CPU_Time_Needed then
            S.Running_Proc.State := Finished;
            S.Finished_List.Append (S.Running_Proc);
            S.Is_Idle := True;
            Put_Line ("  -> Process" & Process_ID'Image(S.Running_Proc.ID) & " FINISHED.");

         -- B) Job yields for I/O voluntarily
         elsif S.Running_Proc.IO_Frequency > 0 and then S.Running_Proc.Ticks_Since_Yield >= S.Running_Proc.IO_Frequency then
            S.Running_Proc.State := Blocked;
            S.Running_Proc.Current_IO_Wait := S.Running_Proc.IO_Duration;
            S.Running_Proc.Ticks_Since_Yield := 0;
            S.Blocked_List.Append (S.Running_Proc);
            S.Is_Idle := True;
            Put_Line ("  -> Process" & Process_ID'Image(S.Running_Proc.ID) & " YIELDED for I/O.");

         -- C) Time Allotment exhausted (Rule 4)
         elsif S.Running_Proc.Allotment_Left = 0 then
            if S.Running_Proc.Priority < S.Num_Queues then
               S.Running_Proc.Priority := S.Running_Proc.Priority + 1;
            end if;
            S.Running_Proc.Allotment_Left := S.Quantums(S.Running_Proc.Priority);
            S.Running_Proc.State := Ready;
            S.Queues(S.Running_Proc.Priority).Append (S.Running_Proc);
            S.Is_Idle := True;
            Put_Line ("  -> Process" & Process_ID'Image(S.Running_Proc.ID) & " DEMOTED to Q" & Natural'Image(S.Running_Proc.Priority));
         end if;
      else
         Put_Line ("Tick:" & Natural'Image(S.Clock) & " | CPU IDLE");
      end if;

      S.Clock := S.Clock + 1;
   end Tick;

   function All_Finished (S : Scheduler) return Boolean is
   begin
      if not S.Is_Idle then return False; end if;
      if not S.Blocked_List.Is_Empty then return False; end if;
      for Q in 1 .. S.Num_Queues loop
         if not S.Queues(Q).Is_Empty then return False; end if;
      end loop;
      return True;
   end All_Finished;

   procedure Run_Simulation (S : in out Scheduler) is
   begin
      Put_Line ("--- Starting MLFQ Simulation ---");
      while not All_Finished (S) loop
         Tick (S);
      end loop;
      Put_Line ("--- Simulation Complete in" & Natural'Image(S.Clock) & " Ticks ---");
   end Run_Simulation;

   procedure Setup_And_Run_Example is
      S     : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 2, 2 => 4, 3 => 8, others => 1);
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 25);
      
      -- Job 1: Long running CPU bound task
      Add_Process (S, ID => 1, CPU_Time => 20, IO_Frequency => 0, IO_Duration => 0); 
      
      -- Job 2: Interactive I/O bound task (Yields often, never demotes)
      Add_Process (S, ID => 2, CPU_Time => 5,  IO_Frequency => 1, IO_Duration => 3); 
      
      -- Job 3: Medium length, yields occasionally
      Add_Process (S, ID => 3, CPU_Time => 12, IO_Frequency => 4, IO_Duration => 2); 
      
      Run_Simulation (S);
   end Setup_And_Run_Example;

end MLFQ;
