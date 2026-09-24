pragma SPARK_Mode (Off); --  Exceptions are used to test precondition traps

with Ada.Text_IO; use Ada.Text_IO;
with Accumulator; use Accumulator;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean);

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

   E : Engine;
   Caught : Boolean;
begin
   --  TEST 1: Single Positive Addition
   Put_Line ("TEST 1 — Single Positive Addition");
   Reset (E);
   Add_Sample (E, 500);
   Check ("1.1 Count is 1", E.Count = 1);
   Check ("1.2 Total is 500", E.Total = 500);
   Check ("1.3 Mean is 500", Current_Mean (E) = 500);

   --  TEST 2: Multiple Positive Additions
   Put_Line ("TEST 2 — Multiple Positive Additions");
   Reset (E);
   Add_Sample (E, 100);
   Add_Sample (E, 200);
   Add_Sample (E, 300);
   Check ("2.1 Count is 3", E.Count = 3);
   Check ("2.2 Total is 600", E.Total = 600);
   Check ("2.3 Mean is 200", Current_Mean (E) = 200);

   --  TEST 3: Reset Functionality
   Put_Line ("TEST 3 — Reset Functionality");
   Reset (E);
   Add_Sample (E, 1000);
   Reset (E);
   Check ("3.1 Count is 0 after reset", E.Count = 0);
   Check ("3.2 Total is 0 after reset", E.Total = 0);
   Add_Sample (E, 50);
   Check ("3.3 Count resumes at 1", E.Count = 1);

   --  TEST 4: Single Negative Addition
   Put_Line ("TEST 4 — Single Negative Addition");
   Reset (E);
   Add_Sample (E, -500);
   Check ("4.1 Count is 1", E.Count = 1);
   Check ("4.2 Total is -500", E.Total = -500);
   Check ("4.3 Mean is -500", Current_Mean (E) = -500);

   --  TEST 5: Multiple Negative Additions
   Put_Line ("TEST 5 — Multiple Negative Additions");
   Reset (E);
   Add_Sample (E, -100);
   Add_Sample (E, -200);
   Add_Sample (E, -300);
   Check ("5.1 Count is 3", E.Count = 3);
   Check ("5.2 Total is -600", E.Total = -600);
   Check ("5.3 Mean is -200", Current_Mean (E) = -200);

   --  TEST 6: Symmetrical Cancellation
   Put_Line ("TEST 6 — Symmetrical Cancellation");
   Reset (E);
   Add_Sample (E, 5000);
   Add_Sample (E, -5000);
   Check ("6.1 Count is 2", E.Count = 2);
   Check ("6.2 Total is 0", E.Total = 0);
   Check ("6.3 Mean is 0", Current_Mean (E) = 0);

   --  TEST 7: Extreme Positive Value
   Put_Line ("TEST 7 — Extreme Positive Value");
   Reset (E);
   Add_Sample (E, 10_000);
   Check ("7.1 Count is 1", E.Count = 1);
   Check ("7.2 Total is 10000", E.Total = 10_000);
   Check ("7.3 Mean is 10000", Current_Mean (E) = 10_000);

   --  TEST 8: Extreme Negative Value
   Put_Line ("TEST 8 — Extreme Negative Value");
   Reset (E);
   Add_Sample (E, -10_000);
   Check ("8.1 Count is 1", E.Count = 1);
   Check ("8.2 Total is -10000", E.Total = -10_000);
   Check ("8.3 Mean is -10000", Current_Mean (E) = -10_000);

   --  TEST 9: Zero Samples
   Put_Line ("TEST 9 — Zero Samples");
   Reset (E);
   Add_Sample (E, 0);
   Add_Sample (E, 0);
   Add_Sample (E, 0);
   Check ("9.1 Count is 3", E.Count = 3);
   Check ("9.2 Total is 0", E.Total = 0);
   Check ("9.3 Mean is 0", Current_Mean (E) = 0);

   --  TEST 10: Truncation Check (Positive)
   Put_Line ("TEST 10 — Truncation Check (Positive)");
   Reset (E);
   Add_Sample (E, 10);
   Add_Sample (E, 10);
   Add_Sample (E, 11);
   Check ("10.1 Count is 3", E.Count = 3);
   Check ("10.2 Total is 31", E.Total = 31);
   Check ("10.3 Mean truncates to 10", Current_Mean (E) = 10);

   --  TEST 11: Truncation Check (Negative)
   Put_Line ("TEST 11 — Truncation Check (Negative)");
   Reset (E);
   Add_Sample (E, -10);
   Add_Sample (E, -10);
   Add_Sample (E, -11);
   Check ("11.1 Count is 3", E.Count = 3);
   Check ("11.2 Total is -31", E.Total = -31);
   Check ("11.3 Mean truncates to -10", Current_Mean (E) = -10);

   --  TEST 12: Empty Mean Precondition Exception
   Put_Line ("TEST 12 — Empty Mean Precondition Exception");
   Reset (E);
   Check ("12.1 Engine is empty", E.Count = 0);
   Caught := False;
   begin
      declare
         Val : constant Sample_Value := Current_Mean (E);
         pragma Unreferenced (Val);
      begin
         null;
      end;
   exception
      when others => Caught := True;
   end;
   Check ("12.2 Exception caught calling Mean on empty", Caught);
   Check ("12.3 Engine count remains 0", E.Count = 0);

   --  TEST 13: Max Capacity Precondition Exception
   Put_Line ("TEST 13 — Max Capacity Precondition Exception");
   Reset (E);
   for I in 1 .. 1000 loop
      Add_Sample (E, 1);
   end loop;
   Check ("13.1 Count reached maximum 1000", E.Count = 1000);
   Check ("13.2 Total matches loop executions", E.Total = 1000);
   Caught := False;
   begin
      Add_Sample (E, 1);
   exception
      when others => Caught := True;
   end;
   Check ("13.3 Exception caught on 1001st addition", Caught);

   Put_Line ("");
   Put_Line
     ("=== " & Natural'Image (Pass_Count) & " passed, " &
      Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
