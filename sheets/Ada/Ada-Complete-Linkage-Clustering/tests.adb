--  Standalone test suite for Complete_Linkage_Clustering (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Complete_Linkage_Clustering; use Complete_Linkage_Clustering;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  Same-partition check (labels may be permuted).
   function Same_Partition (A, B : Labels) return Boolean is
      N : constant Natural := A'Length;
      Map : array (0 .. Max_Points) of Natural := [others => 0];
      Inv : array (0 .. Max_Points) of Natural := [others => 0];
   begin
      if B'Length /= N then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            La : constant Natural := A (A'First + (I - 1));
            Lb : constant Natural := B (B'First + (I - 1));
         begin
            if La = 0 or else Lb = 0 then
               return False;
            end if;
            if Map (La) = 0 then
               if Inv (Lb) /= 0 then
                  return False;
               end if;
               Map (La) := Lb;
               Inv (Lb) := La;
            elsif Map (La) /= Lb then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Same_Partition;

begin
   Put_Line ("Complete_Linkage_Clustering test suite");
   Put_Line ("======================================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   end;

   ---------------------------------------------------------------------
   Section ("2. Euclidean_Distance");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [0.0, 0.0];
      B : constant Point := [3.0, 4.0];
      C : constant Point := [1.0, 1.0, 1.0];
      D : constant Point := [1.0, 1.0, 1.0];
   begin
      Check (Approx (Euclidean_Distance (A, B), 5.0), "3-4-5 triangle = 5");
      Check (Approx (Euclidean_Distance (A, A), 0.0), "identical → 0");
      Check (Approx (Euclidean_Distance (C, D), 0.0), "identical 3-D → 0");
      Check (Approx (Euclidean_Distance ([0.0], [2.0]), 2.0), "1-D abs");
      Check (Euclidean_Distance (A, B) > 0.0, "positive for distinct");
   end;

   ---------------------------------------------------------------------
   Section ("3. Build_Distance_Matrix");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [3.0, 4.0],
         [0.0, 0.0]];
      Dist : constant Distance_Matrix := Build_Distance_Matrix (Data);
   begin
      Check (Dist'Length (1) = 3, "matrix rows = 3");
      Check (Dist'Length (2) = 3, "matrix cols = 3");
      Check (Approx (Dist (1, 1), 0.0), "diag (1,1)=0");
      Check (Approx (Dist (2, 2), 0.0), "diag (2,2)=0");
      Check (Approx (Dist (1, 2), 5.0), "d(1,2)=5");
      Check (Approx (Dist (2, 1), 5.0), "symmetric d(2,1)=5");
      Check (Approx (Dist (1, 3), 0.0), "identical points d=0");
      Check (Approx (Dist (3, 2), 5.0), "d(3,2)=5");
   end;

   ---------------------------------------------------------------------
   Section ("4. Complete_Linkage_Distance (max pairwise)");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 4, 1 .. 4) :=
        [[0.0, 2.0, 9.0, 8.0],
         [2.0, 0.0, 7.0, 6.0],
         [9.0, 7.0, 0.0, 1.0],
         [8.0, 6.0, 1.0, 0.0]];
      --  Cluster {1,2} vs {3,4}: max(9,8,7,6) = 9
      XA : constant Labels := [1, 2];
      XB : constant Labels := [3, 4];
      XC : constant Labels := [1];
      XD : constant Labels := [2];
   begin
      Check (Approx (Complete_Linkage_Distance (Dist, XA, XB), 9.0),
             "D({1,2},{3,4})=9");
      Check (Approx (Cluster_Distance (Dist, XA, XB), 9.0),
             "Cluster_Distance alias = 9");
      Check (Approx (Complete_Linkage_Distance (Dist, XC, XD), 2.0),
             "D({1},{2})=2");
      Check (Approx (Complete_Linkage_Distance (Dist, XA, XC), 2.0),
             "D({1,2},{1})=2 (max to self member)");
      Check (Approx (Complete_Linkage_Distance (Dist, [3], [4]), 1.0),
             "D({3},{4})=1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia bacteria 5×5 complete-linkage example");
   ---------------------------------------------------------------------
   --  a b c d e with JC69 distances (Wikipedia complete-linkage working
   --  example).  Merge: a+b @17; (ab)+e @23; c+d @28; ((ab)e)+(cd) @43.
   declare
      Dist : constant Distance_Matrix (1 .. 5, 1 .. 5) :=
        [[0.0, 17.0, 21.0, 31.0, 23.0],
         [17.0, 0.0, 30.0, 34.0, 21.0],
         [21.0, 30.0, 0.0, 28.0, 39.0],
         [31.0, 34.0, 28.0, 0.0, 43.0],
         [23.0, 21.0, 39.0, 43.0, 0.0]];
      Tree : constant Dendrogram := Run_Complete_Linkage (Dist);
   begin
      Check (Tree'Length = 4, "hierarchy size N-1 = 4");

      --  Merge 1: a+b at 17
      Check (Tree (1).Left = 1, "M1 Left = a (1)");
      Check (Tree (1).Right = 2, "M1 Right = b (2)");
      Check (Approx (Tree (1).Height, 17.0), "M1 Height = 17");
      Check (Tree (1).Size = 2, "M1 Size = 2");
      Check (Approx (Merge_Height (Tree, 1), 17.0), "Merge_Height(1)=17");

      --  After ab: distances to c,d,e = max → 30, 34, 23
      declare
         XA : constant Labels := [1, 2];
      begin
         Check (Approx (Complete_Linkage_Distance (Dist, XA, [3]), 30.0),
                "D(ab,c)=30 after first merge");
         Check (Approx (Complete_Linkage_Distance (Dist, XA, [4]), 34.0),
                "D(ab,d)=34 after first merge");
         Check (Approx (Complete_Linkage_Distance (Dist, XA, [5]), 23.0),
                "D(ab,e)=23 after first merge");
      end;

      --  Merge 2: (ab)=6 with e=5 at 23
      Check (Tree (2).Left = 6, "M2 Left = cluster (ab)=6");
      Check (Tree (2).Right = 5, "M2 Right = e (5)");
      Check (Approx (Tree (2).Height, 23.0), "M2 Height = 23");
      Check (Tree (2).Size = 3, "M2 Size = 3");

      --  Merge 3: c=3 with d=4 at 28
      Check (Tree (3).Left = 3, "M3 Left = c (3)");
      Check (Tree (3).Right = 4, "M3 Right = d (4)");
      Check (Approx (Tree (3).Height, 28.0), "M3 Height = 28");
      Check (Tree (3).Size = 2, "M3 Size = 2");

      --  Merge 4: ((ab)e)=7 with (cd)=8 at 43
      Check (Tree (4).Left = 7, "M4 Left = cluster ((ab)e)=7");
      Check (Tree (4).Right = 8, "M4 Right = cluster (cd)=8");
      Check (Approx (Tree (4).Height, 43.0), "M4 Height = 43");
      Check (Tree (4).Size = 5, "M4 Size = 5");

      Check (Approx (Merge_Height (Tree, 4), 43.0), "Merge_Height(4)=43");
      Check (Tree (1).Height <= Tree (2).Height, "heights nondecreasing 1≤2");
      Check (Tree (2).Height <= Tree (3).Height, "heights nondecreasing 2≤3");
      Check (Tree (3).Height <= Tree (4).Height, "heights nondecreasing 3≤4");
   end;

   ---------------------------------------------------------------------
   Section ("6. Cut / Labels_At_Height on Wikipedia tree");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 5, 1 .. 5) :=
        [[0.0, 17.0, 21.0, 31.0, 23.0],
         [17.0, 0.0, 30.0, 34.0, 21.0],
         [21.0, 30.0, 0.0, 28.0, 39.0],
         [31.0, 34.0, 28.0, 0.0, 43.0],
         [23.0, 21.0, 39.0, 43.0, 0.0]];
      Tree : constant Dendrogram := Run_Complete_Linkage (Dist);
      L5 : constant Labels := Cut_Dendrogram (Tree, 5, 5);
      L4 : constant Labels := Cut_Dendrogram (Tree, 5, 4);
      L3 : constant Labels := Cut_Dendrogram (Tree, 5, 3);
      L2 : constant Labels := Cut_Dendrogram (Tree, 5, 2);
      L1 : constant Labels := Cut_Dendrogram (Tree, 5, 1);
      H0  : constant Labels := Labels_At_Height (Tree, 5, 0.0);
      H17 : constant Labels := Labels_At_Height (Tree, 5, 17.0);
      H23 : constant Labels := Labels_At_Height (Tree, 5, 23.0);
      H28 : constant Labels := Labels_At_Height (Tree, 5, 28.0);
      H43 : constant Labels := Labels_At_Height (Tree, 5, 43.0);
      P23 : constant Parameters := (Cut_Height => 23.0);
      HP  : constant Labels := Labels_At_Height (Tree, 5, P23);
   begin
      Check (L5'Length = 5, "Cut K=5 length");
      Check (L5 (1) /= L5 (2) and then L5 (1) /= L5 (3)
             and then L5 (1) /= L5 (4) and then L5 (1) /= L5 (5)
             and then L5 (2) /= L5 (3) and then L5 (2) /= L5 (4)
             and then L5 (2) /= L5 (5) and then L5 (3) /= L5 (4)
             and then L5 (3) /= L5 (5) and then L5 (4) /= L5 (5),
             "K=5 all singletons");

      --  K=4: only a,b merged
      Check (L4 (1) = L4 (2), "K=4: a and b same cluster");
      Check (L4 (1) /= L4 (3) and then L4 (1) /= L4 (4)
             and then L4 (1) /= L4 (5),
             "K=4: c,d,e distinct from ab");
      Check (L4 (3) /= L4 (4) and then L4 (3) /= L4 (5)
             and then L4 (4) /= L4 (5),
             "K=4: c,d,e pairwise distinct");

      --  K=3: {a,b,e}, {c}, {d}
      Check (L3 (1) = L3 (2) and then L3 (1) = L3 (5),
             "K=3: a,b,e same");
      Check (L3 (1) /= L3 (3) and then L3 (1) /= L3 (4),
             "K=3: c,d distinct from abe");
      Check (L3 (3) /= L3 (4), "K=3: c ≠ d");

      --  K=2: {a,b,e} vs {c,d}
      Check (L2 (1) = L2 (2) and then L2 (1) = L2 (5),
             "K=2: a,b,e same");
      Check (L2 (3) = L2 (4), "K=2: c,d same");
      Check (L2 (1) /= L2 (3), "K=2: abe ≠ cd");

      Check (L1 (1) = L1 (2) and then L1 (1) = L1 (3)
             and then L1 (1) = L1 (4) and then L1 (1) = L1 (5),
             "K=1: all one cluster");

      Check (Same_Partition (H0, L5), "height 0 → 5 singletons");
      Check (Same_Partition (H17, L4), "height 17 → ab merged");
      Check (Same_Partition (H23, L3), "height 23 → abe vs c vs d");
      Check (Same_Partition (H28, L2), "height 28 → abe vs cd");
      Check (Same_Partition (H43, L1), "height 43 → one cluster");
      Check (Same_Partition (HP, H23), "Parameters Cut_Height=23");
   end;

   ---------------------------------------------------------------------
   Section ("7. Two-point trivial + identical points");
   ---------------------------------------------------------------------
   declare
      Dist2 : constant Distance_Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 3.5],
         [3.5, 0.0]];
      T2 : constant Dendrogram := Run_Complete_Linkage (Dist2);
      Data_Id : constant Dataset :=
        [[1.0, 2.0],
         [1.0, 2.0],
         [1.0, 2.0]];
      T0 : constant Dendrogram := Run_Complete_Linkage (Data_Id);
   begin
      Check (T2'Length = 1, "2-point: one merge");
      Check (T2 (1).Left = 1 and then T2 (1).Right = 2, "2-point: 1+2");
      Check (Approx (T2 (1).Height, 3.5), "2-point height 3.5");
      Check (T2 (1).Size = 2, "2-point size 2");

      Check (T0'Length = 2, "identical: N-1=2 merges");
      Check (Approx (T0 (1).Height, 0.0), "identical first height 0");
      Check (Approx (T0 (2).Height, 0.0), "identical second height 0");
      Check (T0 (1).Size = 2, "identical M1 size 2");
      Check (T0 (2).Size = 3, "identical M2 size 3");
   end;

   ---------------------------------------------------------------------
   Section ("8. Compact clusters vs single-link chaining");
   ---------------------------------------------------------------------
   --  Line 0—1—2—3—10.  Complete linkage grows by diameter (max), so at
   --  height 1.5 the chain does NOT fully link: expect {0,1}, {2,3}, {10}
   --  (contrast single-linkage which would chain first four at height 1.5).
   declare
      Data : constant Dataset :=
        [[0.0],
         [1.0],
         [2.0],
         [3.0],
         [10.0]];
      Tree : constant Dendrogram := Run_Complete_Linkage (Data);
      Lab  : constant Labels := Labels_At_Height (Tree, 5, 1.5);
   begin
      Check (Tree'Length = 4, "chain: 4 merges");
      Check (Approx (Tree (1).Height, 1.0), "chain M1 height ~1");
      Check (Approx (Tree (2).Height, 1.0), "chain M2 height ~1");
      --  Next merge joins the two diameter-1 pairs at max-link 3
      Check (Approx (Tree (3).Height, 3.0), "chain M3 diameter ~3");
      Check (Approx (Tree (4).Height, 10.0), "chain final jump ~10");
      --  At 1.5: two pairs + outlier (no long single-link chain)
      Check (Lab (1) = Lab (2), "compact: 0 and 1 linked at 1.5");
      Check (Lab (3) = Lab (4), "compact: 2 and 3 linked at 1.5");
      Check (Lab (1) /= Lab (3), "compact: pairs still separate at 1.5");
      Check (Lab (1) /= Lab (5) and then Lab (3) /= Lab (5),
             "compact: outlier separate");
      Check (Tree (1).Height <= Tree (4).Height, "chain heights ordered");
   end;

   ---------------------------------------------------------------------
   Section ("9. Planted two blobs (compact tendency)");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.1],
         [-0.1, 0.3],
         [0.1, -0.2],
         [10.0, 10.0],
         [10.2, 9.8],
         [9.9, 10.3],
         [10.1, 10.1]];
      Tree : constant Dendrogram := Run_Complete_Linkage (Data);
      Lab : constant Labels := Labels_At_Height (Tree, 8, 2.0);
      K2  : constant Labels := Cut_Dendrogram (Tree, 8, 2);
   begin
      Check (Tree'Length = 7, "blobs: N-1=7 merges");
      Check (Lab (1) = Lab (2) and then Lab (1) = Lab (3)
             and then Lab (1) = Lab (4),
             "blob A cohesive at height 2");
      Check (Lab (5) = Lab (6) and then Lab (5) = Lab (7)
             and then Lab (5) = Lab (8),
             "blob B cohesive at height 2");
      Check (Lab (1) /= Lab (5), "blobs separated at height 2");
      Check (Same_Partition (Lab, K2), "height cut ≡ K=2 cut");
      Check (Tree (7).Height > 5.0, "final merge crosses gap");
      Check (Tree (6).Height < 3.0, "within-blob merges small");
   end;

   ---------------------------------------------------------------------
   Section ("10. Run from points matches distance-matrix path");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      Dist : constant Distance_Matrix := Build_Distance_Matrix (Data);
      Tp : constant Dendrogram := Run_Complete_Linkage (Data);
      Td : constant Dendrogram := Run_Complete_Linkage (Dist);
   begin
      Check (Tp'Length = Td'Length, "points vs matrix: same length");
      Check (Approx (Tp (1).Height, Td (1).Height), "M1 height match");
      Check (Approx (Tp (2).Height, Td (2).Height), "M2 height match");
      Check (Tp (1).Left = Td (1).Left and then Tp (1).Right = Td (1).Right,
             "M1 partners match");
      Check (Tp (2).Size = Td (2).Size, "M2 size match");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid arguments / capacity");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            D : constant Distance_Matrix (1 .. 1, 1 .. 1) := [[0.0]];
            T : constant Dendrogram := Run_Complete_Linkage (D);
            pragma Unreferenced (T);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "N=1 distance matrix → Invalid_Argument");

      Raised := False;
      begin
         declare
            D : constant Distance_Matrix (1 .. 2, 1 .. 3) :=
              [[0.0, 1.0, 2.0],
               [1.0, 0.0, 3.0]];
            T : constant Dendrogram := Run_Complete_Linkage (D);
            pragma Unreferenced (T);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "non-square matrix → Invalid_Argument");

      Raised := False;
      begin
         declare
            Dist : constant Distance_Matrix (1 .. 2, 1 .. 2) :=
              [[0.0, 1.0], [1.0, 0.0]];
            T : constant Dendrogram := Run_Complete_Linkage (Dist);
            L : constant Labels := Cut_Dendrogram (T, 2, 3);
            pragma Unreferenced (L);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "K > N → Invalid_Argument");

      Raised := False;
      begin
         declare
            Dist : constant Distance_Matrix (1 .. 2, 1 .. 2) :=
              [[0.0, 1.0], [1.0, 0.0]];
            T : constant Dendrogram := Run_Complete_Linkage (Dist);
            H : constant Real := Merge_Height (T, 99);
            pragma Unreferenced (H);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Merge_Height OOB → Invalid_Argument");

      Raised := False;
      begin
         declare
            Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
              [[0.0, 1.0, 2.0],
               [1.0, 0.0, 3.0],
               [2.0, 3.0, 0.0]];
            Bad : constant Labels := [1, 9];
            Dij : constant Real :=
              Complete_Linkage_Distance (Dist, [1], Bad);
            pragma Unreferenced (Dij);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "bad cluster index → Invalid_Argument");

      Raised := False;
      begin
         declare
            A : constant Point := [1.0, 2.0];
            B : constant Point := [1.0];
            D : constant Real := Euclidean_Distance (A, B);
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "point length mismatch → error");
   end;

   ---------------------------------------------------------------------
   Section ("12. Hierarchy_Result shape / sizes");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
        [[0.0, 1.0, 4.0],
         [1.0, 0.0, 5.0],
         [4.0, 5.0, 0.0]];
      Tree : constant Dendrogram := Run_Complete_Linkage (Dist);
      Hres : constant Hierarchy_Result :=
        (Last_Merge => 2, N => 3, Tree => Tree);
   begin
      Check (Hres.N = 3, "Hierarchy_Result.N = 3");
      Check (Hres.Tree'Length = Hres.Last_Merge,
             "Hierarchy_Result tree length = Last_Merge");
      Check (Hres.Tree'Length = 2, "Hierarchy_Result tree length 2");
      Check (Hres.Tree (1).Size = 2, "first merge size 2");
      Check (Hres.Tree (2).Size = 3, "second merge size 3");
      Check (Approx (Hres.Tree (1).Height, 1.0), "3-pt first height 1");
      --  Complete: D({1,2},3)=max(4,5)=5
      Check (Approx (Hres.Tree (2).Height, 5.0), "3-pt second height 5");
   end;

   New_Line;
   Put_Line ("Passed: " & Pass_Count'Image & "  Failed: " & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);

end Tests;
