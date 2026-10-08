-- tmap.ads
-- Texas Medication Algorithm Project (TMAP) implementation
-- Defines the decision tree for medication management in psychiatric care.

package TMAP is

   -- The three primary psychiatric conditions covered by TMAP
   type Disease_Category is (
      Unspecified,
      Major_Depressive_Disorder,
      Schizophrenia,
      Bipolar_Disorder
   );

   -- Stages of the algorithm. Patients progress through stages upon negative response.
   type Treatment_Stage is (
      Initial_Evaluation,
      Stage_1,
      Stage_2,
      Stage_3,
      Stage_4,
      Stage_5,
      Stage_6,
      Maintenance, -- Successful management
      Refractory   -- Treatment resistant
   );

   -- How the patient responded to the current medication phase
   type Response_Type is (
      None,
      Positive_Response,
      Partial_Response,
      Negative_Response,
      Intolerable_Side_Effects
   );

   -- Generalized classes of medications/treatments mapped across the TMAP framework
   type Medication_Type is (
      No_Medication,
      -- MDD Specific
      SSRI_Monotherapy,
      Alternative_SSRI_or_SNRI,
      TCA_Antidepressant,
      MAOI_or_Combination,
      Electroconvulsive_Therapy,
      -- Schizophrenia Specific
      Atypical_Antipsychotic,
      Alternative_Atypical,
      Clozapine_Monotherapy,
      Clozapine_Combination,
      Typical_Antipsychotic,
      Combination_Antipsychotics,
      -- Bipolar Specific
      Lithium_or_Valproate,
      Alternative_Mood_Stabilizer,
      Combination_Mood_Stabilizers,
      -- General
      Continue_Current_Regimen,
      Consult_Specialist
   );

   -- Patient record containing algorithmic state
   type Patient_Record is record
      Disease            : Disease_Category := Unspecified;
      Current_Stage      : Treatment_Stage  := Initial_Evaluation;
      Last_Response      : Response_Type    := None;
      Current_Medication : Medication_Type  := No_Medication;
   end record;

   -- Exceptions for algorithmic edge cases
   Invalid_State_Transition : exception;
   Refractory_State_Reached : exception;
   Unspecified_Disease      : exception;

   -- Core Procedures & Functions
   
   -- Initializes a new patient onto the TMAP pathway
   procedure Initialize_Patient (Patient : out Patient_Record; Disease : Disease_Category);
   
   -- Progresses the state machine based on patient's response to current stage
   procedure Evaluate_Response (Patient : in out Patient_Record; Response : Response_Type);
   
   -- Outputs the algorithmic recommendation based on disease and current stage
   function Get_Recommendation (Patient : Patient_Record) return Medication_Type;

private
   -- Helper procedure to progress a stage forward on failure
   procedure Advance_Stage (Patient : in out Patient_Record);

end TMAP;
