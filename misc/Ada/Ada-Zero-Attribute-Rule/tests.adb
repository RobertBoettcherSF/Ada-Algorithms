with Ada.Text_IO; use Ada.Text_IO;
with Zero_Attribute_Rule; use Zero_Attribute_Rule;

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
begin
   -----------------------------------------------------------------------------
   --  TEST 1: Numeric Mean (Basic)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 1 — Numeric Mean (Basic Arrays)");
   Check ("1.1 Calculate mean of (1.0, 3.0) -> 2.0", 
          Predict_Numeric_Mean (Numeric_Array'[1.0, 3.0]) = 2.0);
   Check ("1.2 Calculate mean of (-1.0, 1.0) -> 0.0", 
          Predict_Numeric_Mean (Numeric_Array'[-1.0, 1.0]) = 0.0);
   Check ("1.3 Calculate mean of (2.5, 7.5) -> 5.0", 
          Predict_Numeric_Mean (Numeric_Array'[2.5, 7.5]) = 5.0);

   -----------------------------------------------------------------------------
   --  TEST 2: Numeric Mean (Single Elements)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 2 — Numeric Mean (Single Element)");
   Check ("2.1 Array (42.0) -> 42.0", 
          Predict_Numeric_Mean (Numeric_Array'[1 => 42.0]) = 42.0);
   Check ("2.2 Array (0.0) -> 0.0", 
          Predict_Numeric_Mean (Numeric_Array'[1 => 0.0]) = 0.0);
   Check ("2.3 Array (-5.5) -> -5.5", 
          Predict_Numeric_Mean (Numeric_Array'[1 => -5.5]) = -5.5);

   -----------------------------------------------------------------------------
   --  TEST 3: Numeric Mean (Uniform Datasets)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 3 — Numeric Mean (Uniform Elements)");
   Check ("3.1 Array (7.0, 7.0) -> 7.0", 
          Predict_Numeric_Mean (Numeric_Array'[7.0, 7.0]) = 7.0);
   Check ("3.2 Array of ones -> 1.0", 
          Predict_Numeric_Mean (Numeric_Array'[1.0, 1.0, 1.0, 1.0]) = 1.0);
   Check ("3.3 Array of neg twos -> -2.0", 
          Predict_Numeric_Mean (Numeric_Array'[-2.0, -2.0, -2.0]) = -2.0);

   -----------------------------------------------------------------------------
   --  TEST 4: Numeric Median (Odd Array Lengths)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 4 — Numeric Median (Odd Array Lengths)");
   Check ("4.1 Array (1.0, 2.0, 3.0) -> 2.0", 
          Predict_Numeric_Median (Numeric_Array'[1.0, 2.0, 3.0]) = 2.0);
   Check ("4.2 Unsorted (10.0, 50.0, 30.0) -> 30.0", 
          Predict_Numeric_Median (Numeric_Array'[10.0, 50.0, 30.0]) = 30.0);
   Check ("4.3 Unsorted mixed (-5.0, 5.0, 0.0) -> 0.0", 
          Predict_Numeric_Median (Numeric_Array'[-5.0, 5.0, 0.0]) = 0.0);

   -----------------------------------------------------------------------------
   --  TEST 5: Numeric Median (Even Array Lengths)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 5 — Numeric Median (Even Array Lengths)");
   Check ("5.1 Array (1.0, 2.0, 3.0, 4.0) -> 2.5", 
          Predict_Numeric_Median (Numeric_Array'[1.0, 2.0, 3.0, 4.0]) = 2.5);
   Check ("5.2 Unsorted (20.0, 10.0) -> 15.0", 
          Predict_Numeric_Median (Numeric_Array'[20.0, 10.0]) = 15.0);
   Check ("5.3 Edge balance (-1.0, 1.0) -> 0.0", 
          Predict_Numeric_Median (Numeric_Array'[-1.0, 1.0]) = 0.0);

   -----------------------------------------------------------------------------
   --  TEST 6: Numeric Median (Single Elements)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 6 — Numeric Median (Single Element)");
   Check ("6.1 Array (8.0) -> 8.0", 
          Predict_Numeric_Median (Numeric_Array'[1 => 8.0]) = 8.0);
   Check ("6.2 Array (-8.0) -> -8.0", 
          Predict_Numeric_Median (Numeric_Array'[1 => -8.0]) = -8.0);
   Check ("6.3 Array (0.0) -> 0.0", 
          Predict_Numeric_Median (Numeric_Array'[1 => 0.0]) = 0.0);

   -----------------------------------------------------------------------------
   --  TEST 7: Nominal Mode (Clear Winners)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 7 — Nominal Mode (Clear Winner)");
   Check ("7.1 Array (1, 2, 2) -> 2", 
          Predict_Nominal_Mode (Nominal_Array'[1, 2, 2]) = 2);
   Check ("7.2 Array (3, 3, 3, 1) -> 3", 
          Predict_Nominal_Mode (Nominal_Array'[3, 3, 3, 1]) = 3);
   Check ("7.3 Array (5, 5, 1, 1, 5) -> 5", 
          Predict_Nominal_Mode (Nominal_Array'[5, 5, 1, 1, 5]) = 5);

   -----------------------------------------------------------------------------
   --  TEST 8: Nominal Mode (Tiebreakers)
   -----------------------------------------------------------------------------
   --  Tie-breaking logic picks the numerically smallest class ID by design.
   Put_Line ("TEST 8 — Nominal Mode (Tiebreakers resolve to smallest ID)");
   Check ("8.1 Ties 1 and 2: (1, 1, 2, 2) -> 1", 
          Predict_Nominal_Mode (Nominal_Array'[1, 1, 2, 2]) = 1);
   Check ("8.2 Ties 1 and 2 reversed input: (2, 2, 1, 1) -> 1", 
          Predict_Nominal_Mode (Nominal_Array'[2, 2, 1, 1]) = 1);
   Check ("8.3 Complex ties (30, 20, 10, 30, 20, 10) -> 10", 
          Predict_Nominal_Mode (Nominal_Array'[30, 20, 10, 30, 20, 10]) = 10);

   -----------------------------------------------------------------------------
   --  TEST 9: Nominal Mode (Single Elements)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 9 — Nominal Mode (Single Element)");
   Check ("9.1 Array (1) -> 1", 
          Predict_Nominal_Mode (Nominal_Array'[1 => 1]) = 1);
   Check ("9.2 Array (99) -> 99", 
          Predict_Nominal_Mode (Nominal_Array'[1 => 99]) = 99);
   Check ("9.3 Array (42) -> 42", 
          Predict_Nominal_Mode (Nominal_Array'[1 => 42]) = 42);

   -----------------------------------------------------------------------------
   --  TEST 10: Safe Numeric Mean (Exception Handling)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 10 — Safe Numeric Mean");
   begin
      if Safe_Predict_Numeric_Mean (Numeric_Array'[1 .. 0 => 0.0]) = 0.0 then
         Check ("10.1 Empty dataset raises exception", False);
      end if;
      Check ("10.1 Impossible path reached", False);
   exception
      when Empty_Dataset_Error => Check ("10.1 Empty dataset raises exception", True);
      when others => Check ("10.1 Wrong exception raised", False);
   end;
   Check ("10.2 Normal usage via Safe array (1.0) -> 1.0", 
          Safe_Predict_Numeric_Mean (Numeric_Array'[1 => 1.0]) = 1.0);
   Check ("10.3 Normal usage via Safe array (1.0, 3.0) -> 2.0", 
          Safe_Predict_Numeric_Mean (Numeric_Array'[1.0, 3.0]) = 2.0);

   -----------------------------------------------------------------------------
   --  TEST 11: Safe Numeric Median (Exception Handling)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 11 — Safe Numeric Median");
   begin
      if Safe_Predict_Numeric_Median (Numeric_Array'[1 .. 0 => 0.0]) = 0.0 then
         Check ("11.1 Empty dataset raises exception", False);
      end if;
      Check ("11.1 Impossible path reached", False);
   exception
      when Empty_Dataset_Error => Check ("11.1 Empty dataset raises exception", True);
      when others => Check ("11.1 Wrong exception raised", False);
   end;
   Check ("11.2 Normal usage via Safe array (1.0) -> 1.0", 
          Safe_Predict_Numeric_Median (Numeric_Array'[1 => 1.0]) = 1.0);
   Check ("11.3 Normal usage via Safe array (1.0, 3.0) -> 2.0", 
          Safe_Predict_Numeric_Median (Numeric_Array'[1.0, 3.0]) = 2.0);

   -----------------------------------------------------------------------------
   --  TEST 12: Safe Nominal Mode (Exception Handling)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 12 — Safe Nominal Mode");
   begin
      if Safe_Predict_Nominal_Mode (Nominal_Array'[1 .. 0 => 0]) = 0 then
         Check ("12.1 Empty dataset raises exception", False);
      end if;
      Check ("12.1 Impossible path reached", False);
   exception
      when Empty_Dataset_Error => Check ("12.1 Empty dataset raises exception", True);
      when others => Check ("12.1 Wrong exception raised", False);
   end;
   Check ("12.2 Normal usage via Safe array (1) -> 1", 
          Safe_Predict_Nominal_Mode (Nominal_Array'[1 => 1]) = 1);
   Check ("12.3 Normal usage via Safe array (1, 3) -> 1 (tie breaks to 1)", 
          Safe_Predict_Nominal_Mode (Nominal_Array'[1, 3]) = 1);

   -----------------------------------------------------------------------------
   --  TEST 13: Invariants Cross-Check
   -----------------------------------------------------------------------------
   Put_Line ("TEST 13 — Algorithmic Invariants");
   Check ("13.1 Mean(2, 2) == Median(2, 2)", 
          Predict_Numeric_Mean (Numeric_Array'[2.0, 2.0]) = 
          Predict_Numeric_Median (Numeric_Array'[2.0, 2.0]));
   Check ("13.2 Mean(-1, 1) == Median(-1, 1)", 
          Predict_Numeric_Mean (Numeric_Array'[-1.0, 1.0]) = 
          Predict_Numeric_Median (Numeric_Array'[-1.0, 1.0]));
   Check ("13.3 Mode(1, 2, 2) independent of order (2, 1, 2)", 
          Predict_Nominal_Mode (Nominal_Array'[1, 2, 2]) = 
          Predict_Nominal_Mode (Nominal_Array'[2, 1, 2]));

   -----------------------------------------------------------------------------
   --  TEST 14: Large Datasets / Aggregates Validate Performance & Correctness
   -----------------------------------------------------------------------------
   Put_Line ("TEST 14 — Large Arrays");
   declare
      A : constant Nominal_Array (1 .. 100) := [others => 1];
      B : constant Nominal_Array (1 .. 101) := [1 .. 50 => 1, 51 .. 101 => 2];
      C : constant Nominal_Array (1 .. 101) := [1 .. 51 => 1, 52 .. 101 => 2];
   begin
      Check ("14.1 Mode of 100 1s -> 1", 
             Predict_Nominal_Mode (A) = 1);
      Check ("14.2 Mode of 50 1s and 51 2s -> 2", 
             Predict_Nominal_Mode (B) = 2);
      Check ("14.3 Mode of 51 1s and 50 2s -> 1", 
             Predict_Nominal_Mode (C) = 1);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
