with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Discrete_Event_Simulation; use Discrete_Event_Simulation;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- State verification tracking for tests
   type Trace_Value_Type is new Integer;
   Trace : array (1 .. 100) of Trace_Value_Type := [others => 0];
   Trace_Idx : Natural := 0;

   procedure Reset_Trace is
   begin
      Trace_Idx := 0;
      Trace := [others => 0];
   end Reset_Trace;

   procedure Log_Trace (V : Trace_Value_Type) is
   begin
      Trace_Idx := Trace_Idx + 1;
      Trace (Trace_Idx) := V;
   end Log_Trace;

   -- Custom Dummy Event
   type Dummy_Event is new Event with record
      Val : Trace_Value_Type;
   end record;

   overriding procedure Execute (This : in out Dummy_Event; Sim : in out Simulator'Class) is
   begin
      Log_Trace (This.Val);
   end Execute;

   type Dummy_Access is access all Dummy_Event;
   function To_Event_Access is new Ada.Unchecked_Conversion (Dummy_Access, Event_Access);

   -- Custom Event that schedules another event
   type Spawner_Event is new Event with record
      Child_Time : Sim_Time;
      Child_Val  : Trace_Value_Type;
   end record;

   type Spawner_Access is access all Spawner_Event;
   function To_Event_Access is new Ada.Unchecked_Conversion (Spawner_Access, Event_Access);

   overriding procedure Execute (This : in out Spawner_Event; Sim : in out Simulator'Class) is
      Child : constant Dummy_Access := new Dummy_Event'(Time      => This.Child_Time, 
                                                        Id        => 0, 
                                                        Cancelled => False, 
                                                        Val       => This.Child_Val);
      Discard_Id : Event_Id_Type;
   begin
      Log_Trace (999);
      Sim.Schedule (To_Event_Access (Child), Discard_Id);
   end Execute;

   Sim : Simulator (Max_Capacity => 10);
   Dummy_Id : Event_Id_Type;

begin
   Put_Line ("TEST 1 — Simulator Initialization");
   Check ("1.1 Clock is 0.0", Sim.Current_Time = 0.0);
   Check ("1.2 Pending_Events is 0", Sim.Pending_Events = 0);
   Check ("1.3 Is_Empty is True", Sim.Is_Empty);

   Put_Line ("TEST 2 — Basic Scheduling and Step (Next-Event)");
   Reset_Trace;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 10.0, Id => 0, Cancelled => False, Val => 42)), Dummy_Id);
   Check ("2.1 Is_Empty is False", not Sim.Is_Empty);
   Check ("2.2 Pending_Events is 1", Sim.Pending_Events = 1);
   Sim.Step_Next_Event;
   Check ("2.3 Clock advanced to 10.0", Sim.Current_Time = 10.0);
   Check ("2.4 Event Executed (Trace updated)", Trace_Idx = 1 and then Trace (1) = 42);
   Check ("2.5 Is_Empty is True again", Sim.Is_Empty);

   Put_Line ("TEST 3 — Event Ordering (Min-Heap validation)");
   Sim.Clear; Reset_Trace;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 20.0, Id => 0, Cancelled => False, Val => 2)), Dummy_Id);
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 10.0, Id => 0, Cancelled => False, Val => 1)), Dummy_Id);
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 30.0, Id => 0, Cancelled => False, Val => 3)), Dummy_Id);
   Check ("3.1 Pending_Events is 3", Sim.Pending_Events = 3);
   Sim.Run_Until (100.0);
   Check ("3.2 Trace 1 is Val 1", Trace (1) = 1);
   Check ("3.3 Trace 2 is Val 2", Trace (2) = 2);
   Check ("3.4 Trace 3 is Val 3", Trace (3) = 3);
   Check ("3.5 Clock advanced to 100.0", Sim.Current_Time = 100.0);

   Put_Line ("TEST 4 — Run_Until with partial execution");
   Sim.Clear; Reset_Trace;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 5.0, Id => 0, Cancelled => False, Val => 1)), Dummy_Id);
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 15.0, Id => 0, Cancelled => False, Val => 2)), Dummy_Id);
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 25.0, Id => 0, Cancelled => False, Val => 3)), Dummy_Id);
   Sim.Run_Until (15.0);
   Check ("4.1 Pending_Events is 1 (partial consumption)", Sim.Pending_Events = 1);
   Check ("4.2 Clock is exactly End_Time (15.0)", Sim.Current_Time = 15.0);
   Check ("4.3 Trace 2 is Val 2", Trace (2) = 2);

   Put_Line ("TEST 5 — Step_Fixed_Increment (Activity Scanning)");
   Sim.Clear; Reset_Trace;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 2.0, Id => 0, Cancelled => False, Val => 1)), Dummy_Id);
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 4.0, Id => 0, Cancelled => False, Val => 2)), Dummy_Id);
   Sim.Step_Fixed_Increment (3.0); 
   Check ("5.1 Clock advanced by 3.0", Sim.Current_Time = 3.0);
   Check ("5.2 One event ran", Trace_Idx = 1 and then Trace(1) = 1);
   Sim.Step_Fixed_Increment (3.0); 
   Check ("5.3 Clock advanced by 3.0 (now 6.0)", Sim.Current_Time = 6.0);
   Check ("5.4 Queue empty after second increment", Sim.Is_Empty);

   Put_Line ("TEST 6 — Event Cancellation (Lazy Deletion)");
   Sim.Clear; Reset_Trace;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 10.0, Id => 0, Cancelled => False, Val => 1)), Dummy_Id);
   Sim.Cancel_Event (Dummy_Id);
   Check ("6.1 Pending_Events goes to 0", Sim.Pending_Events = 0);
   Check ("6.2 Is_Empty reports True", Sim.Is_Empty);
   declare
      Caught : Boolean := False;
   begin
      begin
         Sim.Step_Next_Event; 
      exception
         when Event_Error => Caught := True;
      end;
      Check ("6.3 Step_Next_Event on cancelled queue raises exception", Caught);
   end;

   Put_Line ("TEST 7 — Precondition: Scheduling in the Past");
   declare
      Caught : Boolean := False;
   begin
      begin
         Sim.Run_Until (50.0);
         Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 10.0, Id => 0, Cancelled => False, Val => 1)), Dummy_Id);
      exception
         when Event_Error => Caught := True;
      end;
      Check ("7.1 Past scheduling caught Event_Error", Caught);
      Check ("7.2 Simulator state unbroken (Is_Empty)", Sim.Is_Empty);
      Check ("7.3 Clock remains 50.0", Sim.Current_Time = 50.0);
   end;

   Put_Line ("TEST 8 — Precondition: Step on Empty Simulator");
   Sim.Clear;
   declare
      Caught : Boolean := False;
   begin
      begin
         Sim.Step_Next_Event;
      exception
         when Event_Error => Caught := True;
      end;
      Check ("8.1 Event_Error caught on empty Step", Caught);
      Check ("8.2 Clock unchanged", Sim.Current_Time = 0.0);
      Check ("8.3 Pending_Events remains 0", Sim.Pending_Events = 0);
   end;

   Put_Line ("TEST 9 — Simulator Capacity Limits");
   Sim.Clear;
   declare
      Caught : Boolean := False;
   begin
      begin
         for I in 1 .. 10 loop
            Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 10.0, Id => 0, Cancelled => False, Val => Trace_Value_Type(I))), Dummy_Id);
         end loop;
         Check ("9.1 Hit max capacity successfully", Sim.Pending_Events = 10);
         
         -- Attempt 11th
         Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 10.0, Id => 0, Cancelled => False, Val => 99)), Dummy_Id);
      exception
         when Event_Error => Caught := True;
      end;
      Check ("9.2 Capacity exceeded correctly caught", Caught);
      Check ("9.3 Pending_Events securely capped at 10", Sim.Pending_Events = 10);
   end;

   Put_Line ("TEST 10 — Clear Simulator");
   Check ("10.1 Pending events before clear is > 0", Sim.Pending_Events > 0);
   Sim.Clear;
   Check ("10.2 Pending events after clear is 0", Sim.Pending_Events = 0);
   Check ("10.3 Is_Empty is True", Sim.Is_Empty);

   Put_Line ("TEST 11 — Dynamic Event Spawning");
   Sim.Clear; Reset_Trace;
   Sim.Schedule (To_Event_Access (new Spawner_Event'(Time => 5.0, Id => 0, Cancelled => False, Child_Time => 15.0, Child_Val => 77)), Dummy_Id);
   Sim.Step_Next_Event;
   Check ("11.1 Spawner executed at 5.0", Sim.Current_Time = 5.0 and then Trace(1) = 999);
   Check ("11.2 Spawned child added to queue", Sim.Pending_Events = 1);
   Sim.Step_Next_Event;
   Check ("11.3 Spawned child executed at 15.0", Sim.Current_Time = 15.0);
   Check ("11.4 Child Trace updated", Trace(2) = 77);

   Put_Line ("TEST 12 — Cancel Non-Existent ID");
   Sim.Clear;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 20.0, Id => 0, Cancelled => False, Val => 1)), Dummy_Id);
   Sim.Cancel_Event (Event_Id_Type'Last);
   Check ("12.1 Cancelling invalid ID does not affect Active_Count", Sim.Pending_Events = 1);
   Sim.Step_Next_Event;
   Check ("12.2 Valid event executes normally after invalid cancel", Sim.Current_Time = 20.0);
   Check ("12.3 Is_Empty is True", Sim.Is_Empty);

   Put_Line ("TEST 13 — Identical Event Times");
   Sim.Clear; Reset_Trace;
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 5.0, Id => 0, Cancelled => False, Val => 10)), Dummy_Id);
   Sim.Schedule (To_Event_Access (new Dummy_Event'(Time => 5.0, Id => 0, Cancelled => False, Val => 20)), Dummy_Id);
   Sim.Run_Until (5.0);
   Check ("13.1 Both events ran", Trace_Idx = 2);
   Check ("13.2 Clock is EXACTLY 5.0", Sim.Current_Time = 5.0);
   Check ("13.3 Pending is 0", Sim.Pending_Events = 0);

   Put_Line ("TEST 14 — Zero Fixed Increment");
   Sim.Clear;
   declare
      Caught_Zero : Boolean := False;
   begin
      begin
         Sim.Step_Fixed_Increment (0.0);
      exception
         when Event_Error => Caught_Zero := True;
      end;
      
      Check ("14.1 Zero increment caught", Caught_Zero);
      Check ("14.2 Clock safely unchanged", Sim.Current_Time = 0.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
