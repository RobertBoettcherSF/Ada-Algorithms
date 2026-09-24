--  Hirschbergs_Algorithm — Ada 2023 educational package for Hirschberg's
--  algorithm: optimal global sequence alignment in linear extra space.
--  Divide-and-conquer Needleman–Wunsch: forward / reverse last-row scores
--  locate an optimal split, then recurse; time O(mn), extra space
--  O(min(m,n)) besides the output alignment (vs NW's O(mn) DP matrix).
--  Same educational scoring as Needleman–Wunsch: Match=+2, Mismatch=-1,
--  Gap=-1 (linear gap). Optimal score matches full NW for the same scheme.
--  This package does not `with` Needleman_Wunsch or Smith_Waterman; a
--  two-row NW last-row helper is reimplemented inline.
--  Primary source:
--  https://en.wikipedia.org/wiki/Hirschberg%27s_algorithm

pragma Ada_2022;

with Ada.Strings.Unbounded;

package Hirschbergs_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational fixed score-row pool)
   ---------------------------------------------------------------------------

   --  Maximum length of each input string. Forward / reverse score rows are
   --  sized to Max_Len+1. Inputs longer than Max_Len raise Invalid_Argument.
   Max_Len : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Scoring (simple match / mismatch / linear gap)
   ---------------------------------------------------------------------------

   --  Default substitution and gap costs (documented constants).
   --  Match = +2, Mismatch = −1, Gap = −1 (affine gaps are not used).
   Match_Score    : constant Integer := 2;
   Mismatch_Score : constant Integer := -1;
   Gap_Penalty    : constant Integer := -1;

   type Scoring_Scheme is record
      Match    : Integer := Match_Score;
      Mismatch : Integer := Mismatch_Score;
      Gap      : Integer := Gap_Penalty;
   end record;

   Default_Scoring : constant Scoring_Scheme :=
     (Match    => Match_Score,
      Mismatch => Mismatch_Score,
      Gap      => Gap_Penalty);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Len or B'Length > Max_Len.

   ---------------------------------------------------------------------------
   -- Result types
   ---------------------------------------------------------------------------

   --  One optimal global alignment: end-to-end score plus gapped strings
   --  (gap character '-'). Empty vs empty → Score = 0 and empty strings.
   --  Empty vs nonempty → Score = length * Gap and one string is all gaps.
   type Alignment_Result is record
      Score     : Integer := 0;
      A_Aligned : Ada.Strings.Unbounded.Unbounded_String :=
                    Ada.Strings.Unbounded.Null_Unbounded_String;
      B_Aligned : Ada.Strings.Unbounded.Unbounded_String :=
                    Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   ---------------------------------------------------------------------------
   -- Best global score (two-row NW; linear extra space)
   ---------------------------------------------------------------------------

   function Best_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer;
   --  Optimal global alignment score of A vs B (same as Needleman–Wunsch
   --  F(m,n)). Uses a two-row DP of length O(min(|A|,|B|)).
   --  Raises Invalid_Argument if either length exceeds Max_Len.

   ---------------------------------------------------------------------------
   -- Align (Hirschberg: score + gapped strings, linear extra space)
   ---------------------------------------------------------------------------

   function Align
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Alignment_Result;
   --  Best global score and one optimal gapped alignment via Hirschberg's
   --  divide-and-conquer. Extra working space is O(min(|A|,|B|)) besides
   --  the output. Raises Invalid_Argument if either length exceeds Max_Len.

   procedure Align
     (A, B                 : String;
      Score                : out Integer;
      A_Aligned, B_Aligned : out Ada.Strings.Unbounded.Unbounded_String;
      Scoring              : Scoring_Scheme := Default_Scoring);
   --  Same optimal path as function Align, with out-parameter form.
   --  Raises Invalid_Argument if either length exceeds Max_Len.

   function Pair_Score
     (Left, Right : Character;
      Scoring     : Scoring_Scheme := Default_Scoring) return Integer;
   --  Match_Score if Left = Right, else Mismatch_Score.

end Hirschbergs_Algorithm;
