-- Test package specification for SSTF algorithm
-- Comprehensive test suite to verify correctness

with SSTF;
use SSTF;

package SSTF_Tests is

   -- Test result type
   type Test_Result is (Pass, Fail, Error);

   -- Maximum test cases
   Max_Test_Cases : constant := 15;
   
   -- Test case record
   type Test_Case is record
      Name        : String(1..50);
      Initial     : Track_Index;
      Request_Count : Integer range 1..10;
      Requests    : Track_Array(1..10);
      Expected    : Track_Array(1..10);
      Result      : Test_Result;
      Actual      : Track_Array(1..10);
   end record;

   -- Array of test cases
   type Test_Case_Array is array (1..Max_Test_Cases) of Test_Case;

   -- Procedure to run all tests
   procedure Run_All_Tests (Results : out Test_Case_Array);

   -- Procedure to print test results
   procedure Print_Results (Results : in Test_Case_Array);

   -- Function to check if all tests passed
   function All_Passed (Results : in Test_Case_Array) return Boolean;

end SSTF_Tests;
