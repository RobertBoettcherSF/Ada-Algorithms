-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Cristians_Algorithm; use Cristians_Algorithm;

procedure Tests is
   Standard_Sample   : constant Sync_Sample := (T_Send => 10.0, T_Server => 50.0, T_Recv => 20.0);
   Zero_Delay_Sample : constant Sync_Sample := (T_Send => 5.0,  T_Server => 10.0, T_Recv => 5.0);
   Negative_Sample   : constant Sync_Sample := (T_Send => 20.0, T_Server => 50.0, T_Recv => 10.0);
   
   Multi_Samples : constant Sample_Array(1..3) := (
      1 => (T_Send => 1.0, T_Server => 100.0, T_Recv => 11.0), -- RTT = 10
      2 => (T_Send => 2.0, T_Server => 101.0, T_Recv => 6.0),  -- RTT = 4 (Best)
      3 => (T_Send => 3.0, T_Server => 102.0, T_Recv => 15.0)  -- RTT = 12
   );
   
   Empty_Samples : constant Sample_Array(1..0) := (others => Standard_Sample);
   
begin
   Put_Line ("===================================================");
   Put_Line (" RUNNING CRISTIAN'S ALGORITHM VERIFICATION SUITE");
   Put_Line (" Assuming code is faulty. PASS disproves assumption.");
   Put_Line ("===================================================");

   -- TEST 1: Calculate RTT
   Put_Line ("TEST 1 - RTT Calculation (Normal)");
   Put_Line ("  1.1 [Assertion: Verify RTT is correctly calculated as T_Recv - T_Send]");
   Assert (Calculate_RTT (Standard_Sample) = 10.0, "RTT Calculation failed");
   Put_Line ("      PASS");

   -- TEST 2: RTT Edge Case (Zero Delay)
   Put_Line ("TEST 2 - RTT Calculation (Zero Delay)");
   Put_Line ("  2.1 [Assertion: Verify RTT handles simultaneous send/receive (0s delay)]");
   Assert (Calculate_RTT (Zero_Delay_Sample) = 0.0, "Zero RTT handled incorrectly");
   Put_Line ("      PASS");

   -- TEST 3: Negative Time Guard
   Put_Line ("TEST 3 - Time Travel / Causality Check");
   Put_Line ("  3.1 [Assertion: Verify receive time before send time raises Invalid_Time_Error]");
   begin
      declare
         Dummy : Time_Delta := Calculate_RTT (Negative_Sample);
      begin
         Assert (False, "Expected Invalid_Time_Error, none raised");
      end;
   exception
      when Invalid_Time_Error => Put_Line ("      PASS");
   end;

   -- TEST 4: Basic Synchronization
   Put_Line ("TEST 4 - Basic Synchronization Math");
   Put_Line ("  4.1 [Assertion: Verify Synchronize_Basic yields correct time (50.0 + 10.0/2 = 55.0)]");
   Assert (Synchronize_Basic (Standard_Sample) = 55.0, "Basic Sync Math failed");
   Put_Line ("      PASS");

   -- TEST 5: Threshold Validation (Accepted)
   Put_Line ("TEST 5 - Threshold Sync (Valid bounds)");
   Put_Line ("  5.1 [Assertion: Verify sample is accepted when RTT < Max_RTT]");
   Assert (Synchronize_With_Threshold (Standard_Sample, 15.0) = 55.0, "Valid threshold rejected");
   Put_Line ("      PASS");

   -- TEST 6: Threshold Validation (Exact Bound)
   Put_Line ("TEST 6 - Threshold Sync (Boundary condition)");
   Put_Line ("  6.1 [Assertion: Verify sample is accepted when RTT == Max_RTT]");
   Assert (Synchronize_With_Threshold (Standard_Sample, 10.0) = 55.0, "Boundary threshold rejected");
   Put_Line ("      PASS");

   -- TEST 7: Threshold Validation (Rejected Outlier)
   Put_Line ("TEST 7 - Threshold Sync (Outlier rejection)");
   Put_Line ("  7.1 [Assertion: Verify sample is rejected and raises Outlier_Error when RTT > Max_RTT]");
   begin
      declare
         Dummy : Timestamp := Synchronize_With_Threshold (Standard_Sample, 5.0);
      begin
         Assert (False, "Expected Outlier_Error, none raised");
      end;
   exception
      when Outlier_Error => Put_Line ("      PASS");
   end;

   -- TEST 8: Multi-Sample Selection
   Put_Line ("TEST 8 - Multiple Samples Optimization");
   Put_Line ("  8.1 [Assertion: Verify Synchronize_Multiple selects sample with minimum RTT]");
   -- Sample 2 has RTT=4. Time calculation: Server (101.0) + RTT/2 (2.0) = 103.0
   Assert (Synchronize_Multiple (Multi_Samples) = 103.0, "Multi-Sample selected wrong RTT");
   Put_Line ("      PASS");

   -- TEST 9: Multi-Sample with single element
   Put_Line ("TEST 9 - Multiple Samples (Single element array)");
   Put_Line ("  9.1 [Assertion: Verify array of length 1 resolves correctly]");
   declare
      Single_Array : constant Sample_Array(1..1) := (1 => Standard_Sample);
   begin
      Assert (Synchronize_Multiple (Single_Array) = 55.0, "Single element array failed");
      Put_Line ("      PASS");
   end;

   -- TEST 10: Multi-Sample Empty Array
   Put_Line ("TEST 10 - Multiple Samples (Empty Array Protection)");
   Put_Line ("  10.1 [Assertion: Verify empty array raises No_Valid_Samples_Error]");
   begin
      declare
         Dummy : Timestamp := Synchronize_Multiple (Empty_Samples);
      begin
         Assert (False, "Expected No_Valid_Samples_Error for empty array");
      end;
   exception
      when No_Valid_Samples_Error => Put_Line ("      PASS");
   end;

   -- TEST 11: Error Bound Calculation (Standard)
   Put_Line ("TEST 11 - Error Bound Math");
   Put_Line ("  11.1 [Assertion: Verify Error Bound equals ±(RTT - Min_Delay)/2]");
   -- Standard_Sample RTT=10.0. Min_Delay=2.0. Error = (10 - 2) / 2 = 4.0
   Assert (Calculate_Error_Bound (Standard_Sample, 2.0) = 4.0, "Error Bound Math Failed");
   Put_Line ("      PASS");

   -- TEST 12: Error Bound Calculation (Zero Min Delay)
   Put_Line ("TEST 12 - Error Bound Math (No minimum delay)");
   Put_Line ("  12.1 [Assertion: Verify Error Bound equals RTT/2 when min delay is 0]");
   Assert (Calculate_Error_Bound (Standard_Sample, 0.0) = 5.0, "Zero Delay Error Bound Failed");
   Put_Line ("      PASS");

   -- TEST 13: Error Bound Physics Violation
   Put_Line ("TEST 13 - Error Bound Safety Guard");
   Put_Line ("  13.1 [Assertion: Verify Min_Delay > RTT raises Invalid_Delay_Error]");
   begin
      declare
         Dummy : Time_Delta := Calculate_Error_Bound (Standard_Sample, 15.0); -- 15 > 10
      begin
         Assert (False, "Expected Invalid_Delay_Error, none raised");
      end;
   exception
      when Invalid_Delay_Error => Put_Line ("      PASS");
   end;

   -- TEST 14: Error Bound Zero RTT Check
   Put_Line ("TEST 14 - Error Bound (Zero RTT Edge Case)");
   Put_Line ("  14.1 [Assertion: Verify Error Bound is exactly 0.0 when RTT and Min Delay are 0.0]");
   Assert (Calculate_Error_Bound (Zero_Delay_Sample, 0.0) = 0.0, "Zero RTT Error Bound failed");
   Put_Line ("      PASS");

   Put_Line ("===================================================");
   Put_Line (" ALL TESTS PASSED. CODEBASE VERIFIED.");
   Put_Line ("===================================================");
end Tests;
