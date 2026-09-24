with Clock_Algorithms; use Clock_Algorithms;
with Ada.Text_IO; use Ada.Text_IO;

package body Clock_Tests is

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if not Condition then
         Failed_Tests := Failed_Tests + 1;
         Put_Line("  [FAIL] " & Message);
      else
         Put_Line("  [PASS] " & Message);
      end if;
   end Assert;

   procedure Assert_Equal (Actual, Expected : Natural; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Actual = Expected then
         Put_Line("  [PASS] " & Message & " (Expected: " & Natural'Image(Expected) & 
                  ", Actual: " & Natural'Image(Actual) & ")");
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line("  [FAIL] " & Message & " (Expected: " & Natural'Image(Expected) & 
                  ", Actual: " & Natural'Image(Actual) & ")");
      end if;
   end Assert_Equal;

   procedure Assert_Equal (Actual, Expected : Float; Message : String; Tolerance : Float := 0.001) is
   begin
      Total_Tests := Total_Tests + 1;
      if abs(Actual - Expected) <= Tolerance then
         Put_Line("  [PASS] " & Message & " (Expected: " & Float'Image(Expected) & 
                  ", Actual: " & Float'Image(Actual) & ")");
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line("  [FAIL] " & Message & " (Expected: " & Float'Image(Expected) & 
                  ", Actual: " & Float'Image(Actual) & ")");
      end if;
   end Assert_Equal;


   -- ========================================================
   -- Test 1: Standard Clock Algorithm
   -- ========================================================

   procedure Test_Clock_Empty_Access is
      Algo : constant Clock_Algo := Init_Clock(3);
   begin
      New_Line;
      Put_Line("Test 1: Standard Clock Algorithm");
      Put_Line("  1.1: Empty access sequence");
      
      Assert_Equal(Get_Page_Faults(Algo), 0, "Empty access = 0 page faults");
      Assert_Equal(Get_Hit_Rate(Algo), 0.0, "Empty access = 0% hit rate");
      Passed_Tests := Passed_Tests + 1;
   end Test_Clock_Empty_Access;

   procedure Test_Clock_Single_Page is
      Algo : Clock_Algo := Init_Clock(3);
   begin
      New_Line;
      Put_Line("  1.2: Single page repeated access");
      
      for I in 1..5 loop
         Access_Page(Algo, 1);
      end loop;
      
      Assert_Equal(Get_Page_Faults(Algo), 1, "Single page = 1 page fault");
      Assert_Equal(Get_Hit_Rate(Algo), 0.8, "Single page = 80% hit rate");
      Passed_Tests := Passed_Tests + 1;
   end Test_Clock_Single_Page;

   procedure Test_Clock_Page_Faults is
      Algo : Clock_Algo := Init_Clock(3);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
   begin
      Put_Line("  1.3: Page fault counting");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;
      
      Assert_Equal(Get_Page_Faults(Algo), 8, "Reference string = 8 page faults");
      Passed_Tests := Passed_Tests + 1;
   end Test_Clock_Page_Faults;

   procedure Test_Clock_Hit_Rate is
      Algo : Clock_Algo := Init_Clock(3);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 1, 2, 3, 1, 2, 3, 1);
   begin
      Put_Line("  1.4: Hit rate calculation");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;
      
      Assert_Equal(Get_Page_Faults(Algo), 3, "3 unique pages = 3 faults");
      Assert_Equal(Get_Hit_Rate(Algo), 0.7, "7 hits out of 10 = 70% hit rate");
      Passed_Tests := Passed_Tests + 1;
   end Test_Clock_Hit_Rate;

   procedure Test_Clock_Circular_Replacement is
      Algo : Clock_Algo := Init_Clock(3);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 5, 6, 1, 2, 3, 4);
   begin
      Put_Line("  1.5: Circular replacement behavior");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;
      
      Assert_Equal(Get_Page_Faults(Algo), 10, "All accesses are faults with this sequence");
      Passed_Tests := Passed_Tests + 1;
   end Test_Clock_Circular_Replacement;


   -- ========================================================
   -- Test 2: GCLOCK Algorithm
   -- ========================================================

   procedure Test_GCLOCK_Empty_Access is
      Algo : constant GCLOCK_Algo := Init_GCLOCK(3, 2);
   begin
      New_Line;
      Put_Line("Test 2: GCLOCK Algorithm");
      Put_Line("  2.1: Empty access sequence");
      
      Assert_Equal(Get_Page_Faults(Algo), 0, "Empty access = 0 page faults");
      Assert_Equal(Get_Hit_Rate(Algo), 0.0, "Empty access = 0% hit rate");
      Passed_Tests := Passed_Tests + 1;
   end Test_GCLOCK_Empty_Access;

   procedure Test_GCLOCK_Single_Page is
      Algo : GCLOCK_Algo := Init_GCLOCK(3, 2);
   begin
      Put_Line("  2.2: Single page repeated access");
      
      for I in 1..5 loop
         Access_Page(Algo, 1);
      end loop;
      
      Assert_Equal(Get_Page_Faults(Algo), 1, "Single page = 1 page fault");
      Assert_Equal(Get_Hit_Rate(Algo), 0.8, "Single page = 80% hit rate");
      Passed_Tests := Passed_Tests + 1;
   end Test_GCLOCK_Single_Page;

   procedure Test_GCLOCK_Page_Faults is
      Algo : GCLOCK_Algo := Init_GCLOCK(3, 2);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
   begin
      Put_Line("  2.3: Page fault counting with counter");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;
      
      Assert(Get_Page_Faults(Algo) <= 8, "GCLOCK should have <= 8 faults");
      Passed_Tests := Passed_Tests + 1;
   end Test_GCLOCK_Page_Faults;

   procedure Test_GCLOCK_Counter_Decrement is
      Algo : GCLOCK_Algo := Init_GCLOCK(2, 2);
   begin
      Put_Line("  2.4: Counter decrement on access");
      
      Access_Page(Algo, 1);
      Access_Page(Algo, 2);
      Access_Page(Algo, 3);
      Access_Page(Algo, 1);
      
      Assert_Equal(Get_Page_Faults(Algo), 4, "Should have 4 faults");
      Passed_Tests := Passed_Tests + 1;
   end Test_GCLOCK_Counter_Decrement;

   procedure Test_GCLOCK_Higher_Count_Survival is
      Algo : GCLOCK_Algo := Init_GCLOCK(2, 3);
   begin
      Put_Line("  2.5: Higher count means longer survival");
      
      Access_Page(Algo, 1);
      Access_Page(Algo, 2);
      Access_Page(Algo, 3);
      Access_Page(Algo, 4);
      Access_Page(Algo, 5);
      
      Assert_Equal(Get_Page_Faults(Algo), 5, "Should have 5 faults with Max_Count=3");
      Passed_Tests := Passed_Tests + 1;
   end Test_GCLOCK_Higher_Count_Survival;


   -- ========================================================
   -- Test 3: WSClock Algorithm
   -- ========================================================

   procedure Test_WSClock_Empty_Access is
      Algo : constant WSClock_Algo := Init_WSClock(3, 10);
   begin
      New_Line;
      Put_Line("Test 3: WSClock Algorithm");
      Put_Line("  3.1: Empty access sequence");
      
      Assert_Equal(Get_Page_Faults(Algo), 0, "Empty access = 0 page faults");
      Assert_Equal(Get_Hit_Rate(Algo), 0.0, "Empty access = 0% hit rate");
      Passed_Tests := Passed_Tests + 1;
   end Test_WSClock_Empty_Access;

   procedure Test_WSClock_Recent_Access_Protection is
      Algo : WSClock_Algo := Init_WSClock(3, 5);
   begin
      Put_Line("  3.2: Recent access protection (Tau)");
      
      Access_Page(Algo, 1);
      Access_Page(Algo, 2);
      Access_Page(Algo, 3);
      Access_Page(Algo, 1);
      Access_Page(Algo, 4);
      
      Assert_Equal(Get_Page_Faults(Algo), 4, "Should have 4 faults, page 1 protected");
      Passed_Tests := Passed_Tests + 1;
   end Test_WSClock_Recent_Access_Protection;

   procedure Test_WSClock_Tau_Expiration is
      Algo : WSClock_Algo := Init_WSClock(2, 2);
   begin
      Put_Line("  3.3: Tau expiration behavior");
      
      Access_Page(Algo, 1);
      Access_Page(Algo, 2);
      for I in 1..10 loop
         Access_Page(Algo, 1);
      end loop;
      Access_Page(Algo, 3);
      
      Assert(Get_Page_Faults(Algo) >= 3, "Should have at least 3 faults");
      Passed_Tests := Passed_Tests + 1;
   end Test_WSClock_Tau_Expiration;


   -- ========================================================
   -- Test 4: Comparison Tests
   -- ========================================================

   procedure Test_Clock_vs_GCLOCK is
      Clock_Algo1 : Clock_Algo := Init_Clock(3);
      GCLOCK_Algo1 : GCLOCK_Algo := Init_GCLOCK(3, 2);
      Pages : constant array(1..20) of Page_ID := (1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4);
   begin
      New_Line;
      Put_Line("Test 4: Comparison Tests");
      Put_Line("  4.1: Clock vs GCLOCK - Both produce faults");
      
      for P of Pages loop
         Access_Page(Clock_Algo1, P);
      end loop;
      
      for P of Pages loop
         Access_Page(GCLOCK_Algo1, P);
      end loop;
      
      Assert(Get_Page_Faults(Clock_Algo1) > 0, "Clock should have faults");
      Assert(Get_Page_Faults(GCLOCK_Algo1) > 0, "GCLOCK should have faults");
      Passed_Tests := Passed_Tests + 1;
   end Test_Clock_vs_GCLOCK;

   procedure Test_All_Algorithms_Same_Input is
      Clock_Algo1 : Clock_Algo := Init_Clock(5);
      GCLOCK_Algo1 : GCLOCK_Algo := Init_GCLOCK(5, 2);
      WSClock_Algo1 : WSClock_Algo := Init_WSClock(5, 10);
      Pages : constant array(1..10) of Page_ID := (1,2,3,4,5,1,2,3,4,5);
   begin
      Put_Line("  4.2: All algorithms produce faults");
      
      for P of Pages loop
         Access_Page(Clock_Algo1, P);
      end loop;
      
      for P of Pages loop
         Access_Page(GCLOCK_Algo1, P);
      end loop;
      
      for P of Pages loop
         Access_Page(WSClock_Algo1, P);
      end loop;
      
      Assert(Get_Page_Faults(Clock_Algo1) > 0, "Clock should have faults");
      Assert(Get_Page_Faults(GCLOCK_Algo1) > 0, "GCLOCK should have faults");
      Assert(Get_Page_Faults(WSClock_Algo1) > 0, "WSClock should have faults");
      Passed_Tests := Passed_Tests + 1;
   end Test_All_Algorithms_Same_Input;


   -- ========================================================
   -- Test Runner
   -- ========================================================

   procedure Run_All_Tests is
   begin
      Put_Line("========================================");
      Put_Line("  Clock Replacement Algorithm Tests");
      Put_Line("========================================");
      New_Line;
      
      Total_Tests := 0;
      Passed_Tests := 0;
      Failed_Tests := 0;
      
      Test_Clock_Empty_Access;
      Test_Clock_Single_Page;
      Test_Clock_Page_Faults;
      Test_Clock_Hit_Rate;
      Test_Clock_Circular_Replacement;
      
      Test_GCLOCK_Empty_Access;
      Test_GCLOCK_Single_Page;
      Test_GCLOCK_Page_Faults;
      Test_GCLOCK_Counter_Decrement;
      Test_GCLOCK_Higher_Count_Survival;
      
      Test_WSClock_Empty_Access;
      Test_WSClock_Recent_Access_Protection;
      Test_WSClock_Tau_Expiration;
      
      Test_Clock_vs_GCLOCK;
      Test_All_Algorithms_Same_Input;
      
      Print_Summary;
   end Run_All_Tests;

   procedure Print_Summary is
   begin
      New_Line;
      Put_Line("========================================");
      Put_Line("  Test Summary");
      Put_Line("========================================");
      Put_Line("  Tests:        15");
      Put_Line("  Assertions:   " & Natural'Image(Total_Tests));
      Put_Line("  Passed:       " & Natural'Image(Passed_Tests));
      Put_Line("  Failed:       " & Natural'Image(Failed_Tests));
      
      if Failed_Tests = 0 then
         Put_Line("  Status:       ALL TESTS PASSED!");
      else
         Put_Line("  Status:       SOME TESTS FAILED");
      end if;
      Put_Line("========================================");
   end Print_Summary;

end Clock_Tests;
