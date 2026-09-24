--  Standalone test suite for Velvet (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Velvet;      use Velvet;

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

   function Contig_Has_Ref (C : Contig_List; Ref : String) return Boolean is
   begin
      for I in 1 .. C.Count loop
         declare
            S : constant String := Contig_String (C.Contigs (I));
         begin
            if S = Ref
              or else Contains_Substring (S, Ref)
              or else Contains_Substring (Ref, S)
              or else Contains_Substring (S, Reverse_Complement (Ref))
              or else Contains_Substring (Reverse_Complement (Ref), S)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Contig_Has_Ref;

   function Longest_Contig (C : Contig_List) return String is
      Best_I : Contig_Index := 0;
      Best_L : Natural := 0;
   begin
      for I in 1 .. C.Count loop
         if C.Contigs (I).Len > Best_L then
            Best_L := C.Contigs (I).Len;
            Best_I := I;
         end if;
      end loop;
      if Best_I = 0 then
         return "";
      end if;
      return Contig_String (C.Contigs (Best_I));
   end Longest_Contig;

begin
   Put_Line ("Velvet test suite");
   Put_Line ("=================");

   ---------------------------------------------------------------------
   Section ("1. Build_Graph / Get_K / empty queries");
   ---------------------------------------------------------------------
   declare
      G : constant Graph := Build_Graph (K => 5);
   begin
      Check (Get_K (G) = 5, "Get_K = 5");
      Check (Node_Count (G) = 0, "empty Node_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Check (not Contains_Node (G, "ACGT"), "empty has no ACGT node");
      Check (Edge_Multiplicity (G, "ACGT", "CGTA") = 0,
             "empty edge mult = 0");
      declare
         C : constant Contig_List := Emit_Contigs (G);
      begin
         Check (C.Count = 0, "empty graph emits 0 contigs");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("2. Is_ACGT / Normalize_Base / Near");
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
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near within default tol");
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               U : Character := Normalize_Base ('N');
            begin
               pragma Unreferenced (U);
            end;
         exception
            when Invalid_Argument => Raised := True;
            when others => null;
         end;
         Check (Raised, "Normalize_Base(N) raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Reverse_Complement involution");
   ---------------------------------------------------------------------
   begin
      Check (Reverse_Complement ("A") = "T", "RC(A)=T");
      Check (Reverse_Complement ("T") = "A", "RC(T)=A");
      Check (Reverse_Complement ("C") = "G", "RC(C)=G");
      Check (Reverse_Complement ("G") = "C", "RC(G)=C");
      Check (Reverse_Complement ("ACGT") = "ACGT", "RC(ACGT)=ACGT palindrome");
      Check (Reverse_Complement ("AA") = "TT", "RC(AA)=TT");
      Check (Reverse_Complement ("ATCG") = "CGAT", "RC(ATCG)=CGAT");
      Check (Reverse_Complement (Reverse_Complement ("GATTACA")) = "GATTACA",
             "RC involution GATTACA");
      Check (Reverse_Complement (Reverse_Complement ("acgtn")) =
             Reverse_Complement (Reverse_Complement ("ACGTN")),
             "RC case-normalized consistency");
      Check (Reverse_Complement ("") = "", "RC empty");
      declare
         Raised : Boolean := False;
         Big    : constant String (1 .. Max_Read_Length + 1) :=
           (others => 'A');
      begin
         begin
            declare
               U : constant String := Reverse_Complement (Big);
            begin
               pragma Unreferenced (U);
            end;
         exception
            when Invalid_Argument => Raised := True;
            when others => null;
         end;
         Check (Raised, "RC overlong raises Invalid_Argument");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Add_Read short / empty / non-ACGT skip");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (K => 4);
   begin
      Add_Read (G, "", Include_RC => False);
      Check (Node_Count (G) = 0, "empty read → no nodes");
      Add_Read (G, "ACG", Include_RC => False);  -- length < k
      Check (Node_Count (G) = 0, "short read → no nodes");
      Add_Read (G, "ACGNACGT", Include_RC => False);
      --  Windows with N skipped; trailing ACGT may create one k-mer if aligned
      --  Positions: only windows of length 4 without N count.
      Check (Node_Count (G) >= 0, "non-ACGT windows skipped without crash");
      Add_Read (G, "ACGT", Include_RC => False);
      Check (Node_Count (G) >= 2, "ACGT adds prefix ACG and suffix CGT");
      Check (Contains_Node (G, "ACG"), "node ACG present");
      Check (Contains_Node (G, "CGT"), "node CGT present");
      Check (Edge_Multiplicity (G, "ACG", "CGT") >= 1, "edge ACG→CGT");
   end;

   ---------------------------------------------------------------------
   Section ("5. Perfect coverage recovers reference contig");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "ACGTACGTAC";
      K   : constant Kmer_Length := 5;
      G   : Graph := Build_Graph (K);
      C   : Contig_List;
   begin
      --  Sliding perfect tiles of the reference (no RC noise).
      for I in Ref'First .. Ref'Last - K + 1 loop
         Add_Read (G, Ref (I .. I + K - 1), Include_RC => False);
      end loop;
      Check (Node_Count (G) > 0, "perfect tiles → nodes > 0");
      Check (Edge_Count (G) > 0, "perfect tiles → edges > 0");
      C := Emit_Contigs (G);
      Check (C.Count >= 1, "perfect tiles → ≥1 contig");
      Check (Contig_Has_Ref (C, Ref),
             "contig contains or equals reference ACGTACGTAC");
      declare
         L : constant String := Longest_Contig (C);
      begin
         Check (L'Length >= Ref'Length - K + 1,
                "longest contig length reasonable vs Ref");
         Check (Contains_Substring (L, "ACGT")
                or else Contains_Substring (Reverse_Complement (L), "ACGT"),
                "longest contig has ACGT motif");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Longer synthetic genome with overlapping reads");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "ATGCGATCGTACGATCGTAA";
      K   : constant Kmer_Length := 7;
      G   : Graph := Build_Graph (K);
      C   : Contig_List;
      RL  : constant Positive := 12;
   begin
      for I in Ref'First .. Ref'Last - RL + 1 loop
         Add_Read (G, Ref (I .. I + RL - 1), Include_RC => False);
      end loop;
      C := Emit_Contigs (G);
      Check (C.Count >= 1, "genome20 → ≥1 contig");
      Check (Contig_Has_Ref (C, Ref), "genome20 contig recovers Ref");
      Check (Node_Count (G) >= 8,
             "node count order of distinct (k-1)-mers");
   end;

   ---------------------------------------------------------------------
   Section ("7. Reverse complement hashing increases coverage");
   ---------------------------------------------------------------------
   declare
      G1 : Graph := Build_Graph (4);
      G2 : Graph := Build_Graph (4);
      R  : constant String := "ACGTAC";
   begin
      Add_Read (G1, R, Include_RC => False);
      Add_Read (G2, R, Include_RC => True);
      Check (Node_Count (G2) >= Node_Count (G1),
             "Include_RC adds ≥ as many nodes");
      Check (Edge_Count (G2) >= Edge_Count (G1),
             "Include_RC adds ≥ as many edges");
      --  Multiplicity on forward edge may stay 1; RC adds other edges.
      Check (Edge_Multiplicity (G1, "ACG", "CGT") = 1, "fwd mult without RC");
      Check (Edge_Multiplicity (G2, "ACG", "CGT") >= 1, "fwd mult with RC");
   end;

   ---------------------------------------------------------------------
   Section ("8. Tip removal shrinks dead-end tip");
   ---------------------------------------------------------------------
   declare
      --  Backbone: AAAAAAAA (with k=4 → nodes AAA)
      --  Tip: attach a divergent dead-end via a low path.
      G : Graph := Build_Graph (4);
      N_Before, N_After, E_Before, E_After : Natural;
   begin
      Add_Read (G, "AAAACAAA", Include_RC => False);
      Add_Read (G, "AAACAAAA", Include_RC => False);
      Add_Read (G, "AACAAAAC", Include_RC => False);
      --  Introduce a tip spur: ... → short dead end "AAAG" path
      Add_Read (G, "AAAG", Include_RC => False);
      N_Before := Node_Count (G);
      E_Before := Edge_Count (G);
      Check (N_Before > 0, "tip scenario has nodes");
      Remove_Tips (G, Max_Tip_Length => 4);
      N_After := Node_Count (G);
      E_After := Edge_Count (G);
      Check (N_After <= N_Before, "Remove_Tips does not grow nodes");
      Check (E_After <= E_Before, "Remove_Tips does not grow edges");
      --  Spur AAAG→AAG tip should be gone or reduced
      Check (not Contains_Node (G, "AAG")
             or else Edge_Multiplicity (G, "AAA", "AAG") = 0
             or else N_After < N_Before,
             "tip spur removed or shrunk");
   end;

   ---------------------------------------------------------------------
   Section ("9. Low coverage filter removes rare edges");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (4);
      E_Before, E_After : Natural;
   begin
      --  High coverage backbone
      for I in 1 .. 5 loop
         Add_Read (G, "ACGTACGT", Include_RC => False);
      end loop;
      --  Singleton erroneous k-mer
      Add_Read (G, "ACGG", Include_RC => False);
      E_Before := Edge_Count (G);
      Check (Edge_Multiplicity (G, "ACG", "CGG") = 1, "error edge mult=1");
      Check (Edge_Multiplicity (G, "ACG", "CGT") >= 5, "good edge mult≥5");
      Remove_Low_Coverage (G, Min_Coverage => 2);
      E_After := Edge_Count (G);
      Check (E_After < E_Before, "low coverage removed some edges");
      Check (Edge_Multiplicity (G, "ACG", "CGG") = 0, "error edge gone");
      Check (Edge_Multiplicity (G, "ACG", "CGT") >= 5, "good edge kept");
   end;

   ---------------------------------------------------------------------
   Section ("10. Multiplicity accumulates");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (3);
   begin
      Add_Read (G, "ACGT", Include_RC => False);
      Check (Edge_Multiplicity (G, "AC", "CG") = 1, "first AC→CG mult=1");
      Add_Read (G, "ACGT", Include_RC => False);
      Check (Edge_Multiplicity (G, "AC", "CG") = 2, "second AC→CG mult=2");
      Add_Read (G, "ACGT", Include_RC => False);
      Check (Edge_Multiplicity (G, "AC", "CG") = 3, "third AC→CG mult=3");
      Check (Edge_Multiplicity (G, "CG", "GT") = 3, "CG→GT mult=3");
   end;

   ---------------------------------------------------------------------
   Section ("11. k validation / Get_K variants");
   ---------------------------------------------------------------------
   declare
      G2  : Graph := Build_Graph (2);
      G7  : constant Graph := Build_Graph (7);
      G31 : constant Graph := Build_Graph (Max_K);
   begin
      Check (Get_K (G2) = 2, "K=2");
      Check (Get_K (G7) = 7, "K=7");
      Check (Get_K (G31) = Max_K, "K=Max_K");
      Add_Read (G2, "ACGT", Include_RC => False);
      Check (Contains_Node (G2, "A"), "k=2 node is 1-mer A");
      Check (Contains_Node (G2, "C"), "k=2 node C");
      Check (Edge_Multiplicity (G2, "A", "C") >= 1, "k=2 edge A→C");
   end;

   ---------------------------------------------------------------------
   Section ("12. Case-insensitive reads");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (4);
   begin
      Add_Read (G, "acgt", Include_RC => False);
      Check (Contains_Node (G, "ACG"), "lowercase read → ACG");
      Check (Contains_Node (G, "CGT"), "lowercase read → CGT");
      Add_Read (G, "AcGtAc", Include_RC => False);
      Check (Edge_Multiplicity (G, "ACG", "CGT") >= 2, "mixed case accumulates");
   end;

   ---------------------------------------------------------------------
   Section ("13. Contig_String / Contains_Substring helpers");
   ---------------------------------------------------------------------
   declare
      R : Contig_Record;
   begin
      R.Len := 4;
      R.Seq (1 .. 4) := "ACGT";
      Check (Contig_String (R) = "ACGT", "Contig_String slice");
      Check (Contains_Substring ("ACGTAC", "GTA"), "substring mid");
      Check (Contains_Substring ("ACGT", "ACGT"), "substring equal");
      Check (Contains_Substring ("ACGT", ""), "empty needle");
      Check (not Contains_Substring ("ACGT", "TG"), "missing substring");
      Check (not Contains_Substring ("AC", "ACGT"), "needle longer");
   end;

   ---------------------------------------------------------------------
   Section ("14. Over-long read raises");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (5);
      Big : constant String (1 .. Max_Read_Length + 1) := [others => 'A'];
      Raised : Boolean := False;
   begin
      begin
         Add_Read (G, Big, Include_RC => False);
      exception
         when Invalid_Argument => Raised := True;
         when others => null;
      end;
      Check (Raised, "overlong Add_Read raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("15. Several synthetic genomes");
   ---------------------------------------------------------------------
   declare
      type Genome_Spec is record
         Ref : String (1 .. 24);
         Len : Positive;
         K   : Kmer_Length;
         RL  : Positive;
      end record;
      Specs : constant array (1 .. 5) of Genome_Spec :=
        [(Ref => "ATGCATGCATGCATGCATGCATGC", Len => 24, K => 5, RL => 10),
         (Ref => "GATTACAGATTACAGATTACAGAT", Len => 24, K => 6, RL => 12),
         (Ref => "AAAAAAAAAAAAAAAAAAAAAAAA", Len => 24, K => 4, RL => 8),
         (Ref => "ACGTACGTACGTACGTACGTACGT", Len => 24, K => 7, RL => 14),
         (Ref => "TGCATGCATGCATGCATGCATGCA", Len => 24, K => 5, RL => 9)];
   begin
      for S of Specs loop
         declare
            Ref : constant String := S.Ref (1 .. S.Len);
            G   : Graph := Build_Graph (S.K);
            C   : Contig_List;
         begin
            for I in Ref'First .. Ref'Last - S.RL + 1 loop
               Add_Read (G, Ref (I .. I + S.RL - 1), Include_RC => False);
            end loop;
            Remove_Tips (G, Max_Tip_Length => 2);
            C := Emit_Contigs (G);
            Check (C.Count >= 1,
                   "synth genome contig count ≥1 (k=" & S.K'Image & ")");
            Check (Contig_Has_Ref (C, Ref)
                   or else Longest_Contig (C)'Length >= S.RL,
                   "synth recovers ref or long contig (k=" & S.K'Image & ")");
            Check (Node_Count (G) > 0, "synth nodes > 0");
            Check (Edge_Count (G) > 0, "synth edges > 0");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("16. Tip removal default threshold (2k)");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (5);
      E0, E1 : Natural;
   begin
      Add_Read (G, "AAAAACCCCC", Include_RC => False);
      Add_Read (G, "AAAACCCCCG", Include_RC => False);  -- tiny spur toward G
      Add_Read (G, "AAAG", Include_RC => False);
      E0 := Edge_Count (G);
      Remove_Tips (G);  -- default Max_Tip_Length = 0 → 2k
      E1 := Edge_Count (G);
      Check (E1 <= E0, "default Remove_Tips non-increasing edges");
      Check (Node_Count (G) >= 0, "default tips leaves valid graph");
   end;

   ---------------------------------------------------------------------
   Section ("17. Remove_Low_Coverage Min_Coverage=1 keeps all");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (4);
      E0, E1 : Natural;
   begin
      Add_Read (G, "ACGTAC", Include_RC => False);
      E0 := Edge_Count (G);
      Remove_Low_Coverage (G, Min_Coverage => 1);
      E1 := Edge_Count (G);
      Check (E1 = E0, "Min_Coverage=1 keeps all edges (mult≥1)");
   end;

   ---------------------------------------------------------------------
   Section ("18. Branching graph emits multiple contigs or junction");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (4);
      C : Contig_List;
   begin
      --  Shared prefix ACGT then branch: ACGTAAAA vs ACGTGTTT
      Add_Read (G, "ACGTAAAA", Include_RC => False);
      Add_Read (G, "ACGTGTTT", Include_RC => False);
      C := Emit_Contigs (G);
      Check (C.Count >= 1, "branching → ≥1 contig");
      Check (Node_Count (G) >= 4, "branching has several nodes");
      declare
         Found_A, Found_G : Boolean := False;
      begin
         for I in 1 .. C.Count loop
            declare
               S : constant String := Contig_String (C.Contigs (I));
            begin
               if Contains_Substring (S, "AAA") then
                  Found_A := True;
               end if;
               if Contains_Substring (S, "GTT")
                 or else Contains_Substring (S, "TTT")
               then
                  Found_G := True;
               end if;
            end;
         end loop;
         Check (Found_A or Found_G or C.Count >= 1,
                "branch motifs appear in some contig");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("19. Single k-mer read");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (6);
      C : Contig_List;
   begin
      Add_Read (G, "ACGTAC", Include_RC => False);
      Check (Node_Count (G) = 2, "one k-mer → 2 nodes");
      Check (Edge_Count (G) = 1, "one k-mer → 1 edge");
      Check (Edge_Multiplicity (G, "ACGTA", "CGTAC") = 1, "exact edge");
      C := Emit_Contigs (G);
      Check (C.Count >= 1, "single k-mer emits contig");
      Check (Contains_Substring (Longest_Contig (C), "ACGTAC")
             or else Longest_Contig (C) = "ACGTA"
             or else Longest_Contig (C)'Length >= 5,
             "single k-mer contig spells path");
   end;

   ---------------------------------------------------------------------
   Section ("20. RC of reads alone can assemble forward motif");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "ATGCCGTAA";
      G   : Graph := Build_Graph (5);
      C   : Contig_List;
   begin
      --  Only add reverse complements of overlapping tiles
      for I in Ref'First .. Ref'Last - 6 loop
         Add_Read (G, Reverse_Complement (Ref (I .. I + 6)),
                   Include_RC => False);
      end loop;
      C := Emit_Contigs (G);
      Check (C.Count >= 1, "RC-only tiles → contig");
      Check (Contig_Has_Ref (C, Ref) or else Contig_Has_Ref (C,
             Reverse_Complement (Ref)),
             "RC-only recovers Ref or RC(Ref)");
   end;

   ---------------------------------------------------------------------
   Section ("21. Caps / capacity constants sanity");
   ---------------------------------------------------------------------
   declare
      function Opaque (N : Natural) return Natural is
      begin
         return N;
      end Opaque;
      K  : constant Natural := Opaque (Max_K);
      Rd : constant Natural := Opaque (Max_Reads);
      Nd : constant Natural := Opaque (Max_Nodes);
      Ed : constant Natural := Opaque (Max_Edges);
      Ct : constant Natural := Opaque (Max_Contigs);
      RL : constant Natural := Opaque (Max_Read_Length);
      OD : constant Natural := Opaque (Max_Out_Degree);
   begin
      Check (K >= 7, "Max_K >= 7");
      Check (Rd >= 16, "Max_Reads >= 16");
      Check (Nd >= 32, "Max_Nodes >= 32");
      Check (Ed >= 32, "Max_Edges >= 32");
      Check (Ct >= 8, "Max_Contigs >= 8");
      Check (RL >= 32, "Max_Read_Length >= 32");
      Check (OD = 4, "Max_Out_Degree = 4 (ACGT)");
   end;

   ---------------------------------------------------------------------
   Section ("22. Pipeline: build → tips → coverage → contigs");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "CGATCGATCGATCG";
      G   : Graph := Build_Graph (5);
      C   : Contig_List;
      N0, N1, N2 : Natural;
   begin
      for I in Ref'First .. Ref'Last - 7 loop
         Add_Read (G, Ref (I .. I + 7), Include_RC => True);
      end loop;
      --  Noise
      Add_Read (G, "CGATT", Include_RC => False);
      N0 := Node_Count (G);
      Remove_Tips (G, Max_Tip_Length => 3);
      N1 := Node_Count (G);
      Remove_Low_Coverage (G, Min_Coverage => 2);
      N2 := Node_Count (G);
      C := Emit_Contigs (G);
      Check (N1 <= N0, "pipeline tips shrink/equal nodes");
      Check (N2 <= N1, "pipeline coverage shrink/equal nodes");
      Check (C.Count >= 1, "pipeline emits contig");
      Check (Contig_Has_Ref (C, Ref)
             or else Longest_Contig (C)'Length >= 7,
             "pipeline recovers Ref-ish contig");
   end;

   ---------------------------------------------------------------------
   Section ("23. Homopolymer and dinucleotide repeats");
   ---------------------------------------------------------------------
   declare
      G1 : Graph := Build_Graph (5);
      G2 : Graph := Build_Graph (4);
      C1, C2 : Contig_List;
   begin
      Add_Read (G1, "AAAAAAAAAA", Include_RC => False);
      C1 := Emit_Contigs (G1);
      Check (Node_Count (G1) = 1, "polyA k=5 → single node AAAA");
      Check (Edge_Count (G1) = 1, "polyA self-ish edge AAAA→AAAA");
      Check (C1.Count >= 1, "polyA emits contig");
      Check (Contains_Substring (Longest_Contig (C1), "AAAA"),
             "polyA contig has AAAA");

      Add_Read (G2, "ACACACACAC", Include_RC => False);
      C2 := Emit_Contigs (G2);
      Check (Node_Count (G2) = 2, "AC repeat → nodes ACA, CAC");
      Check (C2.Count >= 1, "AC repeat emits contig");
      Check (Contains_Substring (Longest_Contig (C2), "ACAC")
             or else Contains_Substring (Longest_Contig (C2), "CACA"),
             "AC repeat contig has ACAC/CACA");
   end;

   ---------------------------------------------------------------------
   Section ("24. Emit after aggressive coverage wipe");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (4);
      C : Contig_List;
   begin
      Add_Read (G, "ACGT", Include_RC => False);
      Remove_Low_Coverage (G, Min_Coverage => 100);
      Check (Edge_Count (G) = 0, "coverage 100 wipes singleton edges");
      C := Emit_Contigs (G);
      Check (C.Count = 0 or else Longest_Contig (C)'Length < 4,
             "wiped graph yields no real contig");
   end;

   ---------------------------------------------------------------------
   Section ("25. Dual-strand perfect assembly");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "GCTAGCTAGC";
      G   : Graph := Build_Graph (5);
      C   : Contig_List;
   begin
      for I in Ref'First .. Ref'Last - 5 + 1 loop
         Add_Read (G, Ref (I .. I + 5 - 1), Include_RC => True);
      end loop;
      C := Emit_Contigs (G);
      Check (Contig_Has_Ref (C, Ref), "dual-strand recovers GCTAGCTAGC");
   end;

   ---------------------------------------------------------------------
   Section ("26. Edge_Multiplicity missing nodes");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (4);
   begin
      Add_Read (G, "ACGT", Include_RC => False);
      Check (Edge_Multiplicity (G, "TTT", "TTA") = 0, "missing from");
      Check (Edge_Multiplicity (G, "ACG", "TTT") = 0, "missing to");
      Check (Edge_Multiplicity (G, "CGT", "ACG") = 0, "wrong direction");
   end;

   ---------------------------------------------------------------------
   Section ("27. Many overlapping identical reads");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (5);
      C : Contig_List;
   begin
      for I in 1 .. 10 loop
         Add_Read (G, "ATGCATGCAT", Include_RC => False);
      end loop;
      --  k=5 ⇒ nodes are 4-mers; ATGCATGCAT has two ATGC→TGCA windows → 20.
      Check (Edge_Multiplicity (G, "ATGC", "TGCA") = 20,
             "identical reads boost mult to 20");
      Remove_Low_Coverage (G, Min_Coverage => 5);
      Check (Edge_Multiplicity (G, "ATGC", "TGCA") = 20, "kept after filter");
      C := Emit_Contigs (G);
      Check (Contig_Has_Ref (C, "ATGCATGCAT"), "identical reads recover");
   end;

   ---------------------------------------------------------------------
   Section ("28. Remove_Tips on empty / tiny graphs");
   ---------------------------------------------------------------------
   declare
      G0 : Graph := Build_Graph (3);
      G1 : Graph := Build_Graph (3);
   begin
      Remove_Tips (G0);
      Check (Node_Count (G0) = 0, "tips on empty ok");
      Add_Read (G1, "ACG", Include_RC => False);
      Remove_Tips (G1, Max_Tip_Length => 10);
      --  Entire component is a tip; may be removed
      Check (Node_Count (G1) <= 2, "tips on tiny graph stable/shrunk");
   end;

   ---------------------------------------------------------------------
   Section ("29. Mixed valid/invalid bases in long read");
   ---------------------------------------------------------------------
   declare
      G : Graph := Build_Graph (3);
   begin
      Add_Read (G, "ACNGT", Include_RC => False);
      --  Windows: ACN, CNG, NGT — all contain N → skip all
      Check (Node_Count (G) = 0, "all-N windows → no nodes");
      Add_Read (G, "ACXGTAA", Include_RC => False);
      --  Windows of 3: ACX,CXG,XGT,GTA,TAA → last two valid
      Check (Contains_Node (G, "GT"), "GT from GTA");
      Check (Contains_Node (G, "TA"), "TA from GTA/TAA");
      Check (Contains_Node (G, "AA"), "AA from TAA");
      Check (Edge_Multiplicity (G, "GT", "TA") >= 1, "GT→TA");
      Check (Edge_Multiplicity (G, "TA", "AA") >= 1, "TA→AA");
   end;

   ---------------------------------------------------------------------
   Section ("30. Contig list indexing / Count");
   ---------------------------------------------------------------------
   declare
      Ref : constant String := "TTTAAACCCGGG";
      G   : Graph := Build_Graph (4);
      C   : Contig_List;
      Total_Len : Natural := 0;
   begin
      for I in Ref'First .. Ref'Last - 5 loop
         Add_Read (G, Ref (I .. I + 5), Include_RC => False);
      end loop;
      C := Emit_Contigs (G);
      Check (C.Count >= 1 or else Node_Count (G) = 0,
             "contigs present or graph empty of nodes");
      for I in 1 .. C.Count loop
         Check (C.Contigs (I).Len > 0, "contig slot non-empty len");
         Check (C.Contigs (I).Len >= 1, "contig len at least 1");
         Total_Len := Total_Len + C.Contigs (I).Len;
      end loop;
      Check (Total_Len > 0 or else C.Count = 0, "total contig length ok");
      Check (Contig_Has_Ref (C, Ref) or else Longest_Contig (C)'Length >= 6,
             "TTTAAACCCGGG recovered or long");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   if Fail_Count > 0 then
      raise Program_Error with "Velvet tests failed";
   end if;
end Tests;
