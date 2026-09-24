--  Standalone test suite for Manning_Criteria (main program).
--  Educational unit tests of published criterion counting — not clinical validation.

pragma Ada_2022;

with Ada.Text_IO;
with Manning_Criteria;

procedure Tests is

   use Ada.Text_IO;

   package MC renames Manning_Criteria;

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

   Empty : constant MC.Criteria := (others => <>);

   All_True : constant MC.Criteria :=
     (Pain_Linked_To_More_Frequent_Stools => True,
      Looser_Stools_With_Pain_Onset       => True,
      Pain_Relieved_By_Defecation         => True,
      Noticeable_Abdominal_Bloating       => True,
      Incomplete_Evacuation_GT_25_Pct     => True,
      Diarrhea_With_Mucus_GT_25_Pct       => True);

   function Bit_Set (Mask : Natural; Bit : Natural) return Boolean is
      M : Natural := Mask;
   begin
      for I in 1 .. Bit loop
         M := M / 2;
      end loop;
      return (M rem 2) = 1;
   end Bit_Set;

   function From_Mask (Mask : Natural) return MC.Criteria is
      C : MC.Criteria := Empty;
   begin
      C.Pain_Linked_To_More_Frequent_Stools := Bit_Set (Mask, 0);
      C.Looser_Stools_With_Pain_Onset       := Bit_Set (Mask, 1);
      C.Pain_Relieved_By_Defecation         := Bit_Set (Mask, 2);
      C.Noticeable_Abdominal_Bloating       := Bit_Set (Mask, 3);
      C.Incomplete_Evacuation_GT_25_Pct     := Bit_Set (Mask, 4);
      C.Diarrhea_With_Mucus_GT_25_Pct       := Bit_Set (Mask, 5);
      return C;
   end From_Mask;

   function Popcount6 (Mask : Natural) return Natural is
      N : Natural := 0;
   begin
      for Bit in 0 .. 5 loop
         if Bit_Set (Mask, Bit) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Popcount6;

begin
   Put_Line ("Manning_Criteria test suite");
   Put_Line ("===========================");
   Put_Line ("EDUCATIONAL ONLY — not for clinical use.");

   ---------------------------------------------------------------------
   Section ("1. Contribution helpers (absent / present)");
   ---------------------------------------------------------------------
   Check (MC.Pain_Linked_Contribution (False) = 0, "Pain_Linked absent = 0");
   Check (MC.Pain_Linked_Contribution (True) = 1, "Pain_Linked present = 1");
   Check (MC.Looser_Stools_Contribution (False) = 0, "Looser_Stools absent = 0");
   Check (MC.Looser_Stools_Contribution (True) = 1, "Looser_Stools present = 1");
   Check (MC.Pain_Relieved_Contribution (False) = 0, "Pain_Relieved absent = 0");
   Check (MC.Pain_Relieved_Contribution (True) = 1, "Pain_Relieved present = 1");
   Check (MC.Bloating_Contribution (False) = 0, "Bloating absent = 0");
   Check (MC.Bloating_Contribution (True) = 1, "Bloating present = 1");
   Check (MC.Incomplete_Evacuation_Contribution (False) = 0,
          "Incomplete_Evac absent = 0");
   Check (MC.Incomplete_Evacuation_Contribution (True) = 1,
          "Incomplete_Evac present = 1");
   Check (MC.Mucus_Diarrhea_Contribution (False) = 0, "Mucus absent = 0");
   Check (MC.Mucus_Diarrhea_Contribution (True) = 1, "Mucus present = 1");

   ---------------------------------------------------------------------
   Section ("2. Empty / all-true / threshold constants");
   ---------------------------------------------------------------------
   Check (MC.Positive_Count (Empty) = 0, "Empty Positive_Count = 0");
   Check (not MC.Is_Positive (Empty), "Empty not Is_Positive (default 3)");
   Check (not MC.Meets_Threshold (Empty, 2), "Empty fails threshold 2");
   Check (not MC.Meets_Threshold (Empty, 3), "Empty fails threshold 3");
   Check (not MC.Meets_Threshold (Empty, 4), "Empty fails threshold 4");
   Check (MC.Positive_Count (All_True) = 6, "All_True Positive_Count = 6");
   Check (MC.Is_Positive (All_True), "All_True Is_Positive");
   Check (MC.Meets_Threshold (All_True, 2), "All_True meets 2");
   Check (MC.Meets_Threshold (All_True, 3), "All_True meets 3");
   Check (MC.Meets_Threshold (All_True, 4), "All_True meets 4");
   declare
      --  Read default via Is_Positive semantics rather than comparing the
      --  named constant to a literal (avoids -gnatwc always-True warning).
      Two   : MC.Criteria;
      Three : MC.Criteria;
   begin
      Two := Empty;
      Two.Pain_Linked_To_More_Frequent_Stools := True;
      Two.Looser_Stools_With_Pain_Onset := True;
      Three := Two;
      Three.Pain_Relieved_By_Defecation := True;
      Check (not MC.Is_Positive (Two), "Default thr: count 2 not positive");
      Check (MC.Is_Positive (Three), "Default thr: count 3 is positive");
      Check (MC.Is_Positive (Three) = MC.Meets_Threshold (Three, 3),
             "Default Is_Positive matches thr 3");
   end;
   Check (MC.Meets_Threshold (0, 2) = False, "Count 0 fails thr 2");
   Check (MC.Meets_Threshold (1, 2) = False, "Count 1 fails thr 2");
   Check (MC.Meets_Threshold (2, 2) = True, "Count 2 meets thr 2");
   Check (MC.Meets_Threshold (2, 3) = False, "Count 2 fails thr 3");
   Check (MC.Meets_Threshold (3, 3) = True, "Count 3 meets thr 3");
   Check (MC.Meets_Threshold (3, 4) = False, "Count 3 fails thr 4");
   Check (MC.Meets_Threshold (4, 4) = True, "Count 4 meets thr 4");
   Check (MC.Meets_Threshold (5, 4) = True, "Count 5 meets thr 4");
   Check (MC.Meets_Threshold (6, 2) = True, "Count 6 meets thr 2");

   ---------------------------------------------------------------------
   Section ("3. Each single flag increments count by 1");
   ---------------------------------------------------------------------
   declare
      C : MC.Criteria;
   begin
      C := Empty;
      C.Pain_Linked_To_More_Frequent_Stools := True;
      Check (MC.Positive_Count (C) = 1, "Only pain-linked => 1");
      Check (MC.Has_Pain_Linked_To_More_Frequent_Stools (C),
             "Has_Pain_Linked true");
      Check (not MC.Is_Positive (C), "Single flag not positive @3");
      Check (MC.Meets_Threshold (C, 2) = False, "Single fails thr 2");

      C := Empty;
      C.Looser_Stools_With_Pain_Onset := True;
      Check (MC.Positive_Count (C) = 1, "Only looser stools => 1");
      Check (MC.Has_Looser_Stools_With_Pain_Onset (C), "Has_Looser true");

      C := Empty;
      C.Pain_Relieved_By_Defecation := True;
      Check (MC.Positive_Count (C) = 1, "Only pain relieved => 1");
      Check (MC.Has_Pain_Relieved_By_Defecation (C), "Has_Pain_Relieved true");

      C := Empty;
      C.Noticeable_Abdominal_Bloating := True;
      Check (MC.Positive_Count (C) = 1, "Only bloating => 1");
      Check (MC.Has_Noticeable_Abdominal_Bloating (C), "Has_Bloating true");

      C := Empty;
      C.Incomplete_Evacuation_GT_25_Pct := True;
      Check (MC.Positive_Count (C) = 1, "Only incomplete evac => 1");
      Check (MC.Has_Incomplete_Evacuation_GT_25_Pct (C),
             "Has_Incomplete true");

      C := Empty;
      C.Diarrhea_With_Mucus_GT_25_Pct := True;
      Check (MC.Positive_Count (C) = 1, "Only mucus diarrhea => 1");
      Check (MC.Has_Diarrhea_With_Mucus_GT_25_Pct (C), "Has_Mucus true");
   end;

   Check (not MC.Has_Pain_Linked_To_More_Frequent_Stools (Empty),
          "Empty Has_Pain_Linked false");
   Check (not MC.Has_Looser_Stools_With_Pain_Onset (Empty),
          "Empty Has_Looser false");
   Check (not MC.Has_Pain_Relieved_By_Defecation (Empty),
          "Empty Has_Pain_Relieved false");
   Check (not MC.Has_Noticeable_Abdominal_Bloating (Empty),
          "Empty Has_Bloating false");
   Check (not MC.Has_Incomplete_Evacuation_GT_25_Pct (Empty),
          "Empty Has_Incomplete false");
   Check (not MC.Has_Diarrhea_With_Mucus_GT_25_Pct (Empty),
          "Empty Has_Mucus false");

   ---------------------------------------------------------------------
   Section ("4. Pairwise increments (two flags => count 2)");
   ---------------------------------------------------------------------
   declare
      C : MC.Criteria;
   begin
      C := Empty;
      C.Pain_Linked_To_More_Frequent_Stools := True;
      C.Looser_Stools_With_Pain_Onset := True;
      Check (MC.Positive_Count (C) = 2, "Pain+Looser => 2");
      Check (MC.Meets_Threshold (C, 2), "Pair meets thr 2");
      Check (not MC.Meets_Threshold (C, 3), "Pair fails thr 3");
      Check (not MC.Is_Positive (C), "Pair not Is_Positive @3");
      Check (MC.Is_Positive (C, 2), "Pair Is_Positive @2");

      C := Empty;
      C.Pain_Relieved_By_Defecation := True;
      C.Noticeable_Abdominal_Bloating := True;
      Check (MC.Positive_Count (C) = 2, "Relieved+Bloating => 2");

      C := Empty;
      C.Incomplete_Evacuation_GT_25_Pct := True;
      C.Diarrhea_With_Mucus_GT_25_Pct := True;
      Check (MC.Positive_Count (C) = 2, "Incomplete+Mucus => 2");

      C := Empty;
      C.Pain_Linked_To_More_Frequent_Stools := True;
      C.Diarrhea_With_Mucus_GT_25_Pct := True;
      Check (MC.Positive_Count (C) = 2, "Pain+Mucus => 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Triple / quadruple thresholds");
   ---------------------------------------------------------------------
   declare
      C : MC.Criteria;
   begin
      C := Empty;
      C.Pain_Linked_To_More_Frequent_Stools := True;
      C.Looser_Stools_With_Pain_Onset := True;
      C.Pain_Relieved_By_Defecation := True;
      Check (MC.Positive_Count (C) = 3, "Classic triad => 3");
      Check (MC.Is_Positive (C), "Triad Is_Positive @3");
      Check (MC.Meets_Threshold (C, 2), "Triad meets 2");
      Check (MC.Meets_Threshold (C, 3), "Triad meets 3");
      Check (not MC.Meets_Threshold (C, 4), "Triad fails 4");
      Check (MC.Is_Positive (C, 4) = False, "Triad not positive @4");

      C.Noticeable_Abdominal_Bloating := True;
      Check (MC.Positive_Count (C) = 4, "Four flags => 4");
      Check (MC.Meets_Threshold (C, 4), "Four meets thr 4");
      Check (MC.Is_Positive (C, 4), "Four Is_Positive @4");
      Check (MC.Is_Positive (C), "Four Is_Positive @default");

      C.Incomplete_Evacuation_GT_25_Pct := True;
      Check (MC.Positive_Count (C) = 5, "Five flags => 5");
      C.Diarrhea_With_Mucus_GT_25_Pct := True;
      Check (MC.Positive_Count (C) = 6, "Six flags => 6");
   end;

   ---------------------------------------------------------------------
   Section ("6. Full combinatorial mask space (2^6 = 64)");
   ---------------------------------------------------------------------
   declare
      Comb_Pass : Natural := 0;
   begin
      for Mask in 0 .. 63 loop
         declare
            C      : constant MC.Criteria := From_Mask (Mask);
            Count  : constant Natural := Natural (MC.Positive_Count (C));
            Expect : constant Natural := Popcount6 (Mask);
            OK     : Boolean;
         begin
            OK := Count = Expect
              and then MC.Meets_Threshold
                         (MC.Criterion_Count (Count), 2) = (Expect >= 2)
              and then MC.Meets_Threshold
                         (MC.Criterion_Count (Count), 3) = (Expect >= 3)
              and then MC.Meets_Threshold
                         (MC.Criterion_Count (Count), 4) = (Expect >= 4)
              and then MC.Is_Positive (C) = (Expect >= 3)
              and then MC.Is_Positive (C, 2) = (Expect >= 2)
              and then MC.Is_Positive (C, 4) = (Expect >= 4);
            Check (OK,
                   "Mask" & Natural'Image (Mask)
                   & " count=" & Natural'Image (Expect));
            if OK then
               Comb_Pass := Comb_Pass + 1;
            end if;
         end;
      end loop;
      Check (Comb_Pass = 64, "All 64 combinatorial masks OK");
   end;

   ---------------------------------------------------------------------
   Section ("7. Educational vignettes (not clinical cases)");
   ---------------------------------------------------------------------
   declare
      C : MC.Criteria;
   begin
      C := (Pain_Linked_To_More_Frequent_Stools => True,
            Looser_Stools_With_Pain_Onset       => True,
            Pain_Relieved_By_Defecation         => True,
            Noticeable_Abdominal_Bloating       => False,
            Incomplete_Evacuation_GT_25_Pct     => False,
            Diarrhea_With_Mucus_GT_25_Pct       => False);
      Check (MC.Positive_Count (C) = 3, "Vignette A count = 3");
      Check (MC.Is_Positive (C), "Vignette A positive @3");
      Check (not MC.Is_Positive (C, 4), "Vignette A not @4");

      C := (Pain_Linked_To_More_Frequent_Stools => False,
            Looser_Stools_With_Pain_Onset       => False,
            Pain_Relieved_By_Defecation         => False,
            Noticeable_Abdominal_Bloating       => True,
            Incomplete_Evacuation_GT_25_Pct     => True,
            Diarrhea_With_Mucus_GT_25_Pct       => True);
      Check (MC.Positive_Count (C) = 3, "Vignette B count = 3");
      Check (MC.Is_Positive (C), "Vignette B positive @3");

      C := Empty;
      C.Noticeable_Abdominal_Bloating := True;
      Check (MC.Positive_Count (C) = 1, "Vignette C count = 1");
      Check (not MC.Is_Positive (C, 2), "Vignette C not @2");

      C := (Pain_Linked_To_More_Frequent_Stools => True,
            Looser_Stools_With_Pain_Onset       => False,
            Pain_Relieved_By_Defecation         => True,
            Noticeable_Abdominal_Bloating       => True,
            Incomplete_Evacuation_GT_25_Pct     => False,
            Diarrhea_With_Mucus_GT_25_Pct       => True);
      Check (MC.Positive_Count (C) = 4, "Vignette D count = 4");
      Check (MC.Is_Positive (C, 4), "Vignette D positive @4");
      Check (MC.Meets_Threshold (C, 2) and then MC.Meets_Threshold (C, 3)
               and then MC.Meets_Threshold (C, 4),
             "Vignette D meets 2/3/4");

      C := Empty;
      C.Pain_Relieved_By_Defecation := True;
      C.Looser_Stools_With_Pain_Onset := True;
      Check (MC.Positive_Count (C) = 2, "Vignette E count = 2");
      Check (MC.Is_Positive (C, 2), "Vignette E positive @2");
      Check (not MC.Is_Positive (C), "Vignette E not @default 3");
      Check (not MC.Is_Positive (C, 4), "Vignette E not @4");
   end;

   ---------------------------------------------------------------------
   Section ("8. Record vs count Meets_Threshold overloads");
   ---------------------------------------------------------------------
   declare
      C : MC.Criteria := All_True;
   begin
      for T in MC.Threshold_Range loop
         Check (MC.Meets_Threshold (C, T) = MC.Meets_Threshold (6, T),
                "All_True overload match thr"
                & MC.Threshold_Range'Image (T));
         Check (MC.Is_Positive (C, T) = MC.Meets_Threshold (C, T),
                "Is_Positive equiv Meets thr"
                & MC.Threshold_Range'Image (T));
      end loop;
      C := Empty;
      for T in MC.Threshold_Range loop
         Check (not MC.Meets_Threshold (C, T),
                "Empty fails thr" & MC.Threshold_Range'Image (T));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Contribution sum equals Positive_Count");
   ---------------------------------------------------------------------
   declare
      C   : MC.Criteria;
      Sum : Natural;
   begin
      for Mask in 0 .. 15 loop
         C := From_Mask (Mask);
         Sum := MC.Pain_Linked_Contribution
                  (C.Pain_Linked_To_More_Frequent_Stools)
              + MC.Looser_Stools_Contribution
                  (C.Looser_Stools_With_Pain_Onset)
              + MC.Pain_Relieved_Contribution
                  (C.Pain_Relieved_By_Defecation)
              + MC.Bloating_Contribution
                  (C.Noticeable_Abdominal_Bloating)
              + MC.Incomplete_Evacuation_Contribution
                  (C.Incomplete_Evacuation_GT_25_Pct)
              + MC.Mucus_Diarrhea_Contribution
                  (C.Diarrhea_With_Mucus_GT_25_Pct);
         Check (Sum = Natural (MC.Positive_Count (C)),
                "Contrib sum mask" & Natural'Image (Mask));
      end loop;
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("All tests passed.");
   else
      Put_Line ("SOME TESTS FAILED.");
   end if;
end Tests;
