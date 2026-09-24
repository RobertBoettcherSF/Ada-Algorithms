--  Body for Pulmonary_Embolism_Algorithms (educational scoring only).

pragma Ada_2022;

package body Pulmonary_Embolism_Algorithms is

   --------------------------------------------------------------------------
   -- Wells point helpers
   --------------------------------------------------------------------------

   function Wells_DVT_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 3.0;
      else
         return 0.0;
      end if;
   end Wells_DVT_Points;

   function Wells_PE_Likely_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 3.0;
      else
         return 0.0;
      end if;
   end Wells_PE_Likely_Points;

   function Wells_HR_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 1.5;
      else
         return 0.0;
      end if;
   end Wells_HR_Points;

   function Wells_Immob_Surgery_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 1.5;
      else
         return 0.0;
      end if;
   end Wells_Immob_Surgery_Points;

   function Wells_Prior_VTE_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 1.5;
      else
         return 0.0;
      end if;
   end Wells_Prior_VTE_Points;

   function Wells_Hemoptysis_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 1.0;
      else
         return 0.0;
      end if;
   end Wells_Hemoptysis_Points;

   function Wells_Malignancy_Points (Present : Boolean) return Wells_Points is
   begin
      if Present then
         return 1.0;
      else
         return 0.0;
      end if;
   end Wells_Malignancy_Points;

   function Wells_Score (C : Wells_Criteria) return Wells_Points is
   begin
      return Wells_DVT_Points (C.Clinical_Signs_Of_DVT)
        + Wells_PE_Likely_Points (C.PE_Most_Or_Equally_Likely)
        + Wells_HR_Points (C.Heart_Rate_Above_100)
        + Wells_Immob_Surgery_Points (C.Immobilization_Or_Surgery)
        + Wells_Prior_VTE_Points (C.Previous_DVT_Or_PE)
        + Wells_Hemoptysis_Points (C.Hemoptysis)
        + Wells_Malignancy_Points (C.Malignancy);
   end Wells_Score;

   function Wells_Category_Three_Tier
     (Score : Wells_Points) return Wells_Three_Tier
   is
   begin
      if Score < 2.0 then
         return Low;
      elsif Score <= 6.0 then
         return Moderate;
      else
         return High;
      end if;
   end Wells_Category_Three_Tier;

   function Wells_Category_Three_Tier
     (C : Wells_Criteria) return Wells_Three_Tier
   is
   begin
      return Wells_Category_Three_Tier (Wells_Score (C));
   end Wells_Category_Three_Tier;

   function Wells_Category_Two_Tier
     (Score : Wells_Points) return Wells_Two_Tier
   is
   begin
      if Score <= 4.0 then
         return Unlikely;
      else
         return Likely;
      end if;
   end Wells_Category_Two_Tier;

   function Wells_Category_Two_Tier
     (C : Wells_Criteria) return Wells_Two_Tier
   is
   begin
      return Wells_Category_Two_Tier (Wells_Score (C));
   end Wells_Category_Two_Tier;

   function Simplified_Wells_Score (C : Wells_Criteria) return Natural is
      N : Natural := 0;
   begin
      if C.Clinical_Signs_Of_DVT then
         N := N + 1;
      end if;
      if C.PE_Most_Or_Equally_Likely then
         N := N + 1;
      end if;
      if C.Heart_Rate_Above_100 then
         N := N + 1;
      end if;
      if C.Immobilization_Or_Surgery then
         N := N + 1;
      end if;
      if C.Previous_DVT_Or_PE then
         N := N + 1;
      end if;
      if C.Hemoptysis then
         N := N + 1;
      end if;
      if C.Malignancy then
         N := N + 1;
      end if;
      return N;
   end Simplified_Wells_Score;

   function Simplified_Wells_Category
     (Score : Natural) return Simplified_Wells_Tier
   is
   begin
      if Score <= 1 then
         return Unlikely;
      else
         return Likely;
      end if;
   end Simplified_Wells_Category;

   function Simplified_Wells_Category
     (C : Wells_Criteria) return Simplified_Wells_Tier
   is
   begin
      return Simplified_Wells_Category (Simplified_Wells_Score (C));
   end Simplified_Wells_Category;

   --------------------------------------------------------------------------
   -- Revised Geneva
   --------------------------------------------------------------------------

   function Geneva_Age_Points (Age : Age_Years) return Geneva_Points is
   begin
      if Age >= 65 then
         return 1;
      else
         return 0;
      end if;
   end Geneva_Age_Points;

   function Geneva_HR_Points (HR : Heart_Rate_BPM) return Geneva_Points is
   begin
      if HR >= 95 then
         return 5;
      elsif HR >= 75 then
         return 3;
      else
         return 0;
      end if;
   end Geneva_HR_Points;

   function Geneva_Score (C : Geneva_Criteria) return Geneva_Points is
      S : Geneva_Points := 0;
   begin
      S := S + Geneva_Age_Points (C.Age);
      if C.Previous_DVT_Or_PE then
         S := S + 3;
      end if;
      if C.Surgery_Or_Fracture_1_Mo then
         S := S + 2;
      end if;
      if C.Active_Malignancy then
         S := S + 2;
      end if;
      if C.Unilateral_Lower_Limb_Pain then
         S := S + 3;
      end if;
      if C.Hemoptysis then
         S := S + 2;
      end if;
      S := S + Geneva_HR_Points (C.Heart_Rate);
      if C.Pain_On_Palpation_And_Edema then
         S := S + 4;
      end if;
      return S;
   end Geneva_Score;

   function Geneva_Category (Score : Geneva_Points) return Geneva_Tier is
   begin
      if Score <= 3 then
         return Low;
      elsif Score <= 10 then
         return Intermediate;
      else
         return High;
      end if;
   end Geneva_Category;

   function Geneva_Category (C : Geneva_Criteria) return Geneva_Tier is
   begin
      return Geneva_Category (Geneva_Score (C));
   end Geneva_Category;

   --------------------------------------------------------------------------
   -- PERC
   --------------------------------------------------------------------------

   function PERC_Age_OK (Age : Age_Years) return Boolean is
   begin
      return Age < 50;
   end PERC_Age_OK;

   function PERC_Heart_Rate_OK (HR : Heart_Rate_BPM) return Boolean is
   begin
      return HR < 100;
   end PERC_Heart_Rate_OK;

   function PERC_Oxygen_OK (Sat : Oxygen_Saturation_Pct) return Boolean is
   begin
      return Sat >= 95;
   end PERC_Oxygen_OK;

   function PERC_Positive_Count (C : PERC_Criteria) return Natural is
      N : Natural := 0;
   begin
      --  Each failure of a protective condition increments the count.
      if not PERC_Age_OK (C.Age) then
         N := N + 1;
      end if;
      if not PERC_Heart_Rate_OK (C.Heart_Rate) then
         N := N + 1;
      end if;
      if not PERC_Oxygen_OK (C.Oxygen_Saturation) then
         N := N + 1;
      end if;
      if C.Hemoptysis then
         N := N + 1;
      end if;
      if C.Estrogen_Use then
         N := N + 1;
      end if;
      if C.Prior_DVT_Or_PE then
         N := N + 1;
      end if;
      if C.Unilateral_Leg_Swelling then
         N := N + 1;
      end if;
      if C.Surgery_Or_Trauma_4_Wk then
         N := N + 1;
      end if;
      return N;
   end PERC_Positive_Count;

   function PERC_All_Negative (C : PERC_Criteria) return Boolean is
   begin
      return PERC_Positive_Count (C) = 0;
   end PERC_All_Negative;

   function PERC_Is_Positive (C : PERC_Criteria) return Boolean is
   begin
      return PERC_Positive_Count (C) > 0;
   end PERC_Is_Positive;

   function Educational_Wells_Unlikely_And_PERC_Negative
     (W : Wells_Criteria;
      P : PERC_Criteria) return Boolean
   is
   begin
      return Wells_Category_Two_Tier (W) = Unlikely
        and then PERC_All_Negative (P);
   end Educational_Wells_Unlikely_And_PERC_Negative;

end Pulmonary_Embolism_Algorithms;
