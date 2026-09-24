--  tests.adb
--  
--  Test suite for the Exponential Backoff algorithm.
--  
--  This file contains 13+ tests that assume the code is broken.
--  Tests PASS when they disprove this assumption (code works correctly).
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2025

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Exponential_Backoff; use Exponential_Backoff;

procedure Tests is

   --  Helper procedure to print test results
   procedure Print_Result (Test_Name : String; Passed : Boolean) is
   begin
      if Passed then
         Put_Line("     PASS");
      else
         Put_Line("     FAIL");
      end if;
   end Print_Result;

   --  Default configuration for tests
   Test_Config : Backoff_Config := 
     (Base => 2, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);

begin
   Put_Line("=== Exponential Backoff Test Suite ===");
   Put_Line("Assumption: The code is broken. Tests PASS when they disprove this.");
   New_Line;

   --  === TEST 1: Deterministic Backoff - Basic Functionality ===
   Put_Line("TEST 1 - Deterministic Backoff (Basic Functionality)");
   
   --  1.1: Verify delay for 0 collisions is Initial_Delay (1)
   declare
      Result : Delay_Type := Deterministic_Backoff(Test_Config, 0);
   begin
      Put_Line("  1.1 Assert delay for 0 collisions = Initial_Delay (1)");
      Assert (Result = 1, "Delay for 0 collisions should be 1");
      Print_Result("1.1", True);
   exception
      when others =>
         Print_Result("1.1", False);
   end;

   --  1.2: Verify delay for 1 collision is Base^1 * Initial_Delay (2)
   declare
      Result : Delay_Type := Deterministic_Backoff(Test_Config, 1);
   begin
      Put_Line("  1.2 Assert delay for 1 collision = 2");
      Assert (Result = 2, "Delay for 1 collision should be 2");
      Print_Result("1.2", True);
   exception
      when others =>
         Print_Result("1.2", False);
   end;

   --  1.3: Verify delay for 2 collisions is Base^2 * Initial_Delay (4)
   declare
      Result : Delay_Type := Deterministic_Backoff(Test_Config, 2);
   begin
      Put_Line("  1.3 Assert delay for 2 collisions = 4");
      Assert (Result = 4, "Delay for 2 collisions should be 4");
      Print_Result("1.3", True);
   exception
      when others =>
         Print_Result("1.3", False);
   end;

   New_Line;

   --  === TEST 2: Deterministic Backoff - Edge Cases ===
   Put_Line("TEST 2 - Deterministic Backoff (Edge Cases)");
   
   --  2.1: Verify delay for Max_Retries (10) is Base^10 * Initial_Delay (1024)
   declare
      Result : Delay_Type := Deterministic_Backoff(Test_Config, 10);
   begin
      Put_Line("  2.1 Assert delay for 10 collisions = 1024");
      Assert (Result = 1024, "Delay for 10 collisions should be 1024");
      Print_Result("2.1", True);
   exception
      when others =>
         Print_Result("2.1", False);
   end;

   --  2.2: Verify delay for Base = 3, Collision_Count = 2 is 9
   declare
      Config : Backoff_Config := (Base => 3, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);
      Result : Delay_Type := Deterministic_Backoff(Config, 2);
   begin
      Put_Line("  2.2 Assert delay for Base=3, Collision_Count=2 = 9");
      Assert (Result = 9, "Delay should be 9");
      Print_Result("2.2", True);
   exception
      when others =>
         Print_Result("2.2", False);
   end;

   --  2.3: Verify delay for Initial_Delay = 10, Collision_Count = 1 is 20
   declare
      Config : Backoff_Config := (Base => 2, Max_Retries => 10, Initial_Delay => 10, Slot_Time => 512);
      Result : Delay_Type := Deterministic_Backoff(Config, 1);
   begin
      Put_Line("  2.3 Assert delay for Initial_Delay=10, Collision_Count=1 = 20");
      Assert (Result = 20, "Delay should be 20");
      Print_Result("2.3", True);
   exception
      when others =>
         Print_Result("2.3", False);
   end;

   New_Line;

   --  === TEST 3: Randomized Backoff - Basic Functionality ===
   Put_Line("TEST 3 - Randomized Backoff (Basic Functionality)");
   
   --  3.1: Verify delay is within [0, Base^Collision_Count - 1] * Slot_Time
   declare
      Result : Delay_Type := Randomized_Backoff(Test_Config, 2);
      Max_Delay : Delay_Type := (2**2 - 1) * 512; --  3 * 512 = 1536
   begin
      Put_Line("  3.1 Assert delay for 2 collisions is in [0, 1536]");
      Assert (Result <= Max_Delay, "Delay should be <= 1536");
      Print_Result("3.1", True);
   exception
      when others =>
         Print_Result("3.1", False);
   end;

   --  3.2: Verify delay for 0 collisions is in [0, 0] (always 0)
   declare
      Result : Delay_Type := Randomized_Backoff(Test_Config, 0);
   begin
      Put_Line("  3.2 Assert delay for 0 collisions = 0");
      Assert (Result = 0, "Delay for 0 collisions should be 0");
      Print_Result("3.2", True);
   exception
      when others =>
         Print_Result("3.2", False);
   end;

   --  3.3: Verify delay is non-negative
   declare
      Result : Delay_Type := Randomized_Backoff(Test_Config, 5);
   begin
      Put_Line("  3.3 Assert delay is non-negative");
      Assert (Result >= 0, "Delay should be non-negative");
      Print_Result("3.3", True);
   exception
      when others =>
         Print_Result("3.3", False);
   end;

   New_Line;

   --  === TEST 4: Truncated Backoff - Basic Functionality ===
   Put_Line("TEST 4 - Truncated Backoff (Basic Functionality)");
   
   --  4.1: Verify delay for Collision_Count < Max_Retries is unchanged
   declare
      Result : Delay_Type := Truncated_Backoff(Test_Config, 5);
      Expected_Delay : Delay_Type := 2**5 * 1; --  32
   begin
      Put_Line("  4.1 Assert delay for 5 collisions (Max_Retries=10) = 32");
      Assert (Result = Expected_Delay, "Delay should be 32");
      Print_Result("4.1", True);
   exception
      when others =>
         Print_Result("4.1", False);
   end;

   --  4.2: Verify delay for Collision_Count = Max_Retries is capped
   declare
      Result : Delay_Type := Truncated_Backoff(Test_Config, 10);
      Expected_Delay : Delay_Type := 2**10 * 1; --  1024
   begin
      Put_Line("  4.2 Assert delay for 10 collisions (Max_Retries=10) = 1024");
      Assert (Result = Expected_Delay, "Delay should be 1024");
      Print_Result("4.2", True);
   exception
      when others =>
         Print_Result("4.2", False);
   end;

   --  4.3: Verify delay for Collision_Count > Max_Retries is capped
   declare
      Result : Delay_Type := Truncated_Backoff(Test_Config, 15);
      Expected_Delay : Delay_Type := 2**10 * 1; --  1024 (capped)
   begin
      Put_Line("  4.3 Assert delay for 15 collisions (Max_Retries=10) = 1024");
      Assert (Result = Expected_Delay, "Delay should be capped at 1024");
      Print_Result("4.3", True);
   exception
      when others =>
         Print_Result("4.3", False);
   end;

   New_Line;

   --  === TEST 5: Binary Exponential Backoff (BEB) ===
   Put_Line("TEST 5 - Binary Exponential Backoff (BEB)");
   
   --  5.1: Verify BEB for 0 collisions is Slot_Time (512)
   declare
      Result : Delay_Type := Binary_Exponential_Backoff(0);
   begin
      Put_Line("  5.1 Assert BEB delay for 0 collisions = 512");
      Assert (Result = 512, "BEB delay for 0 collisions should be 512");
      Print_Result("5.1", True);
   exception
      when others =>
         Print_Result("5.1", False);
   end;

   --  5.2: Verify BEB for 1 collision is 2 * Slot_Time (1024)
   declare
      Result : Delay_Type := Binary_Exponential_Backoff(1);
   begin
      Put_Line("  5.2 Assert BEB delay for 1 collision = 1024");
      Assert (Result = 1024, "BEB delay for 1 collision should be 1024");
      Print_Result("5.2", True);
   exception
      when others =>
         Print_Result("5.2", False);
   end;

   --  5.3: Verify BEB for custom Slot_Time
   declare
      Result : Delay_Type := Binary_Exponential_Backoff(1, 1000);
   begin
      Put_Line("  5.3 Assert BEB delay for 1 collision with Slot_Time=1000 = 2000");
      Assert (Result = 2000, "BEB delay should be 2000");
      Print_Result("5.3", True);
   exception
      when others =>
         Print_Result("5.3", False);
   end;

   New_Line;

   --  === TEST 6: Adaptive Backoff (Heuristic RCP) ===
   Put_Line("TEST 6 - Adaptive Backoff (Heuristic RCP)");
   
   --  6.1: Verify K(0) = 1
   declare
      Result : Delay_Type := Adaptive_Backoff(0);
   begin
      Put_Line("  6.1 Assert Adaptive_Backoff(0) = 1");
      Assert (Result = 1, "Adaptive backoff for 0 collisions should be 1");
      Print_Result("6.1", True);
   exception
      when others =>
         Print_Result("6.1", False);
   end;

   --  6.2: Verify K(1) = 10
   declare
      Result : Delay_Type := Adaptive_Backoff(1);
   begin
      Put_Line("  6.2 Assert Adaptive_Backoff(1) = 10");
      Assert (Result = 10, "Adaptive backoff for 1 collision should be 10");
      Print_Result("6.2", True);
   exception
      when others =>
         Print_Result("6.2", False);
   end;

   --  6.3: Verify K(2) = 100
   declare
      Result : Delay_Type := Adaptive_Backoff(2);
   begin
      Put_Line("  6.3 Assert Adaptive_Backoff(2) = 100");
      Assert (Result = 100, "Adaptive backoff for 2 collisions should be 100");
      Print_Result("6.3", True);
   exception
      when others =>
         Print_Result("6.3", False);
   end;

   New_Line;

   --  === TEST 7: Expected Backoff ===
   Put_Line("TEST 7 - Expected Backoff");
   
   --  7.1: Verify E(0) = 0
   declare
      Expected : Delay_Type := Expected_Backoff(0);
   begin
      Put_Line("  7.1 Assert Expected_Backoff(0) = 0");
      Assert (Expected = 0, "Expected backoff for 0 collisions should be 0");
      Print_Result("7.1", True);
   exception
      when others =>
         Print_Result("7.1", False);
   end;

   --  7.2: Verify E(1) = (2^1 - 1)/2 = 0
   declare
      Expected : Delay_Type := Expected_Backoff(1);
   begin
      Put_Line("  7.2 Assert Expected_Backoff(1) = 0");
      Assert (Expected = 0, "Expected backoff for 1 collision should be 0");
      Print_Result("7.2", True);
   exception
      when others =>
         Print_Result("7.2", False);
   end;

   --  7.3: Verify E(3) = (2^3 - 1)/2 = 3
   declare
      Expected : Delay_Type := Expected_Backoff(3);
   begin
      Put_Line("  7.3 Assert Expected_Backoff(3) = 3");
      Assert (Expected = 3, "Expected backoff for 3 collisions should be 3");
      Print_Result("7.3", True);
   exception
      when others =>
         Print_Result("7.3", False);
   end;

   New_Line;

   --  === TEST 8: Recovery Mechanism ===
   Put_Line("TEST 8 - Recovery Mechanism");
   
   --  8.1: Verify Reset_Backoff returns 0 when Cooling_Off = True
   declare
      Reset_Count : Collision_Count_Type := Reset_Backoff(5, True);
   begin
      Put_Line("  8.1 Assert Reset_Backoff(5, True) = 0");
      Assert (Reset_Count = 0, "Reset backoff should return 0 when cooling off");
      Print_Result("8.1", True);
   exception
      when others =>
         Print_Result("8.1", False);
   end;

   --  8.2: Verify Reset_Backoff returns unchanged count when Cooling_Off = False
   declare
      Reset_Count : Collision_Count_Type := Reset_Backoff(5, False);
   begin
      Put_Line("  8.2 Assert Reset_Backoff(5, False) = 5");
      Assert (Reset_Count = 5, "Reset backoff should return 5 when not cooling off");
      Print_Result("8.2", True);
   exception
      when others =>
         Print_Result("8.2", False);
   end;

   --  8.3: Verify Reset_Backoff works for count = 0
   declare
      Reset_Count : Collision_Count_Type := Reset_Backoff(0, True);
   begin
      Put_Line("  8.3 Assert Reset_Backoff(0, True) = 0");
      Assert (Reset_Count = 0, "Reset backoff for 0 should return 0");
      Print_Result("8.3", True);
   exception
      when others =>
         Print_Result("8.3", False);
   end;

   New_Line;

   --  === TEST 9: Helper Functions ===
   Put_Line("TEST 9 - Helper Functions");
   
   --  9.1: Verify Compute_Power(2, 3) = 8
   declare
      Power : Delay_Type := Compute_Power(2, 3);
   begin
      Put_Line("  9.1 Assert Compute_Power(2, 3) = 8");
      Assert (Power = 8, "Compute_Power(2, 3) should be 8");
      Print_Result("9.1", True);
   exception
      when others =>
         Print_Result("9.1", False);
   end;

   --  9.2: Verify Compute_Power(3, 2) = 9
   declare
      Power : Delay_Type := Compute_Power(3, 2);
   begin
      Put_Line("  9.2 Assert Compute_Power(3, 2) = 9");
      Assert (Power = 9, "Compute_Power(3, 2) should be 9");
      Print_Result("9.2", True);
   exception
      when others =>
         Print_Result("9.2", False);
   end;

   --  9.3: Verify Compute_Power(Base, 0) = 1 for any Base
   declare
      Power : Delay_Type := Compute_Power(5, 0);
   begin
      Put_Line("  9.3 Assert Compute_Power(5, 0) = 1");
      Assert (Power = 1, "Compute_Power(Base, 0) should be 1");
      Print_Result("9.3", True);
   exception
      when others =>
         Print_Result("9.3", False);
   end;

   New_Line;

   --  === TEST 10: Invalid Input Handling ===
   Put_Line("TEST 10 - Invalid Input Handling");
   
   --  10.1: Verify Validate_Config does not raise for valid Base
   declare
      Config : Backoff_Config := (Base => 2, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);
   begin
      Put_Line("  10.1 Assert Validate_Config does not raise for Base=2");
      Validate_Config(Config);
      Print_Result("10.1", True);
   exception
      when Invalid_Base =>
         Print_Result("10.1", False);
      when others =>
         Print_Result("10.1", False);
   end;

   --  10.2: Verify Validate_Config does not raise for Base >= 2
   declare
   begin
      Put_Line("  10.2 Assert Validate_Config does not raise for Base=2");
      Validate_Config(Test_Config);
      Print_Result("10.2", True);
   exception
      when others =>
         Print_Result("10.2", False);
   end;

   --  10.3: Verify Random_Delay returns a value in [0, Max_Value]
   declare
      Result : Delay_Type := Random_Delay(100);
   begin
      Put_Line("  10.3 Assert Random_Delay(100) is in [0, 100]");
      Assert (Result >= 0 and Result <= 100, "Random_Delay should be in [0, 100]");
      Print_Result("10.3", True);
   exception
      when others =>
         Print_Result("10.3", False);
   end;

   New_Line;

   --  === TEST 11: Edge Cases for All Variants ===
   Put_Line("TEST 11 - Edge Cases for All Variants");
   
   --  11.1: Verify all variants handle Collision_Count = 0
   declare
      Result1 : Delay_Type := Deterministic_Backoff(Test_Config, 0);
      Result2 : Delay_Type := Randomized_Backoff(Test_Config, 0);
      Result3 : Delay_Type := Truncated_Backoff(Test_Config, 0);
      Result4 : Delay_Type := Binary_Exponential_Backoff(0);
      Result5 : Delay_Type := Adaptive_Backoff(0);
      Result6 : Delay_Type := Expected_Backoff(0);
   begin
      Put_Line("  11.1 Assert all variants handle Collision_Count=0");
      Assert (Result1 = 1 and Result2 = 0 and Result3 = 1 and Result4 = 512 and Result5 = 1 and Result6 = 0,
              "All variants should handle Collision_Count=0");
      Print_Result("11.1", True);
   exception
      when others =>
         Print_Result("11.1", False);
   end;

   --  11.2: Verify Truncated_Backoff caps at Max_Retries = 1
   declare
      Config : Backoff_Config := (Base => 2, Max_Retries => 1, Initial_Delay => 1, Slot_Time => 512);
      Result : Delay_Type := Truncated_Backoff(Config, 100);
   begin
      Put_Line("  11.2 Assert Truncated_Backoff caps at Max_Retries=1");
      Assert (Result = 2, "Delay should be capped at 2 (2^1 * 1)");
      Print_Result("11.2", True);
   exception
      when others =>
         Print_Result("11.2", False);
   end;

   --  11.3: Verify Binary_Exponential_Backoff with Slot_Time=1
   declare
      Result : Delay_Type := Binary_Exponential_Backoff(3, 1);
   begin
      Put_Line("  11.3 Assert Binary_Exponential_Backoff(3, 1) = 8");
      Assert (Result = 8, "Delay should be 8 (2^3 * 1)");
      Print_Result("11.3", True);
   exception
      when others =>
         Print_Result("11.3", False);
   end;

   New_Line;

   --  === TEST 12: Consistency Across Variants ===
   Put_Line("TEST 12 - Consistency Across Variants");
   
   --  12.1: Verify Deterministic_Backoff and Binary_Exponential_Backoff match for Base=2
   declare
      Result1 : Delay_Type := Deterministic_Backoff(Test_Config, 3);
      Result2 : Delay_Type := Binary_Exponential_Backoff(3, 1);
   begin
      Put_Line("  12.1 Assert Deterministic_Backoff and BEB match for Base=2");
      Assert (Result1 = Result2, "Deterministic and BEB should match for Base=2");
      Print_Result("12.1", True);
   exception
      when others =>
         Print_Result("12.1", False);
   end;

   --  12.2: Verify Truncated_Backoff matches Deterministic_Backoff for Collision_Count <= Max_Retries
   declare
      Result1 : Delay_Type := Deterministic_Backoff(Test_Config, 5);
      Result2 : Delay_Type := Truncated_Backoff(Test_Config, 5);
   begin
      Put_Line("  12.2 Assert Truncated_Backoff matches Deterministic_Backoff for c <= Max_Retries");
      Assert (Result1 = Result2, "Truncated and Deterministic should match for c <= Max_Retries");
      Print_Result("12.2", True);
   exception
      when others =>
         Print_Result("12.2", False);
   end;

   --  12.3: Verify Expected_Backoff for Base=2 matches (2^c - 1)/2
   declare
      Expected : Delay_Type := Expected_Backoff(4, 2);
   begin
      Put_Line("  12.3 Assert Expected_Backoff(4, 2) = 7");
      Assert (Expected = 7, "Expected backoff for c=4, Base=2 should be 7");
      Print_Result("12.3", True);
   exception
      when others =>
         Print_Result("12.3", False);
   end;

   New_Line;

   --  === TEST 13: Performance and Scalability ===
   Put_Line("TEST 13 - Performance and Scalability");
   
   --  13.1: Verify Compute_Power handles large exponents (e.g., 2^20)
   declare
      Power : Delay_Type := Compute_Power(2, 20);
   begin
      Put_Line("  13.1 Assert Compute_Power(2, 20) = 1048576");
      Assert (Power = 1_048_576, "Compute_Power(2, 20) should be 1048576");
      Print_Result("13.1", True);
   exception
      when others =>
         Print_Result("13.1", False);
   end;

   --  13.2: Verify Deterministic_Backoff handles large Collision_Count
   declare
      Config : Backoff_Config := (Base => 2, Max_Retries => 100, Initial_Delay => 1, Slot_Time => 512);
      Result : Delay_Type := Deterministic_Backoff(Config, 20);
   begin
      Put_Line("  13.2 Assert Deterministic_Backoff handles Collision_Count=20");
      Assert (Result = 1_048_576, "Delay should be 1048576");
      Print_Result("13.2", True);
   exception
      when others =>
         Print_Result("13.2", False);
   end;

   --  13.3: Verify Truncated_Backoff handles Collision_Count > Max_Retries gracefully
   declare
      Config : Backoff_Config := (Base => 2, Max_Retries => 5, Initial_Delay => 1, Slot_Time => 512);
      Result : Delay_Type := Truncated_Backoff(Config, 100);
   begin
      Put_Line("  13.3 Assert Truncated_Backoff handles Collision_Count=100 (Max_Retries=5)");
      Assert (Result = 32, "Delay should be capped at 32 (2^5 * 1)");
      Print_Result("13.3", True);
   exception
      when others =>
         Print_Result("13.3", False);
   end;

   New_Line;
   Put_Line("=== Test Suite Complete ===");
   Put_Line("All tests assume the code is broken. PASS = assumption disproven (code works).");

end Tests;
