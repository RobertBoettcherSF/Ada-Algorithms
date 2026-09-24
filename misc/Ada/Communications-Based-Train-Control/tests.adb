with Ada.Text_IO; use Ada.Text_IO;
with CBTC;        use CBTC;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   function Approx_Equal (Left, Right : Distance_M) return Boolean is
   begin
      return abs (Float (Left) - Float (Right)) < 0.01;
   end Approx_Equal;

   function Approx_Equal (Left, Right : Acceleration_MPS2) return Boolean is
   begin
      return abs (Float (Left) - Float (Right)) < 0.01;
   end Approx_Equal;

begin
   Put_Line ("--- Starting CBTC Test Suite ---");

   -- TEST 1: Braking Distance Calculation (Normal ranges)
   Put_Line ("TEST 1 -- Braking_Distance Normal");
   Check ("1.1 10mps @ -1.0 -> 50m", Approx_Equal (Braking_Distance (10.0, -1.0), 50.0));
   Check ("1.2 20mps @ -2.0 -> 100m", Approx_Equal (Braking_Distance (20.0, -2.0), 100.0));
   Check ("1.3 30mps @ -3.0 -> 150m", Approx_Equal (Braking_Distance (30.0, -3.0), 150.0));

   -- TEST 2: Braking Distance (Zero speed edge cases)
   Put_Line ("TEST 2 -- Braking_Distance Zero Speed");
   Check ("2.1 0mps @ -1.0 -> 0m", Approx_Equal (Braking_Distance (0.0, -1.0), 0.0));
   Check ("2.2 0mps @ -20.0 -> 0m", Approx_Equal (Braking_Distance (0.0, -20.0), 0.0));
   Check ("2.3 0mps @ -0.5 -> 0m", Approx_Equal (Braking_Distance (0.0, -0.5), 0.0));

   -- TEST 3: Braking Distance (High speed cases)
   Put_Line ("TEST 3 -- Braking_Distance High Speed");
   Check ("3.1 100mps @ -10.0 -> 500m", Approx_Equal (Braking_Distance (100.0, -10.0), 500.0));
   Check ("3.2 150mps @ -5.0 -> 2250m", Approx_Equal (Braking_Distance (150.0, -5.0), 2250.0));
   Check ("3.3 200mps @ -2.0 -> 10000m", Approx_Equal (Braking_Distance (200.0, -2.0), 10000.0));

   -- TEST 4: Moving Block Authority (Normal computation)
   Put_Line ("TEST 4 -- Moving_Block_Authority Normal");
   Check ("4.1 L=1000, M=50 -> MA=950", Approx_Equal (Moving_Block_Authority (1000.0, 500.0, 50.0), 950.0));
   Check ("4.2 L=2000, M=100 -> MA=1900", Approx_Equal (Moving_Block_Authority (2000.0, 1000.0, 100.0), 1900.0));
   Check ("4.3 L=500, M=0 -> MA=500", Approx_Equal (Moving_Block_Authority (500.0, 100.0, 0.0), 500.0));

   -- TEST 5: Moving Block Authority (Margin clipping near zero)
   Put_Line ("TEST 5 -- Moving_Block_Authority Margin Clipping");
   Check ("5.1 L=40, M=50 -> MA=0", Approx_Equal (Moving_Block_Authority (40.0, 10.0, 50.0), 0.0));
   Check ("5.2 L=10, M=20 -> MA=0", Approx_Equal (Moving_Block_Authority (10.0, 0.0, 20.0), 0.0));
   Check ("5.3 L=50, M=50 -> MA=0", Approx_Equal (Moving_Block_Authority (50.0, 20.0, 50.0), 0.0));

   -- TEST 6: Moving Block Authority (Collision Exception Validation)
   Put_Line ("TEST 6 -- Moving_Block_Authority Collision Exceptions");
   declare
      Caught : Boolean;
   begin
      Caught := False;
      begin
         if Moving_Block_Authority (50.0, 100.0, 10.0) >= 0.0 then null; end if;
      exception
         when Collision_Error => Caught := True;
      end;
      Check ("6.1 Follower exceeds Leader (F=100 > L=50)", Caught);

      Caught := False;
      begin
         if Moving_Block_Authority (0.0, 10.0, 0.0) >= 0.0 then null; end if;
      exception
         when Collision_Error => Caught := True;
      end;
      Check ("6.2 Follower exceeds Leader (F=10 > L=0)", Caught);

      Caught := False;
      begin
         if Moving_Block_Authority (999.0, 1000.0, 50.0) >= 0.0 then null; end if;
      exception
         when Collision_Error => Caught := True;
      end;
      Check ("6.3 Follower exceeds Leader (F=1000 > L=999)", Caught);
   end;

   -- TEST 7: Fixed Block Authority (Normal computation)
   Put_Line ("TEST 7 -- Fixed_Block_Authority Normal Occupancy");
   Check ("7.1 L=5, F=2, Len=100 -> MA=500", Approx_Equal (Fixed_Block_Authority (5, 2, 100.0), 500.0));
   Check ("7.2 L=10, F=5, Len=500 -> MA=5000", Approx_Equal (Fixed_Block_Authority (10, 5, 500.0), 5000.0));
   Check ("7.3 L=3, F=1, Len=100 -> MA=300", Approx_Equal (Fixed_Block_Authority (3, 1, 100.0), 300.0));

   -- TEST 8: Fixed Block Authority (Adjacent blocks and Collisions)
   Put_Line ("TEST 8 -- Fixed_Block_Authority Adjacent and Collisions");
   Check ("8.1 Adjacent (L=5, F=4, Len=1000) -> MA=5000", Approx_Equal (Fixed_Block_Authority (5, 4, 1000.0), 5000.0));
   declare
      Caught : Boolean;
   begin
      Caught := False;
      begin
         if Fixed_Block_Authority (2, 2, 100.0) >= 0.0 then null; end if;
      exception
         when Collision_Error => Caught := True;
      end;
      Check ("8.2 Same Block Collision (L=2, F=2)", Caught);

      Caught := False;
      begin
         if Fixed_Block_Authority (1, 5, 100.0) >= 0.0 then null; end if;
      exception
         when Collision_Error => Caught := True;
      end;
      Check ("8.3 Follower Ahead Collision (L=1, F=5)", Caught);
   end;

   -- TEST 9: ATP System Check (Speed Limit Validation)
   Put_Line ("TEST 9 -- ATP_Is_Safe Speed Limit Violation");
   Check ("9.1 Over limit by 5", not ATP_Is_Safe (20.0, 15.0, 0.0, 1000.0, -1.0));
   Check ("9.2 Over limit by 50", not ATP_Is_Safe (100.0, 50.0, 0.0, 1000.0, -1.0));
   Check ("9.3 Over limit by 5", not ATP_Is_Safe (25.0, 20.0, 0.0, 1000.0, -1.0));

   -- TEST 10: ATP System Check (Authority Curve Validation)
   Put_Line ("TEST 10 -- ATP_Is_Safe Authority Violation");
   -- 10mps @ -1.0 = 50m braking required. 900+50 = 950 >= 940 (Unsafe)
   Check ("10.1 Projected > Authority", not ATP_Is_Safe (10.0, 20.0, 900.0, 940.0, -1.0));
   -- 20mps @ -2.0 = 100m. 500+100 = 600 >= 600 (Unsafe - edge)
   Check ("10.2 Projected == Authority", not ATP_Is_Safe (20.0, 30.0, 500.0, 600.0, -2.0));
   -- 10mps @ -1.0 = 50m. 10+50 = 60 >= 40 (Unsafe)
   Check ("10.3 Short authority", not ATP_Is_Safe (10.0, 20.0, 10.0, 40.0, -1.0));

   -- TEST 11: ATP System Check (Safe Parameters)
   Put_Line ("TEST 11 -- ATP_Is_Safe Safe Conditions");
   -- 10mps @ -1.0 = 50m. 0+50 = 50 < 100 (Safe)
   Check ("11.1 Plenty of authority", ATP_Is_Safe (10.0, 20.0, 0.0, 100.0, -1.0));
   -- 15mps @ -2.0 = 56.25m. 50+56.25 = 106.25 < 250 (Safe)
   Check ("11.2 High speed safe", ATP_Is_Safe (15.0, 15.0, 50.0, 250.0, -2.0));
   -- 0mps -> 0m braking. 5+0 < 10 (Safe)
   Check ("11.3 Stationary safe", ATP_Is_Safe (0.0, 10.0, 5.0, 10.0, -1.0));

   -- TEST 12: ATO Command Generation (Acceleration/Coasting)
   Put_Line ("TEST 12 -- ATO_Command Acceleration & Coasting Modes");
   Check ("12.1 Accelerate to target", Approx_Equal (ATO_Command (0.0, 20.0, 0.0, 1000.0, -1.0, 1.0), 1.0));
   Check ("12.2 Coast at target", Approx_Equal (ATO_Command (20.0, 20.0, 0.0, 1000.0, -1.0, 1.0), 0.0));
   Check ("12.3 Service brake for lower target", Approx_Equal (ATO_Command (25.0, 20.0, 0.0, 1000.0, -1.0, 1.0), -1.0));

   -- TEST 13: ATO Command Generation (Target Braking)
   Put_Line ("TEST 13 -- ATO_Command Stopping Mode");
   -- Braking needed is 50. Authority is 50 away. Needs to brake now.
   Check ("13.1 Exact braking point", Approx_Equal (ATO_Command (10.0, 20.0, 0.0, 50.0, -1.0, 1.0), -1.0));
   -- Braking needed is 100. Authority is 150 away. Accelerate.
   Check ("13.2 Before braking point", Approx_Equal (ATO_Command (20.0, 30.0, 0.0, 150.0, -2.0, 2.0), 2.0));
   -- Braking needed is 100. Authority is 90 away. Brake.
   Check ("13.3 Past braking point", Approx_Equal (ATO_Command (20.0, 20.0, 10.0, 100.0, -2.0, 1.0), -2.0));

   -- TEST 14: ATS Schedule Check (Headway)
   Put_Line ("TEST 14 -- ATS_Safe_Departure Headway checking");
   Check ("14.1 Too soon", not ATS_Safe_Departure (0.0, 10.0, 20.0));
   Check ("14.2 Exact time", ATS_Safe_Departure (0.0, 20.0, 20.0));
   Check ("14.3 Later time", ATS_Safe_Departure (0.0, 30.0, 20.0));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
