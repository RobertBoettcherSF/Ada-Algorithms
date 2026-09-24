-- tests.adb
-- Verification and Validation (V&V) suite for the TMAP algorithm.
-- Assumes code is broken; PASS indicates an assumption of failure was disproved.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with TMAP; use TMAP;

procedure Tests is
   Patient : Patient_Record;
   Passed_Count : Integer := 0;
   Total_Tests  : Integer := 14;

   procedure Print_Pass is
   begin
      Put_Line ("      [PASS]");
      Passed_Count := Passed_Count + 1;
   end Print_Pass;

begin
   Put_Line ("=================================================");
   Put_Line ("   TMAP ALGORITHM VERIFICATION & VALIDATION");
   Put_Line ("=================================================");

   -- TEST 1
   Put_Line ("TEST 1 - MDD Initialization");
   Put_Line ("  1.1 Verify new patient starts at Stage 1");
   Initialize_Patient (Patient, Major_Depressive_Disorder);
   Assert (Patient.Current_Stage = Stage_1, "Init failed to set Stage 1");
   Print_Pass;

   -- TEST 2
   Put_Line ("TEST 2 - MDD Stage 1 Recommendation");
   Put_Line ("  2.1 Verify Stage 1 MDD recommends SSRI Monotherapy");
   Assert (Get_Recommendation (Patient) = SSRI_Monotherapy, "Wrong Stage 1 MDD Med");
   Print_Pass;

   -- TEST 3
   Put_Line ("TEST 3 - Positive Response Trajectory");
   Put_Line ("  3.1 Verify positive response shifts patient to Maintenance");
   Evaluate_Response (Patient, Positive_Response);
   Assert (Patient.Current_Stage = Maintenance, "Did not enter Maintenance");
   Print_Pass;

   -- TEST 4
   Put_Line ("TEST 4 - Maintenance Recommendation");
   Put_Line ("  4.1 Verify Maintenance state returns Continue_Current_Regimen");
   Assert (Get_Recommendation (Patient) = Continue_Current_Regimen, "Maintenance rec failed");
   Print_Pass;

   -- TEST 5
   Put_Line ("TEST 5 - Intolerable Side Effects Advancement");
   Put_Line ("  5.1 Verify side effects push Schizophrenia patient to Stage 2");
   Initialize_Patient (Patient, Schizophrenia);
   Evaluate_Response (Patient, Intolerable_Side_Effects);
   Assert (Patient.Current_Stage = Stage_2, "Failed to advance on side effects");
   Print_Pass;

   -- TEST 6
   Put_Line ("TEST 6 - Schizophrenia Stage 3 Requirement (Clozapine Check)");
   Put_Line ("  6.1 Verify Stage 3 Schizophrenia prescribes Clozapine (Core TMAP rule)");
   Evaluate_Response (Patient, Negative_Response); -- Moves to Stage 3
   Assert (Get_Recommendation (Patient) = Clozapine_Monotherapy, "Clozapine rule violated");
   Print_Pass;

   -- TEST 7
   Put_Line ("TEST 7 - Bipolar Initialization");
   Put_Line ("  7.1 Verify Bipolar starts with Lithium or Valproate");
   Initialize_Patient (Patient, Bipolar_Disorder);
   Assert (Get_Recommendation (Patient) = Lithium_or_Valproate, "Bipolar init failed");
   Print_Pass;

   -- TEST 8
   Put_Line ("TEST 8 - Relapse from Maintenance");
   Put_Line ("  8.1 Verify negative response in Maintenance restarts evaluation");
   Initialize_Patient (Patient, Bipolar_Disorder);
   Evaluate_Response (Patient, Positive_Response); -- Enter Maintenance
   Evaluate_Response (Patient, Negative_Response); -- Relapse
   Assert (Patient.Current_Stage = Stage_1, "Relapse logic failed");
   Print_Pass;

   -- TEST 9
   Put_Line ("TEST 9 - Exception on Unspecified Disease");
   Put_Line ("  9.1 Assert Initialize raises Unspecified_Disease on invalid input");
   begin
      Initialize_Patient (Patient, Unspecified);
      Assert (False, "Expected Unspecified_Disease not raised");
   exception
      when Unspecified_Disease => Print_Pass;
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Progression to Refractory");
   Put_Line ("  10.1 Verify 6 successive failures leads to Refractory state");
   Initialize_Patient (Patient, Major_Depressive_Disorder);
   Evaluate_Response (Patient, Negative_Response); -- S2
   Evaluate_Response (Patient, Negative_Response); -- S3
   Evaluate_Response (Patient, Negative_Response); -- S4
   Evaluate_Response (Patient, Negative_Response); -- S5
   Evaluate_Response (Patient, Negative_Response); -- S6
   Evaluate_Response (Patient, Negative_Response); -- Refractory
   Assert (Patient.Current_Stage = Refractory, "Failed to reach Refractory");
   Print_Pass;

   -- TEST 11
   Put_Line ("TEST 11 - Refractory Recommendation");
   Put_Line ("  11.1 Verify Refractory state recommends Consulting Specialist");
   Assert (Get_Recommendation(Patient) = Consult_Specialist, "Refractory rec failed");
   Print_Pass;

   -- TEST 12
   Put_Line ("TEST 12 - Refractory Bound Exception");
   Put_Line ("  12.1 Assert advancing past Refractory raises Refractory_State_Reached");
   begin
      Evaluate_Response (Patient, Negative_Response);
      Assert (False, "Expected Refractory_State_Reached not raised");
   exception
      when Refractory_State_Reached => Print_Pass;
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Partial Response Logic");
   Put_Line ("  13.1 Verify Partial Response safely advances the treatment stage");
   Initialize_Patient (Patient, Schizophrenia);
   Evaluate_Response (Patient, Partial_Response);
   Assert (Patient.Current_Stage = Stage_2, "Partial Response failed to advance");
   Print_Pass;

   -- TEST 14
   Put_Line ("TEST 14 - MDD Stage 5 ECT validation");
   Put_Line ("  14.1 Verify MDD Stage 5 prescribes ECT");
   Initialize_Patient (Patient, Major_Depressive_Disorder);
   Patient.Current_Stage := Stage_5; -- Direct manipulation for test isolation
   Assert (Get_Recommendation (Patient) = Electroconvulsive_Therapy, "ECT not recommended");
   Print_Pass;

   Put_Line ("=================================================");
   Put_Line ("Tests Passed: " & Integer'Image(Passed_Count) & " / " & Integer'Image(Total_Tests));
   if Passed_Count = Total_Tests then
      Put_Line ("STATUS: ALL CLEAR");
   else
      Put_Line ("STATUS: ERRORS DETECTED");
   end if;
end Tests;
