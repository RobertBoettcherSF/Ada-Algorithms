-- Test Runner for SSTF Algorithm
-- This program runs the comprehensive test suite and reports results

with SSTF_Tests;

procedure Test_Runner is

   Results : SSTF_Tests.Test_Case_Array;

begin
   SSTF_Tests.Run_All_Tests(Results);
   SSTF_Tests.Print_Results(Results);

end Test_Runner;
