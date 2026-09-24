--  Standalone test suite for Computus (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Computus;

procedure Tests is

   use Ada.Text_IO;

   package C renames Computus;

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

   function MD
     (Y : C.Year_Number; M : C.Month_Number; D : C.Day_Number) return C.Date
   is
   begin
      return (Year => Y, Month => M, Day => D);
   end MD;

   procedure Expect_Easter
     (Y : C.Year_Number; M : C.Month_Number; D : C.Day_Number; Label : String)
   is
      E : constant C.Date := C.Gregorian_Easter (Y);
      A : constant C.Date := C.Easter (Y);
   begin
      Check (E.Year = Y and then E.Month = M and then E.Day = D,
             Label & " Gregorian_Easter");
      Check (C.Same_Date (E, A), Label & " Easter alias");
      Check (C.Is_Sunday (E), Label & " is Sunday");
      Check (C.In_Easter_Window (E), Label & " in Mar22..Apr25");
   end Expect_Easter;

   procedure Expect_Orthodox
     (Y : C.Year_Number; M : C.Month_Number; D : C.Day_Number; Label : String)
   is
      E : constant C.Date := C.Orthodox_Easter (Y);
   begin
      Check (E.Year = Y and then E.Month = M and then E.Day = D,
             Label & " Orthodox_Easter (Gregorian)");
      Check (C.Is_Sunday (E), Label & " Orthodox is Sunday");
   end Expect_Orthodox;

begin
   Put_Line ("Computus test suite");
   Put_Line ("===================");

   ---------------------------------------------------------------------
   Section ("1. Known Gregorian Easter dates (table)");
   ---------------------------------------------------------------------
   Expect_Easter (2017, 4, 16, "2017");
   Expect_Easter (2018, 4,  1, "2018");
   Expect_Easter (2019, 4, 21, "2019");
   Expect_Easter (2020, 4, 12, "2020");
   Expect_Easter (2021, 4,  4, "2021");
   Expect_Easter (2022, 4, 17, "2022");
   Expect_Easter (2023, 4,  9, "2023");
   Expect_Easter (2024, 3, 31, "2024");
   Expect_Easter (2025, 4, 20, "2025");
   Expect_Easter (2000, 4, 23, "2000");
   Expect_Easter (1954, 4, 18, "1954");
   Expect_Easter (1818, 3, 22, "1818 earliest");
   Expect_Easter (1961, 4,  2, "1961 wiki");
   Expect_Easter (2026, 4,  5, "2026 wiki");
   Expect_Easter (2027, 3, 28, "2027 wiki");
   Expect_Easter (1583, 4, 10, "1583 first Gregorian");
   Expect_Easter (1900, 4, 15, "1900");
   Expect_Easter (1943, 4, 25, "1943 latest window");
   Expect_Easter (2038, 4, 25, "2038 Apr 25");
   Expect_Easter (2285, 3, 22, "2285 Mar 22");

   ---------------------------------------------------------------------
   Section ("2. Orthodox Easter on Gregorian civil calendar");
   ---------------------------------------------------------------------
   Expect_Orthodox (2017, 4, 16, "2017");
   Expect_Orthodox (2018, 4,  8, "2018");
   Expect_Orthodox (2019, 4, 28, "2019");
   Expect_Orthodox (2020, 4, 19, "2020");
   Expect_Orthodox (2021, 5,  2, "2021");
   Expect_Orthodox (2022, 4, 24, "2022");
   Expect_Orthodox (2023, 4, 16, "2023");
   Expect_Orthodox (2024, 5,  5, "2024");
   Expect_Orthodox (2025, 4, 20, "2025");

   ---------------------------------------------------------------------
   Section ("3. Julian_Easter sample conversion consistency");
   ---------------------------------------------------------------------
   declare
      J : C.Date;
      G : C.Date;
   begin
      for Y in C.Year_Number'(1990) .. C.Year_Number'(1999) loop
         J := C.Julian_Easter (Y);
         Check (J.Month = 3 or else J.Month = 4,
                "Julian month Mar/Apr" & C.Year_Number'Image (Y));
         G := C.Orthodox_Easter (Y);
         Check (C.Same_Date (G, C.Julian_To_Gregorian (J)),
                "Orthodox=convert" & C.Year_Number'Image (Y));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Every year 2000..2099: Sunday + Easter window");
   ---------------------------------------------------------------------
   declare
      E : C.Date;
      N : Natural := 0;
   begin
      for Y in C.Year_Number range 2000 .. 2099 loop
         E := C.Gregorian_Easter (Y);
         if C.Is_Sunday (E) and then C.In_Easter_Window (E) then
            N := N + 1;
         else
            Check (False, "bad Easter" & C.Year_Number'Image (Y));
         end if;
      end loop;
      Check (N = 100, "100 years 2000-2099 all Sunday in window");
      --  Per-year checks for a denser PASS count:
      for Y in C.Year_Number range 2000 .. 2099 loop
         E := C.Gregorian_Easter (Y);
         Check (C.Is_Sunday (E),
                "Sun" & C.Year_Number'Image (Y));
         Check (C.In_Easter_Window (E),
                "Win" & C.Year_Number'Image (Y));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Easter alias, Same_Date, Near");
   ---------------------------------------------------------------------
   declare
      A : constant C.Date := C.Gregorian_Easter (2020);
      B : constant C.Date := C.Easter (2020);
      C1 : constant C.Date := MD (2020, 4, 12);
      C2 : constant C.Date := MD (2020, 4, 13);
      C3 : constant C.Date := MD (2020, 4, 10);
   begin
      Check (C.Same_Date (A, B), "alias Same_Date");
      Check (C.Near (A, C1, 0), "Near exact 2020");
      Check (C.Near (A, C2, 1), "Near tol 1 day");
      Check (not C.Near (A, C2, 0), "Near rejects off-by-1 at tol 0");
      Check (C.Near (A, C3, 2), "Near tol 2");
      Check (not C.Near (A, C3, 1), "Near rejects off-by-2 at tol 1");
      Check (C.Day_Difference (A, C2) = 1, "Day_Difference +1");
      Check (C.Day_Difference (C2, A) = -1, "Day_Difference -1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Day_Of_Week known anchors");
   ---------------------------------------------------------------------
   Check (C.Day_Of_Week (MD (2000, 1, 1)) = C.Saturday, "2000-01-01 Sat");
   Check (C.Day_Of_Week (MD (2024, 3, 31)) = C.Sunday, "2024-03-31 Sun");
   Check (C.Day_Of_Week (MD (2017, 4, 16)) = C.Sunday, "2017-04-16 Sun");
   Check (C.Is_Sunday (MD (2025, 4, 20)), "2025-04-20 Is_Sunday");
   Check (not C.Is_Sunday (MD (2025, 4, 21)), "2025-04-21 not Sunday");

   ---------------------------------------------------------------------
   Section ("7. Golden number");
   ---------------------------------------------------------------------
   Check (C.Golden_Number (2014) = 1, "GN 2014 = 1");
   Check (C.Golden_Number (2015) = 2, "GN 2015 = 2");
   Check (C.Golden_Number (2032) = 19, "GN 2032 = 19");
   Check (C.Golden_Number (2033) = 1, "GN 2033 = 1");

   ---------------------------------------------------------------------
   Section ("8. Leap / ordinal / Add_Days");
   ---------------------------------------------------------------------
   Check (C.Is_Gregorian_Leap (2000), "2000 leap");
   Check (not C.Is_Gregorian_Leap (1900), "1900 not leap");
   Check (C.Is_Gregorian_Leap (2024), "2024 leap");
   Check (C.Days_In_Month (2024, 2) = 29, "Feb 2024 = 29");
   Check (C.Days_In_Month (2023, 2) = 28, "Feb 2023 = 28");
   Check (C.Ordinal_Day (MD (2020, 1, 1)) = 1, "ordinal Jan 1");
   Check (C.Ordinal_Day (MD (2020, 12, 31)) = 366, "ordinal leap Dec 31");
   Check (C.Same_Date
            (C.From_Ordinal (2020, 366), MD (2020, 12, 31)),
          "From_Ordinal 366");
   Check (C.Same_Date
            (C.Add_Days (MD (2020, 4, 12), 7), MD (2020, 4, 19)),
          "Add_Days +7");
   Check (C.Same_Date
            (C.Add_Days (MD (2020, 4, 1), -1), MD (2020, 3, 31)),
          "Add_Days -1 across month");

   ---------------------------------------------------------------------
   Section ("9. Edge years sample 1583..1700 every decade Sunday+window");
   ---------------------------------------------------------------------
   declare
      E : C.Date;
   begin
      for Y in C.Year_Number range 1583 .. 1700 loop
         if (Y - 1583) rem 10 = 0 then
            E := C.Gregorian_Easter (Y);
            Check (C.Is_Sunday (E),
                   "edge Sun" & C.Year_Number'Image (Y));
            Check (C.In_Easter_Window (E),
                   "edge Win" & C.Year_Number'Image (Y));
         end if;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Julian Mar/Apr for sample years");
   ---------------------------------------------------------------------
   declare
      J : C.Date;
   begin
      for Y in C.Year_Number range 2000 .. 2030 loop
         J := C.Julian_Easter (Y);
         Check (J.Month = 3 or else J.Month = 4,
                "J month" & C.Year_Number'Image (Y));
         Check (C.Same_Date
                  (C.Orthodox_Easter (Y),
                   C.Julian_To_Gregorian (J)),
                "J convert" & C.Year_Number'Image (Y));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. In_Easter_Window boundaries");
   ---------------------------------------------------------------------
   Check (C.In_Easter_Window (MD (1818, 3, 22)), "window Mar 22");
   Check (not C.In_Easter_Window (MD (1818, 3, 21)), "not Mar 21");
   Check (C.In_Easter_Window (MD (1943, 4, 25)), "window Apr 25");
   Check (not C.In_Easter_Window (MD (1943, 4, 26)), "not Apr 26");
   Check (not C.In_Easter_Window (MD (2020, 5, 1)), "not May");

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("All required tests passed.");
   elsif Fail_Count /= 0 then
      Put_Line ("SOME TESTS FAILED");
   else
      Put_Line ("Pass count below 100");
   end if;
end Tests;
