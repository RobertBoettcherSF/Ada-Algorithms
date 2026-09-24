--  BLAST — Ada 2023 educational package for Wikipedia
--  "Basic Local Alignment Search Tool" (Altschul, Gish, Miller, Myers,
--  Lipman, J. Mol. Biol. 1990). Heuristic local similarity search:
--  exact word (seed) hits of length W, ungapped X-drop extension to HSPs,
--  optional Smith–Waterman local alignment for short gapped refinement.
--  Pedagogical DNA subset (alphabet ACGT) — not NCBI BLAST / BLAST+.

pragma Ada_2022;

package BLAST
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity
   ---------------------------------------------------------------------------

   type Real is digits 12;

   --  Educational bound on query / subject length for in-memory search.
   Max_Seq_Len : constant Positive := 400;
   Max_W       : constant Positive := 12;
   Max_Hits    : constant Positive := 512;
   Max_HSPs    : constant Positive := 64;

   subtype Word_Length is Positive range 1 .. Max_W;
   subtype Seq_Length  is Natural range 0 .. Max_Seq_Len;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Scoring (match / mismatch; linear gap for Smith–Waterman)
   ---------------------------------------------------------------------------

   type Score_Params is record
      Match    : Integer := 2;
      Mismatch : Integer := -1;
      Gap      : Integer := -2;  -- linear gap penalty for SW
   end record;

   Default_Scores : constant Score_Params :=
     (Match => 2, Mismatch => -1, Gap => -2);

   function Pair_Score
     (A, B   : Character;
      Params : Score_Params := Default_Scores) return Integer
     with Global => null;
   --  Match score if bases equal (case-insensitive ACGT), else mismatch.
   --  Non-ACGT bases always score as mismatch.

   function Ungapped_Score
     (Query, Subject : String;
      Params         : Score_Params := Default_Scores) return Integer
     with Global => null;
   --  Sum of Pair_Score over min lengths aligned from first index.
   --  Raises Invalid_Argument if either string longer than Max_Seq_Len.

   ---------------------------------------------------------------------------
   -- Word index (subject k-mers)
   ---------------------------------------------------------------------------

   type Word_Index is private;

   function Build_Index
     (Subject : String;
      W       : Word_Length) return Word_Index
     with Global => null;
   --  Index every exact ACGT W-mer of Subject (1-based starts).
   --  Windows containing non-ACGT are skipped.
   --  Raises Invalid_Argument if Subject'Length > Max_Seq_Len;
   --  Capacity_Exceeded if too many indexed windows (should not occur
   --  within Max_Seq_Len).

   function Index_W (Idx : Word_Index) return Word_Length
     with Global => null;

   function Index_Subject_Length (Idx : Word_Index) return Seq_Length
     with Global => null;

   function Index_Entry_Count (Idx : Word_Index) return Natural
     with Global => null;
   --  Number of indexed subject W-mer starts.

   ---------------------------------------------------------------------------
   -- Word hits (exact seed matches)
   ---------------------------------------------------------------------------

   type Word_Hit is record
      Q_Start : Positive := 1;
      S_Start : Positive := 1;
   end record;

   type Hit_Array is array (1 .. Max_Hits) of Word_Hit;

   type Hit_List is record
      Count : Natural := 0;
      Hits  : Hit_Array;
   end record;

   function Find_Word_Hits
     (Idx   : Word_Index;
      Query : String) return Hit_List
     with Global => null;
   --  Exact matches of every ACGT Query W-mer against the index.
   --  Raises Invalid_Argument if Query'Length > Max_Seq_Len;
   --  Capacity_Exceeded if hits would exceed Max_Hits.

   ---------------------------------------------------------------------------
   -- High-scoring segment pairs (HSPs)
   ---------------------------------------------------------------------------

   type HSP_Record is record
      Q_Start : Positive := 1;
      Q_End   : Positive := 1;
      S_Start : Positive := 1;
      S_End   : Positive := 1;
      Score   : Integer  := 0;
   end record;

   type HSP_Array is array (1 .. Max_HSPs) of HSP_Record;

   type HSP_List is record
      Count : Natural := 0;
      HSPs  : HSP_Array;
   end record;

   function Extend_HSP
     (Query, Subject : String;
      Q_Seed, S_Seed : Positive;
      W              : Word_Length;
      X_Drop         : Natural;
      Params         : Score_Params := Default_Scores) return HSP_Record
     with Global => null;
   --  Ungapped bidirectional X-drop extension from an exact word seed
   --  starting at (Q_Seed, S_Seed) of length W. Stops in each direction
   --  when running score falls X_Drop below the best score seen on that
   --  path. Returns the HSP covering the max-scoring ungapped segment.
   --  Raises Invalid_Argument on empty/oversized sequences or seeds that
   --  do not fit a W-mer inside both strings.

   function Search
     (Query, Subject : String;
      W              : Word_Length  := 3;
      X_Drop         : Natural      := 16;
      Min_Score      : Integer      := 1;
      Max_Results    : Positive     := Max_HSPs;
      Params         : Score_Params := Default_Scores) return HSP_List
     with Global => null;
   --  Full pedagogical pipeline: Build_Index → Find_Word_Hits →
   --  Extend_HSP per seed → filter by Min_Score → deduplicate overlapping
   --  HSPs (keep higher score) → sort descending → keep up to Max_Results.
   --  Raises Invalid_Argument if sequences exceed Max_Seq_Len or
   --  Max_Results > Max_HSPs.

   function HSPs_Overlap (A, B : HSP_Record) return Boolean
     with Global => null;
   --  True if A and B overlap on both query and subject intervals
   --  (inclusive endpoints).

   function Best_HSP (List : HSP_List) return HSP_Record
     with Global => null;
   --  Highest-scoring HSP, or a zero-score dummy if List.Count = 0.

   ---------------------------------------------------------------------------
   -- Optional Smith–Waterman (short gapped local alignment)
   ---------------------------------------------------------------------------

   type SW_Result is record
      Score   : Integer  := 0;
      Q_Start : Positive := 1;
      Q_End   : Positive := 1;
      S_Start : Positive := 1;
      S_End   : Positive := 1;
   end record;

   function Smith_Waterman_Local
     (Query, Subject : String;
      Params         : Score_Params := Default_Scores) return SW_Result
     with Global => null;
   --  Classic Smith–Waterman local alignment with linear gap Params.Gap.
   --  Recurrence: H(i,j) = max(0, diag+s, up+gap, left+gap).
   --  Returns best score and endpoints of one optimal local path.
   --  Intended for short pairs / gapped refinement comparison.
   --  Raises Invalid_Argument if either length > Max_Seq_Len or empty.

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_ACGT (C : Character) return Boolean
     with Global => null;

   function Normalize_Base (C : Character) return Character
     with Global => null;
   --  Uppercase ACGT; raises Invalid_Argument otherwise.

   function Normalize_Sequence (S : String) return String
     with Global => null;
   --  Uppercase each base; raises Invalid_Argument on non-ACGT or
   --  S'Length > Max_Seq_Len.

   function All_ACGT (S : String) return Boolean
     with Global => null;

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function HSP_Length (H : HSP_Record) return Natural
     with Global => null;
   --  Number of aligned columns = Q_End - Q_Start + 1
   --  (equals S_End - S_Start + 1 for ungapped HSPs).

private

   type Pos_Array is array (1 .. Max_Seq_Len) of Positive;

   type Word_Index is record
      W           : Word_Length := 3;
      Subject_Len : Seq_Length  := 0;
      Subject     : String (1 .. Max_Seq_Len) := [others => ' '];
      Count       : Natural := 0;
      Positions   : Pos_Array := [others => 1];
   end record;

end BLAST;
