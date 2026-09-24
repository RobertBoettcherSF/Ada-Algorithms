pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Automatic_Train_Operation; use Automatic_Train_Operation;

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

   -- Helper for floating point tolerance tests
   function Is_Near (Value : Speed_Mps; Target : Float) return Boolean is
   begin
      return abs (Float (Value) - Target) < 0.001;
   end Is_Near;

   Test_Speed  : Speed_Mps := 0.0;
   Test_Action : Train_Action := Coast;
   Test_Doors  : Door_State := Closed;
begin
   -- TEST 1 - ATP Safe Speed Kinematics
   Put_Line ("TEST 1 - ATP Safe Speed Kinematics");
   Test_Speed := Calculate_ATP_Safe_Speed (50.0, 100.0, -2.0);
   Check ("1.1 Computes exact kinematic speed", Is_Near (Test_Speed, 20.0));
   Test_Speed := Calculate_ATP_Safe_Speed (50.0, 50.0, -1.0);
   Check ("1.2 Computes correct speed for lower decel", Is_Near (Test_Speed, 10.0));
   Check ("1.3 Does not exceed track limit", Is_Near (Calculate_ATP_Safe_Speed (15.0, 100.0, -2.0), 15.0));

   -- TEST 2 - ATP Safe Speed Edge Cases
   Put_Line ("TEST 2 - ATP Safe Speed Edge Cases");
   Check ("2.1 Distance 0.0 results in 0.0 speed", Is_Near (Calculate_ATP_Safe_Speed (50.0, 0.0, -2.0), 0.0));
   Check ("2.2 Negative distance results in 0.0 speed", Is_Near (Calculate_ATP_Safe_Speed (50.0, -10.0, -2.0), 0.0));
   Check ("2.3 Track limit 0.0 results in 0.0 speed", Is_Near (Calculate_ATP_Safe_Speed (0.0, 100.0, -2.0), 0.0));

   -- TEST 3 - ATO Drive Accelerate
   Put_Line ("TEST 3 - ATO Drive Accelerate");
   Check ("3.1 Start from zero", Determine_Drive_Action (0.0, 10.0) = Accelerate);
   Check ("3.2 Moving, target is higher", Determine_Drive_Action (15.0, 20.0) = Accelerate);
   Check ("3.3 Just outside coast tolerance", Determine_Drive_Action (9.4, 10.0) = Accelerate);

   -- TEST 4 - ATO Drive Brake
   Put_Line ("TEST 4 - ATO Drive Brake");
   Check ("4.1 Target speed lower", Determine_Drive_Action (20.0, 10.0) = Service_Brake);
   Check ("4.2 Just outside coast tolerance", Determine_Drive_Action (10.6, 10.0) = Service_Brake);
   Check ("4.3 Target is zero", Determine_Drive_Action (5.0, 0.0) = Service_Brake);

   -- TEST 5 - ATO Drive Coast
   Put_Line ("TEST 5 - ATO Drive Coast");
   Check ("5.1 Exactly on target", Determine_Drive_Action (10.0, 10.0) = Coast);
   Check ("5.2 Slightly below target", Determine_Drive_Action (9.6, 10.0) = Coast);
   Check ("5.3 Slightly above target", Determine_Drive_Action (10.4, 10.0) = Coast);

   -- TEST 6 - ATO Drive Stopped
   Put_Line ("TEST 6 - ATO Drive Stopped");
   Check ("6.1 Speed 0, Target 0", Determine_Drive_Action (0.0, 0.0) = Stopped);
   Check ("6.2 Speed > 0, Target 0", Determine_Drive_Action (0.5, 0.0) = Service_Brake);
   Check ("6.3 High speed, Target 0", Determine_Drive_Action (1.5, 0.0) = Service_Brake);

   -- TEST 7 - Station Braking Far
   Put_Line ("TEST 7 - Station Braking Far");
   Test_Action := Precision_Station_Stop (15.0, 1000.0, -1.0);
   Check ("7.1 Far away, speed low -> Accelerate", Test_Action = Accelerate);
   Test_Action := Precision_Station_Stop (40.0, 800.0, -1.0);
   Check ("7.2 Far away, speed matches -> Coast", Test_Action = Coast);
   Test_Action := Precision_Station_Stop (50.0, 800.0, -1.0);
   Check ("7.3 Far away, speed high -> Brake", Test_Action = Service_Brake);

   -- TEST 8 - Station Braking Near
   Put_Line ("TEST 8 - Station Braking Near");
   Test_Action := Precision_Station_Stop (10.0, 50.0, -1.0);
   Check ("8.1 Approaching exactly on curve -> Coast", Test_Action = Coast);
   Test_Action := Precision_Station_Stop (15.0, 50.0, -1.0);
   Check ("8.2 Above curve -> Brake", Test_Action = Service_Brake);
   Test_Action := Precision_Station_Stop (5.0, 50.0, -1.0);
   Check ("8.3 Below curve -> Accelerate", Test_Action = Accelerate);

   -- TEST 9 - Station Braking Arrived
   Put_Line ("TEST 9 - Station Braking Arrived");
   Check ("9.1 Perfectly stopped at mark", Precision_Station_Stop (0.0, 0.0, -1.0) = Stopped);
   Check ("9.2 Stopped within tolerance", Precision_Station_Stop (0.0, 0.4, -1.0) = Stopped);
   Check ("9.3 Moving slowly in tolerance", Precision_Station_Stop (0.5, 0.2, -1.0) = Service_Brake);

   -- TEST 10 - Station Braking Overshoot
   Put_Line ("TEST 10 - Station Braking Overshoot");
   Check ("10.1 Slight overshoot", Precision_Station_Stop (0.0, -0.6, -1.0) = Emergency_Brake);
   Check ("10.2 Major overshoot", Precision_Station_Stop (10.0, -50.0, -1.0) = Emergency_Brake);
   Check ("10.3 Moving during overshoot", Precision_Station_Stop (1.0, -0.6, -1.0) = Emergency_Brake);

   -- TEST 11 - Door Control Open
   Put_Line ("TEST 11 - Door Control Open");
   Test_Doors := Closed;
   Control_Doors (0.0, 0.0, GoA_4, Test_Doors);
   Check ("11.1 GoA4 perfectly aligned", Test_Doors = Open);
   Test_Doors := Closed;
   Control_Doors (0.0, 0.4, GoA_3, Test_Doors);
   Check ("11.2 GoA3 within tolerance", Test_Doors = Open);
   Test_Doors := Closed;
   Control_Doors (0.0, -0.4, GoA_2, Test_Doors);
   Check ("11.3 GoA2 within tolerance", Test_Doors = Open);

   -- TEST 12 - Door Control Closed
   Put_Line ("TEST 12 - Door Control Closed");
   Test_Doors := Open;
   Control_Doors (1.0, 0.0, GoA_4, Test_Doors);
   Check ("12.1 Moving train -> Closed", Test_Doors = Closed);
   Test_Doors := Open;
   Control_Doors (0.0, 1.0, GoA_4, Test_Doors);
   Check ("12.2 Misaligned train -> Closed", Test_Doors = Closed);
   Test_Doors := Open;
   Control_Doors (0.0, 0.0, GoA_1, Test_Doors);
   Check ("12.3 GoA1 ignores automatic doors -> Keeps state", Test_Doors = Open);

   -- TEST 13 - Obstacle Handling (GoA 4)
   Put_Line ("TEST 13 - Obstacle Handling (GoA 4)");
   Check ("13.1 Obstacle near -> Emergency", Handle_Obstacle (True, 150.0, GoA_4) = Emergency_Brake);
   Check ("13.2 Obstacle far -> Service Brake", Handle_Obstacle (True, 500.0, GoA_4) = Service_Brake);
   Check ("13.3 No Obstacle -> Coast", Handle_Obstacle (False, 100.0, GoA_4) = Coast);

   -- TEST 14 - Error Handling Exceptions
   Put_Line ("TEST 14 - Error Handling Exceptions");
   declare
   begin
      -- Positive deceleration should fail the Precondition (< 0.0)
      Check ("14.1 Precondition on Decel failed to raise", Precision_Station_Stop (10.0, 10.0, 1.0) = Stopped);
   exception
      when others =>
         Check ("14.1 Precondition caught invalid positive decel", True);
   end;

   declare
   begin
      -- Handle_Obstacle strictly expects GoA_4
      Check ("14.2 Precondition on GoA failed to raise", Handle_Obstacle (True, 100.0, GoA_2) = Coast);
   exception
      when others =>
         Check ("14.2 Precondition caught invalid GoA for UTO", True);
   end;

   declare
   begin
      -- Positive deceleration should fail ATP Precondition (< 0.0)
      Check ("14.3 Precondition on ATP failed to raise", Is_Near (Calculate_ATP_Safe_Speed (50.0, 100.0, 1.0), 0.0));
   exception
      when others =>
         Check ("14.3 Precondition on ATP caught positive decel", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
