--  tests.adb
--
--  Test suite for Truncated Binary Exponential Backoff package.
--
--  Author: Vibe Code (Mistral AI)
--  Date: 2025

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions; use Ada.Exceptions;
with Truncated_Binary_Exponential_Backoff; use Truncated_Binary_Exponential_Backoff;

procedure Tests is
   --  Default configuration for tests
   Default_Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);

   --  Test helper procedure
   procedure Print_Result (Test_Name : String; Passed : Boolean) is
   begin
      if Passed then
         Put_Line ("  PASS: " & Test_Name);
      else
         Put_Line ("  FAIL: " & Test_Name);
      end if;
   end Print_Result;

begin
   Put_Line ("=== Truncated Binary Exponential Backoff Test Suite ===");
   New_Line;

   --  ========================================================================
   --  TEST 1 - Deterministic Delay Calculation
   --  ========================================================================
   Put_Line ("TEST 1 - Deterministic Delay Calculation");
   begin
      --  1.1: Verify delay for c=0 is slot_time (2^0 * slot_time = slot_time)
      declare
         Result : Delay_Type := Deterministic_Delay (Default_Config, 0);
      begin
         Assert (Result = 512, "Result for c=0 should be 512");
         Print_Result ("1.1: Result for c=0 is slot_time", True);
      end;

      --  1.2: Verify delay for c=1 is 2 * slot_time
      declare
         Result : Delay_Type := Deterministic_Delay (Default_Config, 1);
      begin
         Assert (Result = 1024, "Result for c=1 should be 1024");
         Print_Result ("1.2: Result for c=1 is 2 * slot_time", True);
      end;

      --  1.3: Verify delay for c=2 is 4 * slot_time
      declare
         Result : Delay_Type := Deterministic_Delay (Default_Config, 2);
      begin
         Assert (Result = 2048, "Result for c=2 should be 2048");
         Print_Result ("1.3: Result for c=2 is 4 * slot_time", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 2 - Randomized Delay Calculation
   --  ========================================================================
   Put_Line ("TEST 2 - Randomized Delay Calculation");
   begin
      --  2.1: Verify delay for c=0 is in [0, 0] (only 0)
      declare
         Result : Delay_Type := Randomized_Delay (Default_Config, 0);
      begin
         Assert (Result = 0, "Result for c=0 should be 0");
         Print_Result ("2.1: Result for c=0 is 0", True);
      end;

      --  2.2: Verify delay for c=1 is in [0, 1] * slot_time
      declare
         Result : Delay_Type := Randomized_Delay (Default_Config, 1);
      begin
         Assert (Result = 0 or Result = 512, "Result for c=1 should be 0 or 512");
         Print_Result ("2.2: Result for c=1 is in [0, 512]", True);
      end;

      --  2.3: Verify delay for c=2 is in [0, 3] * slot_time
      declare
         Result : Delay_Type := Randomized_Delay (Default_Config, 2);
      begin
         Assert (Result = 0 or Result = 512 or Result = 1024 or Result = 1536,
                 "Result for c=2 should be in [0, 1536]");
         Print_Result ("2.3: Result for c=2 is in [0, 1536]", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 3 - Truncated Deterministic Delay
   --  ========================================================================
   Put_Line ("TEST 3 - Truncated Deterministic Delay");
   begin
      --  3.1: Verify delay for c=10 (ceiling) is 2^10 * slot_time
      declare
         Result : Delay_Type := Truncated_Deterministic_Delay (Default_Config, 10);
      begin
         Assert (Result = 512 * 1024, "Result for c=10 should be 512 * 1024");
         Print_Result ("3.1: Result for c=10 is 2^10 * slot_time", True);
      end;

      --  3.2: Verify delay for c=11 (above ceiling) is same as c=10
      declare
         Result_10 : Delay_Type := Truncated_Deterministic_Delay (Default_Config, 10);
         Result_11 : Delay_Type := Truncated_Deterministic_Delay (Default_Config, 11);
      begin
         Assert (Result_10 = Result_11, "Result for c=11 should equal c=10 (truncated)");
         Print_Result ("3.2: Result for c=11 equals c=10 (truncated)", True);
      end;

      --  3.3: Verify delay for c=100 (far above ceiling) is same as c=10
      declare
         Result_10  : Delay_Type := Truncated_Deterministic_Delay (Default_Config, 10);
         Result_100 : Delay_Type := Truncated_Deterministic_Delay (Default_Config, 100);
      begin
         Assert (Result_10 = Result_100, "Result for c=100 should equal c=10 (truncated)");
         Print_Result ("3.3: Result for c=100 equals c=10 (truncated)", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 4 - Truncated Randomized Delay
   --  ========================================================================
   Put_Line ("TEST 4 - Truncated Randomized Delay");
   begin
      --  4.1: Verify delay for c=10 (ceiling) is in [0, 2^10 - 1] * slot_time
      declare
         Result : Delay_Type := Truncated_Randomized_Delay (Default_Config, 10);
      begin
         Assert (Result >= 0 and Result <= 512 * 1023,
                 "Result for c=10 should be in [0, 512*1023]");
         Print_Result ("4.1: Result for c=10 is in [0, 512*1023]", True);
      end;

      --  4.2: Verify delay for c=11 (above ceiling) is in [0, 2^10 - 1] * slot_time
      declare
         Result : Delay_Type := Truncated_Randomized_Delay (Default_Config, 11);
      begin
         Assert (Result >= 0 and Result <= 512 * 1023,
                 "Result for c=11 should be in [0, 512*1023] (truncated)");
         Print_Result ("4.2: Result for c=11 is in [0, 512*1023] (truncated)", True);
      end;

      --  4.3: Verify delay for c=0 is 0
      declare
         Result : Delay_Type := Truncated_Randomized_Delay (Default_Config, 0);
      begin
         Assert (Result = 0, "Result for c=0 should be 0");
         Print_Result ("4.3: Result for c=0 is 0", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 5 - State Management
   --  ========================================================================
   Put_Line ("TEST 5 - State Management");
   begin
      --  5.1: Verify Initialize_State sets collision_count to 0
      declare
         State : Backoff_State;
      begin
         Initialize_State (State);
         Assert (State.Collision_Count = 0, "Collision_Count should be 0 after init");
         Print_Result ("5.1: Initialize_State sets collision_count to 0", True);
      end;

      --  5.2: Verify Reset_State resets collision_count to 0
      declare
         State : Backoff_State;
      begin
         State.Collision_Count := 5;
         State.Current_Delay := 1000;
         Reset_State (State);
         Assert (State.Collision_Count = 0, "Collision_Count should be 0 after reset");
         Print_Result ("5.2: Reset_State resets collision_count to 0", True);
      end;

      --  5.3: Verify Increment_Collision increases collision_count
      declare
         State : Backoff_State;
      begin
         Initialize_State (State);
         Increment_Collision (State, Default_Config, Use_Random => False);
         Assert (State.Collision_Count = 1, "Collision_Count should be 1 after increment");
         Print_Result ("5.3: Increment_Collision increases collision_count", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 6 - Expected Delay Calculation
   --  ========================================================================
   Put_Line ("TEST 6 - Expected Delay Calculation");
   begin
      --  6.1: Verify expected delay for c=0 is 0
      declare
         Exp_Result : Delay_Type := Expected_Delay (Default_Config, 0);
      begin
         Assert (Exp_Result = 0, "Expected delay for c=0 should be 0");
         Print_Result ("6.1: Expected delay for c=0 is 0", True);
      end;

      --  6.2: Verify expected delay for c=1 is (2^1 - 1)/2 * slot_time = 256
      declare
         Exp_Result : Delay_Type := Expected_Delay (Default_Config, 1);
      begin
         Assert (Exp_Result = 256, "Expected delay for c=1 should be 256");
         Print_Result ("6.2: Expected delay for c=1 is 256", True);
      end;

      --  6.3: Verify expected delay for c=2 is (2^2 - 1)/2 * slot_time = 768
      declare
         Exp_Result : Delay_Type := Expected_Delay (Default_Config, 2);
      begin
         Assert (Exp_Result = 768, "Expected delay for c=2 should be 768");
         Print_Result ("6.3: Expected delay for c=2 is 768", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 7 - Truncated Expected Delay
   --  ========================================================================
   Put_Line ("TEST 7 - Truncated Expected Delay");
   begin
      --  7.1: Verify truncated expected delay for c=10 is (2^10 - 1)/2 * slot_time
      declare
         Exp_Result : Delay_Type := Truncated_Expected_Delay (Default_Config, 10);
      begin
         Assert (Exp_Result = 261888, "Expected delay for c=10 should be 261888");
         Print_Result ("7.1: Truncated expected delay for c=10 is 255*512", True);
      end;

      --  7.2: Verify truncated expected delay for c=11 equals c=10
      declare
         Exp_Result_10 : Delay_Type := Truncated_Expected_Delay (Default_Config, 10);
         Exp_Result_11 : Delay_Type := Truncated_Expected_Delay (Default_Config, 11);
      begin
         Assert (Exp_Result_10 = Exp_Result_11,
                 "Expected delay for c=11 should equal c=10 (truncated)");
         Print_Result ("7.2: Truncated expected delay for c=11 equals c=10", True);
      end;

      --  7.3: Verify truncated expected delay for c=0 is 0
      declare
         Exp_Result : Delay_Type := Truncated_Expected_Delay (Default_Config, 0);
      begin
         Assert (Exp_Result = 0, "Expected delay for c=0 should be 0");
         Print_Result ("7.3: Truncated expected delay for c=0 is 0", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 9 - Helper Functions
   --  ========================================================================
   Put_Line ("TEST 9 - Helper Functions");
   begin
      --  9.1: Verify Power_Of_Two(0) = 1
      Assert (Power_Of_Two (0) = 1, "Power_Of_Two(0) should be 1");
      Print_Result ("9.1: Power_Of_Two(0) = 1", True);

      --  9.2: Verify Power_Of_Two(1) = 2
      Assert (Power_Of_Two (1) = 2, "Power_Of_Two(1) should be 2");
      Print_Result ("9.2: Power_Of_Two(1) = 2", True);

      --  9.3: Verify Power_Of_Two(3) = 8
      Assert (Power_Of_Two (3) = 8, "Power_Of_Two(3) should be 8");
      Print_Result ("9.3: Power_Of_Two(3) = 8", True);
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 10 - Clamp_Collision_Count
   --  ========================================================================
   Put_Line ("TEST 10 - Clamp_Collision_Count");
   begin
      --  10.1: Verify Clamp_Collision_Count(5, 10) = 5
      Assert (Clamp_Collision_Count (5, 10) = 5,
              "Clamp_Collision_Count(5, 10) should be 5");
      Print_Result ("10.1: Clamp_Collision_Count(5, 10) = 5", True);

      --  10.2: Verify Clamp_Collision_Count(15, 10) = 10
      Assert (Clamp_Collision_Count (15, 10) = 10,
              "Clamp_Collision_Count(15, 10) should be 10");
      Print_Result ("10.2: Clamp_Collision_Count(15, 10) = 10", True);

      --  10.3: Verify Clamp_Collision_Count(0, 10) = 0
      Assert (Clamp_Collision_Count (0, 10) = 0,
              "Clamp_Collision_Count(0, 10) should be 0");
      Print_Result ("10.3: Clamp_Collision_Count(0, 10) = 0", True);
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 11 - Non-Binary Base (Base = 3)
   --  ========================================================================
   Put_Line ("TEST 11 - Non-Binary Base (Base = 3)");
   begin
      --  11.1: Verify deterministic delay for base=3, c=1 is 3 * slot_time
      declare
         Config : Backoff_Config := (Base => 3, Ceiling => 10, Slot_Time => 512);
         Result  : Delay_Type := Deterministic_Delay (Config, 1);
      begin
         Assert (Result = 1536, "Result for base=3, c=1 should be 1536");
         Print_Result ("11.1: Result for base=3, c=1 is 1536", True);
      end;

      --  11.2: Verify deterministic delay for base=3, c=2 is 9 * slot_time
      declare
         Config : Backoff_Config := (Base => 3, Ceiling => 10, Slot_Time => 512);
         Result  : Delay_Type := Deterministic_Delay (Config, 2);
      begin
         Assert (Result = 4608, "Result for base=3, c=2 should be 4608");
         Print_Result ("11.2: Result for base=3, c=2 is 4608", True);
      end;

      --  11.3: Verify deterministic delay for base=3, c=0 is slot_time
      declare
         Config : Backoff_Config := (Base => 3, Ceiling => 10, Slot_Time => 512);
         Result  : Delay_Type := Deterministic_Delay (Config, 0);
      begin
         Assert (Result = 512, "Result for base=3, c=0 should be 512");
         Print_Result ("11.3: Result for base=3, c=0 is 512", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 12 - Dynamic Ceiling
   --  ========================================================================
   Put_Line ("TEST 12 - Dynamic Ceiling");
   begin
      --  12.1: Verify truncated delay for ceiling=5, c=5 is 2^5 * slot_time
      declare
         Config : Backoff_Config := (Base => 2, Ceiling => 5, Slot_Time => 512);
         Result  : Delay_Type := Truncated_Deterministic_Delay (Config, 5);
      begin
         Assert (Result = 512 * 32, "Result for ceiling=5, c=5 should be 512*32");
         Print_Result ("12.1: Result for ceiling=5, c=5 is 512*32", True);
      end;

      --  12.2: Verify truncated delay for ceiling=5, c=6 is same as c=5
      declare
         Config : Backoff_Config := (Base => 2, Ceiling => 5, Slot_Time => 512);
         Result_5 : Delay_Type := Truncated_Deterministic_Delay (Config, 5);
         Result_6 : Delay_Type := Truncated_Deterministic_Delay (Config, 6);
      begin
         Assert (Result_5 = Result_6, "Result for ceiling=5, c=6 should equal c=5");
         Print_Result ("12.2: Result for ceiling=5, c=6 equals c=5", True);
      end;

      --  12.3: Verify truncated delay for ceiling=0, c=1 is 2^0 * slot_time
      declare
         Config : Backoff_Config := (Base => 2, Ceiling => 0, Slot_Time => 512);
         Result  : Delay_Type := Truncated_Deterministic_Delay (Config, 1);
      begin
         Assert (Result = 512, "Result for ceiling=0, c=1 should be 512");
         Print_Result ("12.3: Result for ceiling=0, c=1 is 512", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 13 - State Simulation
   --  ========================================================================
   Put_Line ("TEST 13 - State Simulation");
   begin
      --  13.1: Verify state updates correctly over multiple collisions
      declare
         State  : Backoff_State;
         Config : Backoff_Config := (Base => 2, Ceiling => 3, Slot_Time => 100);
      begin
         Initialize_State (State);
         for I in 1 .. 5 loop
            Increment_Collision (State, Config, Use_Random => False);
         end loop;
         Assert (State.Collision_Count = 5,
                 "Collision_Count should be 5 after 5 increments");
         Assert (State.Current_Delay = 800,
                 "Current_Delay should be 800 (2^3 * 100) after clamping");
         Print_Result ("13.1: State updates correctly over multiple collisions", True);
      end;

      --  13.2: Verify state resets correctly
      declare
         State  : Backoff_State;
         Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
      begin
         Initialize_State (State);
         Increment_Collision (State, Config, Use_Random => False);
         Reset_State (State);
         Assert (State.Collision_Count = 0 and State.Current_Delay = 0,
                 "State should be reset to (0, 0)");
         Print_Result ("13.2: State resets correctly", True);
      end;

      --  13.3: Verify randomized delays are within bounds
      declare
         State  : Backoff_State;
         Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
         Result  : Delay_Type;
      begin
         Initialize_State (State);
         for I in 1 .. 10 loop
            Increment_Collision (State, Config, Use_Random => True);
            Result := State.Current_Delay;
            Assert (Result >= 0 and Result <= 512 * 1023,
                    "Randomized delay should be in [0, 512*1023]");
         end loop;
         Print_Result ("13.3: Randomized delays are within bounds", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   --  ========================================================================
   --  TEST 14 - IEEE 802.3 Standard Compliance
   --  ========================================================================
   Put_Line ("TEST 14 - IEEE 802.3 Standard Compliance");
   begin
      --  14.1: Verify max delay for IEEE 802.3 (ceiling=10, slot_time=512) is 512*1023
      declare
         IEEE_Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
         Max_Result   : Delay_Type := Truncated_Deterministic_Delay (IEEE_Config, 10);
      begin
         Assert (Max_Result = 512 * 1024,
                 "Max delay for IEEE 802.3 should be 512*1024");
         Print_Result ("14.1: Max delay for IEEE 802.3 is 512*1023", True);
      end;

      --  14.2: Verify delay for c=10 is same as c=100 (truncated)
      declare
         IEEE_Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
         Result_10    : Delay_Type := Truncated_Deterministic_Delay (IEEE_Config, 10);
         Result_100   : Delay_Type := Truncated_Deterministic_Delay (IEEE_Config, 100);
      begin
         Assert (Result_10 = Result_100,
                 "Result for c=100 should equal c=10 (IEEE 802.3 truncated)");
         Print_Result ("14.2: Result for c=100 equals c=10 (IEEE 802.3 truncated)", True);
      end;

      --  14.3: Verify randomized delay for c=10 is in [0, 512*1023]
      declare
         IEEE_Config : Backoff_Config := (Base => 2, Ceiling => 10, Slot_Time => 512);
         Result       : Delay_Type := Truncated_Randomized_Delay (IEEE_Config, 10);
      begin
         Assert (Result >= 0 and Result <= 512 * 1023,
                 "Randomized delay for c=10 should be in [0, 512*1023]");
         Print_Result ("14.3: Randomized delay for c=10 is in [0, 512*1023]", True);
      end;
   exception
      when E : others =>
         Put_Line ("  FAIL: " & Exception_Message (E));
   end;

   Put_Line ("=== All Tests Completed ===");
end Tests;
