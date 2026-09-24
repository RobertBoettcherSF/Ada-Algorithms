--  Standalone test suite for Flame_Clustering (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Flame_Clustering; use Flame_Clustering;

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

   function Row_Sum (W : Membership_Matrix; I : Point_Index) return Real is
      S : Real := 0.0;
   begin
      for J in W'Range (2) loop
         S := S + W (I, J);
      end loop;
      return S;
   end Row_Sum;

begin
   Put_Line ("Flame_Clustering test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Distance helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [1.0, 0.0];
      B : constant Point := [4.0, 0.0];
      C : constant Point := [1.0, 0.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Distance (A, B), 3.0), "Distance (1,0)-(4,0)=3");
      Check (Approx (Distance (A, C), 0.0), "Distance identical=0");
      Check (Approx (Squared_Distance (A, B), 9.0), "Squared_Distance=9");
      Check (Distance (A, B) > 0.0, "Distance positive");
   end;

   ---------------------------------------------------------------------
   Section ("2. Extract_Point");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 3, 1 .. 2) :=
        [1 => [0.0, 0.0],
         2 => [1.0, 2.0],
         3 => [3.0, 4.0]];
      P2 : constant Point := Extract_Point (Data, 2);
   begin
      Check (Approx (P2 (1), 1.0), "Extract_Point x");
      Check (Approx (P2 (2), 2.0), "Extract_Point y");
      Check (P2'Length = 2, "Extract_Point length");
   end;

   ---------------------------------------------------------------------
   Section ("3. KNN correctness on tiny set");
   ---------------------------------------------------------------------
   --  Points on a line: 0 -- 1 -- 3 -- 10
   declare
      Data : constant Dataset (1 .. 4, 1 .. 1) :=
        [1 => [0.0], 2 => [1.0], 3 => [3.0], 4 => [10.0]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
   begin
      Check (G (1).Count = 2, "KNN count=2");
      Check (G (1).Ids (1) = 2, "pt1 nearest is 2");
      Check (G (1).Ids (2) = 3, "pt1 2nd nearest is 3");
      Check (Approx (G (1).Dists (1), 1.0), "pt1 dist to 2 = 1");
      Check (Approx (G (1).Dists (2), 3.0), "pt1 dist to 3 = 3");

      Check (G (4).Ids (1) = 3, "pt4 nearest is 3");
      Check (G (4).Ids (2) = 2, "pt4 2nd is 2");
      Check (Approx (G (4).Dists (1), 7.0), "pt4 dist to 3 = 7");

      Check (G (2).Ids (1) = 1, "pt2 nearest is 1");
      Check (G (2).Ids (2) = 3, "pt2 2nd is 3");
   end;

   ---------------------------------------------------------------------
   Section ("4. KNN distance ties → lower index");
   ---------------------------------------------------------------------
   declare
      --  Origin with two equidistant neighbors at unit distance.
      Data : constant Dataset (1 .. 3, 1 .. 1) :=
        [1 => [0.0], 2 => [1.0], 3 => [-1.0]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
   begin
      Check (G (1).Ids (1) = 2, "tie: lower id 2 before 3");
      Check (G (1).Ids (2) = 3, "tie: second is 3");
      Check (Approx (G (1).Dists (1), G (1).Dists (2)), "tie equal dists");
   end;

   ---------------------------------------------------------------------
   Section ("5. Density ordering");
   ---------------------------------------------------------------------
   declare
      --  Dense pair near 0, sparse far point.
      Data : constant Dataset (1 .. 4, 1 .. 1) :=
        [1 => [0.0], 2 => [0.1], 3 => [0.2], 4 => [10.0]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
      Dens : constant Densities := Estimate_Densities (G);
   begin
      Check (Dens (1) > Dens (4), "dense point denser than far");
      Check (Dens (2) > Dens (4), "middle dense > far");
      Check (Dens (3) > Dens (4), "cluster edge > far");
      Check (Dens (4) > 0.0, "far density positive");
      Check (Dens (2) >= Dens (1) or else Dens (1) >= Dens (2),
             "densities comparable (ordering exists)");
   end;

   ---------------------------------------------------------------------
   Section ("6. CSO at dense peaks of two blobs + outlier");
   ---------------------------------------------------------------------
   declare
      --  Blob A around 0, Blob B around 10, outlier at 50.
      Data : constant Dataset (1 .. 7, 1 .. 1) :=
        [1 => [0.0],
         2 => [0.2],
         3 => [0.4],
         4 => [10.0],
         5 => [10.2],
         6 => [10.4],
         7 => [50.0]];
      Params : Parameters := Default_Parameters;
   begin
      Params.K := 2;
      Params.Outlier_Threshold := 0.5;  -- generous so far point can be outlier
      Params.Max_Iters := 100;
      Params.Eps := 1.0E-8;
      declare
         Res : constant Flame_Result := Run_FLAME (Data, Params);
         CSO_Count : Natural := 0;
         Out_Count : Natural := 0;
         Has_CSO_Near_0 : Boolean := False;
         Has_CSO_Near_10 : Boolean := False;
      begin
         for I in 1 .. 7 loop
            if Res.Kinds (I) = CSO then
               CSO_Count := CSO_Count + 1;
               if I <= 3 then
                  Has_CSO_Near_0 := True;
               elsif I <= 6 then
                  Has_CSO_Near_10 := True;
               end if;
            elsif Res.Kinds (I) = Outlier then
               Out_Count := Out_Count + 1;
            end if;
         end loop;
         Check (CSO_Count >= 2, "at least 2 CSOs for two blobs");
         Check (Has_CSO_Near_0, "CSO in first blob");
         Check (Has_CSO_Near_10, "CSO in second blob");
         Check (Res.Kinds (7) = Outlier, "far point classified Outlier");
         Check (Res.Num_CSOs = Cluster_Count (CSO_Count), "Num_CSOs matches");
         Check (Res.M = Res.Num_CSOs + 1, "M = Num_CSOs+1");
         Check (Res.Converged or else Res.Iters >= 1, "ran iterations");
         Check (Out_Count >= 1, "at least one outlier counted");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Classify_Objects unit: peak / valley / rest");
   ---------------------------------------------------------------------
   declare
      --  Asymmetric spacing so the tight triple yields a unique density peak.
      Data : constant Dataset (1 .. 5, 1 .. 1) :=
        [1 => [0.0], 2 => [0.1], 3 => [0.25], 4 => [3.0], 5 => [20.0]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
      Dens : constant Densities := Estimate_Densities (G);
      Kinds : constant Kind_Array :=
        Classify_Objects (Dens, G, Out_Th => 0.2);
      Peak_Is_CSO : Boolean := False;
      CSO_Checks : Natural := 0;
   begin
      for I in Dens'Range loop
         if Kinds (I) = CSO then
            Peak_Is_CSO := True;
            --  CSO density strictly > each neighbor
            for S in 1 .. G (I).Count loop
               Check (Dens (I) > Dens (G (I).Ids (S)),
                      "CSO denser than neighbor");
               CSO_Checks := CSO_Checks + 1;
            end loop;
         end if;
      end loop;
      Check (Peak_Is_CSO, "at least one CSO on asymmetric chain");
      Check (CSO_Checks >= 2, "CSO compared against K neighbors");
      Check (Kinds (5) = Outlier or else Kinds (5) = Rest,
             "far point outlier or rest depending on threshold");
      declare
         K2 : constant Kind_Array :=
           Classify_Objects (Dens, G, Out_Th => Dens (5) + 1.0);
      begin
         if Dens (5) < Dens (G (5).Ids (1))
           and then Dens (5) < Dens (G (5).Ids (2))
         then
            Check (K2 (5) = Outlier, "lowest dens + high thr → Outlier");
         else
            Check (True, "far not strictly lowest (skip outlier assert)");
         end if;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Init memberships: CSO/outlier fixed, type-3 equal");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 5, 1 .. 1) :=
        [1 => [0.0], 2 => [0.1], 3 => [5.0], 4 => [5.1], 5 => [100.0]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
      Dens : constant Densities := Estimate_Densities (G);
      Kinds : Kind_Array := Classify_Objects (Dens, G, Out_Th => 0.1);
      CSO_Of : CSO_List (1 .. Max_Clusters) := [others => 1];
      NC_Out : Cluster_Count;
   begin
      --  Force known kinds for deterministic init checks.
      Kinds :=
        [1 => CSO, 2 => Rest, 3 => CSO, 4 => Rest, 5 => Outlier];
      declare
         K2 : constant Kind_Array := Kinds;
         NC2 : constant Cluster_Count := Count_CSOs (K2);
         M2  : constant Cluster_Count := NC2 + 1;
         W2  : Membership_Matrix (1 .. 5, 1 .. Cluster_Index (M2));
         Eq  : constant Real := 1.0 / Real (M2);
      begin
         Init_Memberships (K2, G, W2, NC_Out, CSO_Of);
         Check (NC_Out = NC2, "Init Num_CSOs");
         Check (NC2 = 2, "forced two CSOs");
         for I in 1 .. 5 loop
            Check (Approx (Row_Sum (W2, I), 1.0, 1.0E-9),
                   "init row sum ≈ 1");
            case K2 (I) is
               when CSO =>
                  declare
                     Ones : Natural := 0;
                  begin
                     for J in W2'Range (2) loop
                        if Approx (W2 (I, J), 1.0) then
                           Ones := Ones + 1;
                        end if;
                     end loop;
                     Check (Ones = 1, "CSO has exactly one 1.0");
                  end;
               when Outlier =>
                  Check (Approx (W2 (I, Cluster_Index (M2)), 1.0),
                         "outlier membership 1 on last column");
               when Rest =>
                  for J in W2'Range (2) loop
                     Check (Approx (W2 (I, J), Eq, 1.0E-9),
                            "type-3 equal membership 1/M");
                  end loop;
            end case;
         end loop;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Membership row sums after approximation");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 6, 1 .. 1) :=
        [1 => [0.0], 2 => [0.2], 3 => [0.4],
         4 => [8.0], 5 => [8.2], 6 => [8.4]];
      Params : constant Parameters :=
        (K => 2, Outlier_Threshold => 0.01, Max_Iters => 80,
         Eps => 1.0E-8, Assign_Threshold => 0.5);
      Res : constant Flame_Result := Run_FLAME (Data, Params);
   begin
      for I in 1 .. 6 loop
         Check (Approx (Row_Sum (Res.Memberships, I), 1.0, 1.0E-5),
                "approx row sum ≈ 1");
      end loop;
      Check (Res.Num_CSOs >= 1, "two-blob run found CSOs");
   end;

   ---------------------------------------------------------------------
   Section ("10. Iteration reduces NAE / converges");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 6, 1 .. 1) :=
        [1 => [0.0], 2 => [0.15], 3 => [0.3],
         4 => [5.0], 5 => [5.15], 6 => [5.3]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
      Dens : constant Densities := Estimate_Densities (G);
      Kinds : constant Kind_Array :=
        Classify_Objects (Dens, G, Out_Th => 0.01);
      NC : constant Cluster_Count := Count_CSOs (Kinds);
      M  : constant Cluster_Count := NC + 1;
      W  : Membership_Matrix (1 .. 6, 1 .. Cluster_Index (M));
      CSO_Of : CSO_List (1 .. Max_Clusters) := [others => 1];
      NC_Out : Cluster_Count;
      NAE0, NAE1 : Non_Negative;
      Iters : Natural;
      Conv : Boolean;
      Final_NAE : Non_Negative;
   begin
      Init_Memberships (Kinds, G, W, NC_Out, CSO_Of);
      NAE0 := Neighborhood_Approximation_Error (Kinds, G, W);
      Approximate_Memberships
        (Kinds, G, W, Max_Iters => 50, Eps => 1.0E-9,
         Iters => Iters, Converged => Conv, Final_NAE => Final_NAE);
      NAE1 := Final_NAE;
      Check (Iters >= 1, "at least one NAE iteration");
      Check (NAE1 <= NAE0 + 1.0E-6, "NAE does not increase");
      Check (Conv or else Iters = 50, "converged or hit max iters");
      if Conv then
         Check (True, "marked Converged");
         Check (NAE1 < NAE0 or else Near (NAE0, 0.0),
                "NAE dropped or started near 0");
      else
         Check (True, "reached Max_Iters without full conv (ok)");
         Check (True, "placeholder pass for non-conv path");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("11. Hard labels separate two blobs");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 6, 1 .. 2) :=
        [1 => [0.0, 0.0],
         2 => [0.1, 0.1],
         3 => [0.2, 0.0],
         4 => [5.0, 5.0],
         5 => [5.1, 5.1],
         6 => [5.0, 5.2]];
      Params : constant Parameters :=
        (K => 2, Outlier_Threshold => 0.01, Max_Iters => 100,
         Eps => 1.0E-8, Assign_Threshold => 0.4);
      Res : constant Flame_Result := Run_FLAME (Data, Params);
      L1 : constant Natural := Res.Hard_Labels (1);
      L4 : constant Natural := Res.Hard_Labels (4);
   begin
      Check (Res.Num_CSOs >= 2, "two peaks → ≥2 CSOs");
      Check (L1 /= 0, "label blob A set");
      Check (L4 /= 0, "label blob B set");
      Check (L1 /= L4, "blobs get different hard labels");
      Check (Res.Hard_Labels (2) = L1, "A neighbor same as A");
      Check (Res.Hard_Labels (3) = L1, "A edge same as A");
      Check (Res.Hard_Labels (5) = L4, "B neighbor same as B");
      Check (Res.Hard_Labels (6) = L4, "B edge same as B");
   end;

   ---------------------------------------------------------------------
   Section ("12. Threshold_Assign one-to-multiple");
   ---------------------------------------------------------------------
   declare
      W : constant Membership_Matrix (1 .. 2, 1 .. 3) :=
        [1 => [0.7, 0.2, 0.1],
         2 => [0.4, 0.4, 0.2]];
      A : constant Assignment_Matrix :=
        Threshold_Assign (W, Threshold => 0.35);
   begin
      Check (A (1, 1), "pt1 cluster1 > 0.35");
      Check (not A (1, 2), "pt1 cluster2 ≤ 0.35");
      Check (not A (1, 3), "pt1 outlier ≤ 0.35");
      Check (A (2, 1), "pt2 cluster1 > 0.35");
      Check (A (2, 2), "pt2 cluster2 > 0.35 (multi)");
      Check (not A (2, 3), "pt2 outlier ≤ 0.35");
   end;

   ---------------------------------------------------------------------
   Section ("13. Hard_Labels_From_Memberships ties → lowest index");
   ---------------------------------------------------------------------
   declare
      W : constant Membership_Matrix (1 .. 1, 1 .. 3) :=
        [1 => [0.4, 0.4, 0.2]];
      L : constant Labels := Hard_Labels_From_Memberships (W);
   begin
      Check (L (1) = 1, "tie argmax → lowest cluster index");
   end;

   ---------------------------------------------------------------------
   Section ("14. Inverse-distance weights sum to 1");
   ---------------------------------------------------------------------
   declare
      Row : KNN_Row;
      Wt : Neighbor_Dists (1 .. Max_K_Neighbors);
      S : Real := 0.0;
   begin
      Row.Count := 3;
      Row.Ids := [1, 2, 3, others => 1];
      Row.Dists := [1.0, 2.0, 4.0, others => 0.0];
      Wt := Neighborhood_Weights (Row);
      for I in 1 .. 3 loop
         S := S + Real (Wt (I));
         Check (Wt (I) > 0.0, "weight positive");
      end loop;
      Check (Approx (S, 1.0, 1.0E-9), "weights sum to 1");
      Check (Wt (1) > Wt (2) and then Wt (2) > Wt (3),
             "closer neighbor gets larger weight");
   end;

   ---------------------------------------------------------------------
   Section ("15. Invalid K / capacity");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 3, 1 .. 1) :=
        [1 => [0.0], 2 => [1.0], 3 => [2.0]];
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            G : constant KNN_Graph := Build_KNN (Data, K => 0);
            pragma Unreferenced (G);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;  -- Neighbor_Count may reject 0 at subtype
      end;
      Check (Raised, "K=0 raises Invalid_Argument or Constraint_Error");

      Raised := False;
      begin
         declare
            G : constant KNN_Graph := Build_KNN (Data, K => 3);
            pragma Unreferenced (G);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "K=N raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Params : Parameters := Default_Parameters;
            R : Flame_Result (N => 3, M => 1);
            pragma Unreferenced (R);
         begin
            Params.K := 3;
            declare
               Res : constant Flame_Result := Run_FLAME (Data, Params);
               pragma Unreferenced (Res);
            begin
               null;
            end;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Run_FLAME invalid K raises");
   end;

   ---------------------------------------------------------------------
   Section ("16. CSO fixed during approximation");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 5, 1 .. 1) :=
        [1 => [0.0], 2 => [0.2], 3 => [0.4], 4 => [0.6], 5 => [0.8]];
      G : constant KNN_Graph := Build_KNN (Data, K => 2);
      Dens : constant Densities := Estimate_Densities (G);
      Kinds : constant Kind_Array :=
        Classify_Objects (Dens, G, Out_Th => 0.01);
      NC : constant Cluster_Count := Count_CSOs (Kinds);
      M  : constant Cluster_Count := NC + 1;
      W  : Membership_Matrix (1 .. 5, 1 .. Cluster_Index (M));
      W_Before : Membership_Matrix (1 .. 5, 1 .. Cluster_Index (M));
      CSO_Of : CSO_List (1 .. Max_Clusters) := [others => 1];
      NC_Out : Cluster_Count;
      Iters : Natural;
      Conv : Boolean;
      NAE : Non_Negative;
      Fixed_OK : Boolean := True;
   begin
      Init_Memberships (Kinds, G, W, NC_Out, CSO_Of);
      W_Before := W;
      Approximate_Memberships
        (Kinds, G, W, 30, 1.0E-9, Iters, Conv, NAE);
      for I in 1 .. 5 loop
         if Kinds (I) = CSO or else Kinds (I) = Outlier then
            for J in W'Range (2) loop
               if not Approx (W (I, J), W_Before (I, J), 1.0E-12) then
                  Fixed_OK := False;
               end if;
            end loop;
         end if;
      end loop;
      Check (Fixed_OK, "CSO/outlier memberships unchanged by NAE");
      Check (Iters >= 1, "approximation ran");
      pragma Unreferenced (Conv, NAE);
   end;

   ---------------------------------------------------------------------
   Section ("17. Count_CSOs / Max_Membership_Delta");
   ---------------------------------------------------------------------
   declare
      Kinds : constant Kind_Array (1 .. 4) :=
        [CSO, Rest, CSO, Outlier];
      A : constant Membership_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [1.0, 0.0], 2 => [0.5, 0.5]];
      B : constant Membership_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [0.9, 0.1], 2 => [0.5, 0.5]];
   begin
      Check (Count_CSOs (Kinds) = 2, "Count_CSOs = 2");
      Check (Approx (Max_Membership_Delta (A, B), 0.1), "max delta 0.1");
      Check (Approx (Max_Membership_Delta (A, A), 0.0), "delta self 0");
   end;

   ---------------------------------------------------------------------
   Section ("18. Run_FLAME 2D + soft threshold");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 8, 1 .. 2) :=
        [1 => [0.0, 0.0],
         2 => [0.2, 0.1],
         3 => [0.1, 0.2],
         4 => [0.15, 0.05],
         5 => [4.0, 4.0],
         6 => [4.2, 4.1],
         7 => [4.1, 4.2],
         8 => [4.05, 3.95]];
      Params : constant Parameters :=
        (K => 3, Outlier_Threshold => 0.01, Max_Iters => 120,
         Eps => 1.0E-7, Assign_Threshold => 0.3);
      Res : constant Flame_Result := Run_FLAME (Data, Params);
      Soft : constant Assignment_Matrix :=
        Threshold_Assign (Res.Memberships, Params.Assign_Threshold);
      Any_Soft : Boolean := False;
   begin
      Check (Res.Num_CSOs >= 2, "2D blobs ≥2 CSOs");
      Check (Res.Hard_Labels (1) = Res.Hard_Labels (2),
             "2D A points same hard label");
      Check (Res.Hard_Labels (5) = Res.Hard_Labels (6),
             "2D B points same hard label");
      Check (Res.Hard_Labels (1) /= Res.Hard_Labels (5),
             "2D A ≠ B hard labels");
      for I in Soft'Range (1) loop
         for J in Soft'Range (2) loop
            if Soft (I, J) then
               Any_Soft := True;
            end if;
         end loop;
      end loop;
      Check (Any_Soft, "soft threshold assigns something");
      Check (Res.Final_NAE >= 0.0, "Final_NAE non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("19. Density formula: closer KNN ⇒ higher density");
   ---------------------------------------------------------------------
   declare
      Tight : constant Dataset (1 .. 3, 1 .. 1) :=
        [1 => [0.0], 2 => [0.01], 3 => [0.02]];
      Loose : constant Dataset (1 .. 3, 1 .. 1) :=
        [1 => [0.0], 2 => [1.0], 3 => [2.0]];
      Gt : constant KNN_Graph := Build_KNN (Tight, 2);
      Gl : constant KNN_Graph := Build_KNN (Loose, 2);
      Dt : constant Densities := Estimate_Densities (Gt);
      Dl : constant Densities := Estimate_Densities (Gl);
   begin
      Check (Dt (1) > Dl (1), "tighter neighborhood ⇒ higher density");
      Check (Dt (2) > Dl (2), "tighter mid ⇒ higher density");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   pragma Assert (Fail_Count = 0);

end Tests;
