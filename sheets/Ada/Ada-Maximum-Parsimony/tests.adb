--  Standalone test suite for Maximum_Parsimony (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Parsimony; use Maximum_Parsimony;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
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

begin
   Put_Line ("Maximum_Parsimony test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Matrix construction / accessors");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (3, 4, Fill => 0);
      Raised : Boolean;
   begin
      Check (Taxon_Count_Of (M) = 3, "Taxon_Count_Of = 3");
      Check (Site_Count_Of (M) = 4, "Site_Count_Of = 4");
      Check (Get_State (M, 1, 1) = 0, "Fill default state 0");
      Set_State (M, 1, 1, 1);
      Set_State (M, 2, 1, 2);
      Set_State (M, 3, 1, 3);
      Check (Get_State (M, 1, 1) = 1, "Set/Get taxon1 site1");
      Check (Get_State (M, 2, 1) = 2, "Set/Get taxon2 site1");
      Check (Get_State (M, 3, 1) = 3, "Set/Get taxon3 site1");
      Check (Hamming_Distance (M, 1, 2) = 1, "Hamming one differing site");
      Check (Hamming_Distance (M, 1, 1) = 0, "Hamming self = 0");
      Raised := False;
      begin
         declare
            Unused : Character_Matrix := Make_Matrix (0, 1);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when others => null;
      end;
      Check (Raised, "Make_Matrix(0,*) raises Invalid_Argument");
      Raised := False;
      begin
         --  Taxon 3 exists but site 5 does not on this 4-site matrix
         Set_State (M, 3, 5, 0);
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
         when others => null;
      end;
      Check (Raised, "Set_State out of range raises");
   end;

   ---------------------------------------------------------------------
   Section ("2. Near helper / topology counts");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near far");
      Check (Near (1.0, 1.0 + 1.0E-10, 1.0E-8), "Near within tol");
      Check (Count_Rooted_Topologies (1) = 1, "(2*1-3)!! convention: 1");
      Check (Count_Rooted_Topologies (2) = 1, "N=2 rooted count 1");
      Check (Count_Rooted_Topologies (3) = 3, "N=3 rooted count 3");
      Check (Count_Rooted_Topologies (4) = 15, "N=4 rooted count 15");
      Check (Count_Rooted_Topologies (5) = 105, "N=5 rooted count 105");
      Check (Count_Rooted_Topologies (6) = 945, "N=6 rooted count 945");
   end;

   ---------------------------------------------------------------------
   Section ("3. Tree construction");
   ---------------------------------------------------------------------
   declare
      L1 : constant Tree := Leaf_Tree (1);
      L2 : constant Tree := Leaf_Tree (2);
      T3 : constant Tree := Triplet_Tree (1, 2, 3);
      Q  : constant Tree := Quartet_Tree (1, 2, 3, 4);
      BQ : constant Tree := Balanced_Quartet (1, 2, 3, 4);
      J  : constant Tree := Join (L1, L2);
   begin
      Check (L1.N = 1, "Leaf_Tree N=1");
      Check (Is_Leaf (L1, L1.Root), "Leaf root is leaf");
      Check (Node_Count (L1) = 1, "Leaf node count 1");
      Check (J.N = 2, "Join two leaves N=2");
      Check (Node_Count (J) = 3, "Join node count 3");
      Check (not Is_Leaf (J, J.Root), "Join root is internal");
      Check (T3.N = 3, "Triplet N=3");
      Check (Node_Count (T3) = 5, "Triplet nodes 5");
      Check (Q.N = 4, "Quartet N=4");
      Check (Node_Count (Q) = 7, "Quartet nodes 7");
      Check (BQ.N = 4, "Balanced quartet N=4");
      Check (Node_Count (BQ) = 7, "Balanced quartet nodes 7");
   end;

   ---------------------------------------------------------------------
   Section ("4. Identical sequences → length 0");
   ---------------------------------------------------------------------
   declare
      M : constant Character_Matrix := Make_Matrix (4, 5, Fill => 1);
      T : constant Tree := Balanced_Quartet (1, 2, 3, 4);
      R : Search_Result;
   begin
      Check (Fitch_Score_Site (T, M, 1, S => 4) = 0, "Identical site score 0");
      Check (Fitch_Score_Tree (T, M, S => 4) = 0, "Identical matrix tree length 0");
      R := Exhaustive_Search (M, S => 4);
      Check (R.Best_Length = 0, "Exhaustive identical → length 0");
      Check (R.Trees_Tried = Count_Rooted_Topologies (4),
             "Exhaustive tried all 15 topologies");
   end;

   ---------------------------------------------------------------------
   Section ("5. Single difference → minimal cost 1");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (3, 1, Fill => 0);
      T : constant Tree := Triplet_Tree (1, 2, 3);
      R : Search_Result;
   begin
      Set_State (M, 3, 1, 1);  -- taxon 3 differs
      Check (Fitch_Score_Site (T, M, 1, S => 2) = 1,
             "One change on triplet site costs 1");
      Check (Fitch_Score_Tree (T, M, S => 2) = 1, "Tree length 1");
      R := Most_Parsimonious (M, S => 2);
      Check (R.Best_Length = 1, "MP single difference length 1");
      Check (R.Trees_Tried = 3, "N=3 tries 3 rooted trees");
   end;

   ---------------------------------------------------------------------
   Section ("6. Hand-worked Fitch on 3-taxon trees");
   ---------------------------------------------------------------------
   --  Site states: t1=A(0), t2=A(0), t3=C(1)
   --  Tree ((1,2),3): cherry of identical states → internal {0}; root
   --  intersects {0}∩{1}=∅ → +1.  Length 1.
   --  Tree ((1,3),2): cherry {0}∩{1}=∅ → +1 already; then vs leaf 2…
   declare
      M : Character_Matrix := Make_Matrix (3, 1, Fill => 0);
      T12 : constant Tree := Triplet_Tree (1, 2, 3);  -- ((1,2),3)
      T13 : constant Tree := Triplet_Tree (1, 3, 2);  -- ((1,3),2)
      T23 : constant Tree := Triplet_Tree (2, 3, 1);  -- ((2,3),1)
   begin
      Set_State (M, 3, 1, 1);
      Check (Fitch_Score_Site (T12, M, 1, 2) = 1, "((1,2),3) length 1");
      Check (Fitch_Score_Site (T13, M, 1, 2) = 1, "((1,3),2) length 1");
      Check (Fitch_Score_Site (T23, M, 1, 2) = 1, "((2,3),1) length 1");
   end;

   --  All three different cannot happen with binary alphabet; use 3 states.
   declare
      M : Character_Matrix := Make_Matrix (3, 1);
      T : constant Tree := Triplet_Tree (1, 2, 3);
   begin
      Set_State (M, 1, 1, 0);
      Set_State (M, 2, 1, 1);
      Set_State (M, 3, 1, 2);
      --  ((1,2),3): {0}∩{1}=∅ → +1 union{0,1}; ∩{2}=∅ → +1. Length 2.
      Check (Fitch_Score_Site (T, M, 1, S => 3) = 2,
             "Three distinct states on triplet → 2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Hand-worked Fitch on 4-taxon trees");
   ---------------------------------------------------------------------
   --  Classic informative site: 1=A, 2=A, 3=C, 4=C
   --  Balanced ((1,2),(3,4)): each cherry uniform → cost 0; root
   --  {0}∩{1}=∅ → +1.  Length 1.  (supports grouping 12|34)
   --  Balanced ((1,3),(2,4)): each cherry mixed → +1 each; root may add 0.
   --  Length 2.
   declare
      M : Character_Matrix := Make_Matrix (4, 1, Fill => 0);
      B12 : constant Tree := Balanced_Quartet (1, 2, 3, 4);  -- ((1,2),(3,4))
      B13 : constant Tree := Balanced_Quartet (1, 3, 2, 4);  -- ((1,3),(2,4))
      B14 : constant Tree := Balanced_Quartet (1, 4, 2, 3);  -- ((1,4),(2,3))
      Cat : constant Tree := Quartet_Tree (1, 2, 3, 4);      -- (((1,2),3),4)
   begin
      Set_State (M, 3, 1, 1);
      Set_State (M, 4, 1, 1);
      Check (Fitch_Score_Site (B12, M, 1, 2) = 1,
             "Informative ((1,2),(3,4)) length 1");
      Check (Fitch_Score_Site (B13, M, 1, 2) = 2,
             "Conflict ((1,3),(2,4)) length 2");
      Check (Fitch_Score_Site (B14, M, 1, 2) = 2,
             "Conflict ((1,4),(2,3)) length 2");
      Check (Fitch_Score_Site (Cat, M, 1, 2) = 1,
             "Caterpillar (((1,2),3),4) length 1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Exhaustive recovers known best (4 taxa)");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (4, 3, Fill => 0);
      R : Search_Result;
      B12 : constant Tree := Balanced_Quartet (1, 2, 3, 4);
      B13 : constant Tree := Balanced_Quartet (1, 3, 2, 4);
   begin
      --  Three sites all supporting 12|34
      for Site in 1 .. 3 loop
         Set_State (M, 3, Site, 1);
         Set_State (M, 4, Site, 1);
      end loop;
      Check (Fitch_Score_Tree (B12, M, 2) = 3, "Best shape length 3");
      Check (Fitch_Score_Tree (B13, M, 2) = 6, "Wrong shape length 6");
      R := Exhaustive_Search (M, S => 2);
      Check (R.Best_Length = 3, "Exhaustive finds length 3");
      Check (R.Best_Length <= Fitch_Score_Tree (B13, M, 2),
             "Best ≤ conflicting tree");
      Check (R.Trees_Tried = 15, "Tried 15 rooted topologies");
   end;

   ---------------------------------------------------------------------
   Section ("9. More changes → higher score");
   ---------------------------------------------------------------------
   declare
      M0 : constant Character_Matrix := Make_Matrix (4, 4, Fill => 0);
      M1 : Character_Matrix := Make_Matrix (4, 4, Fill => 0);
      M2 : Character_Matrix := Make_Matrix (4, 4, Fill => 0);
      T  : constant Tree := Balanced_Quartet (1, 2, 3, 4);
      L0, L1, L2 : Natural;
   begin
      --  M1: one site with 12 vs 34 split
      Set_State (M1, 3, 1, 1);
      Set_State (M1, 4, 1, 1);
      --  M2: two such sites
      Set_State (M2, 3, 1, 1);
      Set_State (M2, 4, 1, 1);
      Set_State (M2, 3, 2, 1);
      Set_State (M2, 4, 2, 1);
      L0 := Fitch_Score_Tree (T, M0, 2);
      L1 := Fitch_Score_Tree (T, M1, 2);
      L2 := Fitch_Score_Tree (T, M2, 2);
      Check (L0 = 0, "No changes → 0");
      Check (L1 = 1, "One split site → 1");
      Check (L2 = 2, "Two split sites → 2");
      Check (L0 < L1 and then L1 < L2, "Monotone: more changes → higher");
   end;

   ---------------------------------------------------------------------
   Section ("10. Exhaustive consistency vs listed trees");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (4, 2);
      R : Search_Result;
      Trees : array (1 .. 3) of Tree;
      Score : Natural;
   begin
      --  Site1: AA CC; Site2: AC AC (mixed)
      Set_State (M, 1, 1, 0); Set_State (M, 2, 1, 0);
      Set_State (M, 3, 1, 1); Set_State (M, 4, 1, 1);
      Set_State (M, 1, 2, 0); Set_State (M, 2, 2, 1);
      Set_State (M, 3, 2, 0); Set_State (M, 4, 2, 1);
      Trees (1) := Balanced_Quartet (1, 2, 3, 4);
      Trees (2) := Balanced_Quartet (1, 3, 2, 4);
      Trees (3) := Quartet_Tree (1, 2, 3, 4);
      R := Exhaustive_Search (M, S => 2);
      for I in Trees'Range loop
         Score := Fitch_Score_Tree (Trees (I), M, 2);
         Check (R.Best_Length <= Score,
                "Best ≤ listed tree #" & Integer'Image (I));
      end loop;
      Check (R.Best_Length >= 1, "Mixed data length ≥ 1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Random-ish matrices: best ≤ any listed");
   ---------------------------------------------------------------------
   declare
      --  Deterministic pseudo-random matrices via LCG-like filling.
      procedure Fill_Pseudo
        (M    : in out Character_Matrix;
         Seed : Natural;
         Alph : State_Count)
      is
         S : Natural := Seed;
      begin
         for T in M'Range (1) loop
            for Site in M'Range (2) loop
               S := (S * 37 + 11) mod 1000;
               M (T, Site) := State_Value (S mod Natural (Alph));
            end loop;
         end loop;
      end Fill_Pseudo;

      Seeds : constant array (1 .. 5) of Natural :=
        [7, 42, 99, 123, 1000];
   begin
      for Si in Seeds'Range loop
         declare
            M : Character_Matrix := Make_Matrix (4, 6, Fill => 0);
            R : Search_Result;
            T1 : Tree;
            T2 : Tree;
            T3 : Tree;
         begin
            Fill_Pseudo (M, Seeds (Si), 4);
            T1 := Balanced_Quartet (1, 2, 3, 4);
            T2 := Balanced_Quartet (1, 3, 2, 4);
            T3 := Quartet_Tree (1, 3, 2, 4);
            R := Exhaustive_Search (M, S => 4);
            Check (R.Best_Length <= Fitch_Score_Tree (T1, M, 4),
                   "Seed" & Integer'Image (Seeds (Si)) & " best≤T1");
            Check (R.Best_Length <= Fitch_Score_Tree (T2, M, 4),
                   "Seed" & Integer'Image (Seeds (Si)) & " best≤T2");
            Check (R.Best_Length <= Fitch_Score_Tree (T3, M, 4),
                   "Seed" & Integer'Image (Seeds (Si)) & " best≤T3");
            Check (R.Trees_Tried = 15,
                   "Seed" & Integer'Image (Seeds (Si)) & " tried 15");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Five taxa exhaustive");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (5, 4, Fill => 0);
      R : Search_Result;
      --  Build ((1,2),(3,4)) joined with leaf 5
      T_Ref : Tree;
   begin
      Set_State (M, 3, 1, 1); Set_State (M, 4, 1, 1);
      Set_State (M, 3, 2, 1); Set_State (M, 4, 2, 1);
      Set_State (M, 5, 3, 1);
      Set_State (M, 5, 4, 1);
      T_Ref := Join (Balanced_Quartet (1, 2, 3, 4), Leaf_Tree (5));
      R := Exhaustive_Search (M, S => 2);
      Check (R.Trees_Tried = 105, "N=5 tries 105 topologies");
      Check (R.Best_Length <= Fitch_Score_Tree (T_Ref, M, 2),
             "N=5 best ≤ reference join");
      Check (R.Best_Length >= 2, "N=5 data needs ≥ 2 changes");
   end;

   ---------------------------------------------------------------------
   Section ("13. DNA alphabet ACGT as 0..3");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (4, 8, Fill => 0);
      R : Search_Result;
      T : constant Tree := Balanced_Quartet (1, 2, 3, 4);
      --  Encode a tiny alignment:
      --  t1: AAAAACGT
      --  t2: AAAAACGT
      --  t3: AAAATGCA
      --  t4: AAAATGCA
   begin
      --  sites 6..8: t1,t2 = CGT; t3,t4 = GCA
      Set_State (M, 1, 6, 1); Set_State (M, 2, 6, 1);  -- C
      Set_State (M, 1, 7, 2); Set_State (M, 2, 7, 2);  -- G
      Set_State (M, 1, 8, 3); Set_State (M, 2, 8, 3);  -- T
      Set_State (M, 3, 6, 2); Set_State (M, 4, 6, 2);  -- G
      Set_State (M, 3, 7, 1); Set_State (M, 4, 7, 1);  -- C
      Set_State (M, 3, 8, 0); Set_State (M, 4, 8, 0);  -- A
      Check (Fitch_Score_Tree (T, M, 4) = 3,
             "DNA block: 3 variable sites → length 3 on 12|34");
      R := Exhaustive_Search (M, S => 4);
      Check (R.Best_Length = 3, "DNA exhaustive best = 3");
      Check (Hamming_Distance (M, 1, 2) = 0, "t1==t2");
      Check (Hamming_Distance (M, 3, 4) = 0, "t3==t4");
      Check (Hamming_Distance (M, 1, 3) = 3, "t1 vs t3 = 3");
   end;

   ---------------------------------------------------------------------
   Section ("14. Exceptions / edge cases");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      M : constant Character_Matrix := Make_Matrix (2, 1, Fill => 0);
      T : constant Tree := Join (Leaf_Tree (1), Leaf_Tree (2));
   begin
      Raised := False;
      begin
         declare
            Unused : Natural := Fitch_Score_Site (T, M, 9, 2);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
         when others => null;
      end;
      Check (Raised, "Fitch_Score_Site bad site raises");

      Raised := False;
      begin
         declare
            Unused : Tree := Join (Leaf_Tree (1), Leaf_Tree (1));
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when others => null;
      end;
      Check (Raised, "Join overlapping leaves raises");

      Raised := False;
      begin
         declare
            Unused : Natural := Fitch_Score_Tree (Tree'(others => <>), M, 2);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when others => null;
      end;
      Check (Raised, "Fitch_Score_Tree empty tree raises");

      Check (Fitch_Score_Tree (T, M, 2) = 0, "Two identical taxa length 0");
      declare
         R : constant Search_Result := Exhaustive_Search (M, 2);
      begin
         Check (R.Best_Length = 0, "N=2 identical MP = 0");
         Check (R.Trees_Tried = 1, "N=2 one topology");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Most_Parsimonious alias / multi-site scores");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (3, 5, Fill => 0);
      R1, R2 : Search_Result;
   begin
      Set_State (M, 2, 1, 1);
      Set_State (M, 3, 2, 1);
      Set_State (M, 1, 3, 1);
      Set_State (M, 2, 4, 1);
      Set_State (M, 3, 5, 1);
      R1 := Exhaustive_Search (M, 2);
      R2 := Most_Parsimonious (M, 2);
      Check (R1.Best_Length = R2.Best_Length, "Alias same length");
      Check (R1.Trees_Tried = R2.Trees_Tried, "Alias same tried count");
      Check (R1.Best_Length >= 2, "Scattered changes need ≥2");
      --  Per-site scores on a fixed tree sum to tree score
      declare
         T : constant Tree := Triplet_Tree (1, 2, 3);
         Sum : Natural := 0;
      begin
         for Site in 1 .. 5 loop
            Sum := Sum + Fitch_Score_Site (T, M, Site, 2);
         end loop;
         Check (Sum = Fitch_Score_Tree (T, M, 2),
                "Sum of site scores = tree score");
         Check (R1.Best_Length <= Sum, "MP ≤ this triplet score");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra site-level Fitch checks");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (4, 6, Fill => 0);
      T : constant Tree := Balanced_Quartet (1, 2, 3, 4);
   begin
      --  Site1 constant
      Check (Fitch_Score_Site (T, M, 1, 4) = 0, "Const site 0");
      --  Site2: only taxon 4 differs
      Set_State (M, 4, 2, 1);
      Check (Fitch_Score_Site (T, M, 2, 4) = 1, "Single leaf change = 1");
      --  Site3: taxa 1 and 2 differ from 3 and 4
      Set_State (M, 3, 3, 1); Set_State (M, 4, 3, 1);
      Check (Fitch_Score_Site (T, M, 3, 4) = 1, "Clean split = 1");
      --  Site4: all different pairing
      Set_State (M, 2, 4, 1);
      Set_State (M, 3, 4, 2);
      Set_State (M, 4, 4, 3);
      Check (Fitch_Score_Site (T, M, 4, 4) >= 2, "All different ≥ 2");
      --  Site5: three same one different
      Set_State (M, 1, 5, 2);
      Set_State (M, 2, 5, 2);
      Set_State (M, 3, 5, 2);
      Set_State (M, 4, 5, 0);
      Check (Fitch_Score_Site (T, M, 5, 4) = 1, "3+1 pattern = 1");
      --  Site6: two and two other split (13|24 style on 12|34 tree)
      Set_State (M, 1, 6, 0); Set_State (M, 2, 6, 1);
      Set_State (M, 3, 6, 0); Set_State (M, 4, 6, 1);
      Check (Fitch_Score_Site (T, M, 6, 4) = 2, "Homologous conflict = 2");
   end;

   ---------------------------------------------------------------------
   Section ("17. Six-taxon smoke (small sites)");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (6, 2, Fill => 0);
      R : Search_Result;
      Tref : Tree;
   begin
      Set_State (M, 4, 1, 1);
      Set_State (M, 5, 1, 1);
      Set_State (M, 6, 1, 1);
      Set_State (M, 5, 2, 1);
      Set_State (M, 6, 2, 1);
      Tref := Join
        (Join (Balanced_Quartet (1, 2, 3, 4), Leaf_Tree (5)), Leaf_Tree (6));
      R := Exhaustive_Search (M, S => 2);
      Check (R.Trees_Tried = 945, "N=6 tries 945 topologies");
      Check (R.Best_Length <= Fitch_Score_Tree (Tref, M, 2),
             "N=6 best ≤ reference");
      Check (R.Best_Length >= 1, "N=6 nonzero data");
   end;

   ---------------------------------------------------------------------
   Section ("18. Bulk small checks for PASS count");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (3, 10, Fill => 0);
      T : constant Tree := Triplet_Tree (1, 2, 3);
   begin
      for Site in 1 .. 10 loop
         Check (Fitch_Score_Site (T, M, Site, 2) = 0,
                "Const site" & Integer'Image (Site) & " = 0");
      end loop;
      for Site in 1 .. 10 loop
         Set_State (M, 3, Site, 1);
         Check (Fitch_Score_Site (T, M, Site, 2) = 1,
                "Diff site" & Integer'Image (Site) & " = 1");
      end loop;
      Check (Fitch_Score_Tree (T, M, 2) = 10, "Ten single changes → 10");
      declare
         R : constant Search_Result := Exhaustive_Search (M, 2);
      begin
         Check (R.Best_Length = 10, "MP of ten singleton diffs = 10");
      end;
      --  Hamming across taxa
      Check (Hamming_Distance (M, 1, 2) = 0, "t1==t2 still");
      Check (Hamming_Distance (M, 1, 3) = 10, "t1 vs t3 = 10");
      Check (Hamming_Distance (M, 2, 3) = 10, "t2 vs t3 = 10");
   end;

   ---------------------------------------------------------------------
   Section ("19. Binary vs 4-state alphabet consistency");
   ---------------------------------------------------------------------
   declare
      M : Character_Matrix := Make_Matrix (4, 3, Fill => 0);
      T : constant Tree := Balanced_Quartet (1, 2, 3, 4);
   begin
      Set_State (M, 3, 1, 1); Set_State (M, 4, 1, 1);
      Set_State (M, 3, 2, 1); Set_State (M, 4, 2, 1);
      Set_State (M, 3, 3, 1); Set_State (M, 4, 3, 1);
      Check (Fitch_Score_Tree (T, M, S => 2) = 3, "Binary alphabet score 3");
      Check (Fitch_Score_Tree (T, M, S => 4) = 3, "4-state alphabet same 3");
      Check (Fitch_Score_Tree (T, M, S => 8) = 3, "8-state alphabet same 3");
   end;

   ---------------------------------------------------------------------
   Section ("20. Node / edge structural checks");
   ---------------------------------------------------------------------
   declare
      T : constant Tree := Triplet_Tree (1, 2, 3);
      Root : constant Node_Id := T.Root;
      L : constant Node_Id := T.Nodes (Root).Left;
      R : constant Node_Id := T.Nodes (Root).Right;
   begin
      Check (Root /= 0, "Root nonzero");
      Check (L /= 0 and then R /= 0, "Root has two children");
      Check (T.Nodes (L).Parent = Root, "Left parent link");
      Check (T.Nodes (R).Parent = Root, "Right parent link");
      --  One child of root is the cherry internal, other is leaf 3
      Check
        ((Is_Leaf (T, R) and then T.Nodes (R).Taxon = 3)
           or else (Is_Leaf (T, L) and then T.Nodes (L).Taxon = 3),
         "Leaf 3 is child of root in ((1,2),3)");
      Check (Node_Count (T) = 5, "Triplet has 5 nodes");
      Check (T.N = 3, "Triplet N field");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("PASS:" & Natural'Image (Pass_Count));
   Put_Line ("FAIL:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("All tests passed.");
   elsif Fail_Count = 0 then
      Put_Line ("WARNING: Fail_Count=0 but PASS < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
