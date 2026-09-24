-- run_round_robin_tests.adb
-- Main procedure to run the Round Robin test suite

with Round_Robin_Tests;

procedure Run_Round_Robin_Tests is
begin
   Round_Robin_Tests.Run_All_Tests;
end Run_Round_Robin_Tests;
