--  Needleman_Wunsch — Ada 2023 educational package for the Needleman–Wunsch
--  global sequence alignment algorithm (linear gap penalty).
--  Dynamic programming: F(i,0)=i*Gap, F(0,j)=j*Gap;
--  F(i,j)=max(F(i-1,j-1)+s(a_i,b_j), F(i-1,j)+Gap, F(i,j-1)+Gap).
--  Score = F(m,n); traceback from (m,n) to (0,0) recovers one optimal
--  global alignment (gapped strings).
--  Contrast with Smith–Waterman (local alignment): SW zeros negatives and
--  traceback from the matrix maximum; NW forces end-to-end alignment and
--  allows negative scores. This package does not `with` any SW package.
--  Primary source:
--  https://en.wikipedia.org/wiki/Needleman%E2%80%93Wunsch_algorithm

pragma Ada_2022;

with Ada.Strings.Unbounded;

package Needleman_Wunsch
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational fixed DP pool)
   ---------------------------------------------------------------------------

   --  Maximum length of each input string. A fixed score / predecessor
   --  matrix pool of size (Max_Len+1)×(Max_Len+1) is used for Best_Score
   --  and Align. Inputs longer than Max_Len raise Invalid_Argument.
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
   -- Best global score
   ---------------------------------------------------------------------------

   function Best_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer;
   --  F(m,n) for the Needleman–Wunsch DP matrix of A vs B.
   --  Time / space Θ(|A|·|B|) using the fixed Max_Len pool.
   --  Raises Invalid_Argument if either length exceeds Max_Len.

   ---------------------------------------------------------------------------
   -- Align (score + gapped strings)
   ---------------------------------------------------------------------------

   function Align
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Alignment_Result;
   --  Best global score and one optimal gapped alignment.
   --  Traceback prefers diagonal, then up (gap in B), then left (gap in A)
   --  when predecessors tie.
   --  Raises Invalid_Argument if either length exceeds Max_Len.

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

end Needleman_Wunsch;
