--  Standalone test suite for Doomsday (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Doomsday;

procedure Tests is

   use Ada.Text_IO;

   package D renames Doomsday;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   procedure Expect_DOW
     (Y     : D.Year_Number;
      M     : D.Month_Number;
      Day   : Positive;
      W     : D.Weekday;
      Label : String)
   is
      Got : constant D.Weekday := D.Day_Of_Week (Y, M, D.Day_Number (Day));
   begin
      Check (Got = W,
             Label & " -> " & D.Weekday_Name (W)
             & " (got " & D.Weekday_Name (Got) & ")");
   end Expect_DOW;

   function Next_W (W : D.Weekday) return D.Weekday is
   begin
      return D.Weekday ((Integer (W) + 1) rem 7);
   end Next_W;

   function Prev_W (W : D.Weekday) return D.Weekday is
   begin
      return D.Weekday ((Integer (W) + 6) rem 7);
   end Prev_W;

begin
   Put_Line ("Doomsday test suite");
   Put_Line ("===================");

   ---------------------------------------------------------------------
   Section ("1. Century anchors (Gregorian)");
   ---------------------------------------------------------------------
   Check (D.Century_Anchor (1600) = D.Tuesday,   "1600s Tuesday");
   Check (D.Century_Anchor (1699) = D.Tuesday,   "1699 Tuesday");
   Check (D.Century_Anchor (1700) = D.Sunday,    "1700s Sunday");
   Check (D.Century_Anchor (1800) = D.Friday,    "1800s Friday");
   Check (D.Century_Anchor (1900) = D.Wednesday, "1900s Wednesday");
   Check (D.Century_Anchor (1999) = D.Wednesday, "1999 Wednesday");
   Check (D.Century_Anchor (2000) = D.Tuesday,   "2000s Tuesday");
   Check (D.Century_Anchor (2099) = D.Tuesday,   "2099 Tuesday");
   Check (D.Century_Anchor (2100) = D.Sunday,    "2100s Sunday");
   Check (D.Century_Anchor (2200) = D.Friday,    "2200s Friday");

   ---------------------------------------------------------------------
   Section ("2. Year doomsdays (known)");
   ---------------------------------------------------------------------
   Check (D.Year_Doomsday (1966) = D.Monday,    "1966 Monday");
   Check (D.Year_Doomsday (2005) = D.Monday,    "2005 Monday");
   Check (D.Year_Doomsday (2024) = D.Thursday,  "2024 Thursday");
   Check (D.Year_Doomsday (2027) = D.Sunday,    "2027 Sunday");
   Check (D.Year_Doomsday (2000) = D.Tuesday,   "2000 Tuesday");
   Check (D.Year_Doomsday (1900) = D.Wednesday, "1900 Wednesday");
   Check (D.Year_Doomsday (2012) = D.Wednesday, "2012 Wednesday");
   Check (D.Year_Doomsday (2016) = D.Monday,    "2016 Monday");
   Check (D.Year_Doomsday (2020) = D.Saturday,  "2020 Saturday");
   Check (D.Year_Doomsday (1937) = D.Sunday,    "1937 Sunday Conway birth year");
   Check (D.Year_Doomsday (1973) = D.Wednesday, "1973 Wednesday");
   Check (D.Year_Doomsday (1800) = D.Friday,    "1800 Friday");
   Check (D.Year_Doomsday (2100) = D.Sunday,    "2100 Sunday");

   ---------------------------------------------------------------------
   Section ("3. Is_Leap");
   ---------------------------------------------------------------------
   Check (D.Is_Leap (2000),     "2000 leap (div 400)");
   Check (not D.Is_Leap (1900), "1900 not leap");
   Check (not D.Is_Leap (2100), "2100 not leap");
   Check (D.Is_Leap (2004),     "2004 leap");
   Check (D.Is_Leap (2024),     "2024 leap");
   Check (not D.Is_Leap (2023), "2023 not leap");
   Check (not D.Is_Leap (2025), "2025 not leap");
   Check (D.Is_Leap (1600),     "1600 leap");
   Check (not D.Is_Leap (1700), "1700 not leap");
   Check (D.Is_Leap (2012),     "2012 leap");

   ---------------------------------------------------------------------
   Section ("4. Closest_Doomsday memorable dates");
   ---------------------------------------------------------------------
   Check (D.Closest_Doomsday (2023, 1) = 3,   "2023 Jan 3 common");
   Check (D.Closest_Doomsday (2024, 1) = 4,   "2024 Jan 4 leap");
   Check (D.Closest_Doomsday (2023, 2) = 28,  "2023 Feb 28");
   Check (D.Closest_Doomsday (2024, 2) = 29,  "2024 Feb 29");
   Check (D.Closest_Doomsday (2024, 3) = 0,   "Mar 0");
   Check (D.Closest_Doomsday (2024, 4) = 4,   "4/4");
   Check (D.Closest_Doomsday (2024, 5) = 9,   "5/9");
   Check (D.Closest_Doomsday (2024, 6) = 6,   "6/6");
   Check (D.Closest_Doomsday (2024, 7) = 11,  "7/11");
   Check (D.Closest_Doomsday (2024, 8) = 8,   "8/8");
   Check (D.Closest_Doomsday (2024, 9) = 5,   "9/5");
   Check (D.Closest_Doomsday (2024, 10) = 10, "10/10");
   Check (D.Closest_Doomsday (2024, 11) = 7,  "11/7");
   Check (D.Closest_Doomsday (2024, 12) = 12, "12/12");

   ---------------------------------------------------------------------
   Section ("5. Known weekdays (famous / check dates)");
   ---------------------------------------------------------------------
   Expect_DOW (2024, 9, 9, D.Monday, "2024-09-09");
   Expect_DOW (1937, 12, 26, D.Sunday, "Conway birth 1937-12-26");
   Expect_DOW (2027, 12, 25, D.Saturday, "Christmas 2027");
   Expect_DOW (1970, 1, 1, D.Thursday, "Unix epoch 1970-01-01");
   Expect_DOW (2000, 1, 1, D.Saturday, "Y2K 2000-01-01");
   Expect_DOW (2000, 2, 29, D.Tuesday, "2000-02-29 leap doomsday");
   Expect_DOW (1900, 1, 1, D.Monday, "1900-01-01");
   Expect_DOW (2012, 2, 29, D.Wednesday, "2012-02-29");
   Expect_DOW (2016, 2, 29, D.Monday, "2016-02-29");
   Expect_DOW (2020, 2, 29, D.Saturday, "2020-02-29");
   Expect_DOW (2023, 1, 1, D.Sunday, "2023-01-01");
   Expect_DOW (2024, 1, 1, D.Monday, "2024-01-01");
   Expect_DOW (2025, 1, 1, D.Wednesday, "2025-01-01");
   Expect_DOW (2026, 9, 9, D.Wednesday, "2026-09-09");
   Expect_DOW (1776, 7, 4, D.Thursday, "US Independence 1776-07-04");
   Expect_DOW (1969, 7, 20, D.Sunday, "Moon landing 1969-07-20");
   Expect_DOW (1989, 11, 9, D.Thursday, "Berlin Wall 1989-11-09");
   Expect_DOW (2001, 9, 11, D.Tuesday, "2001-09-11");
   Expect_DOW (1818, 5, 5, D.Tuesday, "Marx birth 1818-05-05");
   Expect_DOW (1879, 3, 14, D.Friday, "Einstein birth 1879-03-14");

   ---------------------------------------------------------------------
   Section ("6. Leap vs non-leap January / February");
   ---------------------------------------------------------------------
   declare
      YD23 : constant D.Weekday := D.Year_Doomsday (2023);
      YD24 : constant D.Weekday := D.Year_Doomsday (2024);
   begin
      Check (D.Day_Of_Week (2023, 1, 3) = YD23, "non-leap Jan 3 doomsday");
      Check (D.Day_Of_Week (2023, 2, 28) = YD23, "non-leap Feb 28 doomsday");
      Check (D.Day_Of_Week (2024, 1, 4) = YD24, "leap Jan 4 doomsday");
      Check (D.Day_Of_Week (2024, 2, 29) = YD24, "leap Feb 29 doomsday");
      Check (D.Day_Of_Week (2023, 1, 4) = Next_W (YD23),
             "2023 Jan 4 = doomsday+1");
      Check (D.Day_Of_Week (2024, 1, 3) = Prev_W (YD24),
             "2024 Jan 3 = doomsday-1");
      Check (D.Day_Of_Week (2023, 3, 0) = YD23, "2023 March 0 = doomsday");
      Check (D.Day_Of_Week (2024, 3, 0) = YD24, "2024 March 0 = doomsday");
      Check (D.Day_Of_Week (2023, 3, 14) = YD23, "2023 Pi Day doomsday");
      Check (D.Day_Of_Week (2024, 3, 14) = YD24, "2024 Pi Day doomsday");
   end;

   ---------------------------------------------------------------------
   Section ("7. All memorable doomsdays share year doomsday");
   ---------------------------------------------------------------------
   declare
      procedure Check_Year (Y : D.Year_Number) is
         YD : constant D.Weekday := D.Year_Doomsday (Y);
         DD : D.Day_Number;
         W  : D.Weekday;
      begin
         for M in D.Month_Number loop
            DD := D.Closest_Doomsday (Y, M);
            if DD = 0 then
               W := D.Day_Of_Week (Y, M, 0);
            else
               W := D.Day_Of_Week (Y, M, DD);
            end if;
            Check (W = YD,
                   "Y" & D.Year_Number'Image (Y)
                   & " M" & D.Month_Number'Image (M)
                   & " doomsday shared");
         end loop;
         Check (D.Day_Of_Week (Y, 7, 4) = YD,
                "Y" & D.Year_Number'Image (Y) & " Jul 4 = doomsday");
         Check (D.Day_Of_Week (Y, 10, 31) = YD,
                "Y" & D.Year_Number'Image (Y) & " Halloween = doomsday");
         Check (D.Day_Of_Week (Y, 12, 26) = YD,
                "Y" & D.Year_Number'Image (Y) & " Boxing Day = doomsday");
      end Check_Year;
   begin
      Check_Year (2000);
      Check_Year (2023);
      Check_Year (2024);
      Check_Year (1900);
      Check_Year (2016);
   end;

   ---------------------------------------------------------------------
   Section ("8. Full year 2024 sample (1st of each month)");
   ---------------------------------------------------------------------
   declare
      Firsts : constant array (D.Month_Number) of D.Weekday :=
        [D.Monday,     -- Jan
         D.Thursday,   -- Feb
         D.Friday,     -- Mar
         D.Monday,     -- Apr
         D.Wednesday,  -- May
         D.Saturday,   -- Jun
         D.Monday,     -- Jul
         D.Thursday,   -- Aug
         D.Sunday,     -- Sep
         D.Tuesday,    -- Oct
         D.Friday,     -- Nov
         D.Sunday];    -- Dec
   begin
      for M in D.Month_Number loop
         Expect_DOW (2024, M, 1, Firsts (M),
                     "2024 m" & D.Month_Number'Image (M) & " day 1");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Full year 2000 sample (1st of each month)");
   ---------------------------------------------------------------------
   declare
      Firsts : constant array (D.Month_Number) of D.Weekday :=
        [D.Saturday,   -- Jan
         D.Tuesday,    -- Feb
         D.Wednesday,  -- Mar
         D.Saturday,   -- Apr
         D.Monday,     -- May
         D.Thursday,   -- Jun
         D.Saturday,   -- Jul
         D.Tuesday,    -- Aug
         D.Friday,     -- Sep
         D.Sunday,     -- Oct
         D.Wednesday,  -- Nov
         D.Friday];    -- Dec
   begin
      for M in D.Month_Number loop
         Expect_DOW (2000, M, 1, Firsts (M),
                     "2000 m" & D.Month_Number'Image (M) & " day 1");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Agree with Sakamoto reference (1800-2100 samples)");
   ---------------------------------------------------------------------
   declare
      Agree : Natural := 0;
      Total : Natural := 0;
      W1, W2 : D.Weekday;
      Days_M : constant array (D.Month_Number) of Positive :=
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      Last_D : Positive;
   begin
      for Y in D.Year_Number range 1800 .. 2100 loop
         for M in D.Month_Number loop
            Last_D := Days_M (M);
            if M = 2 and then D.Is_Leap (Y) then
               Last_D := 29;
            end if;
            for Day in Positive range 1 .. Last_D loop
               if Day = 1 or else Day = 15 or else Day = Last_D
                 or else (M = 2 and then Day = 28)
                 or else (M = 4 and then Day = 4)
                 or else (M = 9 and then Day = 9)
               then
                  W1 := D.Day_Of_Week (Y, M, D.Day_Number (Day));
                  W2 := D.Sakamoto_Day_Of_Week (Y, M, Day);
                  Total := Total + 1;
                  if W1 = W2 then
                     Agree := Agree + 1;
                  else
                     Check (False,
                            "Mismatch"
                            & D.Year_Number'Image (Y)
                            & D.Month_Number'Image (M)
                            & Positive'Image (Day));
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
      Check (Agree = Total and then Total > 0,
             "Sakamoto agree all" & Natural'Image (Agree)
             & "/" & Natural'Image (Total));
      for Y in D.Year_Number range 1800 .. 2100 loop
         if Y rem 10 = 0 then
            W1 := D.Day_Of_Week (Y, 6, 6);
            W2 := D.Sakamoto_Day_Of_Week (Y, 6, 6);
            Check (W1 = W2,
                   "Sakamoto 6/6" & D.Year_Number'Image (Y));
         end if;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Weekday_Name");
   ---------------------------------------------------------------------
   Check (D.Weekday_Name (D.Sunday) = "Sunday",       "name Sunday");
   Check (D.Weekday_Name (D.Monday) = "Monday",       "name Monday");
   Check (D.Weekday_Name (D.Tuesday) = "Tuesday",     "name Tuesday");
   Check (D.Weekday_Name (D.Wednesday) = "Wednesday", "name Wednesday");
   Check (D.Weekday_Name (D.Thursday) = "Thursday",   "name Thursday");
   Check (D.Weekday_Name (D.Friday) = "Friday",       "name Friday");
   Check (D.Weekday_Name (D.Saturday) = "Saturday",   "name Saturday");

   ---------------------------------------------------------------------
   Section ("12. Invalid dates raise");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      W      : D.Weekday := D.Sunday;
   begin
      begin
         W := D.Day_Of_Week (2023, 2, 29);
      exception
         when D.Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "2023-02-29 raises");

      Raised := False;
      begin
         W := D.Day_Of_Week (2024, 4, 0);
      exception
         when D.Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Day 0 outside March raises");

      Raised := False;
      begin
         W := D.Day_Of_Week (2024, 4, 31);
      exception
         when D.Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "2024-04-31 raises");
      --  Keep W live for -gnatwa
      Check (W'Valid, "weekday value still valid after exception tests");
   end;

   ---------------------------------------------------------------------
   Section ("13. Sakamoto matches known dates");
   ---------------------------------------------------------------------
   Check (D.Sakamoto_Day_Of_Week (2024, 9, 9) = D.Monday,
          "Sakamoto 2024-09-09 Monday");
   Check (D.Sakamoto_Day_Of_Week (2000, 1, 1) = D.Saturday,
          "Sakamoto 2000-01-01 Saturday");
   Check (D.Sakamoto_Day_Of_Week (1970, 1, 1) = D.Thursday,
          "Sakamoto 1970-01-01 Thursday");
   Check (D.Sakamoto_Day_Of_Week (1937, 12, 26) = D.Sunday,
          "Sakamoto Conway birth Sunday");

   New_Line;
   Put_Line ("========================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
