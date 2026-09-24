with Ada.Text_IO; use Ada.Text_IO;
with Traffic_Simulation; use Traffic_Simulation;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Float comparison helpers
   function Is_Close (Left, Right : Float) return Boolean is
     (abs (Left - Right) < 0.001);

   -- Test Variables
   Micro_State : Microscopic_State;
   Behavior    : constant Driver_Behavior := 
     (Desired_Speed     => 30.0,
      Safe_Time_Headway => 2.0,
      Max_Acceleration  => 2.0,
      Max_Deceleration  => 4.0,
      Minimum_Gap       => 5.0);
      
   Macro_Flow  : Vehicles_Per_Hour;
   Macro_Speed : Meters_Per_Second;
   
   Platoon_Obj : Platoon;
   Discharge   : Vehicle_Volume;
   Exception_Thrown : Boolean;
begin
   Put_Line ("--- Starting Traffic Simulation Test Suite ---");

   -- TEST 1 - Microscopic: Free Flow Acceleration
   Put_Line ("TEST 1 - Microscopic: Free Flow Acceleration");
   Micro_State := (Position => 0.0, Speed => 10.0);
   Advance_Microscopic (Micro_State, Behavior, Gap_To_Leader => 500.0, Leader_Speed => 30.0, Time_Step => 1.0);
   Check ("1.1 Position updated forward", Micro_State.Position > 10.0);
   Check ("1.2 Speed increased (Accelerated)", Micro_State.Speed = 12.0); -- 10 + 2 (Max_Accel) * 1
   Check ("1.3 Gap logic bypassed due to distance", Micro_State.Speed <= Behavior.Desired_Speed);

   -- TEST 2 - Microscopic: Following Slower Car
   Put_Line ("TEST 2 - Microscopic: Following Slower Car");
   Micro_State := (Position => 100.0, Speed => 20.0);
   -- Leader is 45m ahead going 15m/s. Safe_Speed = 15 + (45 - 5) / 2 = 35. 
   -- Commanded_Speed is Min(30, 35) = 30. Still wants to accelerate up to 30.
   Advance_Microscopic (Micro_State, Behavior, Gap_To_Leader => 45.0, Leader_Speed => 15.0, Time_Step => 1.0);
   Check ("2.1 Allowed to accelerate to desired", Micro_State.Speed > 20.0);
   Check ("2.2 Max acceleration bounds respected", Micro_State.Speed = 22.0);
   Check ("2.3 Position mathematically correct", Micro_State.Position = 122.0);

   -- TEST 3 - Microscopic: Hard Braking
   Put_Line ("TEST 3 - Microscopic: Hard Braking");
   Micro_State := (Position => 200.0, Speed => 30.0);
   -- Leader is 15m ahead going 5m/s. Safe_Speed = 5 + (15 - 5) / 2 = 10m/s.
   -- Commanded = 10m/s. Accel_Needed = (10 - 30) / 1.0 = -20.
   -- Max Decel is 4.0, so speed drops by 4.0 -> 26.0m/s.
   Advance_Microscopic (Micro_State, Behavior, Gap_To_Leader => 15.0, Leader_Speed => 5.0, Time_Step => 1.0);
   Check ("3.1 Speed decreased (Decelerated)", Micro_State.Speed = 26.0);
   Check ("3.2 Max deceleration limit applied", Is_Close (Float (Micro_State.Speed), 26.0));
   Check ("3.3 New position is old + new speed", Micro_State.Position = 226.0);

   -- TEST 4 - Microscopic: Approaching stationary target
   Put_Line ("TEST 4 - Microscopic: Approaching stationary");
   Micro_State := (Position => 0.0, Speed => 10.0);
   -- Leader stopped 10m ahead. Safe_speed = 0 + (10 - 5) / 2 = 2.5m/s.
   -- Drops by max decel (4) to 6.0m/s
   Advance_Microscopic (Micro_State, Behavior, Gap_To_Leader => 10.0, Leader_Speed => 0.0, Time_Step => 1.0);
   Check ("4.1 Safe speed logic forces braking", Micro_State.Speed < 10.0);
   Check ("4.2 Speed precisely calculated", Micro_State.Speed = 6.0);
   Check ("4.3 Position progresses safely", Micro_State.Position = 6.0);

   -- TEST 5 - Microscopic: Collision Error Handling
   Put_Line ("TEST 5 - Microscopic: Collision Error Handling");
   Micro_State := (Position => 50.0, Speed => 15.0);
   Exception_Thrown := False;
   begin
      -- Gap (2.0) < Minimum_Gap (5.0) -> Should throw Collision_Error
      Advance_Microscopic (Micro_State, Behavior, Gap_To_Leader => 2.0, Leader_Speed => 10.0, Time_Step => 1.0);
   exception
      when Collision_Error =>
         Exception_Thrown := True;
   end;
   Check ("5.1 Collision exception raised", Exception_Thrown);
   Check ("5.2 State position unmodified", Micro_State.Position = 50.0);
   Check ("5.3 State speed unmodified", Micro_State.Speed = 15.0);

   -- TEST 6 - Macroscopic: Free Flow
   Put_Line ("TEST 6 - Macroscopic: Free Flow State");
   Calculate_Macroscopic_State (Density => 0.0, Free_Flow_Speed => 30.0, Jam_Density => 100.0, 
                                Resulting_Flow => Macro_Flow, Resulting_Speed => Macro_Speed);
   Check ("6.1 Free flow speed maintained", Macro_Speed = 30.0);
   Check ("6.2 Flow is zero (empty road)", Macro_Flow = 0.0);
   Check ("6.3 Valid density scaling", Is_Close (Float(Macro_Speed), 30.0));

   -- TEST 7 - Macroscopic: Jam Density
   Put_Line ("TEST 7 - Macroscopic: Jam Density State");
   Calculate_Macroscopic_State (Density => 100.0, Free_Flow_Speed => 30.0, Jam_Density => 100.0, 
                                Resulting_Flow => Macro_Flow, Resulting_Speed => Macro_Speed);
   Check ("7.1 Speed is zero", Macro_Speed = 0.0);
   Check ("7.2 Flow is zero", Macro_Flow = 0.0);
   Check ("7.3 Fundamental diagram roots verify", Is_Close (Float(Macro_Flow), 0.0));

   -- TEST 8 - Macroscopic: Optimal Flow
   Put_Line ("TEST 8 - Macroscopic: Optimal Flow State");
   Calculate_Macroscopic_State (Density => 50.0, Free_Flow_Speed => 30.0, Jam_Density => 100.0, 
                                Resulting_Flow => Macro_Flow, Resulting_Speed => Macro_Speed);
   Check ("8.1 Speed is exactly half", Macro_Speed = 15.0);
   Check ("8.2 Flow formula (50*15*3.6=2700)", Is_Close (Float(Macro_Flow), 2700.0));
   Check ("8.3 Parabolic flow peak verifies", Macro_Flow > 0.0);

   -- TEST 9 - Macroscopic: Over Jam Density
   Put_Line ("TEST 9 - Macroscopic: Over Capacity");
   Calculate_Macroscopic_State (Density => 120.0, Free_Flow_Speed => 30.0, Jam_Density => 100.0, 
                                Resulting_Flow => Macro_Flow, Resulting_Speed => Macro_Speed);
   Check ("9.1 Speed clamped safely to 0", Macro_Speed = 0.0);
   Check ("9.2 Flow clamped safely to 0", Macro_Flow = 0.0);
   Check ("9.3 Over-density prevents movement", Is_Close (Float(Macro_Speed), 0.0));

   -- TEST 10 - Mesoscopic: Platoon Moving
   Put_Line ("TEST 10 - Mesoscopic: Platoon Moving");
   Platoon_Obj := (Size => 20.0, State => Moving, Time_To_Node => 10.0);
   Advance_Mesoscopic_Platoon (Platoon_Obj, Link_Capacity => 3600.0, Time_Step => 2.0, Discharged_Count => Discharge);
   Check ("10.1 Platoon size unchanged", Platoon_Obj.Size = 20.0);
   Check ("10.2 Discharged is zero", Discharge = 0.0);
   Check ("10.3 Time to node decremented", Platoon_Obj.Time_To_Node = 8.0);

   -- TEST 11 - Mesoscopic: Platoon Arriving (Transition)
   Put_Line ("TEST 11 - Mesoscopic: Platoon Arriving");
   Platoon_Obj := (Size => 20.0, State => Moving, Time_To_Node => 2.0);
   Advance_Mesoscopic_Platoon (Platoon_Obj, Link_Capacity => 3600.0, Time_Step => 3.0, Discharged_Count => Discharge);
   Check ("11.1 State changed to Queued", Platoon_Obj.State = Queued);
   Check ("11.2 Time clamped to zero", Platoon_Obj.Time_To_Node = 0.0);
   Check ("11.3 No discharge on transition frame", Discharge = 0.0);

   -- TEST 12 - Mesoscopic: Platoon Discharging
   Put_Line ("TEST 12 - Mesoscopic: Platoon Discharging");
   Platoon_Obj := (Size => 20.0, State => Queued, Time_To_Node => 0.0);
   -- 3600 Veh/Hr = 1 Veh/Sec. Time_Step = 5.0 -> 5.0 vehicles should discharge.
   Advance_Mesoscopic_Platoon (Platoon_Obj, Link_Capacity => 3600.0, Time_Step => 5.0, Discharged_Count => Discharge);
   Check ("12.1 Valid discharge count computed", Is_Close (Float(Discharge), 5.0));
   Check ("12.2 Remaining size reduced", Is_Close (Float(Platoon_Obj.Size), 15.0));
   Check ("12.3 Platoon still queued", Platoon_Obj.State = Queued);

   -- TEST 13 - Mesoscopic: Platoon Fully Discharged
   Put_Line ("TEST 13 - Mesoscopic: Fully Discharged");
   Platoon_Obj := (Size => 3.0, State => Queued, Time_To_Node => 0.0);
   -- 3600 Veh/Hr = 1 Veh/Sec. Time_Step = 5.0 -> 5 max discharge, clears remaining 3.
   Advance_Mesoscopic_Platoon (Platoon_Obj, Link_Capacity => 3600.0, Time_Step => 5.0, Discharged_Count => Discharge);
   Check ("13.1 Discharge capped to remaining size", Is_Close (Float(Discharge), 3.0));
   Check ("13.2 Size mathematically zeroed", Platoon_Obj.Size = 0.0);
   Check ("13.3 State transitioned to Discharged", Platoon_Obj.State = Discharged);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
