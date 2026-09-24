with Ada.Text_IO; use Ada.Text_IO;
with Grade_5_Math; use Grade_5_Math;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   D, H, M, S : Natural_Value;
begin
   -- TEST 1 — Rounding to Tens
   Put_Line ("TEST 1 — Rounding (Tens)");
   Check ("1.1 Round down", Round (12, Tens) = 10);
   Check ("1.2 Round half up", Round (15, Tens) = 20);
   Check ("1.3 Round up", Round (18, Tens) = 20);

   -- TEST 2 — Rounding to Hundreds
   Put_Line ("TEST 2 — Rounding (Hundreds)");
   Check ("2.1 Round down", Round (149, Hundreds) = 100);
   Check ("2.2 Round half up", Round (150, Hundreds) = 200);
   Check ("2.3 Round up", Round (199, Hundreds) = 200);

   -- TEST 3 — Rounding to Millions
   Put_Line ("TEST 3 — Rounding (Millions)");
   Check ("3.1 Round down", Round (1_499_999, Millions) = 1_000_000);
   Check ("3.2 Round half up", Round (1_500_000, Millions) = 2_000_000);
   Check ("3.3 Round up", Round (1_999_999, Millions) = 2_000_000);

   -- TEST 4 — Rectangle Perimeter
   Put_Line ("TEST 4 — Rectangle Perimeter");
   Check ("4.1 Standard rectangle", Rectangle_Perimeter (10, 5) = 30);
   Check ("4.2 Square rectangle", Rectangle_Perimeter (5, 5) = 20);
   Check ("4.3 Zero dimension edge case", Rectangle_Perimeter (0, 5) = 10);

   -- TEST 5 — Rectangle Area
   Put_Line ("TEST 5 — Rectangle Area");
   Check ("5.1 Standard rectangle", Rectangle_Area (10, 5) = 50);
   Check ("5.2 Square rectangle", Rectangle_Area (5, 5) = 25);
   Check ("5.3 Zero dimension edge case", Rectangle_Area (0, 5) = 0);

   -- TEST 6 — Cuboid Surface Area
   Put_Line ("TEST 6 — Cuboid Surface Area");
   Check ("6.1 Standard cuboid", Cuboid_Surface_Area (2, 3, 4) = 52);
   Check ("6.2 Cube", Cuboid_Surface_Area (2, 2, 2) = 24);
   Check ("6.3 Flat zero-height cuboid", Cuboid_Surface_Area (2, 3, 0) = 12);

   -- TEST 7 — Cuboid Volume
   Put_Line ("TEST 7 — Cuboid Volume");
   Check ("7.1 Standard cuboid", Cuboid_Volume (2, 3, 4) = 24);
   Check ("7.2 Cube", Cuboid_Volume (2, 2, 2) = 8);
   Check ("7.3 Flat zero-height cuboid", Cuboid_Volume (2, 3, 0) = 0);

   -- TEST 8 — Time Conversion: Only Seconds
   Put_Line ("TEST 8 — Time Conversion (Pure Seconds)");
   Convert_Seconds (45, D, H, M, S);
   Check ("8.1 No days", D = 0);
   Check ("8.2 No minutes", M = 0);
   Check ("8.3 45 seconds retained", S = 45);

   -- TEST 9 — Time Conversion: Minutes and Seconds
   Put_Line ("TEST 9 — Time Conversion (Minutes)");
   Convert_Seconds (125, D, H, M, S);
   Check ("9.1 No hours", H = 0);
   Check ("9.2 2 minutes", M = 2);
   Check ("9.3 5 seconds", S = 5);

   -- TEST 10 — Time Conversion: Hours, Minutes, Seconds
   Put_Line ("TEST 10 — Time Conversion (Hours)");
   Convert_Seconds (7265, D, H, M, S);
   Check ("10.1 No days", D = 0);
   Check ("10.2 2 hours", H = 2);
   Check ("10.3 1 min 5 sec remainder", M = 1 and S = 5);

   -- TEST 11 — Time Conversion: Days fully populated
   Put_Line ("TEST 11 — Time Conversion (Days)");
   Convert_Seconds (90_061, D, H, M, S);
   Check ("11.1 1 day", D = 1);
   Check ("11.2 1 hour", H = 1);
   Check ("11.3 1 min 1 sec", M = 1 and S = 1);

   -- TEST 12 — Strict Boundaries (Dimension Error Exceptions)
   Put_Line ("TEST 12 — Edge Cases (Strict Constraints)");
   declare
      Vol : Volume_Unit;
   begin
      Vol := Strict_Cuboid_Volume (0, 5, 5);
      Check ("12.1 Strict L=0 failed to trap", Vol = 0);
   exception
      when Dimension_Error => Check ("12.1 Caught L=0", True);
   end;

   declare
      Vol : Volume_Unit;
   begin
      Vol := Strict_Cuboid_Volume (5, 0, 5);
      Check ("12.2 Strict W=0 failed to trap", Vol = 0);
   exception
      when Dimension_Error => Check ("12.2 Caught W=0", True);
   end;

   declare
      Vol : Volume_Unit;
   begin
      Vol := Strict_Cuboid_Volume (5, 5, 0);
      Check ("12.3 Strict H=0 failed to trap", Vol = 0);
   exception
      when Dimension_Error => Check ("12.3 Caught H=0", True);
   end;

   -- TEST 13 — Exception Handling (Rounding Overflow Limits)
   Put_Line ("TEST 13 — Exception Handling (Rounding Overflow Limits)");
   declare
      Res : Natural_Value;
   begin
      Res := Round (Natural_Value'Last, Tens);
      Check ("13.1 Rounding max tens failed to trap", Res = 0);
   exception
      when Rounding_Error => Check ("13.1 Caught tens overflow", True);
   end;

   declare
      Res : Natural_Value;
   begin
      Res := Round (Natural_Value'Last, Thousands);
      Check ("13.2 Rounding max thousands failed to trap", Res = 0);
   exception
      when Rounding_Error => Check ("13.2 Caught thousands overflow", True);
   end;

   declare
      Res : Natural_Value;
   begin
      Res := Round (Natural_Value'Last, Millions);
      Check ("13.3 Rounding max millions failed to trap", Res = 0);
   exception
      when Rounding_Error => Check ("13.3 Caught millions overflow", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
