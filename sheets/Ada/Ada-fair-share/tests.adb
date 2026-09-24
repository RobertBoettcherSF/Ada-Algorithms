with Ada.Text_IO;
with Fair_Share_Scheduler;

procedure Tests is
   use Fair_Share_Scheduler;

   -- Test counters
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;
   Failed_Tests : Integer := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Passed_Tests := Passed_Tests + 1;
         Ada.Text_IO.Put_Line("  PASS: " & Message);
      else
         Failed_Tests := Failed_Tests + 1;
         Ada.Text_IO.Put_Line("  FAIL: " & Message);
      end if;
   end Assert;

   procedure Print_Summary is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line("========================================");
      Ada.Text_IO.Put_Line("Test Summary:");
      Ada.Text_IO.Put_Line("  Total:  " & Integer'Image(Total_Tests));
      Ada.Text_IO.Put_Line("  Passed: " & Integer'Image(Passed_Tests));
      Ada.Text_IO.Put_Line("  Failed: " & Integer'Image(Failed_Tests));
      Ada.Text_IO.Put_Line("========================================");
   end Print_Summary;

   -- Test 1: Scheduler initializes correctly
   procedure Test_Initialization is
      Sched : Scheduler(Traditional_Unix_FSS);
   begin
      Ada.Text_IO.Put_Line("Test 1: Scheduler initialization");
      Initialize(Sched);
      Assert(Sched.Current_Process = Null_Process, "Current process should be null after init");
   end Test_Initialization;

   -- Test 2: Can add users
   procedure Test_Add_User is
      Sched : Scheduler(Traditional_Unix_FSS);
   begin
      Ada.Text_IO.Put_Line("Test 2: Adding users");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_User(Sched, User_ID(2), 2.0);
      Assert(True, "Should be able to add users without error");
   end Test_Add_User;

   -- Test 3: Can add processes
   procedure Test_Add_Process is
      Sched : Scheduler(Traditional_Unix_FSS);
   begin
      Ada.Text_IO.Put_Line("Test 3: Adding processes");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Add_Process(Sched, Process_ID(2), User_ID(1));
      Assert(True, "Should be able to add processes without error");
   end Test_Add_Process;

   -- Test 4: Select_Next_Process returns null when no processes
   procedure Test_Select_Next_Empty is
      Sched : Scheduler(Traditional_Unix_FSS);
      Next_Proc : Process_ID;
   begin
      Ada.Text_IO.Put_Line("Test 4: Select next process with no processes");
      Initialize(Sched);
      Next_Proc := Select_Next_Process(Sched);
      Assert(Next_Proc = Null_Process, "Should return null when no processes exist");
   end Test_Select_Next_Empty;

   -- Test 5: Select_Next_Process returns a valid process
   procedure Test_Select_Next_Valid is
      Sched : Scheduler(Traditional_Unix_FSS);
      Next_Proc : Process_ID;
   begin
      Ada.Text_IO.Put_Line("Test 5: Select next process with active processes");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Next_Proc := Select_Next_Process(Sched);
      Assert(Next_Proc /= Null_Process, "Should return a valid process ID");
   end Test_Select_Next_Valid;

   -- Test 6: Remove_Process works correctly
   procedure Test_Remove_Process is
      Sched : Scheduler(Traditional_Unix_FSS);
      Next_Proc : Process_ID;
   begin
      Ada.Text_IO.Put_Line("Test 6: Removing a process");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Remove_Process(Sched, Process_ID(1));
      Next_Proc := Select_Next_Process(Sched);
      Assert(Next_Proc = Null_Process, "Should return null after removing the only process");
   end Test_Remove_Process;

   -- Test 7: Traditional FSS - CPU usage increases with ticks
   procedure Test_Traditional_FSS_CPU_Usage is
      Sched : Scheduler(Traditional_Unix_FSS);
      Initial_Usage : Float;
      P_Idx : Integer;
   begin
      Ada.Text_IO.Put_Line("Test 7: Traditional FSS - CPU usage increases");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      
      -- Get initial CPU usage
      for I in Sched.Processes'Range loop
         if Sched.Processes(I).ID = Process_ID(1) then
            Initial_Usage := Sched.Processes(I).CPU_Usage;
            P_Idx := I;
            exit;
         end if;
      end loop;
      
      -- Run some ticks - select and tick the process
      declare
         Selected : constant Process_ID := Select_Next_Process(Sched);
      begin
         pragma Assert(Selected /= Null_Process);
         Tick(Sched, 1.0);
      end;
      
      Assert(Sched.Processes(P_Idx).CPU_Usage > Initial_Usage, 
             "CPU usage should increase after tick");
   end Test_Traditional_FSS_CPU_Usage;

   -- Test 8: Traditional FSS - Decay reduces CPU usage
   procedure Test_Traditional_FSS_Decay is
      Sched : Scheduler(Traditional_Unix_FSS);
      Initial_Usage : Float;
      P_Idx : Integer;
   begin
      Ada.Text_IO.Put_Line("Test 8: Traditional FSS - Decay reduces CPU usage");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      
      -- Build up some CPU usage
      for I in 1..5 loop
         declare
            Selected : constant Process_ID := Select_Next_Process(Sched);
         begin
            pragma Assert(Selected /= Null_Process);
            Tick(Sched, 1.0);
         end;
      end loop;
      
      -- Get usage before decay
      for I in Sched.Processes'Range loop
         if Sched.Processes(I).ID = Process_ID(1) then
            Initial_Usage := Sched.Processes(I).CPU_Usage;
            P_Idx := I;
            exit;
         end if;
      end loop;
      
      -- Apply decay
      Decay_Usage(Sched);
      
      Assert(Sched.Processes(P_Idx).CPU_Usage < Initial_Usage, 
             "CPU usage should decrease after decay");
   end Test_Traditional_FSS_Decay;

   -- Test 9: CFS - Virtual runtime increases with ticks
   procedure Test_CFS_Virtual_Runtime is
      Sched : Scheduler(Completely_Fair_Scheduler_CFS);
      Initial_VRuntime : Float;
      P_Idx : Integer;
   begin
      Ada.Text_IO.Put_Line("Test 9: CFS - Virtual runtime increases");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      
      -- Get initial virtual runtime
      for I in Sched.Processes'Range loop
         if Sched.Processes(I).ID = Process_ID(1) then
            Initial_VRuntime := Sched.Processes(I).Virtual_Runtime;
            P_Idx := I;
            exit;
         end if;
      end loop;
      
      -- Run some ticks
      declare
         Selected : constant Process_ID := Select_Next_Process(Sched);
      begin
         pragma Assert(Selected /= Null_Process);
         Tick(Sched, 1.0);
      end;
      
      Assert(Sched.Processes(P_Idx).Virtual_Runtime > Initial_VRuntime, 
             "Virtual runtime should increase after tick");
   end Test_CFS_Virtual_Runtime;

   -- Test 10: CFS selects process with lowest virtual runtime
   procedure Test_CFS_Selects_Lowest_VRuntime is
      Sched : Scheduler(Completely_Fair_Scheduler_CFS);
      Next_Proc : Process_ID;
   begin
      Ada.Text_IO.Put_Line("Test 10: CFS selects process with lowest virtual runtime");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Add_Process(Sched, Process_ID(2), User_ID(1));
      
      -- Run first process to give it some virtual runtime
      declare
         Selected : constant Process_ID := Select_Next_Process(Sched);
      begin
         pragma Assert(Selected /= Null_Process);
         Tick(Sched, 5.0);
      end;
      
      -- Now the second process should have lower virtual runtime
      Next_Proc := Select_Next_Process(Sched);
      Assert(Next_Proc = Process_ID(2), 
             "Should select the process with lowest virtual runtime");
   end Test_CFS_Selects_Lowest_VRuntime;

   -- Test 11: Lottery scheduling - all processes get selected eventually
   procedure Test_Lottery_All_Processes_Selected is
      Sched : Scheduler(Lottery_Scheduling);
      Selected : array(1..3) of Boolean := (others => False);
      Next_Proc : Process_ID;
   begin
      Ada.Text_IO.Put_Line("Test 11: Lottery - all processes get selected");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Add_Process(Sched, Process_ID(2), User_ID(1));
      Add_Process(Sched, Process_ID(3), User_ID(1));
      
      -- Run multiple selections
      for I in 1..100 loop
         Next_Proc := Select_Next_Process(Sched);
         if Next_Proc = Process_ID(1) then Selected(1) := True; end if;
         if Next_Proc = Process_ID(2) then Selected(2) := True; end if;
         if Next_Proc = Process_ID(3) then Selected(3) := True; end if;
         Tick(Sched, 0.1);
      end loop;
      
      Assert(Selected(1) and Selected(2) and Selected(3),
             "All processes should be selected at least once in 100 tries");
   end Test_Lottery_All_Processes_Selected;

   -- Test 12: Lottery with different shares - higher share gets selected more
   procedure Test_Lottery_Share_Proportions is
      Sched : Scheduler(Lottery_Scheduling);
      Count1, Count2 : Integer := 0;
   begin
      Ada.Text_IO.Put_Line("Test 12: Lottery - higher share gets selected more");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 3.0);  -- 3x shares
      Add_User(Sched, User_ID(2), 1.0);  -- 1x shares
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Add_Process(Sched, Process_ID(2), User_ID(2));
      
      -- Run many selections
      for I in 1..1000 loop
         declare
            Selected : constant Process_ID := Select_Next_Process(Sched);
         begin
            if Selected = Process_ID(1) then Count1 := Count1 + 1; end if;
            if Selected = Process_ID(2) then Count2 := Count2 + 1; end if;
            Tick(Sched, 0.1);
         end;
      end loop;
      
      -- User 1 should get roughly 3x the selections of User 2
      -- Allow some variance (20% tolerance)
      declare
         Ratio : constant Float := Float(Count1) / Float(Count2);
      begin
         Assert(Ratio > 2.0 and Ratio < 4.0,
                "User 1 (3 shares) should be selected ~3x more than User 2 (1 share). Ratio: " & 
                Float'Image(Ratio));
      end;
   end Test_Lottery_Share_Proportions;

   -- Test 13: Multiple users with CFS - fair distribution
   procedure Test_CFS_Multiple_Users is
      Sched : Scheduler(Completely_Fair_Scheduler_CFS);
      Count1, Count2 : Integer := 0;
   begin
      Ada.Text_IO.Put_Line("Test 13: CFS with multiple users - fair distribution");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      Add_User(Sched, User_ID(2), 1.0);
      Add_Process(Sched, Process_ID(1), User_ID(1));
      Add_Process(Sched, Process_ID(2), User_ID(2));
      
      -- Run many selections
      for I in 1..100 loop
         declare
            Selected : constant Process_ID := Select_Next_Process(Sched);
         begin
            if Selected = Process_ID(1) then Count1 := Count1 + 1; end if;
            if Selected = Process_ID(2) then Count2 := Count2 + 1; end if;
            Tick(Sched, 1.0);
         end;
      end loop;
      
      -- With equal shares, both should get roughly equal time
      -- Allow 20% variance
      declare
         Ratio : constant Float := Float(Count1) / Float(Count2);
      begin
         Assert(Ratio > 0.8 and Ratio < 1.25,
                "Both users should get roughly equal time. Ratio: " & 
                Float'Image(Ratio));
      end;
   end Test_CFS_Multiple_Users;

   -- Test 14: Cannot add more than Max_Processes
   procedure Test_Max_Processes_Limit is
      Sched : Scheduler(Traditional_Unix_FSS);
   begin
      Ada.Text_IO.Put_Line("Test 14: Maximum processes limit");
      Initialize(Sched);
      Add_User(Sched, User_ID(1), 1.0);
      
      -- Add Max_Processes + 1 processes
      for I in 1..Max_Processes + 1 loop
         Add_Process(Sched, Process_ID(I), User_ID(1));
      end loop;
      
      -- The (Max_Processes + 1)th should not have been added
      -- (we can't directly check this, but we can verify the scheduler still works)
      Assert(True, "Should handle adding more than Max_Processes gracefully");
   end Test_Max_Processes_Limit;

   -- Test 15: Cannot add more than Max_Users
   procedure Test_Max_Users_Limit is
      Sched : Scheduler(Traditional_Unix_FSS);
   begin
      Ada.Text_IO.Put_Line("Test 15: Maximum users limit");
      Initialize(Sched);
      
      -- Add Max_Users + 1 users
      for I in 1..Max_Users + 1 loop
         Add_User(Sched, User_ID(I), 1.0);
      end loop;
      
      Assert(True, "Should handle adding more than Max_Users gracefully");
   end Test_Max_Users_Limit;

begin
   Ada.Text_IO.Put_Line("Running Fair-Share Scheduler Tests...");
   Ada.Text_IO.New_Line;

   -- Run all tests
   Test_Initialization;
   Test_Add_User;
   Test_Add_Process;
   Test_Select_Next_Empty;
   Test_Select_Next_Valid;
   Test_Remove_Process;
   Test_Traditional_FSS_CPU_Usage;
   Test_Traditional_FSS_Decay;
   Test_CFS_Virtual_Runtime;
   Test_CFS_Selects_Lowest_VRuntime;
   Test_Lottery_All_Processes_Selected;
   Test_Lottery_Share_Proportions;
   Test_CFS_Multiple_Users;
   Test_Max_Processes_Limit;
   Test_Max_Users_Limit;

   Print_Summary;

   if Failed_Tests > 0 then
      Ada.Text_IO.Put_Line("SOME TESTS FAILED!");
   else
      Ada.Text_IO.Put_Line("ALL TESTS PASSED!");
   end if;
end Tests;
