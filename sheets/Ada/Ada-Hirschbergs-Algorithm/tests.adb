--  Standalone test suite for Hirschbergs_Algorithm (main program).
--  Includes an inline reference Needleman–Wunsch (do not `with` the
--  sibling package) for score cross-checks on small cases.

pragma Ada_2022;

with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Hirschbergs_Algorithm;    use Hirschbergs_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   ------------------------------------------------------------------
   -- Inline reference NW (quadratic; for score cross-checks only)
   ------------------------------------------------------------------

   function Ref_NW_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer
   is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
      type Mat is array (0 .. M, 0 .. N) of Integer;
      F : Mat;
      Diag, Up, Left_S, Cell : Integer;

      function PA (I : Positive) return Character is
        (A (A'First + (I - 1)));
      function PB (J : Positive) return Character is
        (B (B'First + (J - 1)));
   begin
      F (0, 0) := 0;
      for J in 1 .. N loop
         F (0, J) := J * Scoring.Gap;
      end loop;
      for I in 1 .. M loop
         F (I, 0) := I * Scoring.Gap;
      end loop;
      for I in 1 .. M loop
         for J in 1 .. N loop
            if PA (I) = PB (J) then
               Diag := F (I - 1, J - 1) + Scoring.Match;
            else
               Diag := F (I - 1, J - 1) + Scoring.Mismatch;
            end if;
            Up     := F (I - 1, J) + Scoring.Gap;
            Left_S := F (I, J - 1) + Scoring.Gap;
            Cell   := Diag;
            if Up > Cell then
               Cell := Up;
            end if;
            if Left_S > Cell then
               Cell := Left_S;
            end if;
            F (I, J) := Cell;
         end loop;
      end loop;
      return F (M, N);
   end Ref_NW_Score;

   function Score_Of_Alignment
     (AA, BB  : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer
   is
      S : Integer := 0;
   begin
      if AA'Length /= BB'Length then
         return Integer'First;
      end if;
      for K in AA'Range loop
         declare
            CA : constant Character := AA (K);
            CB : constant Character := BB (K - AA'First + BB'First);
         begin
            if CA = '-' and then CB = '-' then
               return Integer'First;
            elsif CA = '-' or else CB = '-' then
               S := S + Scoring.Gap;
            elsif CA = CB then
               S := S + Scoring.Match;
            else
               S := S + Scoring.Mismatch;
            end if;
         end;
      end loop;
      return S;
   end Score_Of_Alignment;

   function Degap (S : String) return String is
      Buf : String (1 .. S'Length);
      L   : Natural := 0;
   begin
      for C of S loop
         if C /= '-' then
            L := L + 1;
            Buf (L) := C;
         end if;
      end loop;
      return Buf (1 .. L);
   end Degap;

   function Score_Raises (A, B : String) return Boolean is
      S : Integer;
   begin
      S := Best_Score (A, B);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Score_Raises;

   function Align_Raises (A, B : String) return Boolean is
      R : Alignment_Result;
   begin
      R := Align (A, B);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Align_Raises;

   procedure Expect_Score
     (A, B : String; Expected : Integer; Label : String)
   is
      Got : constant Integer := Best_Score (A, B);
   begin
      Check (Got = Expected,
             Label & " score=" & Got'Image & " expect" & Expected'Image);
   end Expect_Score;

   procedure Expect_Matches_Ref
     (A, B : String; Label : String;
      Scoring : Scoring_Scheme := Default_Scoring)
   is
      H  : constant Integer := Best_Score (A, B, Scoring);
      R  : constant Integer := Ref_NW_Score (A, B, Scoring);
      Al : constant Alignment_Result := Align (A, B, Scoring);
      AA : constant String := To_String (Al.A_Aligned);
      BB : constant String := To_String (Al.B_Aligned);
   begin
      Check (H = R, Label & " Best_Score=Ref_NW" & H'Image);
      Check (Al.Score = R, Label & " Align.Score=Ref_NW");
      Check (AA'Length = BB'Length, Label & " equal gapped lengths");
      Check (Degap (AA) = A (A'First .. A'First + A'Length - 1)
               or else (A'Length = 0 and then Degap (AA) = ""),
             Label & " degap A recovers");
      Check (Degap (BB) = B (B'First .. B'First + B'Length - 1)
               or else (B'Length = 0 and then Degap (BB) = ""),
             Label & " degap B recovers");
      Check (Score_Of_Alignment (AA, BB, Scoring) = R,
             Label & " path score = Ref_NW");
   end Expect_Matches_Ref;

   procedure Expect_Gapped
     (A, B : String; Exp_Sc : Integer; Exp_A, Exp_B : String; Label : String)
   is
      Sc : Integer;
      AA, BB : Unbounded_String;
   begin
      Align (A, B, Sc, AA, BB);
      Check (Sc = Exp_Sc, Label & " gapped score");
      Check (To_String (AA) = Exp_A, Label & " A_Aligned");
      Check (To_String (BB) = Exp_B, Label & " B_Aligned");
      Check (Length (AA) = Length (BB), Label & " equal gapped lengths");
   end Expect_Gapped;

begin
   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   Expect_Score ("", "", 0, "both empty");
   Expect_Score ("", "ACGT", -4, "empty A vs ACGT");
   Expect_Score ("ACGT", "", -4, "ACGT vs empty B");
   Expect_Score ("A", "A", 2, "singleton match");
   Expect_Score ("A", "T", -1, "singleton mismatch");
   Expect_Score ("G", "G", 2, "singleton G");
   Expect_Gapped ("", "", 0, "", "", "both empty gapped");
   Expect_Gapped ("", "AC", -2, "--", "AC", "empty A gapped");
   Expect_Gapped ("TG", "", -2, "TG", "--", "empty B gapped");
   Expect_Gapped ("A", "A", 2, "A", "A", "singleton gapped match");
   Expect_Gapped ("A", "T", -1, "A", "T", "singleton gapped mismatch");

   ---------------------------------------------------------------------
   Section ("2. Identical strings");
   ---------------------------------------------------------------------
   Expect_Score ("AA", "AA", 4, "AA/AA");
   Expect_Score ("ACGT", "ACGT", 8, "ACGT identical");
   Expect_Score ("AAACCC", "AAACCC", 12, "AAACCC identical");
   Expect_Score ("GATTACA", "GATTACA", 14, "GATTACA identical");
   declare
      S : constant String := "ABCDEFGHIJ";
   begin
      Expect_Score (S, S, 20, "len10 identical");
   end;
   Expect_Gapped ("ACGT", "ACGT", 8, "ACGT", "ACGT", "identical gapped");
   Expect_Gapped ("GATTACA", "GATTACA", 14, "GATTACA", "GATTACA",
                  "identical GATTACA gapped");

   ---------------------------------------------------------------------
   Section ("3. Mismatches");
   ---------------------------------------------------------------------
   Expect_Score ("AAAA", "TTTT", -4, "A vs T all mismatch");
   Expect_Score ("GGGG", "CCCC", -4, "G vs C all mismatch");
   Expect_Score ("ABC", "XYZ", -3, "ABC/XYZ");
   Expect_Score ("XY", "UV", -2, "XY/UV");
   Expect_Gapped ("AAAA", "TTTT", -4, "AAAA", "TTTT", "all-mismatch gapped");

   ---------------------------------------------------------------------
   Section ("4. Classic / known scores (match sibling NW)");
   ---------------------------------------------------------------------
   Expect_Score ("GCATGCG", "GATTACA", 4, "wiki DNA default scoring");
   Expect_Score ("GGTTGACTA", "TGTTACGG", 6, "GGTTGACTA/TGTTACGG");
   Expect_Score ("HELLO", "HALLO", 7, "HELLO/HALLO");
   Expect_Score ("ABC", "ABX", 3, "ABC/ABX");
   Expect_Score ("AGTACGCA", "TATGC", 4, "AGTACGCA/TATGC");
   declare
      Wiki : constant Scoring_Scheme :=
        (Match => 1, Mismatch => -1, Gap => -1);
      Got  : constant Integer :=
        Best_Score ("GCATGCG", "GATTACA", Wiki);
   begin
      Check (Got = 0, "wiki scoring Best_Score=0");
      Check (Align ("GCATGCG", "GATTACA", Wiki).Score = 0,
             "wiki scoring Align.Score=0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Indels / length differences");
   ---------------------------------------------------------------------
   Expect_Score ("AA", "A", 1, "AA vs A");
   Expect_Score ("A", "AA", 1, "A vs AA");
   Expect_Score ("ACGT", "AGT", 5, "ACGT vs AGT");
   Expect_Score ("AAAA", "AA", 2, "AAAA vs AA");
   Expect_Score ("ABCDE", "ACE", 4, "ABCDE vs ACE");

   ---------------------------------------------------------------------
   Section ("6. Cross-check vs inline reference NW");
   ---------------------------------------------------------------------
   Expect_Matches_Ref ("", "", "ref empty");
   Expect_Matches_Ref ("A", "", "ref A/empty");
   Expect_Matches_Ref ("", "T", "ref empty/T");
   Expect_Matches_Ref ("ACGT", "ACGT", "ref identical");
   Expect_Matches_Ref ("GCATGCG", "GATTACA", "ref wiki DNA");
   Expect_Matches_Ref ("AAAA", "TTTT", "ref mismatch");
   Expect_Matches_Ref ("AA", "A", "ref indel");
   Expect_Matches_Ref ("HELLO", "HALLO", "ref HELLO");
   Expect_Matches_Ref ("GGTTGACTA", "TGTTACGG", "ref GGTT");
   Expect_Matches_Ref ("AGTACGCA", "TATGC", "ref AGTACGCA");
   Expect_Matches_Ref ("CAT", "CUT", "ref CAT/CUT");
   Expect_Matches_Ref ("ATCG", "TAGC", "ref ATCG/TAGC");
   declare
      Soft : constant Scoring_Scheme :=
        (Match => 5, Mismatch => 0, Gap => -1);
      Harsh : constant Scoring_Scheme :=
        (Match => 2, Mismatch => -1, Gap => -5);
   begin
      Expect_Matches_Ref ("ACGT", "AGT", "ref soft", Soft);
      Expect_Matches_Ref ("AA", "A", "ref harsh", Harsh);
   end;

   ---------------------------------------------------------------------
   Section ("7. Custom Scoring_Scheme");
   ---------------------------------------------------------------------
   declare
      Harsh_Gap : constant Scoring_Scheme :=
        (Match => 2, Mismatch => -1, Gap => -5);
      Soft_Mis  : constant Scoring_Scheme :=
        (Match => 5, Mismatch => 0, Gap => -1);
      Edit_Like : constant Scoring_Scheme :=
        (Match => 0, Mismatch => -1, Gap => -1);
   begin
      Check (Best_Score ("AA", "A", Harsh_Gap) = -3,
             "harsh gap AA/A = -3");
      Check (Best_Score ("AC", "AC", Soft_Mis) = 10,
             "soft match AC/AC = 10");
      Check (Best_Score ("AAA", "AAA", Edit_Like) = 0,
             "edit-like identical = 0");
      Check (Best_Score ("AAA", "TTT", Edit_Like) = -3,
             "edit-like AAA/TTT = -3");
      Check (Best_Score ("AB", "A", Edit_Like) = -1,
             "edit-like AB/A = -1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Pair_Score and API consistency");
   ---------------------------------------------------------------------
   Check (Pair_Score ('A', 'A') = 2, "Pair_Score match");
   Check (Pair_Score ('A', 'T') = -1, "Pair_Score mismatch");
   declare
      Custom : constant Scoring_Scheme :=
        (Match => 7, Mismatch => -3, Gap => -2);
   begin
      Check (Pair_Score ('G', 'G', Custom) = 7, "Pair_Score custom match");
      Check (Pair_Score ('G', 'C', Custom) = -3, "Pair_Score custom mis");
   end;
   declare
      R  : constant Alignment_Result := Align ("AC", "AT");
      Sc : Integer;
      AA, BB : Unbounded_String;
   begin
      Align ("AC", "AT", Sc, AA, BB);
      Check (R.Score = Sc, "fn/proc Score agree");
      Check (To_String (R.A_Aligned) = To_String (AA), "fn/proc A agree");
      Check (To_String (R.B_Aligned) = To_String (BB), "fn/proc B agree");
      Check (Best_Score ("AC", "AT") = Sc, "Best_Score = Align score");
   end;

   ---------------------------------------------------------------------
   Section ("9. Non-1 String'First bounds");
   ---------------------------------------------------------------------
   declare
      A : constant String (5 .. 8) := "ACGT";
      B : constant String (10 .. 13) := "ACGT";
      C : constant String (3 .. 5) := "AGT";
   begin
      Expect_Score (A, B, 8, "non-1 First identical");
      Check (Best_Score (A, C) = Best_Score ("ACGT", "AGT"),
             "non-1 First vs slice-equivalent");
      Expect_Matches_Ref (A, C, "ref non-1 First");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument (oversized)");
   ---------------------------------------------------------------------
   declare
      Big : constant String (1 .. Max_Len + 1) := (others => 'A');
      Ok  : constant String (1 .. Max_Len) := (others => 'A');
   begin
      Check (Score_Raises (Big, "A"), "Best_Score A too long");
      Check (Score_Raises ("A", Big), "Best_Score B too long");
      Check (Align_Raises (Big, Ok), "Align A too long");
      Check (Align_Raises (Ok, Big), "Align B too long");
      Check (not Score_Raises (Ok, Ok), "Max_Len exact OK");
      Expect_Score (Ok, Ok, Max_Len * Match_Score, "Max_Len identical score");
   end;

   ---------------------------------------------------------------------
   Section ("11. More smoke / longer Hirschberg splits");
   ---------------------------------------------------------------------
   Expect_Score ("CAT", "CAT", 6, "CAT/CAT");
   Expect_Score ("CAT", "CUT", 3, "CAT/CUT");
   Expect_Score ("GAATTC", "GAATTC", 12, "GAATTC identical");
   Expect_Score ("T", "TTTT", -1, "T vs TTTT");
   Expect_Score ("ATCG", "TAGC", 1, "ATCG/TAGC");
   Expect_Matches_Ref ("ABCDEFGH", "ABXYEFGH", "ref len8 diverge");
   Expect_Matches_Ref ("MSSQLSERVER", "MYSQLSERVER", "ref MSSQL/MYSQL");
   Expect_Matches_Ref ("1234567890", "123XX67890", "ref digits");
   declare
      R : constant Alignment_Result := Align ("XX", "XY");
   begin
      Check (Length (R.A_Aligned) = Length (R.B_Aligned),
             "XX/XY equal lengths");
      Check (R.Score = Best_Score ("XX", "XY"), "XX/XY score consistent");
   end;

   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures present";
   end if;
end Tests;
