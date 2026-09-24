-- tmap.adb
-- Implementation of the TMAP decision pathways.

package body TMAP is

   procedure Initialize_Patient (Patient : out Patient_Record; Disease : Disease_Category) is
   begin
      if Disease = Unspecified then
         raise Unspecified_Disease with "Cannot initialize algorithm without a valid diagnosis.";
      end if;

      Patient.Disease       := Disease;
      Patient.Current_Stage := Stage_1;
      Patient.Last_Response := None;
      Patient.Current_Medication := Get_Recommendation (Patient);
   end Initialize_Patient;

   procedure Advance_Stage (Patient : in out Patient_Record) is
   begin
      case Patient.Current_Stage is
         when Initial_Evaluation => Patient.Current_Stage := Stage_1;
         when Stage_1 => Patient.Current_Stage := Stage_2;
         when Stage_2 => Patient.Current_Stage := Stage_3;
         when Stage_3 => Patient.Current_Stage := Stage_4;
         when Stage_4 => Patient.Current_Stage := Stage_5;
         when Stage_5 => Patient.Current_Stage := Stage_6;
         when Stage_6 => Patient.Current_Stage := Refractory;
         when Maintenance => 
            -- A relapse from maintenance pushes them back to next logical algorithm step
            -- For simplicity in this model, we restart evaluation or move to Refractory.
            Patient.Current_Stage := Stage_1; 
         when Refractory =>
            raise Refractory_State_Reached with "Patient has exhausted algorithmic pathways.";
      end case;
   end Advance_Stage;

   procedure Evaluate_Response (Patient : in out Patient_Record; Response : Response_Type) is
   begin
      if Patient.Disease = Unspecified then
         raise Unspecified_Disease;
      end if;

      Patient.Last_Response := Response;

      case Response is
         when Positive_Response =>
            -- TMAP goal achieved, enter maintenance phase
            Patient.Current_Stage := Maintenance;
            Patient.Current_Medication := Continue_Current_Regimen;

         when Negative_Response | Intolerable_Side_Effects =>
            -- TMAP dictates advancing to the next treatment stage
            Advance_Stage (Patient);
            Patient.Current_Medication := Get_Recommendation (Patient);

         when Partial_Response =>
            -- Often dictates augmentation, but to keep FSM deterministic we advance to next stage
            -- which usually includes combination therapies in later stages.
            Advance_Stage (Patient);
            Patient.Current_Medication := Get_Recommendation (Patient);

         when None =>
            null; -- Awaiting time for medication to take effect
      end case;
   end Evaluate_Response;

   function Get_Recommendation (Patient : Patient_Record) return Medication_Type is
   begin
      if Patient.Current_Stage = Maintenance then
         return Continue_Current_Regimen;
      elsif Patient.Current_Stage = Refractory then
         return Consult_Specialist;
      end if;

      case Patient.Disease is
         when Major_Depressive_Disorder =>
            case Patient.Current_Stage is
               when Stage_1 => return SSRI_Monotherapy;
               when Stage_2 => return Alternative_SSRI_or_SNRI;
               when Stage_3 => return TCA_Antidepressant;
               when Stage_4 => return MAOI_or_Combination;
               when Stage_5 => return Electroconvulsive_Therapy;
               when Stage_6 => return Consult_Specialist;
               when others  => return No_Medication;
            end case;

         when Schizophrenia =>
            case Patient.Current_Stage is
               when Stage_1 => return Atypical_Antipsychotic;
               when Stage_2 => return Alternative_Atypical;
               when Stage_3 => return Clozapine_Monotherapy;
               when Stage_4 => return Clozapine_Combination;
               when Stage_5 => return Typical_Antipsychotic;
               when Stage_6 => return Combination_Antipsychotics;
               when others  => return No_Medication;
            end case;

         when Bipolar_Disorder =>
            case Patient.Current_Stage is
               when Stage_1 => return Lithium_or_Valproate;
               when Stage_2 => return Alternative_Mood_Stabilizer;
               when Stage_3 => return Combination_Mood_Stabilizers;
               when Stage_4 => return Electroconvulsive_Therapy;
               when others  => return Consult_Specialist;
            end case;

         when Unspecified =>
            raise Unspecified_Disease;
      end case;
   end Get_Recommendation;

end TMAP;
