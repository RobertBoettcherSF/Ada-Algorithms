-- tests.adb
-- Validation and Verification (V&V) suite for the Berkeley Algorithm.
-- Assumes codebase has defects; PASS indicates the assumption was proven false.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Berkeley_Algorithm; use Berkeley_Algorithm;

procedure Tests is

   -- Helper to print test headers
   procedure Print_Header (Msg : String) is
   begin
      Put_Line ("==================================================");
      Put_Line (Msg);
   end Print_Header;

   -- Helper to print test assertions
   procedure Print_Assert (Msg : String) is
   begin
      Put_Line ("  [VERIFY] " & Msg);
   end Print_Assert;

   procedure Print_Pass is
   begin
      Put_Line ("  -> PASS");
   end Print_Pass;

begin
   Print_Header ("TEST 1 - Baseline Functionality (No Slaves)");
   declare
      Slaves     : Slave_Array (1 .. 0); -- Empty
      Offsets    : Offset_Array (1 .. 0);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("1.1 Handles empty slave array without divide-by-zero");
      Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
      Assert (Master_Adj = 0, "Master adj should be 0 when alone");
      Print_Pass;
   end;

   Print_Header ("TEST 2 - Single Synchronized Slave");
   declare
      Slaves     : Slave_Array := (1 => (ID => 1, Reported_Time => 1000, Round_Trip_Time => 0));
      Offsets    : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("2.1 Offset should be 0 for perfectly synchronized slave");
      Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
      Assert (Master_Adj = 0, "Master should not adjust");
      Assert (Offsets(1).Offset = 0, "Slave should not adjust");
      Print_Pass;
   end;

   Print_Header ("TEST 3 - RTT Compensation Validation");
   declare
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 990, Round_Trip_Time => 20));
      -- Estimated time = 990 + (20/2) = 1000
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("3.1 Correctly uses RTT/2 to calculate estimated slave time");
      Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
      Assert (Master_Adj = 0, "Master shouldn't adjust if RTT compensates perfectly");
      Assert (Offsets(1).Offset = 0, "Slave shouldn't adjust");
      Print_Pass;
   end;

   Print_Header ("TEST 4 - Standard Multi-Node Averaging");
   declare
      Slaves : Slave_Array := (
         1 => (ID => 1, Reported_Time => 990, Round_Trip_Time => 0),
         2 => (ID => 2, Reported_Time => 1020, Round_Trip_Time => 0)
      );
      -- Master=1000, S1=990, S2=1020. Avg = (1000+990+1020)/3 = 1003 (truncates)
      Offsets : Offset_Array (1 .. 2);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("4.1 Averages multiple positive/negative drifts correctly");
      Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
      Assert (Master_Adj = 3, "Master adj should be +3");
      Assert (Offsets(1).Offset = 13, "S1 adj should be +13");
      Assert (Offsets(2).Offset = -17, "S2 adj should be -17");
      Print_Pass;
   end;

   Print_Header ("TEST 5 - Negative RTT Edge Case (Error Handling)");
   begin
      Print_Assert ("5.1 Raises Invalid_Data_Error on Negative RTT");
      declare
         Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 1000, Round_Trip_Time => -10));
         Offsets : Offset_Array (1 .. 1);
         Master_Adj : Time_Offset;
      begin
         Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Data_Error => Print_Pass;
   end;

   Print_Header ("TEST 6 - Fault-Tolerant Outlier Rejection");
   declare
      Slaves : Slave_Array := (
         1 => (ID => 1, Reported_Time => 1000, Round_Trip_Time => 0),
         2 => (ID => 2, Reported_Time => 5000, Round_Trip_Time => 0) -- Outlier
      );
      Offsets : Offset_Array (1 .. 2);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("6.1 Ignores clocks outside of Max_Tolerance");
      Calculate_Fault_Tolerant_Offsets (1000, Slaves, 100, Master_Adj, Offsets);
      -- Avg should be (1000+1000) / 2 = 1000. Outlier 5000 is rejected.
      Assert (Master_Adj = 0, "Master should ignore outlier");
      Assert (Offsets(2).Offset = -4000, "Outlier receives heavy correction");
      Print_Pass;
   end;

   Print_Header ("TEST 7 - Fault-Tolerant All Outliers");
   declare
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 9999, Round_Trip_Time => 0));
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("7.1 System remains stable when ALL slaves are outliers");
      Calculate_Fault_Tolerant_Offsets (1000, Slaves, 10, Master_Adj, Offsets);
      Assert (Master_Adj = 0, "Master relies on itself");
      Print_Pass;
   end;

   Print_Header ("TEST 8 - Exact Max Tolerance Boundary");
   declare
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 1010, Round_Trip_Time => 0));
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("8.1 Includes slave exactly AT Max_Tolerance");
      Calculate_Fault_Tolerant_Offsets (1000, Slaves, 10, Master_Adj, Offsets);
      -- Avg of 1000 and 1010 = 1005
      Assert (Master_Adj = 5, "Should include borderline slave");
      Print_Pass;
   end;

   Print_Header ("TEST 9 - Fault-Tolerant Negative Tolerance");
   begin
      Print_Assert ("9.1 Raises Invalid_Data_Error on negative max tolerance");
      declare
         Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 1000, Round_Trip_Time => 0));
         Offsets : Offset_Array (1 .. 1);
         Master_Adj : Time_Offset;
      begin
         Calculate_Fault_Tolerant_Offsets (1000, Slaves, -5, Master_Adj, Offsets);
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Data_Error => Print_Pass;
   end;

   Print_Header ("TEST 10 - Extreme Values (Overflow Protection)");
   declare
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 9_000_000_000, Round_Trip_Time => 0));
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("10.1 Calculates correctly with massive timestamps (Long_Long_Integer)");
      Calculate_Offsets (9_000_000_000, Slaves, Master_Adj, Offsets);
      Assert (Master_Adj = 0, "No adjustment needed for exact match");
      Print_Pass;
   end;

   Print_Header ("TEST 11 - RTT Truncation Logic");
   declare
      -- RTT 5. RTT/2 = 2. Estimated slave time = 1000 + 2 = 1002.
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 1000, Round_Trip_Time => 5));
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("11.1 Validates integer division truncation in RTT/2");
      Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
      -- Master: 1000, Slave Est: 1002. Avg: 1001. Master adj: 1, Slave adj: 1001 - 1002 = -1.
      Assert (Master_Adj = 1, "Master should adjust +1");
      Assert (Offsets(1).Offset = -1, "Slave should adjust -1");
      Print_Pass;
   end;

   Print_Header ("TEST 12 - Master Time 0");
   declare
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 100, Round_Trip_Time => 0));
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("12.1 Calculates gracefully when Master time is 0");
      Calculate_Offsets (0, Slaves, Master_Adj, Offsets);
      -- Avg: 50. Master Adj: 50. Slave adj: -50.
      Assert (Master_Adj = 50, "Master offset should be 50");
      Assert (Offsets(1).Offset = -50, "Slave offset should be -50");
      Print_Pass;
   end;

   Print_Header ("TEST 13 - Standard Vulnerability Proof (vs Fault Tolerant)");
   declare
      Slaves : Slave_Array := (1 => (ID => 1, Reported_Time => 100_000, Round_Trip_Time => 0));
      Offsets : Offset_Array (1 .. 1);
      Master_Adj : Time_Offset;
   begin
      Print_Assert ("13.1 Standard variant is heavily skewed by a single extreme outlier");
      Calculate_Offsets (1000, Slaves, Master_Adj, Offsets);
      -- Avg: 50500. Master moves completely out of sync.
      Assert (Master_Adj = 49500, "Master ruined by outlier");
      Print_Pass;
   end;

   Put_Line ("");
   Put_Line ("==================================================");
   Put_Line ("ALL 13 TESTS PASSED SUCCESSFULLY");
   Put_Line ("CODE ASSUMPTION DISPROVEN: IMPLEMENTATION IS VALID.");
   Put_Line ("==================================================");

end Tests;
