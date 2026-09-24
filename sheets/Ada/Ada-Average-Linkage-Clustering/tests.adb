--  Standalone test suite for Average_Linkage_Clustering / UPGMA (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Average_Linkage_Clustering; use Average_Linkage_Clustering;

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

   function Distinct_Label_Count (Lab : Labels) return Natural is
      Seen : array (0 .. Max_Points) of Boolean := [others => False];
      C    : Natural := 0;
   begin
      for I in Lab'Range loop
         declare
            L : constant Natural := Lab (I);
         begin
            if L > 0 and then not Seen (L) then
               Seen (L) := True;
               C := C + 1;
            end if;
         end;
      end loop;
      return C;
   end Distinct_Label_Count;

begin
   Put_Line ("Average_Linkage_Clustering / UPGMA test suite");
   Put_Line ("==============================================");

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
   Section ("4. Average_Linkage_Distance (mean pairwise)");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 4, 1 .. 4) :=
        [[0.0, 2.0, 9.0, 8.0],
         [2.0, 0.0, 7.0, 6.0],
         [9.0, 7.0, 0.0, 1.0],
         [8.0, 6.0, 1.0, 0.0]];
      --  Cluster {1,2} vs {3,4}: mean(9,8,7,6) = 7.5
      XA : constant Labels := [1, 2];
      XB : constant Labels := [3, 4];
      XC : constant Labels := [1];
      XD : constant Labels := [2];
   begin
      Check (Approx (Average_Linkage_Distance (Dist, XA, XB), 7.5),
             "D({1,2},{3,4})=7.5 mean");
      Check (Approx (UPGMA_Distance (Dist, XA, XB), 7.5),
             "UPGMA_Distance alias = 7.5");
      Check (Approx (Cluster_Distance (Dist, XA, XB), 7.5),
             "Cluster_Distance alias = 7.5");
      Check (Approx (Average_Linkage_Distance (Dist, XC, XD), 2.0),
             "D({1},{2})=2");
      Check (Approx (Average_Linkage_Distance (Dist, [3], [4]), 1.0),
             "D({3},{4})=1");
      --  Contrast: mean ≠ min (6) and ≠ max (9)
      Check (not Approx (Average_Linkage_Distance (Dist, XA, XB), 6.0),
             "average ≠ single-linkage min=6");
      Check (not Approx (Average_Linkage_Distance (Dist, XA, XB), 9.0),
             "average ≠ complete-linkage max=9");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia bacteria JC69 UPGMA example");
   ---------------------------------------------------------------------
   --  a b c d e with JC69 distances (Wikipedia UPGMA working example).
   --  Merges: a+b@17; (ab)+e@22; c+d@28; ((ab)e)+(cd)@33
   declare
      Dist : constant Distance_Matrix (1 .. 5, 1 .. 5) :=
        [[0.0, 17.0, 21.0, 31.0, 23.0],
         [17.0, 0.0, 30.0, 34.0, 21.0],
         [21.0, 30.0, 0.0, 28.0, 39.0],
         [31.0, 34.0, 28.0, 0.0, 43.0],
         [23.0, 21.0, 39.0, 43.0, 0.0]];
      Tree : constant Dendrogram := Run_Average_Linkage (Dist);
      Tree2 : constant Dendrogram := Run_UPGMA (Dist);
   begin
      Check (Tree'Length = 4, "hierarchy size N-1 = 4");
      Check (Tree2'Length = 4, "Run_UPGMA alias length = 4");

      --  First update averages after a+b
      declare
         XA : constant Labels := [1, 2];
      begin
         Check (Approx (Average_Linkage_Distance (Dist, XA, [3]), 25.5),
                "D(ab,c)=25.5 after first merge");
         Check (Approx (Average_Linkage_Distance (Dist, XA, [4]), 32.5),
                "D(ab,d)=32.5 after first merge");
         Check (Approx (Average_Linkage_Distance (Dist, XA, [5]), 22.0),
                "D(ab,e)=22 after first merge");
      end;

      --  Merge 1: a+b at 17
      Check (Tree (1).Left = 1, "M1 Left = a (1)");
      Check (Tree (1).Right = 2, "M1 Right = b (2)");
      Check (Approx (Tree (1).Height, 17.0), "M1 Height = 17");
      Check (Tree (1).Size = 2, "M1 Size = 2");
      Check (Approx (Merge_Height (Tree, 1), 17.0), "Merge_Height(1)=17");

      --  Merge 2: (ab)=6 with e=5 at 22
      Check (Tree (2).Left = 6, "M2 Left = cluster (ab)=6");
      Check (Tree (2).Right = 5, "M2 Right = e (5)");
      Check (Approx (Tree (2).Height, 22.0), "M2 Height = 22");
      Check (Tree (2).Size = 3, "M2 Size = 3");
      Check (Approx (Merge_Height (Tree, 2), 22.0), "Merge_Height(2)=22");

      --  Size-weighted update after step 2: D(((ab)e),c)=30, D(((ab)e),d)=36
      --  Verified via full pairwise mean on original matrix:
      declare
         Abe : constant Labels := [1, 2, 5];
         Cd  : constant Labels := [3, 4];
      begin
         Check (Approx (Average_Linkage_Distance (Dist, Abe, [3]), 30.0),
                "D((ab)e,c)=30 size-weighted");
         Check (Approx (Average_Linkage_Distance (Dist, Abe, [4]), 36.0),
                "D((ab)e,d)=36 size-weighted");
         Check (Approx (Average_Linkage_Distance (Dist, Abe, Cd), 33.0),
                "D((ab)e,(cd))=33 final mean");
         --  Contrast: WPGMA simple average of D(ab,c) and D(e,c) would be
         --  (25.5+39)/2 = 32.25 ≠ 30 — UPGMA uses size weights.
         Check (not Approx
                  ((25.5 + 39.0) / 2.0, 30.0),
                "WPGMA simple avg ≠ UPGMA 30 for ((ab)e),c");
      end;

      --  Merge 3: c+d at 28 (independent of (abe))
      Check (Tree (3).Left = 3, "M3 Left = c (3)");
      Check (Tree (3).Right = 4, "M3 Right = d (4)");
      Check (Approx (Tree (3).Height, 28.0), "M3 Height = 28");
      Check (Tree (3).Size = 2, "M3 Size = 2");

      --  Merge 4: ((ab)e)=7 with (cd)=8 at 33
      Check (Tree (4).Left = 7, "M4 Left = cluster ((ab)e)=7");
      Check (Tree (4).Right = 8, "M4 Right = cluster (cd)=8");
      Check (Approx (Tree (4).Height, 33.0), "M4 Height = 33");
      Check (Tree (4).Size = 5, "M4 Size = 5");
      Check (Approx (Merge_Height (Tree, 4), 33.0), "Merge_Height(4)=33");

      --  Alias Run_UPGMA produces same heights
      Check (Approx (Tree2 (1).Height, 17.0), "Run_UPGMA M1=17");
      Check (Approx (Tree2 (2).Height, 22.0), "Run_UPGMA M2=22");
      Check (Approx (Tree2 (3).Height, 28.0), "Run_UPGMA M3=28");
      Check (Approx (Tree2 (4).Height, 33.0), "Run_UPGMA M4=33");
   end;

   ---------------------------------------------------------------------
   Section ("6. Cut_Dendrogram / Labels_At_Height (Wikipedia)");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 5, 1 .. 5) :=
        [[0.0, 17.0, 21.0, 31.0, 23.0],
         [17.0, 0.0, 30.0, 34.0, 21.0],
         [21.0, 30.0, 0.0, 28.0, 39.0],
         [31.0, 34.0, 28.0, 0.0, 43.0],
         [23.0, 21.0, 39.0, 43.0, 0.0]];
      Tree : constant Dendrogram := Run_Average_Linkage (Dist);
      Lab5 : constant Labels := Cut_Dendrogram (Tree, 5, 5);
      Lab4 : constant Labels := Cut_Dendrogram (Tree, 5, 4);
      Lab3 : constant Labels := Cut_Dendrogram (Tree, 5, 3);
      Lab2 : constant Labels := Cut_Dendrogram (Tree, 5, 2);
      Lab1 : constant Labels := Cut_Dendrogram (Tree, 5, 1);
      --  Expected partitions (label permutation OK):
      --  K=5: all singletons
      --  K=4: {a,b}, {c}, {d}, {e}
      --  K=3: {a,b,e}, {c}, {d}
      --  K=2: {a,b,e}, {c,d}
      --  K=1: all together
      Exp4 : constant Labels := [1, 1, 2, 3, 4];
      Exp3 : constant Labels := [1, 1, 2, 3, 1];
      Exp2 : constant Labels := [1, 1, 2, 2, 1];
      H0   : constant Labels := Labels_At_Height (Tree, 5, 0.0);
      H17  : constant Labels := Labels_At_Height (Tree, 5, 17.0);
      H22  : constant Labels := Labels_At_Height (Tree, 5, 22.0);
      H28  : constant Labels := Labels_At_Height (Tree, 5, 28.0);
      H33  : constant Labels := Labels_At_Height (Tree, 5, 33.0);
      P    : constant Parameters := (Cut_Height => 22.0);
      HP   : constant Labels := Labels_At_Height (Tree, 5, P);
   begin
      Check (Distinct_Label_Count (Lab5) = 5, "Cut K=5 → 5 clusters");
      Check (Distinct_Label_Count (Lab4) = 4, "Cut K=4 → 4 clusters");
      Check (Distinct_Label_Count (Lab3) = 3, "Cut K=3 → 3 clusters");
      Check (Distinct_Label_Count (Lab2) = 2, "Cut K=2 → 2 clusters");
      Check (Distinct_Label_Count (Lab1) = 1, "Cut K=1 → 1 cluster");
      Check (Same_Partition (Lab4, Exp4), "Cut K=4 partition {ab}|c|d|e");
      Check (Same_Partition (Lab3, Exp3), "Cut K=3 partition {abe}|c|d");
      Check (Same_Partition (Lab2, Exp2), "Cut K=2 partition {abe}|{cd}");
      Check (Lab1 (1) = Lab1 (5), "Cut K=1 all same label");

      Check (Distinct_Label_Count (H0) = 5, "Height 0 → 5 singletons");
      Check (Same_Partition (H17, Exp4), "Height 17 → {ab} merged");
      Check (Same_Partition (H22, Exp3), "Height 22 → {abe}");
      Check (Same_Partition (H28, Exp2), "Height 28 → {abe}|{cd}");
      Check (Distinct_Label_Count (H33) = 1, "Height 33 → one cluster");
      Check (Same_Partition (HP, H22), "Parameters.Cut_Height=22");
   end;

   ---------------------------------------------------------------------
   Section ("7. Run from points (Euclidean)");
   ---------------------------------------------------------------------
   declare
      --  Two tight pairs far apart: (0,0),(0.1,0) and (10,0),(10.1,0)
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [10.0, 0.0],
         [10.1, 0.0]];
      Tree : constant Dendrogram := Run_Average_Linkage (Data);
      TreeU : constant Dendrogram := Run_UPGMA (Data);
      Lab2 : constant Labels := Cut_Dendrogram (Tree, 4, 2);
      Exp2 : constant Labels := [1, 1, 2, 2];
   begin
      Check (Tree'Length = 3, "points dendrogram length 3");
      Check (Approx (Tree (1).Height, 0.1), "first merge height ≈ 0.1");
      Check (Approx (Tree (2).Height, 0.1), "second merge height ≈ 0.1");
      Check (Tree (3).Height > 9.0, "final merge joins distant pairs");
      Check (Same_Partition (Lab2, Exp2), "K=2 → two pairs");
      Check (Approx (TreeU (3).Height, Tree (3).Height),
             "Run_UPGMA(points) matches");
   end;

   ---------------------------------------------------------------------
   Section ("8. Two-point and identical points");
   ---------------------------------------------------------------------
   declare
      Dist2 : constant Distance_Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 3.5],
         [3.5, 0.0]];
      Tree2 : constant Dendrogram := Run_Average_Linkage (Dist2);
      Data_Id : constant Dataset :=
        [[1.0, 2.0],
         [1.0, 2.0],
         [1.0, 2.0]];
      Tree_Id : constant Dendrogram := Run_Average_Linkage (Data_Id);
   begin
      Check (Tree2'Length = 1, "2-point dendrogram length 1");
      Check (Tree2 (1).Left = 1, "2-point Left=1");
      Check (Tree2 (1).Right = 2, "2-point Right=2");
      Check (Approx (Tree2 (1).Height, 3.5), "2-point Height=3.5");
      Check (Tree2 (1).Size = 2, "2-point Size=2");

      Check (Tree_Id'Length = 2, "identical points N-1=2");
      Check (Approx (Tree_Id (1).Height, 0.0), "identical M1 Height=0");
      Check (Approx (Tree_Id (2).Height, 0.0), "identical M2 Height=0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Update formula ≠ min / max linkage");
   ---------------------------------------------------------------------
   declare
      --  After merging A={1,2} with sizes, distance to 3:
      --  d(1,3)=4, d(2,3)=10 → UPGMA (4+10)/2=7; single=min=4; complete=max=10
      Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
        [[0.0, 1.0, 4.0],
         [1.0, 0.0, 10.0],
         [4.0, 10.0, 0.0]];
      Tree : constant Dendrogram := Run_Average_Linkage (Dist);
      XA : constant Labels := [1, 2];
   begin
      Check (Approx (Tree (1).Height, 1.0), "merge 1+2 at 1");
      Check (Approx (Tree (2).Height, 7.0), "then join 3 at mean 7");
      Check (Approx (Average_Linkage_Distance (Dist, XA, [3]), 7.0),
             "mean pairwise = 7");
      Check (Tree (2).Height /= 4.0, "update ≠ single-linkage min 4");
      Check (Tree (2).Height /= 10.0, "update ≠ complete-linkage max 10");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid arguments / exceptions");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            D : constant Distance_Matrix (1 .. 1, 1 .. 1) := [[0.0]];
            T : Dendrogram := Run_Average_Linkage (D);
            pragma Unreferenced (T);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "N=1 matrix → Invalid_Argument");

      Raised := False;
      begin
         declare
            D : constant Distance_Matrix (1 .. 2, 1 .. 3) :=
              [[0.0, 1.0, 2.0],
               [1.0, 0.0, 3.0]];
            T : Dendrogram := Run_Average_Linkage (D);
            pragma Unreferenced (T);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "non-square matrix → Invalid_Argument");

      Raised := False;
      begin
         declare
            Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
              [[0.0, 1.0, 2.0],
               [1.0, 0.0, 3.0],
               [2.0, 3.0, 0.0]];
            Tree : constant Dendrogram := Run_Average_Linkage (Dist);
            H : Non_Negative := Merge_Height (Tree, 99);
            pragma Unreferenced (H);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Merge_Height OOR → Invalid_Argument");

      Raised := False;
      begin
         declare
            Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
              [[0.0, 1.0, 2.0],
               [1.0, 0.0, 3.0],
               [2.0, 3.0, 0.0]];
            Tree : constant Dendrogram := Run_Average_Linkage (Dist);
            L : Labels := Cut_Dendrogram (Tree, 3, 4);
            pragma Unreferenced (L);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Cut K>N → Invalid_Argument");

      Raised := False;
      begin
         declare
            Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
              [[0.0, 1.0, 2.0],
               [1.0, 0.0, 3.0],
               [2.0, 3.0, 0.0]];
            Bad : constant Labels := [0];
            Davg : Non_Negative :=
              Average_Linkage_Distance (Dist, Bad, [1]);
            pragma Unreferenced (Davg);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "bad cluster index → Invalid_Argument");

      Raised := False;
      begin
         declare
            A : constant Point := [1.0, 2.0];
            B : constant Point := [1.0];
            D : Non_Negative := Euclidean_Distance (A, B);
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := True;  -- length mismatch may trip Pre'Check
      end;
      Check (Raised, "point length mismatch → exception");
   end;

   ---------------------------------------------------------------------
   Section ("11. Hierarchy_Result / Defaults / misc");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 3, 1 .. 3) :=
        [[0.0, 2.0, 5.0],
         [2.0, 0.0, 4.0],
         [5.0, 4.0, 0.0]];
      Tree : constant Dendrogram := Run_Average_Linkage (Dist);
      HR : Hierarchy_Result (Last_Merge => 2);
   begin
      HR.N := 3;
      HR.Tree := Tree;
      Check (HR.N = 3, "Hierarchy_Result.N = 3");
      Check (HR.Tree'Length = 2, "Hierarchy_Result.Tree length 2");
      Check (Approx (HR.Tree (1).Height, 2.0), "HR first height 2");
      Check (Default_Parameters.Cut_Height = 0.0, "Default Cut_Height=0");
      Check (Point_Count'Last = Max_Points, "Point_Count'Last = Max_Points");
      Check (Dim_Count'Last = Max_Dims, "Dim_Count'Last = Max_Dims");
   end;

   ---------------------------------------------------------------------
   Section ("12. Monotone heights / size tracking");
   ---------------------------------------------------------------------
   declare
      Dist : constant Distance_Matrix (1 .. 5, 1 .. 5) :=
        [[0.0, 17.0, 21.0, 31.0, 23.0],
         [17.0, 0.0, 30.0, 34.0, 21.0],
         [21.0, 30.0, 0.0, 28.0, 39.0],
         [31.0, 34.0, 28.0, 0.0, 43.0],
         [23.0, 21.0, 39.0, 43.0, 0.0]];
      Tree : constant Dendrogram := Run_Average_Linkage (Dist);
      Mono : Boolean := True;
   begin
      for I in Tree'First .. Tree'Last - 1 loop
         if Tree (I).Height > Tree (I + 1).Height + 1.0E-9 then
            Mono := False;
         end if;
      end loop;
      Check (Mono, "merge heights non-decreasing (ultrametric-ish)");
      Check (Tree (1).Size = 2, "size after M1 = 2");
      Check (Tree (2).Size = 3, "size after M2 = 3");
      Check (Tree (3).Size = 2, "size after M3 = 2 (cd)");
      Check (Tree (4).Size = 5, "size after M4 = 5");
   end;

   New_Line;
   Put_Line ("==============================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
end Tests;
