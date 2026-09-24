--  ESC_Algorithm — Ada 2023 educational encoding of ESC-style heart-
--  failure diagnostic pathway helpers (symptoms → natriuretic peptides →
--  echo / EF phenotypes). Deterministic pure functions for unit testing.
--
--  NOT FOR CLINICAL USE. Not medical advice. Clinicians must follow
--  current guidelines and local protocols; this package does not replace
--  clinical judgment, laboratory testing, imaging, or specialist care.
--  Thresholds vary by guideline edition — documented cutoffs are
--  educational chronic rule-of-thumb values only.
--
--  Sources (educational): Wikipedia Heart failure (ESC_algorithm redirect);
--  ESC HF guidelines (chronic NP rule-out / phenotype bands commonly cited);
--  HFA-PEFF mentioned in README as related ESC HFpEF work (not fully encoded).

pragma Ada_2022;

package ESC_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational chronic natriuretic-peptide cutoffs (pg/mL)
   -- Commonly cited ESC chronic ambulatory rule-out style thresholds:
   --   NT-proBNP >= 125 pg/mL or BNP >= 35 pg/mL as "elevated" supporting
   --   further echocardiography. Acute / age-stratified cutoffs differ and
   --   are NOT encoded here.
   ---------------------------------------------------------------------------

   NT_proBNP_Chronic_Cutoff_Pg_Per_mL : constant Natural := 125;
   BNP_Chronic_Cutoff_Pg_Per_mL       : constant Natural := 35;

   ---------------------------------------------------------------------------
   -- Educational EF phenotype bands (percent)
   --   HFrEF  : EF <= 40
   --   HFmrEF : EF 41 .. 49
   --   HFpEF  : EF >= 50
   ---------------------------------------------------------------------------

   EF_HFrEF_Max  : constant Natural := 40;
   EF_HFmrEF_Min : constant Natural := 41;
   EF_HFmrEF_Max : constant Natural := 49;
   EF_HFpEF_Min  : constant Natural := 50;

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   subtype Peptide_Pg_Per_mL is Natural;
   subtype EF_Percent is Natural range 0 .. 100;

   type Phenotype is (HFrEF, HFmrEF, HFpEF);

   --  Simplified educational pathway outcomes.
   type Pathway_Result is
     (Unlikely,
      Consider_Echo,
      HF_Reduced,
      HF_Mildly_Reduced,
      HF_Preserved,
      Incomplete_Data);

   ---------------------------------------------------------------------------
   -- Input records (defaults = no symptoms / no labs / no EF)
   ---------------------------------------------------------------------------

   type Symptom_Flags is record
      Dyspnea   : Boolean := False;
      Orthopnea : Boolean := False;
      Edema     : Boolean := False;
      Fatigue   : Boolean := False;
   end record;

   type Peptide_Panel is record
      NT_proBNP_Measured : Boolean := False;
      NT_proBNP_Value    : Peptide_Pg_Per_mL := 0;
      BNP_Measured       : Boolean := False;
      BNP_Value          : Peptide_Pg_Per_mL := 0;
   end record;

   type Workup is record
      Symptoms    : Symptom_Flags := (others => False);
      Peptides    : Peptide_Panel := (others => <>);
      EF_Measured : Boolean := False;
      EF          : EF_Percent := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Symptom gate
   ---------------------------------------------------------------------------

   function Has_Suggestive_Symptoms (S : Symptom_Flags) return Boolean
     with Global => null;
   --  True if any of dyspnea / orthopnea / edema / fatigue is present.

   function Symptom_Count (S : Symptom_Flags) return Natural
     with Global => null,
          Post   => Symptom_Count'Result <= 4;

   ---------------------------------------------------------------------------
   -- Natriuretic peptide gate (educational chronic cutoffs)
   ---------------------------------------------------------------------------

   function NT_proBNP_Elevated (Value : Peptide_Pg_Per_mL) return Boolean
     with Global => null;
   --  True iff Value >= NT_proBNP_Chronic_Cutoff_Pg_Per_mL (125).

   function BNP_Elevated (Value : Peptide_Pg_Per_mL) return Boolean
     with Global => null;
   --  True iff Value >= BNP_Chronic_Cutoff_Pg_Per_mL (35).

   function Any_Peptide_Measured (P : Peptide_Panel) return Boolean
     with Global => null;

   function Natriuretic_Gate_Positive (P : Peptide_Panel) return Boolean
     with Global => null;
   --  True if a measured peptide meets its educational elevated cutoff.
   --  Unmeasured peptides do not contribute. If nothing measured → False.

   ---------------------------------------------------------------------------
   -- EF phenotype classification
   ---------------------------------------------------------------------------

   function Classify_EF (EF : EF_Percent) return Phenotype
     with Global => null;
   --  HFrEF <= 40; HFmrEF 41..49; HFpEF >= 50.

   function Phenotype_To_Pathway (P : Phenotype) return Pathway_Result
     with Global => null;
   --  Map phenotype to HF_Reduced / HF_Mildly_Reduced / HF_Preserved.

   ---------------------------------------------------------------------------
   -- Simple pathway (symptoms + NP + EF)
   ---------------------------------------------------------------------------

   function Evaluate_Pathway (W : Workup) return Pathway_Result
     with Global => null;
   --  Educational decision helper:
   --    no suggestive symptoms                          → Unlikely
   --    symptoms, no NP measured                        → Incomplete_Data
   --    symptoms, NP measured and not elevated          → Unlikely
   --    symptoms, NP elevated, no EF                    → Consider_Echo
   --    symptoms, NP elevated, EF classified            → HF_* phenotype
   --  Pure encoding of published rule-of-thumb cutoffs — not diagnosis.

   ---------------------------------------------------------------------------
   -- Named symptom queries (mirror record fields)
   ---------------------------------------------------------------------------

   function Has_Dyspnea (S : Symptom_Flags) return Boolean
     with Global => null;

   function Has_Orthopnea (S : Symptom_Flags) return Boolean
     with Global => null;

   function Has_Edema (S : Symptom_Flags) return Boolean
     with Global => null;

   function Has_Fatigue (S : Symptom_Flags) return Boolean
     with Global => null;

end ESC_Algorithm;
