--  Manning_Criteria — Ada 2023 educational encoding of the Manning
--  diagnostic criteria for irritable bowel syndrome (IBS).
--  Deterministic pure functions for unit testing only.
--
--  NOT FOR CLINICAL USE. Not medical advice. Clinicians must follow
--  current guidelines and local protocols; this package does not replace
--  clinical judgment, laboratory testing, or specialist evaluation.
--
--  Sources (educational): Wikipedia Manning Criteria;
--  Manning AP, Thompson WG, Heaton KW, Morris AF. Towards positive
--  diagnosis of the irritable bowel. Br Med J. 1978;2(6138):653-4.

pragma Ada_2022;

package Manning_Criteria
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Number of Manning criteria present (0 .. 6).
   subtype Criterion_Count is Natural range 0 .. 6;

   --  Literature uses a positive diagnosis threshold of 2, 3, or 4
   --  present criteria (Saito et al. Am J Gastroenterol 2000).
   subtype Threshold_Range is Positive range 2 .. 4;

   --  Default educational threshold: >= 3 positive criteria.
   Default_Threshold : constant Threshold_Range := 3;

   ---------------------------------------------------------------------------
   -- Input record (defaults = no symptoms reported)
   ---------------------------------------------------------------------------

   --  Classic six Manning questions (Manning 1978 / Wikipedia list).
   type Criteria is record
      Pain_Linked_To_More_Frequent_Stools : Boolean := False;
      --  1. Onset of pain linked to more frequent bowel movements

      Looser_Stools_With_Pain_Onset       : Boolean := False;
      --  2. Looser stools associated with onset of pain

      Pain_Relieved_By_Defecation         : Boolean := False;
      --  3. Pain relieved by passage of stool

      Noticeable_Abdominal_Bloating       : Boolean := False;
      --  4. Noticeable abdominal bloating

      Incomplete_Evacuation_GT_25_Pct     : Boolean := False;
      --  5. Sensation of incomplete evacuation more than 25% of the time

      Diarrhea_With_Mucus_GT_25_Pct       : Boolean := False;
      --  6. Diarrhea with mucus more than 25% of the time
   end record;

   ---------------------------------------------------------------------------
   -- Core scoring
   ---------------------------------------------------------------------------

   function Positive_Count (C : Criteria) return Criterion_Count
     with Global => null,
          Post   => Positive_Count'Result <= 6;
   --  Count of true (present) Manning criteria.

   function Meets_Threshold
     (Count     : Criterion_Count;
      Threshold : Threshold_Range) return Boolean
     with Global => null;
   --  True iff Count >= Threshold (Threshold in 2 .. 4).

   function Meets_Threshold
     (C         : Criteria;
      Threshold : Threshold_Range) return Boolean
     with Global => null;
   --  True iff Positive_Count (C) >= Threshold.

   function Is_Positive (C : Criteria) return Boolean
     with Global => null;
   --  True iff Positive_Count (C) >= Default_Threshold (3).

   function Is_Positive
     (C         : Criteria;
      Threshold : Threshold_Range) return Boolean
     with Global => null;
   --  Configurable-threshold overload of Is_Positive.

   ---------------------------------------------------------------------------
   -- Per-criterion helpers (1 if present, 0 if absent) for transparent tests
   ---------------------------------------------------------------------------

   function Pain_Linked_Contribution (Present : Boolean) return Natural
     with Global => null,
          Post   => Pain_Linked_Contribution'Result <= 1;

   function Looser_Stools_Contribution (Present : Boolean) return Natural
     with Global => null,
          Post   => Looser_Stools_Contribution'Result <= 1;

   function Pain_Relieved_Contribution (Present : Boolean) return Natural
     with Global => null,
          Post   => Pain_Relieved_Contribution'Result <= 1;

   function Bloating_Contribution (Present : Boolean) return Natural
     with Global => null,
          Post   => Bloating_Contribution'Result <= 1;

   function Incomplete_Evacuation_Contribution
     (Present : Boolean) return Natural
     with Global => null,
          Post   => Incomplete_Evacuation_Contribution'Result <= 1;

   function Mucus_Diarrhea_Contribution (Present : Boolean) return Natural
     with Global => null,
          Post   => Mucus_Diarrhea_Contribution'Result <= 1;

   ---------------------------------------------------------------------------
   -- Named presence queries (mirror record fields)
   ---------------------------------------------------------------------------

   function Has_Pain_Linked_To_More_Frequent_Stools
     (C : Criteria) return Boolean
     with Global => null;

   function Has_Looser_Stools_With_Pain_Onset (C : Criteria) return Boolean
     with Global => null;

   function Has_Pain_Relieved_By_Defecation (C : Criteria) return Boolean
     with Global => null;

   function Has_Noticeable_Abdominal_Bloating (C : Criteria) return Boolean
     with Global => null;

   function Has_Incomplete_Evacuation_GT_25_Pct (C : Criteria) return Boolean
     with Global => null;

   function Has_Diarrhea_With_Mucus_GT_25_Pct (C : Criteria) return Boolean
     with Global => null;

end Manning_Criteria;
