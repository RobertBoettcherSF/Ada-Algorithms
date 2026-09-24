with Ada.Text_IO; use Ada.Text_IO;
with Safety_Supervisor; use Safety_Supervisor;

procedure Test_Safety_Supervisor is
   Pass : Natural := 0;
   Fail : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Put_Line ("PASS: " & Name);
         Pass := Pass + 1;
      else
         Put_Line ("FAIL: " & Name);
         Fail := Fail + 1;
      end if;
   end Check;

   S : Supervisor;
   F : constant Geofence :=
     (Kind => AABB, X_Min => -1000, X_Max => 1000,
      Y_Min => -1000, Y_Max => 1000, CX => 0, CY => 0, R_Cm => 1000);
begin
   -- Overspeed rejected
   Init (S, Max_Speed => 100, Fence => F, Teleop_Ms => 5_000);
   Set_Speed_Command (S, 50);
   Check (Is_Motion_Allowed (S) and then Effective_Speed (S) = 50,
          "nominal speed accepted");
   Set_Speed_Command (S, 200);
   Check (not Is_Motion_Allowed (S) and then Get_Trip (S) = Overspeed,
          "overspeed rejected");

   -- Outside geofence trips
   Init (S, Max_Speed => 100, Fence => F, Teleop_Ms => 5_000);
   Set_Position (S, 0, 0);
   Set_Speed_Command (S, 40);
   Tick (S, 0);
   Check (Is_Motion_Allowed (S), "inside geofence ok");
   Set_Position (S, 5_000, 0);
   Tick (S, 100);
   Check (not Is_Motion_Allowed (S) and then Get_Trip (S) = Outside_Geofence,
          "outside geofence trips");

   -- Teleop timeout trips
   Init (S, Max_Speed => 100, Fence => F, Teleop_Ms => 1_000);
   Set_Speed_Command (S, 30);
   Tick (S, 0);
   Check (Is_Motion_Allowed (S), "before teleop timeout ok");
   Tick (S, 2_000);
   Check (not Is_Motion_Allowed (S) and then Get_Trip (S) = Teleop_Timeout,
          "teleop timeout trips");

   -- Clear e-stop restores when safe
   Init (S, Max_Speed => 100, Fence => F, Teleop_Ms => 5_000);
   Set_E_Stop (S, True);
   Check (not Is_Motion_Allowed (S) and then Get_Trip (S) = E_Stop_Active,
          "e-stop active");
   Set_E_Stop (S, False);
   Clear_Trip (S);
   Check (Is_Motion_Allowed (S) and then Get_Trip (S) = None,
          "clear e-stop restores when safe");

   New_Line;
   Put_Line ("Result:" & Pass'Image & " PASS," & Fail'Image & " FAIL");
   if Fail > 0 then
      raise Program_Error with "tests failed";
   end if;
end Test_Safety_Supervisor;
