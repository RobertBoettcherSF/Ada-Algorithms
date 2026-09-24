-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Zeller; use Zeller;

procedure Tests is
begin
   Put_Line("=========================================");
   Put_Line("ZELLER'S CONGRUENCE V&V TEST SUITE");
   Put_Line("=========================================");

   -- TEST 1 - Known Gregorian Boundary
   Put_Line("TEST 1 - Gregorian: Y2K Boundary");
   Put_Line("  1.1 Assert 2000-01-01 is Saturday");
   Assert (Day_Of_Week_Gregorian(1, 1, 2000) = Saturday, "Y2K Day failed");
   Put_Line("      PASS");

   -- TEST 2 - Gregorian Leap Year Validation
   Put_Line("TEST 2 - Gregorian: Leap Year Edge Cases");
   Put_Line("  2.1 Assert 2024-02-29 is Thursday");
   Assert (Day_Of_Week_Gregorian(29, 2, 2024) = Thursday, "Leap year failed");
   Put_Line("      PASS");

   -- TEST 3 - Gregorian Standard Year Validation
   Put_Line("TEST 3 - Gregorian: Standard Year (Non-Leap)");
   Put_Line("  3.1 Assert 2023-02-28 is Tuesday");
   Assert (Day_Of_Week_Gregorian(28, 2, 2023) = Tuesday, "Standard year failed");
   Put_Line("      PASS");

   -- TEST 4 - Algorithm Shift Validation
   Put_Line("TEST 4 - Gregorian: Month Shift Boundary");
   Put_Line("  4.1 Assert 2023-03-01 is Wednesday");
   Assert (Day_Of_Week_Gregorian(1, 3, 2023) = Wednesday, "March transition failed");
   Put_Line("      PASS");

   -- TEST 5 - Future Proofing
   Put_Line("TEST 5 - Gregorian: Deep Future Prediction");
   Put_Line("  5.1 Assert 3000-01-01 is Wednesday");
   Assert (Day_Of_Week_Gregorian(1, 1, 3000) = Wednesday, "Y3K Day failed");
   Put_Line("      PASS");

   -- TEST 6 - Historical Julian Calculation
   Put_Line("TEST 6 - Julian: Historical Battle of Hastings");
   Put_Line("  6.1 Assert 1066-10-14 is Saturday");
   Assert (Day_Of_Week_Julian(14, 10, 1066) = Saturday, "Julian historical failed");
   Put_Line("      PASS");

   -- TEST 7 - Deep Past Julian
   Put_Line("TEST 7 - Julian: Antiquity Date");
   Put_Line("  7.1 Assert 0001-01-01 is Saturday");
   Assert (Day_Of_Week_Julian(1, 1, 1) = Saturday, "Antiquity calculation failed");
   Put_Line("      PASS");

   -- TEST 8 - Julian Leap Year Discrepancy
   Put_Line("TEST 8 - Julian: Centennial Leap Year");
   Put_Line("  8.1 Assert 1000-02-29 is Thursday (Valid in Julian, not Gregorian)");
   Assert (Day_Of_Week_Julian(29, 2, 1000) = Thursday, "Julian centennial failed");
   Put_Line("      PASS");

   -- TEST 9 - ISO Format Conversion (Gregorian)
   Put_Line("TEST 9 - ISO Format: Gregorian Translation");
   Put_Line("  9.1 Assert 2023-01-01 is Sunday");
   Assert (Day_Of_Week_ISO_Gregorian(1, 1, 2023) = Sunday, "ISO mapping failed");
   Put_Line("      PASS");

   -- TEST 10 - ISO Format Conversion (Julian)
   Put_Line("TEST 10 - ISO Format: Julian Translation");
   Put_Line("  10.1 Assert 1066-10-14 is Saturday");
   Assert (Day_Of_Week_ISO_Julian(14, 10, 1066) = Saturday, "ISO Julian mapping failed");
   Put_Line("      PASS");

   -- TEST 11 - Expected Failure: Impossible Date (Gregorian)
   Put_Line("TEST 11 - Error Handling: Gregorian Centennial Non-Leap Year");
   Put_Line("  11.1 Assert 1900-02-29 raises Invalid_Date");
   begin
      declare
         Result : Day_Of_Week := Day_Of_Week_Gregorian(29, 2, 1900);
         pragma Unreferenced (Result);
      begin
         Assert (False, "Expected Invalid_Date not raised");
      end;
   exception
      when Invalid_Date =>
         Put_Line("      PASS");
   end;

   -- TEST 12 - Expected Failure: Impossible Date (Month Range)
   Put_Line("TEST 12 - Error Handling: Day Out of Bounds");
   Put_Line("  12.1 Assert April 31st raises Invalid_Date");
   begin
      declare
         Result : Day_Of_Week := Day_Of_Week_Gregorian(31, 4, 2023);
         pragma Unreferenced (Result);
      begin
         Assert (False, "Expected Invalid_Date not raised");
      end;
   exception
      when Invalid_Date =>
         Put_Line("      PASS");
   end;

   -- TEST 13 - Current Era Date
   Put_Line("TEST 13 - Gregorian: Current Era Functional Check");
   Put_Line("  13.1 Assert 2026-08-28 is Friday");
   Assert (Day_Of_Week_Gregorian(28, 8, 2026) = Friday, "Modern date check failed");
   Put_Line("      PASS");
   
   -- TEST 14 - Invalid Date for Julian vs Gregorian
   Put_Line("TEST 14 - Robustness: Julian accepts 1900-02-29, while Gregorian fails");
   Put_Line("  14.1 Assert Julian 1900-02-29 calculates to Tuesday");
   Assert(Day_Of_Week_Julian(29, 2, 1900) = Tuesday, "Julian validation logic flawed");
   Put_Line("      PASS");

   Put_Line("=========================================");
   Put_Line("ALL TESTS COMPLETED SUCCESSFULLY");
   Put_Line("=========================================");
end Tests;
