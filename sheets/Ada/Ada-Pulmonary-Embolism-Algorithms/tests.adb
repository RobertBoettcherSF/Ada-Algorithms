--  Standalone test suite for Pulmonary_Embolism_Algorithms (main program).
--  Educational unit tests of published score arithmetic — not clinical validation.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Pulmonary_Embolism_Algorithms; use Pulmonary_Embolism_Algorithms;

procedure Tests is

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

   Empty_Wells  : constant Wells_Criteria  := (others => <>);
   Empty_Geneva : constant Geneva_Criteria := (others => <>);
   Empty_PERC   : constant PERC_Criteria   := (others => <>);

begin
   Put_Line ("Pulmonary_Embolism_Algorithms test suite");
   Put_Line ("========================================");
   Put_Line ("EDUCATIONAL ONLY — not for clinical use.");

   ---------------------------------------------------------------------
   Section ("1. Wells point contributions");
   ---------------------------------------------------------------------
   Check (Wells_DVT_Points (False) = 0.0, "Wells DVT absent = 0");
   Check (Wells_DVT_Points (True) = 3.0, "Wells DVT present = 3");
   Check (Wells_PE_Likely_Points (False) = 0.0, "Wells PE-likely absent = 0");
   Check (Wells_PE_Likely_Points (True) = 3.0, "Wells PE-likely present = 3");
   Check (Wells_HR_Points (False) = 0.0, "Wells HR absent = 0");
   Check (Wells_HR_Points (True) = 1.5, "Wells HR present = 1.5");
   Check (Wells_Immob_Surgery_Points (False) = 0.0, "Wells immob absent = 0");
   Check (Wells_Immob_Surgery_Points (True) = 1.5, "Wells immob present = 1.5");
   Check (Wells_Prior_VTE_Points (False) = 0.0, "Wells prior VTE absent = 0");
   Check (Wells_Prior_VTE_Points (True) = 1.5, "Wells prior VTE present = 1.5");
   Check (Wells_Hemoptysis_Points (False) = 0.0, "Wells hemoptysis absent = 0");
   Check (Wells_Hemoptysis_Points (True) = 1.0, "Wells hemoptysis present = 1");
   Check (Wells_Malignancy_Points (False) = 0.0, "Wells malignancy absent = 0");
   Check (Wells_Malignancy_Points (True) = 1.0, "Wells malignancy present = 1");

   ---------------------------------------------------------------------
   Section ("2. Wells empty / single-criterion totals");
   ---------------------------------------------------------------------
   Check (Wells_Score (Empty_Wells) = 0.0, "Empty Wells score = 0");
   Check (Wells_Category_Three_Tier (Empty_Wells) = Low,
          "Empty Wells three-tier Low");
   Check (Wells_Category_Two_Tier (Empty_Wells) = Unlikely,
          "Empty Wells two-tier Unlikely");
   Check (Simplified_Wells_Score (Empty_Wells) = 0,
          "Empty simplified Wells = 0");
   Check (Simplified_Wells_Category (Empty_Wells) = Unlikely,
          "Empty simplified Wells Unlikely");

   declare
      W : Wells_Criteria;
   begin
      W := Empty_Wells;
      W.Clinical_Signs_Of_DVT := True;
      Check (Wells_Score (W) = 3.0, "Only DVT signs => 3.0");
      Check (Wells_Category_Three_Tier (W) = Moderate, "3.0 => Moderate");
      Check (Wells_Category_Two_Tier (W) = Unlikely, "3.0 => Unlikely");

      W := Empty_Wells;
      W.PE_Most_Or_Equally_Likely := True;
      Check (Wells_Score (W) = 3.0, "Only PE-likely => 3.0");

      W := Empty_Wells;
      W.Heart_Rate_Above_100 := True;
      Check (Wells_Score (W) = 1.5, "Only HR>100 => 1.5");
      Check (Wells_Category_Three_Tier (W) = Low, "1.5 => Low");

      W := Empty_Wells;
      W.Immobilization_Or_Surgery := True;
      Check (Wells_Score (W) = 1.5, "Only immob/surgery => 1.5");

      W := Empty_Wells;
      W.Previous_DVT_Or_PE := True;
      Check (Wells_Score (W) = 1.5, "Only prior VTE => 1.5");

      W := Empty_Wells;
      W.Hemoptysis := True;
      Check (Wells_Score (W) = 1.0, "Only hemoptysis => 1.0");
      Check (Wells_Category_Three_Tier (W) = Low, "1.0 => Low");

      W := Empty_Wells;
      W.Malignancy := True;
      Check (Wells_Score (W) = 1.0, "Only malignancy => 1.0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Wells vignettes and thresholds");
   ---------------------------------------------------------------------
   declare
      W : Wells_Criteria;
   begin
      --  Max classic score = 12.5
      W := (Clinical_Signs_Of_DVT     => True,
            PE_Most_Or_Equally_Likely => True,
            Heart_Rate_Above_100      => True,
            Immobilization_Or_Surgery => True,
            Previous_DVT_Or_PE        => True,
            Hemoptysis                => True,
            Malignancy                => True);
      Check (Wells_Score (W) = 12.5, "All Wells criteria => 12.5");
      Check (Wells_Category_Three_Tier (W) = High, "12.5 => High");
      Check (Wells_Category_Two_Tier (W) = Likely, "12.5 => Likely");
      Check (Simplified_Wells_Score (W) = 7, "Simplified all => 7");
      Check (Simplified_Wells_Category (W) = Likely, "Simplified 7 => Likely");

      --  Boundary three-tier: score 2.0 is Moderate (2..6)
      W := Empty_Wells;
      W.Hemoptysis := True;
      W.Malignancy := True;
      Check (Wells_Score (W) = 2.0, "Hemo+malignancy => 2.0");
      Check (Wells_Category_Three_Tier (2.0) = Moderate, "Score 2.0 Moderate");
      Check (Wells_Category_Three_Tier (1.5) = Low, "Score 1.5 Low");
      Check (Wells_Category_Three_Tier (6.0) = Moderate, "Score 6.0 Moderate");
      Check (Wells_Category_Three_Tier (6.5) = High, "Score 6.5 High");

      --  Two-tier boundary at 4
      Check (Wells_Category_Two_Tier (4.0) = Unlikely, "Score 4.0 Unlikely");
      Check (Wells_Category_Two_Tier (4.5) = Likely, "Score 4.5 Likely");
      Check (Wells_Category_Two_Tier (0.0) = Unlikely, "Score 0 Unlikely");

      --  Vignette: DVT signs + PE likely = 6.0 Moderate / Likely
      W := Empty_Wells;
      W.Clinical_Signs_Of_DVT := True;
      W.PE_Most_Or_Equally_Likely := True;
      Check (Wells_Score (W) = 6.0, "DVT+PE-likely => 6.0");
      Check (Wells_Category_Three_Tier (W) = Moderate, "6.0 Moderate");
      Check (Wells_Category_Two_Tier (W) = Likely, "6.0 Likely (two-tier)");

      --  Vignette: HR + immob + prior = 4.5 Likely
      W := Empty_Wells;
      W.Heart_Rate_Above_100 := True;
      W.Immobilization_Or_Surgery := True;
      W.Previous_DVT_Or_PE := True;
      Check (Wells_Score (W) = 4.5, "HR+immob+prior => 4.5");
      Check (Wells_Category_Two_Tier (W) = Likely, "4.5 Likely");
      Check (Wells_Category_Three_Tier (W) = Moderate, "4.5 Moderate");

      --  Simplified thresholds
      Check (Simplified_Wells_Category (0) = Unlikely, "Simp 0 Unlikely");
      Check (Simplified_Wells_Category (1) = Unlikely, "Simp 1 Unlikely");
      Check (Simplified_Wells_Category (2) = Likely, "Simp 2 Likely");
      W := Empty_Wells;
      W.Hemoptysis := True;
      Check (Simplified_Wells_Score (W) = 1, "Simp single flag = 1");
      Check (Simplified_Wells_Category (W) = Unlikely, "Simp 1 Unlikely via rec");
      W.Malignancy := True;
      Check (Simplified_Wells_Score (W) = 2, "Simp two flags = 2");
      Check (Simplified_Wells_Category (W) = Likely, "Simp 2 Likely via rec");
   end;

   ---------------------------------------------------------------------
   Section ("4. Revised Geneva point helpers and HR bands");
   ---------------------------------------------------------------------
   Check (Geneva_Age_Points (64) = 0, "Geneva age 64 => 0");
   Check (Geneva_Age_Points (65) = 1, "Geneva age 65 => 1");
   Check (Geneva_Age_Points (80) = 1, "Geneva age 80 => 1");
   Check (Geneva_Age_Points (0) = 0, "Geneva age 0 => 0");

   Check (Geneva_HR_Points (74) = 0, "Geneva HR 74 => 0");
   Check (Geneva_HR_Points (75) = 3, "Geneva HR 75 => 3");
   Check (Geneva_HR_Points (94) = 3, "Geneva HR 94 => 3");
   Check (Geneva_HR_Points (95) = 5, "Geneva HR 95 => 5");
   Check (Geneva_HR_Points (120) = 5, "Geneva HR 120 => 5");
   Check (Geneva_HR_Points (0) = 0, "Geneva HR 0 => 0");

   ---------------------------------------------------------------------
   Section ("5. Geneva empty / single / vignettes / tiers");
   ---------------------------------------------------------------------
   Check (Geneva_Score (Empty_Geneva) = 0, "Empty Geneva (age40 HR70) = 0");
   Check (Geneva_Category (Empty_Geneva) = Low, "Empty Geneva Low");

   declare
      G : Geneva_Criteria;
   begin
      G := Empty_Geneva;
      G.Previous_DVT_Or_PE := True;
      Check (Geneva_Score (G) = 3, "Only prior VTE => 3");
      Check (Geneva_Category (G) = Low, "3 => Low");

      G := Empty_Geneva;
      G.Surgery_Or_Fracture_1_Mo := True;
      Check (Geneva_Score (G) = 2, "Only surgery/fracture => 2");

      G := Empty_Geneva;
      G.Active_Malignancy := True;
      Check (Geneva_Score (G) = 2, "Only malignancy => 2");

      G := Empty_Geneva;
      G.Unilateral_Lower_Limb_Pain := True;
      Check (Geneva_Score (G) = 3, "Only unilateral pain => 3");

      G := Empty_Geneva;
      G.Hemoptysis := True;
      Check (Geneva_Score (G) = 2, "Only hemoptysis => 2");

      G := Empty_Geneva;
      G.Pain_On_Palpation_And_Edema := True;
      Check (Geneva_Score (G) = 4, "Only palpation+edema => 4");
      Check (Geneva_Category (G) = Intermediate, "4 => Intermediate");

      G := Empty_Geneva;
      G.Age := 65;
      Check (Geneva_Score (G) = 1, "Only age>=65 => 1");

      G := Empty_Geneva;
      G.Heart_Rate := 80;
      Check (Geneva_Score (G) = 3, "Only HR 80 => 3");

      G := Empty_Geneva;
      G.Heart_Rate := 100;
      Check (Geneva_Score (G) = 5, "Only HR 100 => 5");

      --  Max: age1 + prior3 + surg2 + mal2 + pain3 + hemo2 + HR5 + palp4 = 22
      G := (Age                        => 70,
            Previous_DVT_Or_PE         => True,
            Surgery_Or_Fracture_1_Mo   => True,
            Active_Malignancy          => True,
            Unilateral_Lower_Limb_Pain => True,
            Hemoptysis                 => True,
            Heart_Rate                 => 110,
            Pain_On_Palpation_And_Edema => True);
      Check (Geneva_Score (G) = 22, "All Geneva criteria => 22");
      Check (Geneva_Category (G) = High, "22 => High");

      --  Tier boundaries
      Check (Geneva_Category (0) = Low, "Geneva 0 Low");
      Check (Geneva_Category (3) = Low, "Geneva 3 Low");
      Check (Geneva_Category (4) = Intermediate, "Geneva 4 Intermediate");
      Check (Geneva_Category (10) = Intermediate, "Geneva 10 Intermediate");
      Check (Geneva_Category (11) = High, "Geneva 11 High");

      --  Vignette: age65 + HR95 = 1+5 = 6 Intermediate
      G := Empty_Geneva;
      G.Age := 65;
      G.Heart_Rate := 95;
      Check (Geneva_Score (G) = 6, "Age65+HR95 => 6");
      Check (Geneva_Category (G) = Intermediate, "6 Intermediate");

      --  Ensure HR bands mutually exclusive (not 3+5)
      G := Empty_Geneva;
      G.Heart_Rate := 95;
      Check (Geneva_Score (G) = 5, "HR95 alone is 5 not 8");
   end;

   ---------------------------------------------------------------------
   Section ("6. PERC protective helpers and boundaries");
   ---------------------------------------------------------------------
   Check (PERC_Age_OK (49), "PERC age 49 OK");
   Check (not PERC_Age_OK (50), "PERC age 50 not OK");
   Check (PERC_Age_OK (0), "PERC age 0 OK");
   Check (not PERC_Age_OK (120), "PERC age 120 not OK");

   Check (PERC_Heart_Rate_OK (99), "PERC HR 99 OK");
   Check (not PERC_Heart_Rate_OK (100), "PERC HR 100 not OK");
   Check (PERC_Heart_Rate_OK (60), "PERC HR 60 OK");

   Check (PERC_Oxygen_OK (95), "PERC SpO2 95 OK");
   Check (PERC_Oxygen_OK (100), "PERC SpO2 100 OK");
   Check (not PERC_Oxygen_OK (94), "PERC SpO2 94 not OK");
   Check (not PERC_Oxygen_OK (0), "PERC SpO2 0 not OK");

   Check (PERC_All_Negative (Empty_PERC), "Default PERC all-negative");
   Check (PERC_Positive_Count (Empty_PERC) = 0, "Default PERC count 0");
   Check (not PERC_Is_Positive (Empty_PERC), "Default PERC not positive");

   declare
      P : PERC_Criteria;
   begin
      P := Empty_PERC;
      P.Age := 50;
      Check (PERC_Positive_Count (P) = 1, "Age50 alone => count 1");
      Check (not PERC_All_Negative (P), "Age50 => not all-negative");
      Check (PERC_Is_Positive (P), "Age50 => PERC positive");

      P := Empty_PERC;
      P.Heart_Rate := 100;
      Check (PERC_Positive_Count (P) = 1, "HR100 alone => count 1");

      P := Empty_PERC;
      P.Oxygen_Saturation := 94;
      Check (PERC_Positive_Count (P) = 1, "SpO2 94 alone => count 1");

      P := Empty_PERC;
      P.Hemoptysis := True;
      Check (PERC_Positive_Count (P) = 1, "Hemoptysis alone => count 1");

      P := Empty_PERC;
      P.Estrogen_Use := True;
      Check (PERC_Positive_Count (P) = 1, "Estrogen alone => count 1");

      P := Empty_PERC;
      P.Prior_DVT_Or_PE := True;
      Check (PERC_Positive_Count (P) = 1, "Prior VTE alone => count 1");

      P := Empty_PERC;
      P.Unilateral_Leg_Swelling := True;
      Check (PERC_Positive_Count (P) = 1, "Leg swelling alone => count 1");

      P := Empty_PERC;
      P.Surgery_Or_Trauma_4_Wk := True;
      Check (PERC_Positive_Count (P) = 1, "Surgery/trauma alone => count 1");

      --  All eight positive
      P := (Age                     => 60,
            Heart_Rate              => 110,
            Oxygen_Saturation       => 90,
            Hemoptysis              => True,
            Estrogen_Use            => True,
            Prior_DVT_Or_PE         => True,
            Unilateral_Leg_Swelling => True,
            Surgery_Or_Trauma_4_Wk  => True);
      Check (PERC_Positive_Count (P) = 8, "All PERC flags => count 8");
      Check (PERC_Is_Positive (P), "All flags => positive");
      Check (not PERC_All_Negative (P), "All flags => not negative");
   end;

   ---------------------------------------------------------------------
   Section ("7. PERC exhaustive 2^8 combinatorial (boolean axes)");
   ---------------------------------------------------------------------
   declare
      --  Fix vitals in the "OK" band; vary the 5 boolean risk flags plus
      --  three binary encodings of age/HR/O2 via bit mask on 8 axes:
      --  bit0 Age_Fail, bit1 HR_Fail, bit2 O2_Fail, bit3 Hemo, bit4 Estrogen,
      --  bit5 Prior, bit6 Swelling, bit7 Surgery.
      Expected_Negatives : Natural := 0;
      Observed_Negatives : Natural := 0;
      All_Match          : Boolean := True;
   begin
      for Mask in 0 .. 255 loop
         declare
            P     : PERC_Criteria;
            Bits  : Natural := Mask;
            Count : Natural;
            Exp   : Natural := 0;
         begin
            P := Empty_PERC;
            --  bit 0: age fail
            if (Bits mod 2) = 1 then
               P.Age := 50;
               Exp := Exp + 1;
            else
               P.Age := 40;
            end if;
            Bits := Bits / 2;
            --  bit 1: HR fail
            if (Bits mod 2) = 1 then
               P.Heart_Rate := 100;
               Exp := Exp + 1;
            else
               P.Heart_Rate := 70;
            end if;
            Bits := Bits / 2;
            --  bit 2: O2 fail
            if (Bits mod 2) = 1 then
               P.Oxygen_Saturation := 94;
               Exp := Exp + 1;
            else
               P.Oxygen_Saturation := 98;
            end if;
            Bits := Bits / 2;
            --  bit 3: hemoptysis
            if (Bits mod 2) = 1 then
               P.Hemoptysis := True;
               Exp := Exp + 1;
            end if;
            Bits := Bits / 2;
            --  bit 4: estrogen
            if (Bits mod 2) = 1 then
               P.Estrogen_Use := True;
               Exp := Exp + 1;
            end if;
            Bits := Bits / 2;
            --  bit 5: prior
            if (Bits mod 2) = 1 then
               P.Prior_DVT_Or_PE := True;
               Exp := Exp + 1;
            end if;
            Bits := Bits / 2;
            --  bit 6: swelling
            if (Bits mod 2) = 1 then
               P.Unilateral_Leg_Swelling := True;
               Exp := Exp + 1;
            end if;
            Bits := Bits / 2;
            --  bit 7: surgery
            if (Bits mod 2) = 1 then
               P.Surgery_Or_Trauma_4_Wk := True;
               Exp := Exp + 1;
            end if;

            Count := PERC_Positive_Count (P);
            if Count /= Exp then
               All_Match := False;
            end if;
            if Exp = 0 then
               Expected_Negatives := Expected_Negatives + 1;
            end if;
            if PERC_All_Negative (P) then
               Observed_Negatives := Observed_Negatives + 1;
            end if;
            if (Exp = 0) /= PERC_All_Negative (P) then
               All_Match := False;
            end if;
            if (Exp > 0) /= PERC_Is_Positive (P) then
               All_Match := False;
            end if;
         end;
      end loop;
      Check (All_Match, "PERC 256 masks: counts and flags match");
      Check (Expected_Negatives = 1, "PERC exactly one all-negative mask");
      Check (Observed_Negatives = 1, "PERC exactly one All_Negative observed");
   end;

   --  Spot-check a few mask identities as named assertions
   declare
      P : PERC_Criteria;
   begin
      P := Empty_PERC;
      Check (PERC_Positive_Count (P) = 0, "Mask0 count 0");
      P.Hemoptysis := True;
      P.Estrogen_Use := True;
      Check (PERC_Positive_Count (P) = 2, "Hemo+estrogen count 2");
      P.Prior_DVT_Or_PE := True;
      Check (PERC_Positive_Count (P) = 3, "Three boolean flags count 3");
   end;

   ---------------------------------------------------------------------
   Section ("8. Educational Wells+PERC helper");
   ---------------------------------------------------------------------
   declare
      W : Wells_Criteria := Empty_Wells;
      P : PERC_Criteria := Empty_PERC;
   begin
      Check (Educational_Wells_Unlikely_And_PERC_Negative (W, P),
             "Empty Wells+PERC educational helper True");
      W.Clinical_Signs_Of_DVT := True;
      W.PE_Most_Or_Equally_Likely := True;  -- 6.0 Likely
      Check (not Educational_Wells_Unlikely_And_PERC_Negative (W, P),
             "Likely Wells blocks educational helper");
      W := Empty_Wells;
      P.Hemoptysis := True;
      Check (not Educational_Wells_Unlikely_And_PERC_Negative (W, P),
             "PERC positive blocks educational helper");
      --  Unlikely Wells (score 3) + PERC clear
      W := Empty_Wells;
      W.Clinical_Signs_Of_DVT := True;  -- 3.0 Unlikely
      P := Empty_PERC;
      Check (Wells_Category_Two_Tier (W) = Unlikely, "Score 3 Unlikely");
      Check (Educational_Wells_Unlikely_And_PERC_Negative (W, P),
             "Wells 3 Unlikely + PERC clear => True");
   end;

   ---------------------------------------------------------------------
   Section ("9. Extra combinatorial Wells singles/pairs");
   ---------------------------------------------------------------------
   declare
      --  Each single criterion simplified score is 1
      Flags : constant array (1 .. 7) of Wells_Criteria :=
        [1 => (Clinical_Signs_Of_DVT => True, others => False),
         2 => (PE_Most_Or_Equally_Likely => True, others => False),
         3 => (Heart_Rate_Above_100 => True, others => False),
         4 => (Immobilization_Or_Surgery => True, others => False),
         5 => (Previous_DVT_Or_PE => True, others => False),
         6 => (Hemoptysis => True, others => False),
         7 => (Malignancy => True, others => False)];
      Classic : constant array (1 .. 7) of Wells_Points :=
        [3.0, 3.0, 1.5, 1.5, 1.5, 1.0, 1.0];
   begin
      for I in Flags'Range loop
         Check (Simplified_Wells_Score (Flags (I)) = 1,
                "Simplified single #" & Integer'Image (I) & " = 1");
         Check (Wells_Score (Flags (I)) = Classic (I),
                "Classic single #" & Integer'Image (I) & " matches");
      end loop;

      --  Pair DVT + malignancy = 4.0 Unlikely / Moderate
      declare
         W : Wells_Criteria := Empty_Wells;
      begin
         W.Clinical_Signs_Of_DVT := True;
         W.Malignancy := True;
         Check (Wells_Score (W) = 4.0, "DVT+malignancy => 4.0");
         Check (Wells_Category_Two_Tier (W) = Unlikely, "4.0 Unlikely");
         Check (Wells_Category_Three_Tier (W) = Moderate, "4.0 Moderate");
         Check (Simplified_Wells_Score (W) = 2, "DVT+malignancy simp=2");
      end;

      --  Pair hemoptysis + HR = 2.5 Moderate / Unlikely
      declare
         W : Wells_Criteria := Empty_Wells;
      begin
         W.Hemoptysis := True;
         W.Heart_Rate_Above_100 := True;
         Check (Wells_Score (W) = 2.5, "Hemo+HR => 2.5");
         Check (Wells_Category_Three_Tier (W) = Moderate, "2.5 Moderate");
         Check (Wells_Category_Two_Tier (W) = Unlikely, "2.5 Unlikely");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Geneva HR boundary sweep");
   ---------------------------------------------------------------------
   declare
   begin
      for HR in Heart_Rate_BPM range 70 .. 100 loop
         declare
            G : Geneva_Criteria := Empty_Geneva;
            Pts : Geneva_Points;
         begin
            G.Heart_Rate := HR;
            Pts := Geneva_HR_Points (G.Heart_Rate);
            if HR < 75 then
               Check (Pts = 0, "HR" & Heart_Rate_BPM'Image (HR) & " => 0 pts");
            elsif HR < 95 then
               Check (Pts = 3, "HR" & Heart_Rate_BPM'Image (HR) & " => 3 pts");
            else
               Check (Pts = 5, "HR" & Heart_Rate_BPM'Image (HR) & " => 5 pts");
            end if;
            Check (Geneva_Score (G) = Pts,
                   "Geneva score equals HR pts at" & Heart_Rate_BPM'Image (HR));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("TESTS FAILED OR INSUFFICIENT PASS COUNT");
      raise Program_Error;
   end if;
end Tests;
