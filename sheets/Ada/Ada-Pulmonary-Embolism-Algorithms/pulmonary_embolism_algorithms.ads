--  Pulmonary_Embolism_Algorithms — Ada 2023 educational encoding of
--  published PE pretest scoring / rule-out criteria (Wells PE, Revised
--  Geneva, PERC). Deterministic pure functions for unit testing only.
--
--  NOT FOR CLINICAL USE. Not medical advice. Clinicians must follow
--  current guidelines and local protocols; this package does not replace
--  clinical judgment, imaging, or laboratory testing.
--
--  Sources (educational): Wikipedia Pulmonary embolism / Geneva score;
--  Wells et al. Thromb Haemost 2000; Le Gal et al. Ann Intern Med 2006;
--  Kline et al. J Thromb Haemost 2004/2008 (PERC).

pragma Ada_2022;

package Pulmonary_Embolism_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Classic Wells uses half-points (1.5). Fixed avoids float noise.
   type Wells_Points is delta 0.5 range 0.0 .. 15.0;

   subtype Age_Years is Natural range 0 .. 120;
   subtype Heart_Rate_BPM is Natural range 0 .. 300;
   subtype Oxygen_Saturation_Pct is Natural range 0 .. 100;

   type Geneva_Points is range 0 .. 50;

   ---------------------------------------------------------------------------
   -- Category enumerations (published cutoffs documented in body / README)
   ---------------------------------------------------------------------------

   --  Classic three-tier Wells (Thromb Haemost 2000 style):
   --    Low < 2; Moderate 2 .. 6; High > 6.
   type Wells_Three_Tier is (Low, Moderate, High);

   --  Two-tier / modified Wells (Christopher study style):
   --    Unlikely <= 4; Likely > 4.
   type Wells_Two_Tier is (Unlikely, Likely);

   --  Simplified Wells (each criterion 1 point): Unlikely <= 1; Likely > 1.
   type Simplified_Wells_Tier is (Unlikely, Likely);

   --  Revised Geneva (Le Gal 2006): Low 0..3; Intermediate 4..10; High >= 11.
   type Geneva_Tier is (Low, Intermediate, High);

   ---------------------------------------------------------------------------
   -- Input records (defaults = no risk flags / quiet vitals)
   ---------------------------------------------------------------------------

   type Wells_Criteria is record
      Clinical_Signs_Of_DVT     : Boolean := False;  -- 3.0
      PE_Most_Or_Equally_Likely : Boolean := False;  -- 3.0
      Heart_Rate_Above_100      : Boolean := False;  -- 1.5
      Immobilization_Or_Surgery : Boolean := False;  -- 1.5 (>=3d immob. or surg. 4wk)
      Previous_DVT_Or_PE        : Boolean := False;  -- 1.5
      Hemoptysis                : Boolean := False;  -- 1.0
      Malignancy                : Boolean := False;  -- 1.0
   end record;

   type Geneva_Criteria is record
      Age                       : Age_Years := 40;
      Previous_DVT_Or_PE        : Boolean := False;
      Surgery_Or_Fracture_1_Mo  : Boolean := False;
      Active_Malignancy         : Boolean := False;
      Unilateral_Lower_Limb_Pain : Boolean := False;
      Hemoptysis                : Boolean := False;
      Heart_Rate                : Heart_Rate_BPM := 70;
      Pain_On_Palpation_And_Edema : Boolean := False;
   end record;

   --  PERC "positive" flags mean a criterion that BLOCKS rule-out.
   --  Helpers also accept raw vitals and derive flags.
   type PERC_Criteria is record
      Age                      : Age_Years := 40;
      Heart_Rate               : Heart_Rate_BPM := 70;
      Oxygen_Saturation        : Oxygen_Saturation_Pct := 98;
      Hemoptysis               : Boolean := False;
      Estrogen_Use             : Boolean := False;
      Prior_DVT_Or_PE          : Boolean := False;
      Unilateral_Leg_Swelling  : Boolean := False;
      Surgery_Or_Trauma_4_Wk   : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Wells (classic + simplified)
   ---------------------------------------------------------------------------

   function Wells_Score (C : Wells_Criteria) return Wells_Points
     with Global => null;
   --  Classic weighted Wells PE score (max 12.5).

   function Wells_Category_Three_Tier (Score : Wells_Points) return Wells_Three_Tier
     with Global => null;
   --  Low < 2; Moderate 2..6; High > 6.

   function Wells_Category_Three_Tier (C : Wells_Criteria) return Wells_Three_Tier
     with Global => null;

   function Wells_Category_Two_Tier (Score : Wells_Points) return Wells_Two_Tier
     with Global => null;
   --  Unlikely <= 4; Likely > 4.

   function Wells_Category_Two_Tier (C : Wells_Criteria) return Wells_Two_Tier
     with Global => null;

   function Simplified_Wells_Score (C : Wells_Criteria) return Natural
     with Global => null,
          Post => Simplified_Wells_Score'Result <= 7;
   --  One point per present classic criterion.

   function Simplified_Wells_Category (Score : Natural) return Simplified_Wells_Tier
     with Global => null;
   --  Unlikely <= 1; Likely > 1.

   function Simplified_Wells_Category (C : Wells_Criteria) return Simplified_Wells_Tier
     with Global => null;

   ---------------------------------------------------------------------------
   -- Revised Geneva
   ---------------------------------------------------------------------------

   function Geneva_Score (C : Geneva_Criteria) return Geneva_Points
     with Global => null;
   --  Revised (2006) weighted Geneva; HR 75..94 => +3; HR >= 95 => +5
   --  (not both). Age >= 65 => +1.

   function Geneva_Category (Score : Geneva_Points) return Geneva_Tier
     with Global => null;
   --  Low 0..3; Intermediate 4..10; High >= 11.

   function Geneva_Category (C : Geneva_Criteria) return Geneva_Tier
     with Global => null;

   ---------------------------------------------------------------------------
   -- PERC (Pulmonary Embolism Rule-out Criteria)
   ---------------------------------------------------------------------------

   --  A criterion is "met for rule-out" when the protective condition holds.
   --  PERC_All_Negative means all eight protective conditions hold
   --  (rule-out candidate only in an already low-risk gestalt setting —
   --  not encoded here as clinical advice).

   function PERC_Age_OK (Age : Age_Years) return Boolean
     with Global => null;
   --  Age < 50.

   function PERC_Heart_Rate_OK (HR : Heart_Rate_BPM) return Boolean
     with Global => null;
   --  HR < 100.

   function PERC_Oxygen_OK (Sat : Oxygen_Saturation_Pct) return Boolean
     with Global => null;
   --  SpO2 >= 95.

   function PERC_Positive_Count (C : PERC_Criteria) return Natural
     with Global => null,
          Post => PERC_Positive_Count'Result <= 8;
   --  Count of failed protective criteria (0 .. 8).

   function PERC_All_Negative (C : PERC_Criteria) return Boolean
     with Global => null;
   --  True iff Positive_Count = 0.

   function PERC_Is_Positive (C : PERC_Criteria) return Boolean
     with Global => null;
   --  True iff any protective criterion fails (Positive_Count > 0).

   ---------------------------------------------------------------------------
   -- Educational flowchart helper (NOT clinical pathway)
   ---------------------------------------------------------------------------

   --  Educational only: True when classic two-tier Wells is Unlikely AND
   --  PERC_All_Negative. Does not encode D-dimer, imaging, or gestalt.
   function Educational_Wells_Unlikely_And_PERC_Negative
     (W : Wells_Criteria;
      P : PERC_Criteria) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Point-contribution helpers (for transparent unit tests)
   ---------------------------------------------------------------------------

   function Wells_DVT_Points (Present : Boolean) return Wells_Points
     with Global => null;
   function Wells_PE_Likely_Points (Present : Boolean) return Wells_Points
     with Global => null;
   function Wells_HR_Points (Present : Boolean) return Wells_Points
     with Global => null;
   function Wells_Immob_Surgery_Points (Present : Boolean) return Wells_Points
     with Global => null;
   function Wells_Prior_VTE_Points (Present : Boolean) return Wells_Points
     with Global => null;
   function Wells_Hemoptysis_Points (Present : Boolean) return Wells_Points
     with Global => null;
   function Wells_Malignancy_Points (Present : Boolean) return Wells_Points
     with Global => null;

   function Geneva_Age_Points (Age : Age_Years) return Geneva_Points
     with Global => null;
   function Geneva_HR_Points (HR : Heart_Rate_BPM) return Geneva_Points
     with Global => null;

end Pulmonary_Embolism_Algorithms;
