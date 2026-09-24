--  Body for Manning_Criteria (educational IBS scoring only).

pragma Ada_2022;

package body Manning_Criteria is

   --------------------------------------------------------------------------
   -- Contribution helpers
   --------------------------------------------------------------------------

   function Bool_To_One (Present : Boolean) return Natural is
   begin
      if Present then
         return 1;
      else
         return 0;
      end if;
   end Bool_To_One;

   function Pain_Linked_Contribution (Present : Boolean) return Natural is
   begin
      return Bool_To_One (Present);
   end Pain_Linked_Contribution;

   function Looser_Stools_Contribution (Present : Boolean) return Natural is
   begin
      return Bool_To_One (Present);
   end Looser_Stools_Contribution;

   function Pain_Relieved_Contribution (Present : Boolean) return Natural is
   begin
      return Bool_To_One (Present);
   end Pain_Relieved_Contribution;

   function Bloating_Contribution (Present : Boolean) return Natural is
   begin
      return Bool_To_One (Present);
   end Bloating_Contribution;

   function Incomplete_Evacuation_Contribution
     (Present : Boolean) return Natural
   is
   begin
      return Bool_To_One (Present);
   end Incomplete_Evacuation_Contribution;

   function Mucus_Diarrhea_Contribution (Present : Boolean) return Natural is
   begin
      return Bool_To_One (Present);
   end Mucus_Diarrhea_Contribution;

   --------------------------------------------------------------------------
   -- Named presence queries
   --------------------------------------------------------------------------

   function Has_Pain_Linked_To_More_Frequent_Stools
     (C : Criteria) return Boolean
   is
   begin
      return C.Pain_Linked_To_More_Frequent_Stools;
   end Has_Pain_Linked_To_More_Frequent_Stools;

   function Has_Looser_Stools_With_Pain_Onset (C : Criteria) return Boolean is
   begin
      return C.Looser_Stools_With_Pain_Onset;
   end Has_Looser_Stools_With_Pain_Onset;

   function Has_Pain_Relieved_By_Defecation (C : Criteria) return Boolean is
   begin
      return C.Pain_Relieved_By_Defecation;
   end Has_Pain_Relieved_By_Defecation;

   function Has_Noticeable_Abdominal_Bloating (C : Criteria) return Boolean is
   begin
      return C.Noticeable_Abdominal_Bloating;
   end Has_Noticeable_Abdominal_Bloating;

   function Has_Incomplete_Evacuation_GT_25_Pct
     (C : Criteria) return Boolean
   is
   begin
      return C.Incomplete_Evacuation_GT_25_Pct;
   end Has_Incomplete_Evacuation_GT_25_Pct;

   function Has_Diarrhea_With_Mucus_GT_25_Pct (C : Criteria) return Boolean is
   begin
      return C.Diarrhea_With_Mucus_GT_25_Pct;
   end Has_Diarrhea_With_Mucus_GT_25_Pct;

   --------------------------------------------------------------------------
   -- Core scoring
   --------------------------------------------------------------------------

   function Positive_Count (C : Criteria) return Criterion_Count is
   begin
      return Criterion_Count
        (Pain_Linked_Contribution (C.Pain_Linked_To_More_Frequent_Stools)
         + Looser_Stools_Contribution (C.Looser_Stools_With_Pain_Onset)
         + Pain_Relieved_Contribution (C.Pain_Relieved_By_Defecation)
         + Bloating_Contribution (C.Noticeable_Abdominal_Bloating)
         + Incomplete_Evacuation_Contribution
             (C.Incomplete_Evacuation_GT_25_Pct)
         + Mucus_Diarrhea_Contribution (C.Diarrhea_With_Mucus_GT_25_Pct));
   end Positive_Count;

   function Meets_Threshold
     (Count     : Criterion_Count;
      Threshold : Threshold_Range) return Boolean
   is
   begin
      return Count >= Criterion_Count (Threshold);
   end Meets_Threshold;

   function Meets_Threshold
     (C         : Criteria;
      Threshold : Threshold_Range) return Boolean
   is
   begin
      return Meets_Threshold (Positive_Count (C), Threshold);
   end Meets_Threshold;

   function Is_Positive (C : Criteria) return Boolean is
   begin
      return Meets_Threshold (C, Default_Threshold);
   end Is_Positive;

   function Is_Positive
     (C         : Criteria;
      Threshold : Threshold_Range) return Boolean
   is
   begin
      return Meets_Threshold (C, Threshold);
   end Is_Positive;

end Manning_Criteria;
