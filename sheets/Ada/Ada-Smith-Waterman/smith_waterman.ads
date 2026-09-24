--  Smith_Waterman — Ada 2023 educational package for the Smith–Waterman
--  local sequence alignment algorithm (linear gap penalty).
--  Dynamic programming: H(i,0)=H(0,j)=0; H(i,j)=max(0, diag+s, up+Gap,
--  left+Gap). Best score is the global max over H; optional traceback
--  from the argmax recovers one optimal local alignment (gapped strings
--  and/or start–end indices of the local segments).
--  Contrast with Needleman–Wunsch (global alignment): NW forces end-to-end
--  alignment and allows negative scores; SW zeros negatives and finds the
--  best *local* similarity. This package does not `with` any NW package.
--  Primary source:
--  https://en.wikipedia.org/wiki/Smith%E2%80%93Waterman_algorithm

pragma Ada_2022;

with Ada.Strings.Unbounded;

package Smith_Waterman
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

   --  One optimal local alignment (ungapped segment endpoints).
   --  A_Start / A_End / B_Start / B_End are 1-based logical indices into
   --  A and B (1 = first character, independent of A'First / B'First).
   --  When Score = 0 (no positive local similarity), all four indices
   --  are 0 and the gapped strings are empty.
   type Alignment_Result is record
      Score   : Integer := 0;
      A_Start : Natural := 0;
      A_End   : Natural := 0;
      B_Start : Natural := 0;
      B_End   : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Best local score
   ---------------------------------------------------------------------------

   function Best_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer;
   --  Maximum cell value in the Smith–Waterman DP matrix for A vs B.
   --  Empty inputs or no positive local similarity → 0.
   --  Time / space Θ(|A|·|B|) using the fixed Max_Len pool.
   --  Raises Invalid_Argument if either length exceeds Max_Len.

   ---------------------------------------------------------------------------
   -- Align (score + segment indices; optional gapped strings)
   ---------------------------------------------------------------------------

   function Align
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Alignment_Result;
   --  Best local score and 1-based start/end of one optimal local path.
   --  On score ties, the first maximum in row-major order (smallest i,
   --  then smallest j) is kept. Traceback prefers diagonal, then up
   --  (gap in B), then left (gap in A) when predecessors tie.
   --  Raises Invalid_Argument if either length exceeds Max_Len.

   procedure Align
     (A, B                 : String;
      Score                : out Integer;
      A_Aligned, B_Aligned : out Ada.Strings.Unbounded.Unbounded_String;
      Scoring              : Scoring_Scheme := Default_Scoring);
   --  Same optimal path as function Align, plus gapped alignment strings
   --  (gap character '-'). When Score = 0 both strings are empty.
   --  Raises Invalid_Argument if either length exceeds Max_Len.

   function Pair_Score
     (Left, Right : Character;
      Scoring     : Scoring_Scheme := Default_Scoring) return Integer;
   --  Match_Score if Left = Right, else Mismatch_Score.

end Smith_Waterman;
