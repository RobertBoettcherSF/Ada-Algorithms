--  Body for ESC_Algorithm (educational HF pathway helpers only).

pragma Ada_2022;

package body ESC_Algorithm is

   --------------------------------------------------------------------------
   -- Symptom gate
   --------------------------------------------------------------------------

   function Bool_To_One (Present : Boolean) return Natural is
   begin
      if Present then
         return 1;
      else
         return 0;
      end if;
   end Bool_To_One;

   function Has_Dyspnea (S : Symptom_Flags) return Boolean is
   begin
      return S.Dyspnea;
   end Has_Dyspnea;

   function Has_Orthopnea (S : Symptom_Flags) return Boolean is
   begin
      return S.Orthopnea;
   end Has_Orthopnea;

   function Has_Edema (S : Symptom_Flags) return Boolean is
   begin
      return S.Edema;
   end Has_Edema;

   function Has_Fatigue (S : Symptom_Flags) return Boolean is
   begin
      return S.Fatigue;
   end Has_Fatigue;

   function Symptom_Count (S : Symptom_Flags) return Natural is
   begin
      return Bool_To_One (S.Dyspnea)
        + Bool_To_One (S.Orthopnea)
        + Bool_To_One (S.Edema)
        + Bool_To_One (S.Fatigue);
   end Symptom_Count;

   function Has_Suggestive_Symptoms (S : Symptom_Flags) return Boolean is
   begin
      return Symptom_Count (S) > 0;
   end Has_Suggestive_Symptoms;

   --------------------------------------------------------------------------
   -- Natriuretic peptide gate
   --------------------------------------------------------------------------

   function NT_proBNP_Elevated (Value : Peptide_Pg_Per_mL) return Boolean is
   begin
      return Value >= NT_proBNP_Chronic_Cutoff_Pg_Per_mL;
   end NT_proBNP_Elevated;

   function BNP_Elevated (Value : Peptide_Pg_Per_mL) return Boolean is
   begin
      return Value >= BNP_Chronic_Cutoff_Pg_Per_mL;
   end BNP_Elevated;

   function Any_Peptide_Measured (P : Peptide_Panel) return Boolean is
   begin
      return P.NT_proBNP_Measured or else P.BNP_Measured;
   end Any_Peptide_Measured;

   function Natriuretic_Gate_Positive (P : Peptide_Panel) return Boolean is
      NT_Pos : Boolean := False;
      BNP_Pos : Boolean := False;
   begin
      if P.NT_proBNP_Measured then
         NT_Pos := NT_proBNP_Elevated (P.NT_proBNP_Value);
      end if;
      if P.BNP_Measured then
         BNP_Pos := BNP_Elevated (P.BNP_Value);
      end if;
      return NT_Pos or else BNP_Pos;
   end Natriuretic_Gate_Positive;

   --------------------------------------------------------------------------
   -- EF phenotype
   --------------------------------------------------------------------------

   function Classify_EF (EF : EF_Percent) return Phenotype is
   begin
      if EF <= EF_HFrEF_Max then
         return HFrEF;
      elsif EF <= EF_HFmrEF_Max then
         return HFmrEF;
      else
         return HFpEF;
      end if;
   end Classify_EF;

   function Phenotype_To_Pathway (P : Phenotype) return Pathway_Result is
   begin
      case P is
         when HFrEF  => return HF_Reduced;
         when HFmrEF => return HF_Mildly_Reduced;
         when HFpEF  => return HF_Preserved;
      end case;
   end Phenotype_To_Pathway;

   --------------------------------------------------------------------------
   -- Pathway
   --------------------------------------------------------------------------

   function Evaluate_Pathway (W : Workup) return Pathway_Result is
   begin
      if not Has_Suggestive_Symptoms (W.Symptoms) then
         return Unlikely;
      end if;

      if not Any_Peptide_Measured (W.Peptides) then
         return Incomplete_Data;
      end if;

      if not Natriuretic_Gate_Positive (W.Peptides) then
         return Unlikely;
      end if;

      if not W.EF_Measured then
         return Consider_Echo;
      end if;

      return Phenotype_To_Pathway (Classify_EF (W.EF));
   end Evaluate_Pathway;

end ESC_Algorithm;
