-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with CHS_Conversion; use CHS_Conversion;

procedure Tests is

   -- Assertion philosophy: We assume the code is broken. 
   -- Tests PASS when they explicitly disprove this assumption.
   procedure Assert_Test (Condition : Boolean; Message : String; Step : String) is
   begin
      Put_Line("  " & Step & " " & Message);
      if Condition then
         Put_Line("      PASS");
      else
         Put_Line("      FAIL - Assumption that code is broken was NOT disproven.");
         raise Program_Error with Message;
      end if;
   end Assert_Test;

   Geo_Standard : constant Disk_Geometry := (C_Total => 1024, H_Total => 16, S_Total => 63);
   Geo_Invalid  : constant Disk_Geometry := (C_Total => 1024, H_Total => 0, S_Total => 63);

   Test_CHS_1 : CHS_Address;
   Test_LBA_1 : LBA_Address;

begin
   Put_Line("Starting Test Suite - Assuming codebase is broken until proven otherwise");
   Put_Line("========================================================================");

   -- TEST 1 - Functionality: Basic CHS to LBA (First block)
   Put_Line("TEST 1 - Basic CHS to LBA (Block 0)");
   Test_LBA_1 := CHS_To_LBA ((C => 0, H => 0, S => 1), Geo_Standard);
   Assert_Test (Test_LBA_1 = 0, "First block 0/0/1 should equal LBA 0", "1.1");

   -- TEST 2 - Functionality: Max CHS for geometry
   Put_Line("TEST 2 - Max CHS to LBA");
   Test_LBA_1 := CHS_To_LBA ((C => 1023, H => 15, S => 63), Geo_Standard);
   Assert_Test (Test_LBA_1 = Get_Max_LBA(Geo_Standard) - 1, "Last CHS mapped to Max LBA - 1", "2.1");

   -- TEST 3 - Functionality: Arbitrary Mid-disk CHS
   Put_Line("TEST 3 - Mid-disk CHS to LBA");
   Test_LBA_1 := CHS_To_LBA ((C => 500, H => 5, S => 10), Geo_Standard);
   Assert_Test (Test_LBA_1 = 504324, "Mid-disk CHS calculated to precise integer value", "3.1");

   -- TEST 4 - Functionality: Basic LBA to CHS
   Put_Line("TEST 4 - Basic LBA to CHS (LBA 0)");
   Test_CHS_1 := LBA_To_CHS (0, Geo_Standard);
   Assert_Test (Test_CHS_1.C = 0 and Test_CHS_1.H = 0 and Test_CHS_1.S = 1, "LBA 0 maps correctly to 0/0/1", "4.1");

   -- TEST 5 - Functionality: Mid-disk LBA to CHS
   Put_Line("TEST 5 - Mid-disk LBA to CHS");
   Test_CHS_1 := LBA_To_CHS (504324, Geo_Standard);
   Assert_Test (Test_CHS_1.C = 500 and Test_CHS_1.H = 5 and Test_CHS_1.S = 10, "LBA 504324 maps inversely to correct CHS", "5.1");

   -- TEST 6 - Robustness: CHS to LBA Round-trip
   Put_Line("TEST 6 - Round-trip Validation (LBA -> CHS -> LBA)");
   declare
      LBA_Start : constant LBA_Address := 123456;
      Inter_CHS : CHS_Address;
      LBA_End   : LBA_Address;
   begin
      Inter_CHS := LBA_To_CHS(LBA_Start, Geo_Standard);
      LBA_End   := CHS_To_LBA(Inter_CHS, Geo_Standard);
      Assert_Test (LBA_Start = LBA_End, "Roundtrip conversion maintains 1:1 data integrity", "6.1");
   end;

   -- TEST 7 - Edge Case: Invalid Geometry (Zero Heads)
   Put_Line("TEST 7 - Edge Case: Invalid Geometry Handling (H=0)");
   begin
      Test_LBA_1 := CHS_To_LBA ((C => 0, H => 0, S => 1), Geo_Invalid);
      Assert_Test (False, "Expected Invalid_Geometry not raised", "7.1");
   exception
      when Invalid_Geometry =>
         Assert_Test (True, "Invalid_Geometry correctly intercepted division by zero", "7.1");
   end;

   -- TEST 8 - Edge Case: Invalid Geometry (Zero Sectors)
   Put_Line("TEST 8 - Edge Case: Invalid Geometry Handling (S=0)");
   begin
      Test_CHS_1 := LBA_To_CHS (100, (C_Total => 1024, H_Total => 16, S_Total => 0));
      Assert_Test (False, "Expected Invalid_Geometry not raised", "8.1");
   exception
      when Invalid_Geometry =>
         Assert_Test (True, "Invalid_Geometry correctly intercepted division by zero", "8.1");
   end;

   -- TEST 9 - Robustness: Sector 0 is invalid (1-indexed)
   Put_Line("TEST 9 - Invalid CHS: Sector 0 bounds");
   begin
      Test_LBA_1 := CHS_To_LBA ((C => 0, H => 0, S => 0), Geo_Standard);
      Assert_Test (False, "Expected Invalid_CHS not raised", "9.1");
   exception
      when Invalid_CHS =>
         Assert_Test (True, "Invalid_CHS raised for invalid 0-indexed sector", "9.1");
   end;

   -- TEST 10 - Robustness: Sector exceeds total
   Put_Line("TEST 10 - Invalid CHS: Sector > Total");
   begin
      Test_LBA_1 := CHS_To_LBA ((C => 0, H => 0, S => 64), Geo_Standard);
      Assert_Test (False, "Expected Invalid_CHS not raised", "10.1");
   exception
      when Invalid_CHS =>
         Assert_Test (True, "Invalid_CHS raised when passing bounds of S", "10.1");
   end;

   -- TEST 11 - Robustness: Head exceeds total
   Put_Line("TEST 11 - Invalid CHS: Head >= Total");
   begin
      Test_LBA_1 := CHS_To_LBA ((C => 0, H => 16, S => 1), Geo_Standard);
      Assert_Test (False, "Expected Invalid_CHS not raised", "11.1");
   exception
      when Invalid_CHS =>
         Assert_Test (True, "Invalid_CHS raised when passing bounds of H", "11.1");
   end;

   -- TEST 12 - Robustness: Cylinder exceeds total
   Put_Line("TEST 12 - Invalid CHS: Cylinder >= Total");
   begin
      Test_LBA_1 := CHS_To_LBA ((C => 1024, H => 0, S => 1), Geo_Standard);
      Assert_Test (False, "Expected Invalid_CHS not raised", "12.1");
   exception
      when Invalid_CHS =>
         Assert_Test (True, "Invalid_CHS raised when passing bounds of C", "12.1");
   end;

   -- TEST 13 - Edge Case: LBA exactly at Out of Bounds Limit
   Put_Line("TEST 13 - LBA Out of Bounds Check (Max Volume Limits)");
   begin
      -- Max LBA for Standard is 1024*16*63 = 1032192 (Max accessible index = 1032191)
      Test_CHS_1 := LBA_To_CHS (1032192, Geo_Standard);
      Assert_Test (False, "Expected LBA_Out_Of_Bounds not raised", "13.1");
   exception
      when LBA_Out_Of_Bounds =>
         Assert_Test (True, "LBA_Out_Of_Bounds blocked invalid memory sector reference", "13.1");
   end;

   -- TEST 14 - Edge Case: 1/1/1 Minimal Valid Disk Geometry
   Put_Line("TEST 14 - Minimal Valid Disk Geometry (1/1/1)");
   declare
      Geo_Min : constant Disk_Geometry := (C_Total => 1, H_Total => 1, S_Total => 1);
   begin
      Test_LBA_1 := CHS_To_LBA ((C => 0, H => 0, S => 1), Geo_Min);
      Assert_Test (Test_LBA_1 = 0, "Minimal disk correctly parsed to LBA 0", "14.1");
      begin
         Test_CHS_1 := LBA_To_CHS (1, Geo_Min);
         Assert_Test (False, "Should have raised bounds error on LBA 1", "14.2");
      exception
         when LBA_Out_Of_Bounds =>
            Assert_Test (True, "LBA bounds protected minimal disk structure", "14.2");
      end;
   end;

   Put_Line("========================================================================");
   Put_Line("ALL TESTS PASSED: Pessimistic assumption disproved. Codebase is healthy.");
end Tests;
