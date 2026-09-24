--  Standalone test suite for Wards_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Wards_Method; use Wards_Method;

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

begin
   Put_Line ("Wards_Method test suite");
   Put_Line ("=======================");

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
   Section ("2. Squared_Euclidean");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [1.0, 2.0];
      B : constant Point := [4.0, 6.0];
      --  (3)²+(4)² = 9+16 = 25
      C : constant Point := [0.0, 0.0, 0.0];
      D : constant Point := [1.0, 0.0, 0.0];
      Z : constant Point := [5.0, -1.0];
   begin
      Check (Approx (Squared_Euclidean (A, B), 25.0), "3-4-5 triangle sq=25");
      Check (Approx (Squared_Euclidean (A, A), 0.0), "identical points → 0");
      Check (Approx (Squared_Euclidean (C, D), 1.0), "unit axis 3-D");
      Check (Approx (Squared_Euclidean (Z, [0.0, 0.0]), 26.0), "origin distance");
      Check (Squared_Euclidean (A, B) > 0.0, "positive for distinct");
   end;

   ---------------------------------------------------------------------
   Section ("3. Centroid");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0, 2.0],
         [3.0, 4.0],
         [5.0, 6.0]];
      --  mean = (3, 4)
      Mu : constant Point := Centroid (Data);
      One : constant Dataset := [[7.0, -2.0, 1.0]];
      Mu1 : constant Point := Centroid (One);
   begin
      Check (Approx (Mu (1), 3.0), "centroid x=3");
      Check (Approx (Mu (2), 4.0), "centroid y=4");
      Check (Mu'Length = 2, "centroid dim=2");
      Check (Approx (Mu1 (1), 7.0), "singleton centroid x");
      Check (Approx (Mu1 (2), -2.0), "singleton centroid y");
      Check (Approx (Mu1 (3), 1.0), "singleton centroid z");
   end;

   ---------------------------------------------------------------------
   Section ("4. Ward_Delta on singletons = half squared dist");
   ---------------------------------------------------------------------
   declare
      P1 : constant Point := [0.0, 0.0];
      P2 : constant Point := [2.0, 0.0];
      Sq : constant Real := Squared_Euclidean (P1, P2);  -- 4
      Dlt : constant Real := Ward_Delta (1, 1, P1, P2);
      D2 : constant Real := Ward_Delta_From_Dist (1, 1, Sq);
   begin
      Check (Approx (Sq, 4.0), "fixture squared dist=4");
      Check (Approx (Dlt, 2.0), "Δ(1,1)=½·||·||²=2");
      Check (Approx (D2, 2.0), "Ward_Delta_From_Dist matches");
      Check (Near (Dlt, Sq / 2.0), "singleton Δ = half sq dist");
      --  (2*2)/(2+2) * 4 = 4
      Check (Approx (Ward_Delta (2, 2, P1, P2), 4.0),
             "Δ(2,2)=4 for ||μ||=2");
      Check (Approx (Ward_Delta (1, 3, [0.0], [4.0]), 12.0),
             "Δ(1,3)=(3/4)*16=12");
   end;

   ---------------------------------------------------------------------
   Section ("5. Lance–Williams Ward coefficients / formula");
   ---------------------------------------------------------------------
   declare
      --  ni=1,nj=1,nk=1; αi=αj=2/3, β=-1/3
      R : constant Real :=
        Lance_Williams_Ward (1, 1, 1, Dik => 4.0, Djk => 4.0, Dij => 4.0);
      --  (2/3)*4 + (2/3)*4 + (-1/3)*4 = 8/3 + 8/3 - 4/3 = 12/3 = 4
      R2 : constant Real :=
        Lance_Williams_Ward (2, 1, 1, 10.0, 6.0, 4.0);
      --  tot=4; αi=(2+1)/4=0.75, αj=(1+1)/4=0.5, β=-1/4=-0.25
      --  0.75*10 + 0.5*6 + (-0.25)*4 = 7.5 + 3 - 1 = 9.5
   begin
      Check (Approx (R, 4.0), "LW equal singletons → 4");
      Check (Approx (R2, 9.5), "LW (2,1,1) → 9.5");
      Check (Approx
        (Lance_Williams_Ward (1, 1, 2, 8.0, 8.0, 2.0),
         (3.0 / 4.0) * 8.0 + (3.0 / 4.0) * 8.0 + (-2.0 / 4.0) * 2.0),
             "LW analytic match");
      Check
        (Lance_Williams_Ward (3, 2, 1, 1.0, 1.0, 1.0)
         < Lance_Williams_Ward (3, 2, 1, 10.0, 10.0, 1.0),
         "LW increases with Dik/Djk");
   end;

   ---------------------------------------------------------------------
   Section ("6. Lance–Williams matches direct centroid formula");
   ---------------------------------------------------------------------
   declare
      --  Points: A=0, B=2, C=10 on the line (1-D)
      --  Merge A,B first: μ_AB=1, n=2; d_AB init = 4; Δ=2
      --  Direct Ward d between (AB) and C:
      --    2·Δ = 2 · (2·1)/(2+1) · (1-10)² = 2 · (2/3) · 81 = 108
      --  Or LW: Dik=d(A,C)=100, Djk=d(B,C)=64, Dij=4
      --    αi=(1+1)/3=2/3, αj=(1+1)/3=2/3, β=-1/3
      --    (2/3)*100 + (2/3)*64 + (-1/3)*4 = 200/3 + 128/3 - 4/3 = 324/3 = 108
      LW : constant Real :=
        Lance_Williams_Ward (1, 1, 1, 100.0, 64.0, 4.0);
      Direct_Delta : constant Real :=
        Ward_Delta (2, 1, [1.0], [10.0]);  -- (2*1)/3 * 81 = 54
      Direct_D : constant Real := 2.0 * Direct_Delta;  -- 108
   begin
      Check (Approx (LW, 108.0), "LW after merge A,B vs C = 108");
      Check (Approx (Direct_Delta, 54.0), "direct Δ((AB),C)=54");
      Check (Approx (Direct_D, 108.0), "direct 2Δ = 108");
      Check (Near (LW, Direct_D), "LW equals 2·Δ centroid formula");
      Check (Near (LW / 2.0, Direct_Delta), "LW/2 equals Δ");
   end;

   ---------------------------------------------------------------------
   Section ("7. Ward_Linkage basic: two points");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset := [[0.0], [4.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
   begin
      Check (Tree'Length = 1, "N=2 → one merge");
      Check (Tree (1).Left = 1, "merge left leaf 1");
      Check (Tree (1).Right = 2, "merge right leaf 2");
      Check (Approx (Tree (1).Height, 8.0), "Δ=(1·1)/2·16=8");
      --  Final SSE of one cluster: mean=2, (0-2)²+(4-2)²=8
      declare
         Lab : constant Labels := Cut_Dendrogram (Tree, 2, 1);
         SSE : constant Real := Within_Cluster_SSE (Data, Lab);
      begin
         Check (Lab (1) = Lab (2), "K=1 same label");
         Check (Approx (SSE, 8.0), "final SSE = Δ");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. 1-D well-separated: first merges within clusters");
   ---------------------------------------------------------------------
   declare
      --  Cluster A: 0, 0.1 ; Cluster B: 10, 10.2
      Data : constant Dataset :=
        [[0.0], [0.1], [10.0], [10.2]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
   begin
      Check (Tree'Length = 3, "N=4 → 3 merges");
      --  First merge must be within a tight pair: (1,2) or (3,4)
      Check
        ((Tree (1).Left = 1 and then Tree (1).Right = 2)
         or else (Tree (1).Left = 3 and then Tree (1).Right = 4),
         "first merge within a blob");
      Check
        ((Tree (2).Left = 1 and then Tree (2).Right = 2)
         or else (Tree (2).Left = 3 and then Tree (2).Right = 4)
         or else (Tree (2).Left = 5)  -- after first within-merge, id 5
         or else (Tree (2).Right = 5),
         "second merge still within / joining local");
      --  Heights non-decreasing for Ward (ultrametric-ish / ESS increases)
      Check (Tree (1).Height <= Tree (2).Height + 1.0E-9,
             "height1 <= height2");
      Check (Tree (2).Height <= Tree (3).Height + 1.0E-9,
             "height2 <= height3");
      Check (Tree (3).Height > Tree (1).Height,
             "final cross-blob merge tallest");
   end;

   ---------------------------------------------------------------------
   Section ("9. SSE increases by exactly Δ at each merge");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0],
         [10.0, 10.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      N : constant Positive := 4;
      --  After m merges, K = N - m clusters
      Prev_SSE : Real := 0.0;  -- singletons: SSE=0
   begin
      Check (Approx (Within_Cluster_SSE
        (Data, [1, 2, 3, 4]), 0.0), "singleton SSE=0");
      for M in 1 .. N - 1 loop
         declare
            K : constant Positive := N - M;
            Lab : constant Labels := Cut_Dendrogram (Tree, N, K);
            SSE : constant Real := Within_Cluster_SSE (Data, Lab);
            Expected : constant Real := Prev_SSE + Tree (M).Height;
         begin
            Check (Approx (SSE, Expected, 1.0E-5),
                   "SSE after merge" & Integer'Image (M)
                   & " = prev+Δ");
            Check (SSE >= Prev_SSE - 1.0E-9, "SSE nondecreasing");
            Prev_SSE := SSE;
         end;
      end loop;
      --  One cluster left
      declare
         Lab1 : constant Labels := Cut_Dendrogram (Tree, N, 1);
      begin
         Check (Lab1 (1) = Lab1 (2)
           and then Lab1 (1) = Lab1 (3)
           and then Lab1 (1) = Lab1 (4),
                "final one cluster");
         Check (Approx (Prev_SSE, Within_Cluster_SSE (Data, Lab1), 1.0E-5),
                "final SSE matches cut K=1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Cut into K=2 recovers synthetic blobs");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.1],
         [0.1, -0.1],
         [5.0, 5.0],
         [5.2, 4.9],
         [4.9, 5.1]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      Lab : constant Labels := Cut_Dendrogram (Tree, 6, 2);
   begin
      Check (Tree'Length = 5, "N=6 → 5 merges");
      Check (Lab'Length = 6, "six labels");
      --  Points 1..3 same cluster; 4..6 same; different across
      Check (Lab (1) = Lab (2) and then Lab (2) = Lab (3),
             "blob A co-clustered");
      Check (Lab (4) = Lab (5) and then Lab (5) = Lab (6),
             "blob B co-clustered");
      Check (Lab (1) /= Lab (4), "blobs separated");
      --  Exactly two distinct labels
      declare
         Seen : array (1 .. 6) of Boolean := [others => False];
         Cnt : Natural := 0;
      begin
         for I in Lab'Range loop
            if Lab (I) in 1 .. 6 and then not Seen (Lab (I)) then
               Seen (Lab (I)) := True;
               Cnt := Cnt + 1;
            end if;
         end loop;
         Check (Cnt = 2, "exactly two labels used");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid empty / K raises");
   ---------------------------------------------------------------------
   declare
      Data2 : constant Dataset := [[0.0], [1.0]];
      Tree2 : constant Dendrogram := Ward_Linkage (Data2);
      Raised_Empty : Boolean := False;
      Raised_Bad_Tree : Boolean := False;
      Raised_KBig : Boolean := False;
      Raised_One : Boolean := False;
   begin
      begin
         declare
            Empty : Dataset (1 .. 0, 1 .. 1);
            Unused : Dendrogram (1 .. 0);
         begin
            Unused := Ward_Linkage (Empty);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_Empty := True;
         when others =>
            null;
      end;
      Check (Raised_Empty, "empty / N<2 raises");

      begin
         declare
            --  Tree length must be N-1; pass a too-short tree.
            Short : constant Dendrogram :=
              [1 => (Left => 1, Right => 2, Height => 0.0)];
            Unused : Labels (1 .. 3);
         begin
            Unused := Cut_Dendrogram (Short, N => 3, K => 2);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_Bad_Tree := True;
         when others =>
            null;
      end;
      Check (Raised_Bad_Tree, "mismatched dendrogram length raises");

      begin
         declare
            Unused : Labels (1 .. 2);
         begin
            Unused := Cut_Dendrogram (Tree2, 2, K => 3);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_KBig := True;
         when others =>
            null;
      end;
      Check (Raised_KBig, "K>N raises");

      begin
         declare
            One : constant Dataset := [[1.0, 2.0]];
            Unused : Dendrogram (1 .. 0);
         begin
            Unused := Ward_Linkage (One);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_One := True;
         when others =>
            null;
      end;
      Check (Raised_One, "single point raises");
   end;

   ---------------------------------------------------------------------
   Section ("12. Tie-breaking deterministic (lowest indices)");
   ---------------------------------------------------------------------
   declare
      --  Equilateral-ish: three points on a line at 0,1,2 — pairs (1,2)
      --  and (2,3) have identical distance; Ward must pick (1,2) first.
      Data : constant Dataset := [[0.0], [1.0], [2.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      Data4 : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0],
         [1.0, 1.0]];
      --  All adjacent edge lengths equal; first merge should be leaves 1,2
      --  (lowest indices among min pairs).
      Tree4 : constant Dendrogram := Ward_Linkage (Data4);
   begin
      Check (Tree (1).Left = 1 and then Tree (1).Right = 2,
             "tie: merge (1,2) not (2,3)");
      Check (Tree (1).Height <= Tree (2).Height + 1.0E-9,
             "3-point heights ordered");
      Check (Tree4 (1).Left = 1, "4-point first Left=1");
      Check (Tree4 (1).Right = 2, "4-point first Right=2");
      --  Re-run: deterministic
      declare
         Tree_B : constant Dendrogram := Ward_Linkage (Data);
      begin
         Check (Tree_B (1).Left = Tree (1).Left
           and then Tree_B (1).Right = Tree (1).Right
           and then Near (Tree_B (1).Height, Tree (1).Height),
                "repeated linkage identical");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Cut K=N (no merges) and K=N-1");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset := [[0.0], [1.0], [3.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      LabN : constant Labels := Cut_Dendrogram (Tree, 3, 3);
      Lab2 : constant Labels := Cut_Dendrogram (Tree, 3, 2);
   begin
      Check (LabN (1) /= LabN (2)
        and then LabN (1) /= LabN (3)
        and then LabN (2) /= LabN (3),
             "K=N all distinct");
      Check (LabN (1) = 1 and then LabN (2) = 2 and then LabN (3) = 3,
             "K=N identity labels");
      --  First merge joins 1 and 2 (dist 1 vs 1–3 dist 9 / 2–3 dist 4)
      Check (Lab2 (1) = Lab2 (2), "K=2 first pair joined");
      Check (Lab2 (1) /= Lab2 (3), "K=2 third alone");
   end;

   ---------------------------------------------------------------------
   Section ("14. Within_Cluster_SSE known value");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [2.0, 0.0],
         [0.0, 2.0],
         [2.0, 2.0]];
      --  One cluster: mean (1,1); four points each ||·||²=2 → SSE=8
      Lab1 : constant Labels := [1, 1, 1, 1];
      --  Two vertical pairs: labels 1 for cols x=0, 2 for x=2
      Lab2 : constant Labels := [1, 2, 1, 2];
      --  Cluster1: (0,0),(0,2) mean (0,1) SSE=1+1=2
      --  Cluster2: (2,0),(2,2) mean (2,1) SSE=2 → total 4
   begin
      Check (Approx (Within_Cluster_SSE (Data, Lab1), 8.0),
             "one-cluster SSE=8");
      Check (Approx (Within_Cluster_SSE (Data, Lab2), 4.0),
             "two-column SSE=4");
      Check (Approx (Within_Cluster_SSE
        (Data, [1, 2, 3, 4]), 0.0), "four singletons SSE=0");
      Check (Within_Cluster_SSE (Data, Lab1)
             > Within_Cluster_SSE (Data, Lab2),
             "finer partition lower SSE");
   end;

   ---------------------------------------------------------------------
   Section ("15. 2-D Ward vs manual Δ for first merge");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      --  Closest: points 1,2; ||·||²=1; Δ=0.5
      Expected_D : constant Real := Ward_Delta (1, 1, [0.0, 0.0], [1.0, 0.0]);
   begin
      Check (Tree (1).Left = 1 and then Tree (1).Right = 2,
             "first merge leaves 1,2");
      Check (Approx (Tree (1).Height, Expected_D),
             "first height = Ward_Delta");
      Check (Approx (Tree (1).Height, 0.5), "first height=0.5");
      Check (Tree (2).Left = 4 or else Tree (2).Right = 4,
             "second involves merged cluster id 4");
      Check (Approx (Tree (2).Height,
        Ward_Delta (2, 1, [0.5, 0.0], [10.0, 0.0]), 1.0E-5),
             "second height matches centroid Δ");
   end;


   ---------------------------------------------------------------------
   Section ("16. Capacity constants and Point/Dataset shapes");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 3, 1 .. 2) :=
        [[0.0, 1.0],
         [2.0, 3.0],
         [4.0, 5.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      Lab : constant Labels := Cut_Dendrogram (Tree, 3, 2);
   begin
      Check (Data'Length (1) = 3, "dataset 3 rows");
      Check (Data'Length (2) = 2, "dataset 2 cols");
      Check (Squared_Euclidean ([0.0, 1.0], [2.0, 3.0]) = 8.0,
             "row0-row1 sq dist=8");
      Check (Approx (Centroid (Data) (1), 2.0), "3-row centroid x");
      Check (Approx (Centroid (Data) (2), 3.0), "3-row centroid y");
      Check (Tree'Length = 2, "3 points → 2 merges");
      Check (Lab (1) = Lab (2) or else Lab (2) = Lab (3)
        or else Lab (1) = Lab (3), "K=2 joins one adjacent pair");
      Check (not (Lab (1) = Lab (2) and then Lab (2) = Lab (3)),
             "K=2 not all identical");
   end;

   ---------------------------------------------------------------------
   Section ("17. Monotone ESS and full-tree height sum");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [1.0], [2.0], [10.0]];
      Tree : constant Dendrogram := Ward_Linkage (Data);
      Sum_H : Real := 0.0;
      Lab1 : constant Labels := Cut_Dendrogram (Tree, 4, 1);
      Final_SSE : constant Real := Within_Cluster_SSE (Data, Lab1);
   begin
      for M in Tree'Range loop
         Sum_H := Sum_H + Tree (M).Height;
         if M > Tree'First then
            Check (Tree (M).Height + 1.0E-12 >= Tree (M - 1).Height,
                   "monotone height at" & Integer'Image (M));
         end if;
      end loop;
      Check (Approx (Sum_H, Final_SSE, 1.0E-5),
             "sum of Δ equals final SSE");
      Check (Tree'Length = 3, "four points → 3 merges");
      Check (Final_SSE > 0.0, "final SSE positive");
   end;

   ---------------------------------------------------------------------
   Section ("18. Lance–Williams γ=0 / asymmetry sizes");
   ---------------------------------------------------------------------
   declare
      --  γ=0 ⇒ no |Dik−Djk| term; swapping Dik/Djk with Ni/Nj swap matches
      A : constant Real :=
        Lance_Williams_Ward (3, 1, 2, Dik => 5.0, Djk => 9.0, Dij => 4.0);
      B : constant Real :=
        Lance_Williams_Ward (1, 3, 2, Dik => 9.0, Djk => 5.0, Dij => 4.0);
      C : constant Real :=
        Lance_Williams_Ward (5, 5, 5, 2.0, 2.0, 2.0);
      --  tot=15; αi=αj=10/15=2/3; β=-5/15=-1/3
      --  (2/3)*2*2 + (-1/3)*2 = 8/3 - 2/3 = 2
   begin
      Check (Near (A, B), "LW symmetric in (i,j) swap");
      Check (Approx (C, 2.0), "LW equal sizes → 2");
      Check (Lance_Williams_Ward (1, 1, 1, 0.0, 0.0, 0.0) = 0.0,
             "LW zero distances → 0");
      Check (Approx
        (Lance_Williams_Ward (2, 2, 2, 8.0, 8.0, 8.0),
         (4.0 / 6.0) * 8.0 + (4.0 / 6.0) * 8.0 + (-2.0 / 6.0) * 8.0),
             "LW equal-n analytic");
   end;

   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;
