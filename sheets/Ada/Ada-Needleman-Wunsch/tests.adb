--  Standalone test suite for Needleman_Wunsch (main program).

pragma Ada_2022;

with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Needleman_Wunsch;         use Needleman_Wunsch;

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

   procedure Expect_Align_Fn
     (A, B : String; Exp_Sc : Integer; Exp_A, Exp_B : String; Label : String)
   is
      R : constant Alignment_Result := Align (A, B);
   begin
      Check (R.Score = Exp_Sc, Label & " Align.Score");
      Check (To_String (R.A_Aligned) = Exp_A, Label & " Align.A");
      Check (To_String (R.B_Aligned) = Exp_B, Label & " Align.B");
      Check (Best_Score (A, B) = R.Score, Label & " Best_Score=Align.Score");
   end Expect_Align_Fn;

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
   Expect_Align_Fn ("GATTACA", "GATTACA", 14, "GATTACA", "GATTACA",
                    "identical Align fn");

   ---------------------------------------------------------------------
   Section ("3. Mismatches and all-gaps pressure");
   ---------------------------------------------------------------------
   Expect_Score ("AAAA", "TTTT", -4, "A vs T all mismatch");
   Expect_Score ("GGGG", "CCCC", -4, "G vs C all mismatch");
   Expect_Score ("ABC", "XYZ", -3, "ABC/XYZ");
   Expect_Score ("XY", "UV", -2, "XY/UV");
   Expect_Gapped ("AAAA", "TTTT", -4, "AAAA", "TTTT", "all-mismatch gapped");

   ---------------------------------------------------------------------
   Section ("4. Classic textbook / known scores");
   ---------------------------------------------------------------------
   --  Default Match=+2, Mismatch=-1, Gap=-1 (verified against independent DP).
   Expect_Score ("GCATGCG", "GATTACA", 4, "wiki DNA default scoring");
   Expect_Gapped ("GCATGCG", "GATTACA", 4, "GCA-TGCG", "G-ATTACA",
                  "wiki DNA gapped");
   Expect_Align_Fn ("GCATGCG", "GATTACA", 4, "GCA-TGCG", "G-ATTACA",
                    "wiki DNA Align fn");

   --  Same pair with Wikipedia's Match=+1, Mismatch=-1, Gap=-1 → score 0.
   declare
      Wiki : constant Scoring_Scheme :=
        (Match => 1, Mismatch => -1, Gap => -1);
      Got  : constant Integer :=
        Best_Score ("GCATGCG", "GATTACA", Wiki);
      R    : constant Alignment_Result :=
        Align ("GCATGCG", "GATTACA", Wiki);
   begin
      Check (Got = 0, "wiki scoring Best_Score=0");
      Check (R.Score = 0, "wiki scoring Align.Score=0");
      Check (To_String (R.A_Aligned) = "GCA-TGCG", "wiki scoring A");
      Check (To_String (R.B_Aligned) = "G-ATTACA", "wiki scoring B");
   end;

   Expect_Score ("GGTTGACTA", "TGTTACGG", 6, "GGTTGACTA/TGTTACGG");
   Expect_Gapped ("GGTTGACTA", "TGTTACGG", 6, "GGTTGACTA", "TGTT-ACGG",
                  "GGTTGACTA gapped");
   Expect_Score ("HELLO", "HALLO", 7, "HELLO/HALLO");
   Expect_Gapped ("HELLO", "HALLO", 7, "HELLO", "HALLO", "HELLO gapped");
   Expect_Score ("ABC", "ABX", 3, "ABC/ABX");
   Expect_Score ("AGTACGCA", "TATGC", 4, "AGTACGCA/TATGC");

   ---------------------------------------------------------------------
   Section ("5. Length differences (indels)");
   ---------------------------------------------------------------------
   Expect_Score ("AA", "A", 1, "AA vs A");
   Expect_Gapped ("AA", "A", 1, "AA", "-A", "AA vs A gapped");
   Expect_Score ("A", "AA", 1, "A vs AA");
   Expect_Gapped ("A", "AA", 1, "-A", "AA", "A vs AA gapped");
   Expect_Score ("ACGT", "AGT", 5, "ACGT vs AGT");
   Expect_Score ("AAAA", "AA", 2, "AAAA vs AA");
   Expect_Score ("ABCDE", "ACE", 4, "ABCDE vs ACE");

   ---------------------------------------------------------------------
   Section ("6. Custom Scoring_Scheme");
   ---------------------------------------------------------------------
   declare
      Harsh_Gap : constant Scoring_Scheme :=
        (Match => 2, Mismatch => -1, Gap => -5);
      Soft_Mis  : constant Scoring_Scheme :=
        (Match => 5, Mismatch => 0, Gap => -1);
      Edit_Like : constant Scoring_Scheme :=
        (Match => 0, Mismatch => -1, Gap => -1);
   begin
      Expect_Score ("A", "T", -1, "default mismatch still -1");
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
   Section ("7. Pair_Score and Best_Score consistency");
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
   Section ("8. Non-1 String'First bounds");
   ---------------------------------------------------------------------
   declare
      A : constant String (5 .. 8) := "ACGT";
      B : constant String (10 .. 13) := "ACGT";
      C : constant String (3 .. 5) := "AGT";
   begin
      Expect_Score (A, B, 8, "non-1 First identical");
      Expect_Gapped (A, B, 8, "ACGT", "ACGT", "non-1 First gapped");
      Check (Best_Score (A, C) = Best_Score ("ACGT", "AGT"),
             "non-1 First vs slice-equivalent");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument (oversized)");
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
   Section ("10. More global alignment smoke tests");
   ---------------------------------------------------------------------
   Expect_Score ("CAT", "CAT", 6, "CAT/CAT");
   Expect_Score ("CAT", "CUT", 3, "CAT/CUT");
   Expect_Score ("GAATTC", "GAATTC", 12, "GAATTC identical");
   Expect_Score ("T", "TTTT", -1, "T vs TTTT");
   Expect_Score ("ATCG", "TAGC", 1, "ATCG/TAGC");
   Expect_Gapped ("A", "A", 2, "A", "A", "singleton gapped match");
   Expect_Gapped ("A", "T", -1, "A", "T", "singleton gapped mismatch");
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
