-- Version: 0.12
-- Test specifications for Disk Scheduling Algorithms

package Test_Disk_Scheduling is

   -- Test result type
   type Test_Result is (Pass, Fail);
   
   -- Test statistics
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;
   Failed_Tests : Integer := 0;
   
   -- Run all tests
   procedure Run_All_Tests;
   
   -- Test procedures for each algorithm
   procedure Test_SCAN_Algorithm;
   procedure Test_C_SCAN_Algorithm;
   procedure Test_LOOK_Algorithm;
   procedure Test_C_LOOK_Algorithm;
   procedure Test_F_SCAN_Algorithm;
   
   -- Assumption tests
   procedure Test_Assumptions;
   
   -- Tests to be proven false
   procedure Test_Proven_False;
   
   -- Comparison tests
   procedure Test_Comparisons;
   
   -- Edge case tests
   procedure Test_Edge_Cases;

end Test_Disk_Scheduling;
