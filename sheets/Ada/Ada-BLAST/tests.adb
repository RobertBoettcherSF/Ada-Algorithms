--  Standalone test suite for BLAST (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with BLAST;       use BLAST;

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

   function Has_Covering_HSP
     (List              : HSP_List;
      Q0, Q1, S0, S1    : Positive;
      Min_Score         : Integer) return Boolean
   is
   begin
      for I in 1 .. List.Count loop
         declare
            H : HSP_Record renames List.HSPs (I);
         begin
            if H.Score >= Min_Score
              and then H.Q_Start <= Q0
              and then H.Q_End >= Q1
              and then H.S_Start <= S0
              and then H.S_End >= S1
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Covering_HSP;

   function Any_Hit_At
     (Hits : Hit_List; Q, S : Positive) return Boolean
   is
   begin
      for I in 1 .. Hits.Count loop
         if Hits.Hits (I).Q_Start = Q
           and then Hits.Hits (I).S_Start = S
         then
            return True;
         end if;
      end loop;
      return False;
   end Any_Hit_At;

begin
   Put_Line ("BLAST test suite");
   Put_Line ("================");

   ---------------------------------------------------------------------
   Section ("1. Is_ACGT / Normalize_Base / Near / All_ACGT");
   ---------------------------------------------------------------------
   begin
      Check (Is_ACGT ('A') and Is_ACGT ('a'), "Is_ACGT A/a");
      Check (Is_ACGT ('C') and Is_ACGT ('c'), "Is_ACGT C/c");
      Check (Is_ACGT ('G') and Is_ACGT ('g'), "Is_ACGT G/g");
      Check (Is_ACGT ('T') and Is_ACGT ('t'), "Is_ACGT T/t");
      Check (not Is_ACGT ('N'), "Is_ACGT rejects N");
      Check (not Is_ACGT ('X'), "Is_ACGT rejects X");
      Check (Normalize_Base ('a') = 'A', "Normalize a→A");
      Check (Normalize_Base ('t') = 'T', "Normalize t→T");
      Check (Normalize_Base ('G') = 'G', "Normalize G→G");
      Check (All_ACGT ("ACGT"), "All_ACGT ACGT");
      Check (All_ACGT ("acgtACGT"), "All_ACGT mixed case");
      Check (not All_ACGT ("ACGN"), "All_ACGT rejects N");
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near close");
      Check (not Near (1.0, 2.0), "Near far");
   end;

   ---------------------------------------------------------------------
   Section ("2. Normalize_Sequence / Pair_Score / Ungapped_Score");
   ---------------------------------------------------------------------
   declare
      N : constant String := Normalize_Sequence ("acgt");
      P : constant Score_Params := Default_Scores;
      Soft : constant Score_Params :=
        (Match => 1, Mismatch => -1, Gap => -1);
   begin
      Check (N = "ACGT", "Normalize_Sequence acgt");
      Check (Pair_Score ('A', 'A', P) = 2, "Pair match +2");
      Check (Pair_Score ('A', 'T', P) = -1, "Pair mismatch -1");
      Check (Pair_Score ('a', 'A', P) = 2, "Pair case-insensitive match");
      Check (Pair_Score ('A', 'N', P) = -1, "Pair non-ACGT mismatch");
      Check (Ungapped_Score ("AAAA", "AAAA", P) = 8, "ungapped 4 matches");
      Check (Ungapped_Score ("AAAA", "AAAT", P) = 5, "ungapped 3m1mm");
      Check (Ungapped_Score ("AC", "AG", Soft) = 0, "soft 1m1mm");
      Check (Ungapped_Score ("A", "A", P) = 2, "ungapped single");
      Check (Ungapped_Score ("AT", "A", P) = 2, "ungapped min length");
   end;

   ---------------------------------------------------------------------
   Section ("3. Build_Index basics");
   ---------------------------------------------------------------------
   declare
      Idx : constant Word_Index := Build_Index ("ACGTACGT", 3);
   begin
      Check (Index_W (Idx) = 3, "Index_W = 3");
      Check (Index_Subject_Length (Idx) = 8, "subject length 8");
      Check (Index_Entry_Count (Idx) = 6, "6 windows of W=3 in len 8");
   end;
   declare
      Idx : constant Word_Index := Build_Index ("AC", 3);
   begin
      Check (Index_Entry_Count (Idx) = 0, "short subject → 0 entries");
      Check (Index_Subject_Length (Idx) = 2, "short subject len stored");
   end;
   declare
      Idx : constant Word_Index := Build_Index ("", 3);
   begin
      Check (Index_Entry_Count (Idx) = 0, "empty subject index");
      Check (Index_Subject_Length (Idx) = 0, "empty subject len 0");
   end;
   declare
      Idx : constant Word_Index := Build_Index ("ACGNACGT", 3);
   begin
      --  Windows: 1 ACG ok, 2 CGN skip, 3 GNA skip, 4 NAC skip, 5 ACG ok, 6 CGT ok
      Check (Index_Entry_Count (Idx) = 3, "skip non-ACGT windows");
   end;
   declare
      Idx : constant Word_Index := Build_Index ("aaaa", 2);
   begin
      Check (Index_Entry_Count (Idx) = 3, "lowercase indexed as ACGT");
   end;

   ---------------------------------------------------------------------
   Section ("4. Find_Word_Hits exact seeds");
   ---------------------------------------------------------------------
   declare
      Subj : constant String := "AAACCCGGGTTT";
      Idx  : constant Word_Index := Build_Index (Subj, 3);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "CCCGGG");
   begin
      Check (Hits.Count >= 1, "at least one hit for CCCGGG");
      Check (Any_Hit_At (Hits, 1, 4), "CCC at q1 ↔ s4");
      Check (Any_Hit_At (Hits, 2, 5), "CCG at q2 ↔ s5");
      Check (Any_Hit_At (Hits, 3, 6), "CGG at q3 ↔ s6");
      Check (Any_Hit_At (Hits, 4, 7), "GGG at q4 ↔ s7");
   end;
   declare
      Idx  : constant Word_Index := Build_Index ("ACGTACGT", 4);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "TTTT");
   begin
      Check (Hits.Count = 0, "no hits for unrelated TTTT");
   end;
   declare
      Idx  : constant Word_Index := Build_Index ("AAAAAA", 3);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "AAA");
   begin
      Check (Hits.Count = 4, "AAA vs AAAAAA → 4 subject starts × 1 query");
   end;
   declare
      Idx  : constant Word_Index := Build_Index ("ACGT", 2);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "CG");
   begin
      Check (Any_Hit_At (Hits, 1, 2), "CG hit at subject 2");
      Check (Hits.Count = 1, "exactly one CG hit");
   end;

   ---------------------------------------------------------------------
   Section ("5. Identical sequences → high-scoring covering HSP");
   ---------------------------------------------------------------------
   declare
      Seq : constant String := "ACGTACGTACGT";
      L   : constant HSP_List :=
        Search (Seq, Seq, W => 3, X_Drop => 20, Min_Score => 1);
      B   : constant HSP_Record := Best_HSP (L);
   begin
      Check (L.Count >= 1, "identical: ≥1 HSP");
      Check (B.Score >= Integer (Seq'Length) * 2 - 2,
             "identical: near-perfect score");
      Check (B.Q_Start = 1 and then B.Q_End = Seq'Length,
             "identical: covers full query");
      Check (B.S_Start = 1 and then B.S_End = Seq'Length,
             "identical: covers full subject");
      Check (HSP_Length (B) = Seq'Length, "identical: HSP length");
   end;
   declare
      Seq : constant String := "GGGGCCCCAAAA";
      L   : constant HSP_List := Search (Seq, Seq, W => 4, X_Drop => 30);
      B   : constant HSP_Record := Best_HSP (L);
   begin
      Check (B.Score = Ungapped_Score (Seq, Seq),
             "identical W=4 score = ungapped");
      Check (Has_Covering_HSP (L, 1, Seq'Length, 1, Seq'Length, B.Score),
             "identical covering HSP present");
   end;

   ---------------------------------------------------------------------
   Section ("6. Planted substring found");
   ---------------------------------------------------------------------
   declare
      Motif  : constant String := "GATTACA";
      Subj   : constant String := "TTTT" & Motif & "CCCC";
      Query  : constant String := Motif;
      L      : constant HSP_List :=
        Search (Query, Subj, W => 3, X_Drop => 16, Min_Score => 1);
      B      : constant HSP_Record := Best_HSP (L);
   begin
      Check (L.Count >= 1, "planted: found HSP");
      Check (B.Score >= Motif'Length * 2 - 2, "planted: high score");
      Check (B.S_Start = 5 and then B.S_End = 11, "planted: subject coords");
      Check (B.Q_Start = 1 and then B.Q_End = Motif'Length,
             "planted: query coords");
   end;
   declare
      Motif : constant String := "AATTGGCC";
      Subj  : constant String := "GGG" & Motif & "AAA" & Motif;
      L     : constant HSP_List :=
        Search (Motif, Subj, W => 4, X_Drop => 20);
   begin
      Check (L.Count >= 1, "double plant: ≥1 HSP");
      Check (Best_HSP (L).Score >= Motif'Length, "double plant: score");
   end;

   ---------------------------------------------------------------------
   Section ("7. Mismatch lowers score");
   ---------------------------------------------------------------------
   declare
      A : constant String := "ACGTACGT";
      B : constant String := "ACGTACGA";  -- last base mismatch
      LA : constant HSP_List := Search (A, A, W => 3, X_Drop => 20);
      LB : constant HSP_List := Search (A, B, W => 3, X_Drop => 20);
   begin
      Check (Best_HSP (LA).Score > Best_HSP (LB).Score,
             "mismatch lowers best HSP score");
      Check (Ungapped_Score (A, A) > Ungapped_Score (A, B),
             "ungapped mismatch lower");
      Check (Ungapped_Score (A, B) = 8 * 2 - 3, "7 matches 1 mm → 13");
   end;
   declare
      Perfect : constant Integer := Ungapped_Score ("CCCC", "CCCC");
      One_MM  : constant Integer := Ungapped_Score ("CCCC", "CCCT");
      Two_MM  : constant Integer := Ungapped_Score ("CCCC", "CCTT");
   begin
      Check (Perfect = 8, "4 matches = 8");
      Check (One_MM = 5, "3m1mm = 5");
      Check (Two_MM = 2, "2m2mm = 2");
      Check (Perfect > One_MM and then One_MM > Two_MM, "score monotonic");
   end;

   ---------------------------------------------------------------------
   Section ("8. X-drop stops extension");
   ---------------------------------------------------------------------
   declare
      --  Seed AAA in middle; flanks are mismatches that drain score.
      Query : constant String := "GGGAAACCC";
      Subj  : constant String := "TTTAAATTT";
      H     : constant HSP_Record :=
        Extend_HSP (Query, Subj, 4, 4, W => 3, X_Drop => 0);
      --  With X_Drop=0, cannot extend past first mismatch after seed.
   begin
      Check (H.Q_Start = 4 and then H.Q_End = 6, "X=0: only seed on query");
      Check (H.S_Start = 4 and then H.S_End = 6, "X=0: only seed on subject");
      Check (H.Score = 6, "X=0: seed score 3*2");
   end;
   declare
      --  Flanks mismatch so X=0 cannot improve; large X may still try.
      Query : constant String := "GGGGAAAACCCC";
      Subj  : constant String := "TTTTAAAATTTT";
      H0    : constant HSP_Record :=
        Extend_HSP (Query, Subj, 5, 5, 4, X_Drop => 0);
      HBig  : constant HSP_Record :=
        Extend_HSP (Query, Subj, 5, 5, 4, X_Drop => 100);
   begin
      Check (HSP_Length (H0) = 4, "X=0 length = W");
      Check (H0.Score = 8, "X=0 score = 4*2");
      Check (HSP_Length (HBig) >= HSP_Length (H0), "large X ≥ small X len");
      Check (HBig.Score >= H0.Score, "large X score ≥ small X");
   end;
   declare
      Q : constant String := "AAAAAAAAAA";
      S : constant String := "AAAAAAAAAA";
      H : constant HSP_Record :=
        Extend_HSP (Q, S, 1, 1, W => 3, X_Drop => 2);
   begin
      Check (H.Q_End = 10 and then H.S_End = 10, "matching: extends full");
      Check (H.Score = 20, "10 matches * 2");
   end;

   ---------------------------------------------------------------------
   Section ("9. No hit on unrelated sequences");
   ---------------------------------------------------------------------
   declare
      L : constant HSP_List :=
        Search ("AAAAAAAA", "CCCCCCCC", W => 3, X_Drop => 10,
                Min_Score => 1);
   begin
      Check (L.Count = 0, "A vs C: no HSPs");
   end;
   declare
      Idx  : constant Word_Index := Build_Index ("GGGGGGGG", 4);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "AAAAAAAA");
   begin
      Check (Hits.Count = 0, "no word hits A vs G");
   end;
   declare
      L : constant HSP_List :=
        Search ("ACGT", "TGCA", W => 3, Min_Score => 5);
   begin
      Check (L.Count = 0 or else Best_HSP (L).Score < 10,
             "reversed-ish: no strong HSP");
   end;

   ---------------------------------------------------------------------
   Section ("10. Extend_HSP direct / HSP_Length / Best_HSP");
   ---------------------------------------------------------------------
   declare
      Q : constant String := "TTACGTAA";
      S : constant String := "GGACGTCC";
      H : constant HSP_Record :=
        Extend_HSP (Q, S, 3, 3, W => 4, X_Drop => 8);
      Empty : constant HSP_List := (Count => 0, HSPs => <>);
   begin
      Check (H.Score >= 8, "ACGT seed extends with score ≥ 8");
      Check (HSP_Length (H) >= 4, "HSP length ≥ W");
      Check (Best_HSP (Empty).Score = 0, "Best_HSP empty → 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Search dedup / top scores / overlap");
   ---------------------------------------------------------------------
   declare
      Seq : constant String := "ACACACACACAC";
      L   : constant HSP_List :=
        Search (Seq, Seq, W => 2, X_Drop => 20, Max_Results => 3);
      A, B : HSP_Record;
   begin
      Check (L.Count >= 1, "periodic: ≥1 after dedup");
      Check (L.Count <= 3, "Max_Results=3 honored");
      if L.Count >= 2 then
         A := L.HSPs (1);
         B := L.HSPs (2);
         Check (A.Score >= B.Score, "sorted descending");
      else
         Check (True, "sorted descending (single)");
      end if;
      Check (HSPs_Overlap (L.HSPs (1), L.HSPs (1)), "HSP overlaps self");
   end;
   declare
      H1 : constant HSP_Record :=
        (Q_Start => 1, Q_End => 5, S_Start => 1, S_End => 5, Score => 10);
      H2 : constant HSP_Record :=
        (Q_Start => 3, Q_End => 8, S_Start => 3, S_End => 8, Score => 12);
      H3 : constant HSP_Record :=
        (Q_Start => 20, Q_End => 25, S_Start => 1, S_End => 6, Score => 8);
   begin
      Check (HSPs_Overlap (H1, H2), "overlapping HSPs detected");
      Check (not HSPs_Overlap (H1, H3), "non-overlap on query");
   end;

   ---------------------------------------------------------------------
   Section ("12. Smith_Waterman_Local recovers local match");
   ---------------------------------------------------------------------
   declare
      Q : constant String := "AAAA";
      S : constant String := "TTTTAAAAGGGG";
      R : constant SW_Result := Smith_Waterman_Local (Q, S);
   begin
      Check (R.Score = 8, "SW identical tetranucleotide score 8");
      Check (R.S_Start = 5 and then R.S_End = 8, "SW subject coords");
      Check (R.Q_Start = 1 and then R.Q_End = 4, "SW query coords");
   end;
   declare
      Q : constant String := "ACGTACGT";
      S : constant String := "XXXXACGTACGTYYYY";
      R : constant SW_Result := Smith_Waterman_Local (Q, S);
   begin
      Check (R.Score >= 14, "SW planted high score");
      Check (R.S_Start = 5, "SW planted start");
      Check (R.S_End = 12, "SW planted end");
   end;
   declare
      R : constant SW_Result :=
        Smith_Waterman_Local ("ACGT", "ACGT");
   begin
      Check (R.Score = 8, "SW full identity");
      Check (R.Q_Start = 1 and then R.Q_End = 4, "SW full Q");
      Check (R.S_Start = 1 and then R.S_End = 4, "SW full S");
   end;
   declare
      --  Gap needed: query has insertion relative to local subject stretch.
      R : constant SW_Result :=
        Smith_Waterman_Local ("AAA", "GGGAAAGGG");
   begin
      Check (R.Score = 6, "SW AAA in GGGAAAGGG");
   end;
   declare
      R : constant SW_Result :=
        Smith_Waterman_Local ("AC", "GT");
   begin
      Check (R.Score = 0, "SW unrelated → 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Configurable scores");
   ---------------------------------------------------------------------
   declare
      Soft : constant Score_Params :=
        (Match => 5, Mismatch => -4, Gap => -3);
      H : constant HSP_Record :=
        Extend_HSP ("AAAA", "AAAA", 1, 1, 4, 10, Soft);
      R : constant SW_Result :=
        Smith_Waterman_Local ("AA", "AA", Soft);
   begin
      Check (H.Score = 20, "custom match 5 → 20");
      Check (Pair_Score ('A', 'T', Soft) = -4, "custom mismatch");
      Check (R.Score = 10, "SW custom match");
      Check (Ungapped_Score ("AT", "AA", Soft) = 1, "5 + -4 = 1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Exception paths");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Dummy : Character := Normalize_Base ('N');
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Normalize_Base N raises");

      Raised := False;
      begin
         declare
            Dummy : constant String := Normalize_Sequence ("ACGN");
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Normalize_Sequence N raises");

      Raised := False;
      begin
         declare
            Long : constant String (1 .. Max_Seq_Len + 1) :=
              [others => 'A'];
            Dummy : constant Word_Index := Build_Index (Long, 3);
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Build_Index too long raises");

      Raised := False;
      begin
         declare
            Dummy : constant HSP_List :=
              Search ("AAA", "AAA", Max_Results => Max_HSPs + 1);
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Search Max_Results too big raises");

      Raised := False;
      begin
         declare
            Dummy : constant HSP_Record :=
              Extend_HSP ("AAA", "AAA", 2, 1, W => 3, X_Drop => 1);
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Extend_HSP bad seed raises");

      Raised := False;
      begin
         declare
            Dummy : constant SW_Result := Smith_Waterman_Local ("", "A");
         begin
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "SW empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("15. Synthetic cases / varied W");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "ATGCGATCGTAGCTAGCTAG";
   begin
      for W in Word_Length range 2 .. 6 loop
         declare
            L : constant HSP_List :=
              Search (Ref, Ref, W => W, X_Drop => 24, Min_Score => 1);
         begin
            Check (L.Count >= 1, "self-search W=" & W'Image);
            Check (Best_HSP (L).Score >= Ref'Length,
                   "self-score W=" & W'Image);
         end;
      end loop;
   end;
   declare
      --  Two different motifs.
      Q1 : constant String := "CCCCCCCC";
      Q2 : constant String := "GGGGGGGG";
      S  : constant String := "TTT" & Q1 & "AAA" & Q2 & "TTT";
      L1 : constant HSP_List := Search (Q1, S, W => 3);
      L2 : constant HSP_List := Search (Q2, S, W => 3);
   begin
      Check (Best_HSP (L1).S_Start = 4, "motif1 subject start");
      Check (Best_HSP (L2).S_Start = 15, "motif2 subject start");
      Check (Best_HSP (L1).Score >= 14, "motif1 score");
      Check (Best_HSP (L2).Score >= 14, "motif2 score");
   end;
   declare
      Prefix : constant String := "ACGTACGTACGTACGT";
      Q      : constant String := Prefix (1 .. 8);
      L      : constant HSP_List := Search (Q, Prefix, W => 4);
   begin
      Check (Best_HSP (L).Q_End - Best_HSP (L).Q_Start + 1 >= 8,
             "prefix query full cover");
      Check (Best_HSP (L).S_Start = 1, "prefix at subject start");
   end;

   ---------------------------------------------------------------------
   Section ("16. Case insensitivity in search");
   ---------------------------------------------------------------------
   declare
      L : constant HSP_List :=
        Search ("acgtacgt", "ACGTACGT", W => 3);
   begin
      Check (L.Count >= 1, "lowercase query vs upper subject");
      Check (Best_HSP (L).Score >= 14, "case-insensitive high score");
   end;
   declare
      Idx  : constant Word_Index := Build_Index ("acgt", 2);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "CG");
   begin
      Check (Hits.Count = 1, "index lower, query upper hit");
   end;

   ---------------------------------------------------------------------
   Section ("17. Capacity constants / sanity");
   ---------------------------------------------------------------------
   declare
      function Id (N : Integer) return Integer is (N);
      M : constant Score_Params := Default_Scores;
   begin
      Check (Id (Max_Seq_Len) = 400, "Max_Seq_Len = 400");
      Check (Id (Max_W) = 12, "Max_W = 12");
      Check (Id (Max_HSPs) = 64, "Max_HSPs = 64");
      Check (Id (Max_Hits) = 512, "Max_Hits = 512");
      Check (M.Match = 2, "default match +2");
      Check (M.Mismatch = -1, "default mismatch -1");
      Check (M.Gap = -2, "default gap -2");
   end;

   ---------------------------------------------------------------------
   Section ("18. Longer synthetic / SW vs BLAST score relation");
   ---------------------------------------------------------------------
   declare
      Q : constant String := "GCTAGCTA";
      S : constant String := "NNNN" & Q & "NNNN";
      BL : constant HSP_List := Search (Q, S, W => 3, X_Drop => 20);
      SW : constant SW_Result := Smith_Waterman_Local (Q, S);
   begin
      Check (Best_HSP (BL).Score = 16, "BLAST planted 8*2");
      Check (SW.Score = 16, "SW planted 8*2");
      Check (Best_HSP (BL).S_Start = SW.S_Start, "BLAST/SW same start");
      Check (Best_HSP (BL).S_End = SW.S_End, "BLAST/SW same end");
   end;
   declare
      --  Single mismatch in middle: SW/BLAST both find local region.
      Q : constant String := "AAAAACAAAAA";
      S : constant String := "AAAAATAAAAA";
      BL : constant HSP_List := Search (Q, S, W => 3, X_Drop => 20);
      SW : constant SW_Result := Smith_Waterman_Local (Q, S);
   begin
      Check (BL.Count >= 1, "near-identical BLAST hit");
      Check (SW.Score > 0, "near-identical SW score > 0");
      Check (Best_HSP (BL).Score > 0, "near-identical BLAST score > 0");
      Check (SW.Score >= Best_HSP (BL).Score - 6,
             "SW and BLAST scores in same ballpark");
   end;

   ---------------------------------------------------------------------
   Section ("19. Word index entry positions / multi-hit");
   ---------------------------------------------------------------------
   declare
      Subj : constant String := "CATCATCAT";
      Idx  : constant Word_Index := Build_Index (Subj, 3);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "CAT");
   begin
      Check (Index_Entry_Count (Idx) = 7, "CATCATCAT W=3 → 7");
      Check (Hits.Count = 3, "CAT occurs 3 times");
      Check (Any_Hit_At (Hits, 1, 1), "CAT @1");
      Check (Any_Hit_At (Hits, 1, 4), "CAT @4");
      Check (Any_Hit_At (Hits, 1, 7), "CAT @7");
   end;

   ---------------------------------------------------------------------
   Section ("20. Edge: W=1 and minimal strings");
   ---------------------------------------------------------------------
   declare
      L : constant HSP_List :=
        Search ("A", "A", W => 1, X_Drop => 0, Min_Score => 1);
   begin
      Check (L.Count = 1, "W=1 single base hit");
      Check (Best_HSP (L).Score = 2, "W=1 score +2");
   end;
   declare
      Idx  : constant Word_Index := Build_Index ("ACGT", 1);
      Hits : constant Hit_List := Find_Word_Hits (Idx, "G");
   begin
      Check (Index_Entry_Count (Idx) = 4, "W=1 four bases");
      Check (Any_Hit_At (Hits, 1, 3), "G at position 3");
   end;
   declare
      H : constant HSP_Record :=
        Extend_HSP ("AT", "AT", 1, 1, W => 1, X_Drop => 10);
   begin
      Check (H.Score = 4, "extend W=1 over AT identity → 4");
      Check (HSP_Length (H) = 2, "extended to length 2");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   if Fail_Count > 0 then
      raise Program_Error with "BLAST tests failed";
   end if;
end Tests;
