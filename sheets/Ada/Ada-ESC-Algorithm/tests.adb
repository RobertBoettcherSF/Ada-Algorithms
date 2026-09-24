--  Standalone test suite for ESC_Algorithm (main program).
--  Educational unit tests of published rule-of-thumb cutoffs — not clinical validation.

pragma Ada_2022;

with Ada.Text_IO;
with ESC_Algorithm;

procedure Tests is

   use Ada.Text_IO;

   package EA renames ESC_Algorithm;
   use EA;

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

   Empty_Sx : constant EA.Symptom_Flags := (others => False);

   All_Sx : constant EA.Symptom_Flags :=
     (Dyspnea => True, Orthopnea => True, Edema => True, Fatigue => True);

   function Bit_Set (Mask : Natural; Bit : Natural) return Boolean is
      M : Natural := Mask;
   begin
      for I in 1 .. Bit loop
         M := M / 2;
      end loop;
      return (M rem 2) = 1;
   end Bit_Set;

   function Sx_From_Mask (Mask : Natural) return EA.Symptom_Flags is
      S : EA.Symptom_Flags := Empty_Sx;
   begin
      S.Dyspnea   := Bit_Set (Mask, 0);
      S.Orthopnea := Bit_Set (Mask, 1);
      S.Edema     := Bit_Set (Mask, 2);
      S.Fatigue   := Bit_Set (Mask, 3);
      return S;
   end Sx_From_Mask;

   function Popcount4 (Mask : Natural) return Natural is
      N : Natural := 0;
   begin
      for Bit in 0 .. 3 loop
         if Bit_Set (Mask, Bit) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Popcount4;

   function NT_Panel (Value : EA.Peptide_Pg_Per_mL) return EA.Peptide_Panel is
   begin
      return (NT_proBNP_Measured => True,
              NT_proBNP_Value    => Value,
              BNP_Measured       => False,
              BNP_Value          => 0);
   end NT_Panel;

   function BNP_Panel (Value : EA.Peptide_Pg_Per_mL) return EA.Peptide_Panel is
   begin
      return (NT_proBNP_Measured => False,
              NT_proBNP_Value    => 0,
              BNP_Measured       => True,
              BNP_Value          => Value);
   end BNP_Panel;

   function Both_Panel
     (NT  : EA.Peptide_Pg_Per_mL;
      BNP : EA.Peptide_Pg_Per_mL) return EA.Peptide_Panel
   is
   begin
      return (NT_proBNP_Measured => True,
              NT_proBNP_Value    => NT,
              BNP_Measured       => True,
              BNP_Value          => BNP);
   end Both_Panel;

   function Mk_Workup
     (Sx  : EA.Symptom_Flags;
      P   : EA.Peptide_Panel;
      EF_M : Boolean := False;
      EF  : EA.EF_Percent := 0) return EA.Workup
   is
   begin
      return (Symptoms => Sx, Peptides => P, EF_Measured => EF_M, EF => EF);
   end Mk_Workup;

begin
   Put_Line ("ESC_Algorithm test suite");
   Put_Line ("========================");
   Put_Line ("EDUCATIONAL ONLY — not for clinical use.");

   ---------------------------------------------------------------------
   Section ("1. Named constants used by predicates / bands");
   ---------------------------------------------------------------------
   declare
      NT_Cut  : constant Natural := EA.NT_proBNP_Chronic_Cutoff_Pg_Per_mL;
      BNP_Cut : constant Natural := EA.BNP_Chronic_Cutoff_Pg_Per_mL;
   begin
      Check (not EA.NT_proBNP_Elevated (NT_Cut - 1),
             "NT cutoff-1 not elevated");
      Check (EA.NT_proBNP_Elevated (NT_Cut),
             "NT at named cutoff elevated");
      Check (not EA.BNP_Elevated (BNP_Cut - 1),
             "BNP cutoff-1 not elevated");
      Check (EA.BNP_Elevated (BNP_Cut),
             "BNP at named cutoff elevated");
      Check (EA.Classify_EF (EA.EF_Percent (EA.EF_HFrEF_Max)) = EA.HFrEF,
             "EF_HFrEF_Max classifies HFrEF");
      Check (EA.Classify_EF (EA.EF_Percent (EA.EF_HFmrEF_Min)) = EA.HFmrEF,
             "EF_HFmrEF_Min classifies HFmrEF");
      Check (EA.Classify_EF (EA.EF_Percent (EA.EF_HFmrEF_Max)) = EA.HFmrEF,
             "EF_HFmrEF_Max classifies HFmrEF");
      Check (EA.Classify_EF (EA.EF_Percent (EA.EF_HFpEF_Min)) = EA.HFpEF,
             "EF_HFpEF_Min classifies HFpEF");
   end;

   ---------------------------------------------------------------------
   Section ("2. Symptom gate — empty / single / all");
   ---------------------------------------------------------------------
   Check (not EA.Has_Suggestive_Symptoms (Empty_Sx), "empty symptoms → False");
   Check (EA.Symptom_Count (Empty_Sx) = 0, "empty count = 0");
   Check (EA.Has_Suggestive_Symptoms (All_Sx), "all symptoms → True");
   Check (EA.Symptom_Count (All_Sx) = 4, "all count = 4");

   Check (EA.Has_Dyspnea (All_Sx), "Has_Dyspnea all");
   Check (EA.Has_Orthopnea (All_Sx), "Has_Orthopnea all");
   Check (EA.Has_Edema (All_Sx), "Has_Edema all");
   Check (EA.Has_Fatigue (All_Sx), "Has_Fatigue all");
   Check (not EA.Has_Dyspnea (Empty_Sx), "Has_Dyspnea empty");
   Check (not EA.Has_Orthopnea (Empty_Sx), "Has_Orthopnea empty");
   Check (not EA.Has_Edema (Empty_Sx), "Has_Edema empty");
   Check (not EA.Has_Fatigue (Empty_Sx), "Has_Fatigue empty");

   declare
      Only_D : constant EA.Symptom_Flags :=
        (Dyspnea => True, others => False);
      Only_O : constant EA.Symptom_Flags :=
        (Orthopnea => True, others => False);
      Only_E : constant EA.Symptom_Flags :=
        (Edema => True, others => False);
      Only_F : constant EA.Symptom_Flags :=
        (Fatigue => True, others => False);
   begin
      Check (EA.Has_Suggestive_Symptoms (Only_D), "dyspnea alone suggestive");
      Check (EA.Has_Suggestive_Symptoms (Only_O), "orthopnea alone suggestive");
      Check (EA.Has_Suggestive_Symptoms (Only_E), "edema alone suggestive");
      Check (EA.Has_Suggestive_Symptoms (Only_F), "fatigue alone suggestive");
      Check (EA.Symptom_Count (Only_D) = 1, "dyspnea count = 1");
      Check (EA.Symptom_Count (Only_O) = 1, "orthopnea count = 1");
      Check (EA.Symptom_Count (Only_E) = 1, "edema count = 1");
      Check (EA.Symptom_Count (Only_F) = 1, "fatigue count = 1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Symptom combinatorial masks (0..15)");
   ---------------------------------------------------------------------
   for Mask in 0 .. 15 loop
      declare
         S : constant EA.Symptom_Flags := Sx_From_Mask (Mask);
         N : constant Natural := Popcount4 (Mask);
      begin
         Check (EA.Symptom_Count (S) = N,
                "mask" & Natural'Image (Mask) & " count");
         Check (EA.Has_Suggestive_Symptoms (S) = (N > 0),
                "mask" & Natural'Image (Mask) & " suggestive");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("4. NT-proBNP boundaries (124 vs 125)");
   ---------------------------------------------------------------------
   Check (not EA.NT_proBNP_Elevated (0), "NT-proBNP 0 not elevated");
   Check (not EA.NT_proBNP_Elevated (124), "NT-proBNP 124 not elevated");
   Check (EA.NT_proBNP_Elevated (125), "NT-proBNP 125 elevated");
   Check (EA.NT_proBNP_Elevated (126), "NT-proBNP 126 elevated");
   Check (EA.NT_proBNP_Elevated (1000), "NT-proBNP 1000 elevated");
   Check (not EA.NT_proBNP_Elevated (1), "NT-proBNP 1 not elevated");
   Check (not EA.NT_proBNP_Elevated (62), "NT-proBNP 62 not elevated");
   Check (EA.NT_proBNP_Elevated (250), "NT-proBNP 250 elevated");

   ---------------------------------------------------------------------
   Section ("5. BNP boundaries (34 vs 35)");
   ---------------------------------------------------------------------
   Check (not EA.BNP_Elevated (0), "BNP 0 not elevated");
   Check (not EA.BNP_Elevated (34), "BNP 34 not elevated");
   Check (EA.BNP_Elevated (35), "BNP 35 elevated");
   Check (EA.BNP_Elevated (36), "BNP 36 elevated");
   Check (EA.BNP_Elevated (100), "BNP 100 elevated");
   Check (not EA.BNP_Elevated (1), "BNP 1 not elevated");
   Check (not EA.BNP_Elevated (17), "BNP 17 not elevated");
   Check (EA.BNP_Elevated (70), "BNP 70 elevated");

   ---------------------------------------------------------------------
   Section ("6. Natriuretic_Gate_Positive / Any_Peptide_Measured");
   ---------------------------------------------------------------------
   declare
      None_P : constant EA.Peptide_Panel := (others => <>);
   begin
      Check (not EA.Any_Peptide_Measured (None_P), "none measured");
      Check (not EA.Natriuretic_Gate_Positive (None_P), "none → gate False");
   end;

   Check (EA.Any_Peptide_Measured (NT_Panel (0)), "NT measured even if 0");
   Check (not EA.Natriuretic_Gate_Positive (NT_Panel (124)), "NT 124 gate False");
   Check (EA.Natriuretic_Gate_Positive (NT_Panel (125)), "NT 125 gate True");
   Check (EA.Any_Peptide_Measured (BNP_Panel (0)), "BNP measured even if 0");
   Check (not EA.Natriuretic_Gate_Positive (BNP_Panel (34)), "BNP 34 gate False");
   Check (EA.Natriuretic_Gate_Positive (BNP_Panel (35)), "BNP 35 gate True");

   -- Mixed: either elevated is enough
   Check (EA.Natriuretic_Gate_Positive (Both_Panel (200, 10)),
          "NT high BNP low → gate True");
   Check (EA.Natriuretic_Gate_Positive (Both_Panel (50, 40)),
          "NT low BNP high → gate True");
   Check (EA.Natriuretic_Gate_Positive (Both_Panel (200, 40)),
          "both high → gate True");
   Check (not EA.Natriuretic_Gate_Positive (Both_Panel (100, 20)),
          "both low → gate False");

   -- Unmeasured side ignored (value present but Measured=False)
   declare
      Fake_NT : constant EA.Peptide_Panel :=
        (NT_proBNP_Measured => False,
         NT_proBNP_Value    => 9999,
         BNP_Measured       => False,
         BNP_Value          => 0);
      Fake_BNP : constant EA.Peptide_Panel :=
        (NT_proBNP_Measured => False,
         NT_proBNP_Value    => 0,
         BNP_Measured       => False,
         BNP_Value          => 9999);
   begin
      Check (not EA.Natriuretic_Gate_Positive (Fake_NT),
             "unmeasured high NT ignored");
      Check (not EA.Natriuretic_Gate_Positive (Fake_BNP),
             "unmeasured high BNP ignored");
   end;

   ---------------------------------------------------------------------
   Section ("7. Classify_EF boundaries (40/41/49/50)");
   ---------------------------------------------------------------------
   Check (EA.Classify_EF (0) = EA.HFrEF, "EF 0 → HFrEF");
   Check (EA.Classify_EF (20) = EA.HFrEF, "EF 20 → HFrEF");
   Check (EA.Classify_EF (39) = EA.HFrEF, "EF 39 → HFrEF");
   Check (EA.Classify_EF (40) = EA.HFrEF, "EF 40 → HFrEF");
   Check (EA.Classify_EF (41) = EA.HFmrEF, "EF 41 → HFmrEF");
   Check (EA.Classify_EF (45) = EA.HFmrEF, "EF 45 → HFmrEF");
   Check (EA.Classify_EF (49) = EA.HFmrEF, "EF 49 → HFmrEF");
   Check (EA.Classify_EF (50) = EA.HFpEF, "EF 50 → HFpEF");
   Check (EA.Classify_EF (55) = EA.HFpEF, "EF 55 → HFpEF");
   Check (EA.Classify_EF (60) = EA.HFpEF, "EF 60 → HFpEF");
   Check (EA.Classify_EF (100) = EA.HFpEF, "EF 100 → HFpEF");

   Check (EA.Phenotype_To_Pathway (EA.HFrEF) = EA.HF_Reduced,
          "HFrEF → HF_Reduced");
   Check (EA.Phenotype_To_Pathway (EA.HFmrEF) = EA.HF_Mildly_Reduced,
          "HFmrEF → HF_Mildly_Reduced");
   Check (EA.Phenotype_To_Pathway (EA.HFpEF) = EA.HF_Preserved,
          "HFpEF → HF_Preserved");

   ---------------------------------------------------------------------
   Section ("8. Pathway: no symptoms → Unlikely");
   ---------------------------------------------------------------------
   Check (EA.Evaluate_Pathway
            (Mk_Workup (Empty_Sx, (others => <>))) = EA.Unlikely,
          "no sx, no labs → Unlikely");
   Check (EA.Evaluate_Pathway
            (Mk_Workup (Empty_Sx, NT_Panel (500), True, 30)) = EA.Unlikely,
          "no sx despite high NP+low EF → Unlikely");
   Check (EA.Evaluate_Pathway
            (Mk_Workup (Empty_Sx, BNP_Panel (100))) = EA.Unlikely,
          "no sx high BNP → Unlikely");

   ---------------------------------------------------------------------
   Section ("9. Pathway: incomplete data (symptoms, no NP)");
   ---------------------------------------------------------------------
   declare
      Sx : constant EA.Symptom_Flags :=
        (Dyspnea => True, others => False);
      None_P : constant EA.Peptide_Panel := (others => <>);
   begin
      Check (EA.Evaluate_Pathway (Mk_Workup (Sx, None_P)) = EA.Incomplete_Data,
             "sx no NP → Incomplete_Data");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, None_P, True, 35)) = EA.Incomplete_Data,
             "sx EF but no NP → Incomplete_Data");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (All_Sx, None_P)) = EA.Incomplete_Data,
             "all sx no NP → Incomplete_Data");
   end;

   ---------------------------------------------------------------------
   Section ("10. Pathway: NP not elevated → Unlikely");
   ---------------------------------------------------------------------
   declare
      Sx : constant EA.Symptom_Flags :=
        (Dyspnea => True, Edema => True, others => False);
   begin
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (124))) = EA.Unlikely,
             "sx NT 124 → Unlikely");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, BNP_Panel (34))) = EA.Unlikely,
             "sx BNP 34 → Unlikely");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (100, 20))) = EA.Unlikely,
             "sx both low → Unlikely");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (0), True, 25)) = EA.Unlikely,
             "sx NT 0 with EF → Unlikely");
   end;

   ---------------------------------------------------------------------
   Section ("11. Pathway: NP elevated, no EF → Consider_Echo");
   ---------------------------------------------------------------------
   declare
      Sx : constant EA.Symptom_Flags :=
        (Fatigue => True, others => False);
   begin
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (125))) = EA.Consider_Echo,
             "sx NT 125 no EF → Consider_Echo");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, BNP_Panel (35))) = EA.Consider_Echo,
             "sx BNP 35 no EF → Consider_Echo");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (500))) = EA.Consider_Echo,
             "sx NT 500 no EF → Consider_Echo");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (All_Sx, Both_Panel (200, 50))) = EA.Consider_Echo,
             "all sx both high no EF → Consider_Echo");
   end;

   ---------------------------------------------------------------------
   Section ("12. Pathway: phenotypes with elevated NP");
   ---------------------------------------------------------------------
   declare
      Sx : constant EA.Symptom_Flags :=
        (Dyspnea => True, Orthopnea => True, others => False);
   begin
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (200), True, 40)) = EA.HF_Reduced,
             "EF 40 → HF_Reduced");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (200), True, 30)) = EA.HF_Reduced,
             "EF 30 → HF_Reduced");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, BNP_Panel (40), True, 41)) =
             EA.HF_Mildly_Reduced,
             "EF 41 → HF_Mildly_Reduced");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, BNP_Panel (40), True, 49)) =
             EA.HF_Mildly_Reduced,
             "EF 49 → HF_Mildly_Reduced");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (300), True, 50)) = EA.HF_Preserved,
             "EF 50 → HF_Preserved");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, NT_Panel (300), True, 60)) = EA.HF_Preserved,
             "EF 60 → HF_Preserved");
   end;

   ---------------------------------------------------------------------
   Section ("13. Phenotype exhaustiveness across EF 0..100 sample");
   ---------------------------------------------------------------------
   for EF in EA.EF_Percent loop
      declare
         Ph : constant EA.Phenotype := EA.Classify_EF (EF);
         Ok : Boolean;
      begin
         if EF <= 40 then
            Ok := Ph = EA.HFrEF;
         elsif EF <= 49 then
            Ok := Ph = EA.HFmrEF;
         else
            Ok := Ph = EA.HFpEF;
         end if;
         -- Sample every 5th plus all boundaries to keep output manageable
         if EF rem 5 = 0
           or else EF = 40 or else EF = 41
           or else EF = 49 or else EF = 50
           or else EF = 100
         then
            Check (Ok, "EF" & EA.EF_Percent'Image (EF) & " phenotype band");
         end if;
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("14. Pathway matrix: 4 symptom singles × NP/EF cases");
   ---------------------------------------------------------------------
   declare
      type Sx_Arr is array (1 .. 4) of EA.Symptom_Flags;
      Singles : constant Sx_Arr :=
        [(Dyspnea => True, others => False),
         (Orthopnea => True, others => False),
         (Edema => True, others => False),
         (Fatigue => True, others => False)];
   begin
      for I in Singles'Range loop
         Check (EA.Evaluate_Pathway
                  (Mk_Workup (Singles (I), (others => <>))) =
                EA.Incomplete_Data,
                "single" & Integer'Image (I) & " no NP → Incomplete");
         Check (EA.Evaluate_Pathway
                  (Mk_Workup (Singles (I), NT_Panel (124))) = EA.Unlikely,
                "single" & Integer'Image (I) & " NT124 → Unlikely");
         Check (EA.Evaluate_Pathway
                  (Mk_Workup (Singles (I), NT_Panel (125))) =
                EA.Consider_Echo,
                "single" & Integer'Image (I) & " NT125 → Echo");
         Check (EA.Evaluate_Pathway
                  (Mk_Workup (Singles (I), BNP_Panel (35), True, 35)) =
                EA.HF_Reduced,
                "single" & Integer'Image (I) & " BNP35 EF35 → Reduced");
         Check (EA.Evaluate_Pathway
                  (Mk_Workup (Singles (I), BNP_Panel (35), True, 45)) =
                EA.HF_Mildly_Reduced,
                "single" & Integer'Image (I) & " BNP35 EF45 → Mildly");
         Check (EA.Evaluate_Pathway
                  (Mk_Workup (Singles (I), BNP_Panel (35), True, 55)) =
                EA.HF_Preserved,
                "single" & Integer'Image (I) & " BNP35 EF55 → Preserved");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra NP boundary / dual-panel pathway checks");
   ---------------------------------------------------------------------
   declare
      Sx : constant EA.Symptom_Flags :=
        (Edema => True, Fatigue => True, others => False);
   begin
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (125, 0))) = EA.Consider_Echo,
             "NT@cutoff BNP0 measured → Echo");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (0, 35))) = EA.Consider_Echo,
             "NT0 BNP@cutoff → Echo");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (124, 34))) = EA.Unlikely,
             "both just below → Unlikely");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (125, 35), True, 40)) =
             EA.HF_Reduced,
             "both@cutoff EF40 → Reduced");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (125, 35), True, 41)) =
             EA.HF_Mildly_Reduced,
             "both@cutoff EF41 → Mildly");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (125, 35), True, 49)) =
             EA.HF_Mildly_Reduced,
             "both@cutoff EF49 → Mildly");
      Check (EA.Evaluate_Pathway
               (Mk_Workup (Sx, Both_Panel (125, 35), True, 50)) =
             EA.HF_Preserved,
             "both@cutoff EF50 → Preserved");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("All tests passed.");
   else
      Put_Line ("SOME TESTS FAILED.");
   end if;

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
