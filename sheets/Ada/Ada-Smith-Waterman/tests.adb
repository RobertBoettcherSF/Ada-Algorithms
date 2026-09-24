--  Standalone test suite for Smith_Waterman (main program).

pragma Ada_2022;

with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Smith_Waterman;           use Smith_Waterman;

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

   procedure Expect_Align
     (A, B     : String;
      Exp_Sc   : Integer;
      Exp_AS, Exp_AE, Exp_BS, Exp_BE : Natural;
      Label    : String)
   is
      R : constant Alignment_Result := Align (A, B);
   begin
      Check (R.Score = Exp_Sc, Label & " Align.Score");
      Check (R.A_Start = Exp_AS, Label & " A_Start");
      Check (R.A_End = Exp_AE, Label & " A_End");
      Check (R.B_Start = Exp_BS, Label & " B_Start");
      Check (R.B_End = Exp_BE, Label & " B_End");
      Check (Best_Score (A, B) = R.Score, Label & " Best_Score=Align.Score");
   end Expect_Align;

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
   Expect_Score ("", "ACGT", 0, "empty A");
   Expect_Score ("ACGT", "", 0, "empty B");
   Expect_Score ("A", "A", 2, "singleton match");
   Expect_Score ("A", "T", 0, "singleton mismatch");
   Expect_Score ("G", "G", 2, "singleton G");
   declare
      R : constant Alignment_Result := Align ("", "X");
   begin
      Check (R.Score = 0 and then R.A_Start = 0 and then R.B_Start = 0,
             "empty Align indices zero");
   end;
   declare
      Sc : Integer;
      AA, BB : Unbounded_String;
   begin
      Align ("", "AC", Sc, AA, BB);
      Check (Sc = 0 and then AA = Null_Unbounded_String
             and then BB = Null_Unbounded_String,
             "empty gapped Align empty strings");
   end;

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
   Expect_Align ("ACGT", "ACGT", 8, 1, 4, 1, 4, "identical ACGT");
   Expect_Gapped ("ACGT", "ACGT", 8, "ACGT", "ACGT", "identical gapped");

   ---------------------------------------------------------------------
   Section ("3. No similarity");
   ---------------------------------------------------------------------
   Expect_Score ("AAAA", "TTTT", 0, "A vs T");
   Expect_Score ("ABCDEFG", "XYZ", 0, "disjoint alphabet");
   Expect_Score ("GGGG", "CCCC", 0, "G vs C");
   Expect_Score ("XYZ", "UVW", 0, "XYZ/UVW");
   declare
      R : constant Alignment_Result := Align ("AAAA", "TTTT");
   begin
      Check (R.Score = 0 and then R.A_Start = 0 and then R.A_End = 0
             and then R.B_Start = 0 and then R.B_End = 0,
             "no-sim Align all-zero indices");
   end;

   ---------------------------------------------------------------------
   Section ("4. Classic textbook / known scores");
   ---------------------------------------------------------------------
   --  Match=+2, Mismatch=-1, Gap=-1 (verified against independent DP).
   Expect_Align ("ACACACTA", "AGCACACA", 12, 1, 8, 1, 8, "ACACACTA/AGCACACA");
   Expect_Gapped ("ACACACTA", "AGCACACA", 12,
                  "A-CACACTA", "AGCACAC-A", "ACACACTA gapped");

   Expect_Align ("GGTTGACTA", "TGTTACGG", 9, 2, 7, 2, 6, "GGTTGACTA/TGTTACGG");
   Expect_Gapped ("GGTTGACTA", "TGTTACGG", 9,
                  "GTTGAC", "GTT-AC", "GGTTGACTA gapped");

   Expect_Align ("CGTGAATTCAT", "GACTTAC", 8, 4, 9, 1, 7, "CGTGAATTCAT");
   Expect_Gapped ("CGTGAATTCAT", "GACTTAC", 8,
                  "GAATT-C", "GACTTAC", "CGTGAATTCAT gapped");

   Expect_Align ("HEAGAWGHEE", "PAWHEAE", 8, 5, 10, 2, 7, "HEAGAWGHEE");
   Expect_Gapped ("HEAGAWGHEE", "PAWHEAE", 8,
                  "AWGHE-E", "AW-HEAE", "HEAGAWGHEE gapped");

   Expect_Align ("TATA", "ATAT", 6, 1, 3, 2, 4, "TATA/ATAT");
   Expect_Gapped ("TATA", "ATAT", 6, "TAT", "TAT", "TATA gapped");

   Expect_Align ("GATTACA", "GCATGCU", 5, 1, 3, 1, 4, "GATTACA/GCATGCU");
   Expect_Gapped ("GATTACA", "GCATGCU", 5, "G-AT", "GCAT", "GATTACA gapped");

   Expect_Align ("ATCG", "TAGC", 3, 1, 3, 2, 4, "ATCG/TAGC");
   Expect_Score ("AAAAA", "AAA", 6, "AAAAA/AAA");

   ---------------------------------------------------------------------
   Section ("5. Pair_Score and custom Scoring_Scheme");
   ---------------------------------------------------------------------
   Check (Pair_Score ('A', 'A') = 2, "Pair_Score match");
   Check (Pair_Score ('A', 'T') = -1, "Pair_Score mismatch");
   Check (Pair_Score ('x', 'x', Default_Scoring) = Match_Score,
          "Pair_Score Default_Scoring match");
   declare
      Soft : constant Scoring_Scheme :=
        (Match => 1, Mismatch => 0, Gap => -1);
      Harsh : constant Scoring_Scheme :=
        (Match => 5, Mismatch => -4, Gap => -3);
   begin
      Check (Best_Score ("AA", "AA", Soft) = 2, "soft identical AA");
      Check (Best_Score ("A", "T", Soft) = 0, "soft mismatch floored");
      Check (Best_Score ("AAA", "AAA", Harsh) = 15, "harsh AAA");
      Check (Best_Score ("AC", "AG", Harsh) = 5, "harsh AC/AG one match");
      Check (Align ("ACGT", "ACGT", Soft).Score = 4, "soft Align ACGT");
   end;

   ---------------------------------------------------------------------
   Section ("6. Local (not global) behaviour");
   ---------------------------------------------------------------------
   --  Shared motif buried in dissimilar flanks.
   Expect_Score ("XXXXACGTXXXX", "YYYYACGTYYYY", 8, "buried ACGT motif");
   declare
      R : constant Alignment_Result :=
        Align ("XXXXACGTXXXX", "YYYYACGTYYYY");
   begin
      Check (R.Score = 8, "buried motif score");
      Check (R.A_Start = 5 and then R.A_End = 8, "buried motif A span");
      Check (R.B_Start = 5 and then R.B_End = 8, "buried motif B span");
   end;
   --  Prefix/suffix only.
   Expect_Score ("ACGTZZZZ", "ACGT", 8, "prefix match full B");
   Expect_Score ("ZZZZACGT", "ACGT", 8, "suffix match full B");

   ---------------------------------------------------------------------
   Section ("7. Non-1 String'First bounds");
   ---------------------------------------------------------------------
   declare
      A : constant String (5 .. 8) := "ACGT";
      B : constant String (10 .. 13) := "ACGT";
      R : Alignment_Result;
   begin
      Check (Best_Score (A, B) = 8, "nonzero First Best_Score");
      R := Align (A, B);
      Check (R.Score = 8 and then R.A_Start = 1 and then R.A_End = 4
             and then R.B_Start = 1 and then R.B_End = 4,
             "nonzero First Align logical 1-based");
   end;
   declare
      A : constant String (3 .. 5) := "AAA";
      B : constant String (100 .. 102) := "AAA";
   begin
      Check (Best_Score (A, B) = 6, "First=3 and First=100");
   end;

   ---------------------------------------------------------------------
   Section ("8. Gapped consistency / structure");
   ---------------------------------------------------------------------
   declare
      Sc : Integer;
      AA, BB : Unbounded_String;
      R  : Alignment_Result;
   begin
      R := Align ("GGTTGACTA", "TGTTACGG");
      Align ("GGTTGACTA", "TGTTACGG", Sc, AA, BB);
      Check (Sc = R.Score, "proc/func score agree");
      Check (Length (AA) = Length (BB), "gapped same length");
      --  Non-gap chars in A_Aligned are the local A segment.
      declare
         Ungapped_A : Unbounded_String := Null_Unbounded_String;
         S : constant String := To_String (AA);
      begin
         for C of S loop
            if C /= '-' then
               Append (Ungapped_A, C);
            end if;
         end loop;
         declare
            Src_A : constant String := "GGTTGACTA";
         begin
            Check
              (To_String (Ungapped_A) = Src_A (R.A_Start .. R.A_End),
               "gapped A projects to A segment");
         end;
      end;
   end;
   declare
      Sc : Integer;
      AA, BB : Unbounded_String;
   begin
      Align ("AAAA", "TTTT", Sc, AA, BB);
      Check (Sc = 0 and then Length (AA) = 0 and then Length (BB) = 0,
             "zero-score empty gapped");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument / Max_Len");
   ---------------------------------------------------------------------
   Check (Score_Raises ([1 .. Max_Len + 1 => 'A'], "A"),
          "Max_Len+1 raises (bound check)");
   declare
      Over : constant String (1 .. Max_Len + 1) := [others => 'A'];
      Ok   : constant String (1 .. Max_Len) := [others => 'A'];
      Tiny : constant String := "A";
   begin
      Check (Score_Raises (Over, Tiny), "Best_Score A too long");
      Check (Score_Raises (Tiny, Over), "Best_Score B too long");
      Check (Align_Raises (Over, Tiny), "Align A too long");
      Check (Align_Raises (Over, Over), "Align both too long");
      Check (not Score_Raises (Ok, Tiny), "Best_Score at Max_Len ok");
      Check (Best_Score (Ok, Ok) = 2 * Max_Len, "identical Max_Len score");
   end;
   declare
      Sc : Integer;
      AA, BB : Unbounded_String;
      Over : constant String (1 .. Max_Len + 1) := [others => 'G'];
      Raised : Boolean := False;
   begin
      begin
         Align (Over, "G", Sc, AA, BB);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "proc Align raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("10. More patterns and idempotent score");
   ---------------------------------------------------------------------
   Expect_Score ("A", "AA", 2, "A/AA");
   Expect_Score ("AA", "A", 2, "AA/A");
   Expect_Score ("ABC", "ABC", 6, "ABC identical");
   Expect_Score ("AB", "BA", 2, "AB/BA one match");
   Expect_Score ("12345", "12345", 10, "digits identical");
   Expect_Score ("hello", "hallo", 7, "hello/hallo");
   --  hello/hallo: h=2,e/a=-1 →1, l=2 →3, l=2 →5, o=2 →7
   Check (Best_Score ("ACGT", "ACGT") = Best_Score ("ACGT", "ACGT"),
          "Best_Score idempotent");
   declare
      R1 : constant Alignment_Result := Align ("TATA", "ATAT");
      R2 : constant Alignment_Result := Align ("TATA", "ATAT");
   begin
      Check (R1.Score = R2.Score and then R1.A_Start = R2.A_Start
             and then R1.A_End = R2.A_End and then R1.B_Start = R2.B_Start
             and then R1.B_End = R2.B_End,
             "Align deterministic");
   end;
   Expect_Score ("WWWWW", "W", 2, "long vs single");
   Expect_Score ("AT", "GC", 0, "AT/GC no match");
   Expect_Score ("ATGC", "ATGCATGC", 8, "ATGC vs doubled");
   Check (Pair_Score ('Z', 'Z') = Match_Score, "Match_Score via Pair_Score");
   Check (Pair_Score ('Z', 'Y') = Mismatch_Score, "Mismatch via Pair_Score");
   declare
      Alt : constant Scoring_Scheme :=
        (Match => Match_Score, Mismatch => Mismatch_Score, Gap => Gap_Penalty);
   begin
      Check (Best_Score ("AC", "AC", Alt) = Best_Score ("AC", "AC"),
             "explicit Default-equal scheme");
   end;

   ---------------------------------------------------------------------
   Section ("11. Short DNA motifs");
   ---------------------------------------------------------------------
   Expect_Score ("GAATTC", "GAATTC", 12, "EcoRI site identical");
   Expect_Score ("GAATTC", "GATTC", 9, "EcoRI indel-ish");
   --  Manual: GAATTC vs GATTC with our scoring → verify
   declare
      Sc : constant Integer := Best_Score ("GAATTC", "GATTC");
   begin
      Check (Sc >= 8, "EcoRI indel score at least 8 got" & Sc'Image);
   end;
   Expect_Score ("ATG", "ATG", 6, "start codon");
   Expect_Score ("TAA", "TAG", 4, "stop-ish TA match");
   Expect_Score ("CCCC", "CCAC", 5, "CCCC/CCAC");
   Expect_Score ("AC", "CA", 2, "AC/CA");

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Smith_Waterman tests failed";
   end if;
end Tests;
