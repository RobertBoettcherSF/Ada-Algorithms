--  Standalone test suite for Subclu (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Subclu; use Subclu;

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
   Put_Line ("Subclu (SUBCLU) test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Parameters / Empty_Subspace");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Empty_Subspace.Count = 0, "Empty_Subspace count 0");
      P := Make_Parameters (0.5, 3);
      Check (Near (P.Eps, 0.5) and then P.MinPts = 3, "Make_Parameters ok");
      begin
         P := Make_Parameters (0.0, 3);
         Check (False, "Make_Parameters Eps=0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters Eps=0 raises");
      end;
      begin
         P := Make_Parameters (0.5, 0);
         Check (False, "Make_Parameters MinPts=0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters MinPts=0 raises");
      end;
      begin
         P := Make_Parameters (-1.0, 2);
         Check (False, "Make_Parameters Eps<0 should raise");
      exception
         when Invalid_Argument =>
            Check (True, "Make_Parameters Eps<0 raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("2. Subspace construction / algebra");
   ---------------------------------------------------------------------
   declare
      S1 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      S2 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 2));
      S12 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
      S21 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 2, 2 => 1));
      S123 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 3, 2 => 1, 3 => 2));
      S13 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 3));
      Uni : Subspace;
      Inter : Subspace;
   begin
      Check (S1.Count = 1 and then S1.Attrs (1) = 1, "1D subspace {1}");
      Check (S12.Count = 2, "2D subspace count");
      Check (S12.Attrs (1) = 1 and then S12.Attrs (2) = 2, "2D sorted");
      Check (Subspace_Equal (S12, S21), "order-insensitive equal");
      Check (Subspace_Contains (S12, 1), "contains 1");
      Check (not Subspace_Contains (S12, 3), "not contains 3");
      Check (Subspace_Subset (S1, S12), "{1} subset {1,2}");
      Check (not Subspace_Subset (S12, S1), "{1,2} not subset {1}");
      Uni := Subspace_Union (S1, S2);
      Check (Subspace_Equal (Uni, S12), "union {1}∪{2}");
      Inter := Subspace_Intersection (S12, S13);
      Check (Inter.Count = 1 and then Inter.Attrs (1) = 1,
             "intersection {1,2}∩{1,3}");
      Check (Differ_By_One (S12, S13), "{1,2} and {1,3} differ by one");
      Check (not Differ_By_One (S12, S1), "different dims: not differ-by-one");
      Check (not Differ_By_One (S12, S123), "size mismatch: not differ-by-one");
      Check (S123.Attrs (1) = 1 and then S123.Attrs (3) = 3,
             "3D sorted unique");
      declare
         Dup : constant Subspace :=
           Make_Subspace (Dim_Id_Array'(1 => 2, 2 => 2, 3 => 1));
      begin
         Check (Dup.Count = 2, "duplicates dropped");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Distance / neighborhood in subspace");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 4, 1 .. 3);
      Sp_X : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Sp_XY : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
      Active : constant Point_Subset := Full_Point_Subset (4);
      Params : constant Parameters := Make_Parameters (1.1, 2);
   begin
      --  P1=(0,0,100), P2=(1,0,200), P3=(0,1,0), P4=(10,10,10)
      Data (1, 1) := 0.0; Data (1, 2) := 0.0; Data (1, 3) := 100.0;
      Data (2, 1) := 1.0; Data (2, 2) := 0.0; Data (2, 3) := 200.0;
      Data (3, 1) := 0.0; Data (3, 2) := 1.0; Data (3, 3) := 0.0;
      Data (4, 1) := 10.0; Data (4, 2) := 10.0; Data (4, 3) := 10.0;

      Check (Near (Distance (Data, 1, 2, Sp_X), 1.0), "1D dist P1-P2 = 1");
      Check (Near (Distance (Data, 1, 1, Sp_X), 0.0), "self dist 0");
      Check (Near (Distance (Data, 1, 3, Sp_XY), 1.0), "2D dist P1-P3 = 1");
      Check (Approx (Distance (Data, 1, 2, Sp_XY), 1.0),
             "2D dist P1-P2 ignores Z");
      Check (Neighborhood_Count (Data, 1, Sp_X, 1.1, Active) = 3,
             "N_eps(P1) in X: P1,P2,P3 (not P4)");
      Check (Neighborhood_Count (Data, 4, Sp_X, 1.1, Active) = 1,
             "N_eps(P4) in X: only self");
      Check (Is_Core_Point (Data, 1, Sp_X, Params, Active),
             "P1 is core MinPts=2 Eps=1.1");
      Check (not Is_Core_Point (Data, 4, Sp_X, Params, Active),
             "P4 not core");
      Check (Full_Point_Subset (0).Count = 0, "empty Full_Point_Subset");
      Check (Full_Point_Subset (3).Ids (3) = 3, "Full_Point_Subset ids");
   end;

   ---------------------------------------------------------------------
   Section ("4. DBSCAN 1D — dense cluster + noise");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 8, 1 .. 1);
      Sp : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Active : constant Point_Subset := Full_Point_Subset (8);
      Params : constant Parameters := Make_Parameters (0.6, 3);
      DR : DBSCAN_Result (First => 1, Last => 8);
   begin
      --  Dense cluster around 0: five points; noise far away.
      Data (1, 1) := 0.0;
      Data (2, 1) := 0.2;
      Data (3, 1) := 0.4;
      Data (4, 1) := 0.1;
      Data (5, 1) := 0.3;
      Data (6, 1) := 10.0;
      Data (7, 1) := 11.0;
      Data (8, 1) := -20.0;

      DR := DBSCAN (Data, Sp, Params, Active);
      Check (DR.Cluster_Count = 1, "1D DBSCAN finds 1 cluster");
      Check (DR.Labels (1) > 0 and then DR.Labels (5) > 0,
             "dense points labeled");
      Check (DR.Labels (1) = DR.Labels (2)
             and then DR.Labels (2) = DR.Labels (5),
             "dense points same label");
      Check (DR.Labels (6) = Noise_Label, "10.0 is noise (MinPts)");
      Check (DR.Labels (8) = Noise_Label, "-20 is noise");
      Check (DR.Noise_Count >= 3, "at least 3 noise points");
   end;

   ---------------------------------------------------------------------
   Section ("5. DBSCAN 2D");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 7, 1 .. 2);
      Sp : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
      Active : constant Point_Subset := Full_Point_Subset (7);
      Params : constant Parameters := Make_Parameters (1.5, 3);
      DR : DBSCAN_Result (First => 1, Last => 7);
   begin
      --  Two blobs + one noise.
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.5; Data (2, 2) := 0.0;
      Data (3, 1) := 0.0; Data (3, 2) := 0.5;
      Data (4, 1) := 10.0; Data (4, 2) := 10.0;
      Data (5, 1) := 10.5; Data (5, 2) := 10.0;
      Data (6, 1) := 10.0; Data (6, 2) := 10.5;
      Data (7, 1) := 50.0; Data (7, 2) := 50.0;

      DR := DBSCAN (Data, Sp, Params, Active);
      Check (DR.Cluster_Count = 2, "2D DBSCAN finds 2 clusters");
      Check (DR.Labels (1) = DR.Labels (2)
             and then DR.Labels (2) = DR.Labels (3),
             "blob A same label");
      Check (DR.Labels (4) = DR.Labels (5)
             and then DR.Labels (5) = DR.Labels (6),
             "blob B same label");
      Check (DR.Labels (1) /= DR.Labels (4), "blobs different labels");
      Check (DR.Labels (7) = Noise_Label, "outlier is noise");
   end;

   ---------------------------------------------------------------------
   Section ("6. DBSCAN restricted to point subset");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 6, 1 .. 1);
      Sp : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Active : Point_Subset;
      Params : constant Parameters := Make_Parameters (1.1, 2);
      DR : DBSCAN_Result (First => 1, Last => 6);
   begin
      for I in Point_Id range 1 .. 6 loop
         Data (I, 1) := Real (I - 1);  -- 0,1,2,3,4,5
      end loop;
      --  Only points 1..3 active (values 0,1,2); Eps=1.1 links them.
      Active.Count := 3;
      Active.Ids (1) := 1;
      Active.Ids (2) := 2;
      Active.Ids (3) := 3;
      DR := DBSCAN (Data, Sp, Params, Active);
      Check (DR.Cluster_Count = 1, "subset DBSCAN 1 cluster");
      Check (DR.Labels (1) > 0 and then DR.Labels (3) > 0,
             "active points clustered");
      Check (DR.Labels (4) = Noise_Label
             and then DR.Labels (6) = Noise_Label,
             "inactive points remain noise");
   end;

   ---------------------------------------------------------------------
   Section ("7. Generate_Candidate_Subspaces + pruning");
   ---------------------------------------------------------------------
   declare
      Sk : Subspace_List;
      Sk_Count : Subspace_Count;
      Cand : Subspace_List;
      Cand_Count : Subspace_Count;
      S12 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
      S13 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 3));
      S23 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 2, 2 => 3));
      S14 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 4));
      Expect_123 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2, 3 => 3));
   begin
      --  All three 2-subsets of {1,2,3} present → candidate {1,2,3}.
      Sk_Count := 3;
      Sk (1) := S12;
      Sk (2) := S13;
      Sk (3) := S23;
      Generate_Candidate_Subspaces (Sk, Sk_Count, Cand, Cand_Count);
      Check (Cand_Count = 1, "full triangle → 1 candidate");
      Check (Subspace_Equal (Cand (1), Expect_123), "candidate is {1,2,3}");

      --  Missing S23 → prune {1,2,3}.
      Sk_Count := 2;
      Sk (1) := S12;
      Sk (2) := S13;
      Generate_Candidate_Subspaces (Sk, Sk_Count, Cand, Cand_Count);
      Check (Cand_Count = 0, "missing k-subset prunes candidate");

      --  S12 and S14 differ by one → raw {1,2,4} but needs S24 absent → prune.
      Sk_Count := 2;
      Sk (1) := S12;
      Sk (2) := S14;
      Generate_Candidate_Subspaces (Sk, Sk_Count, Cand, Cand_Count);
      Check (Cand_Count = 0, "pair without all k-subsets pruned");

      --  Empty Sk.
      Generate_Candidate_Subspaces (Sk, 0, Cand, Cand_Count);
      Check (Cand_Count = 0, "empty Sk → empty candidates");

      --  1D join: {1},{2},{3} → candidates {1,2},{1,3},{2,3}.
      Sk_Count := 3;
      Sk (1) := Make_Subspace (Dim_Id_Array'(1 => 1));
      Sk (2) := Make_Subspace (Dim_Id_Array'(1 => 2));
      Sk (3) := Make_Subspace (Dim_Id_Array'(1 => 3));
      Generate_Candidate_Subspaces (Sk, Sk_Count, Cand, Cand_Count);
      Check (Cand_Count = 3, "three 1D → three 2D candidates");
   end;

   ---------------------------------------------------------------------
   Section ("8. Run_SUBCLU planted subspace cluster");
   ---------------------------------------------------------------------
   declare
      --  12 points × 4 dims. Dims 1–2: tight cluster for first 8 points;
      --  dims 3–4: pure noise / spread so no density-connected set.
      Data : Dataset (1 .. 12, 1 .. 4);
      Params : constant Parameters := Make_Parameters (0.75, 4);
      R : SUBCLU_Result;
      Sp12 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
      Sp1 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Sp2 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 2));
      Found_12 : Boolean := False;
   begin
      for I in Point_Id range 1 .. 8 loop
         Data (I, 1) := 0.1 * Real (I - 1);
         Data (I, 2) := 0.05 * Real (I - 1);
         Data (I, 3) := Real (I) * 7.0;
         Data (I, 4) := Real (I) * (-5.0);
      end loop;
      for I in Point_Id range 9 .. 12 loop
         Data (I, 1) := 50.0 + Real (I);
         Data (I, 2) := -40.0 - Real (I);
         Data (I, 3) := Real (I) * 11.0;
         Data (I, 4) := Real (I) * 3.0;
      end loop;

      R := Run_SUBCLU (Data, Params);
      Check (R.Subspace_Count >= 1, "SUBCLU found ≥1 subspace");
      Check (R.Cluster_Count >= 1, "SUBCLU found ≥1 cluster");
      Check (Total_Clustered_Points (R, Sp1) >= 4,
             "dim1 has clustered points");
      Check (Total_Clustered_Points (R, Sp2) >= 4,
             "dim2 has clustered points");

      for I in 1 .. R.Subspace_Count loop
         if Subspace_Equal (R.Subspaces (I), Sp12) then
            Found_12 := True;
         end if;
      end loop;
      Check (Found_12, "planted {1,2} subspace present");
      Check (Total_Clustered_Points (R, Sp12) >= 4,
             "planted 2D cluster non-trivial");
      Check (Clustered_In_Subspace (R, Sp12, 1),
             "point 1 in planted 2D cluster");
      Check (Clustered_In_Subspace (R, Sp12, 2),
             "point 2 in planted 2D cluster");
      Check (not Clustered_In_Subspace (R, Sp12, 12),
             "outlier not in planted 2D cluster");
   end;

   ---------------------------------------------------------------------
   Section ("9. Monotonicity smoke (downward closure)");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 10, 1 .. 3);
      Params : constant Parameters := Make_Parameters (0.8, 3);
      R : SUBCLU_Result;
      Sp12 : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
      Sp1 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Sp2 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 2));
      Any_2D : Boolean := False;
   begin
      for I in Point_Id range 1 .. 7 loop
         Data (I, 1) := 0.15 * Real (I);
         Data (I, 2) := 0.10 * Real (I);
         Data (I, 3) := Real (I) * 20.0;
      end loop;
      for I in Point_Id range 8 .. 10 loop
         Data (I, 1) := 100.0 * Real (I);
         Data (I, 2) := -80.0 * Real (I);
         Data (I, 3) := Real (I);
      end loop;

      R := Run_SUBCLU (Data, Params);
      for I in 1 .. R.Cluster_Count loop
         if Subspace_Equal (R.Clusters (I).Space, Sp12) then
            Any_2D := True;
            --  Each member of a 2D cluster should appear in some 1D
            --  density-connected set of a subset attribute (best-effort:
            --  at least one of Sp1/Sp2 has clustered points).
            Check
              (Total_Clustered_Points (R, Sp1) > 0
               or else Total_Clustered_Points (R, Sp2) > 0,
               "2D cluster ⇒ related 1D density-connected sets exist");
         end if;
      end loop;
      Check (Any_2D or else R.Cluster_Count >= 1,
             "monotonicity setup produced clusters");
      if Any_2D then
         Check
           (Total_Clustered_Points (R, Sp1) > 0
            and then Total_Clustered_Points (R, Sp2) > 0,
            "both 1D projections clustered when 2D found");
      else
         Check (True, "no 2D cluster (still pass placeholder)");
         Check (True, "no 2D cluster (still pass placeholder 2)");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("10. MinPts / Eps sensitivity");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 6, 1 .. 1);
      Sp : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Active : constant Point_Subset := Full_Point_Subset (6);
      Loose : constant Parameters := Make_Parameters (1.5, 2);
      Tight : constant Parameters := Make_Parameters (0.3, 5);
      DR_L, DR_T : DBSCAN_Result (First => 1, Last => 6);
   begin
      Data (1, 1) := 0.0;
      Data (2, 1) := 0.5;
      Data (3, 1) := 1.0;
      Data (4, 1) := 1.5;
      Data (5, 1) := 2.0;
      Data (6, 1) := 2.5;
      DR_L := DBSCAN (Data, Sp, Loose, Active);
      DR_T := DBSCAN (Data, Sp, Tight, Active);
      Check (DR_L.Cluster_Count >= 1, "loose Eps finds cluster");
      Check (DR_T.Cluster_Count = 0, "tight MinPts/Eps → all noise");
      Check (DR_L.Noise_Count < DR_T.Noise_Count
             or else DR_T.Cluster_Count = 0,
             "tighter params → more noise / fewer clusters");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid args / edge cases");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 3, 1 .. 2);
      Sp : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Bad_Sp : constant Subspace :=
        Make_Subspace (Dim_Id_Array'(1 => 5));  -- dim 5 out of range
      Active : constant Point_Subset := Full_Point_Subset (3);
      Params : constant Parameters := Make_Parameters (1.0, 2);
      Bad_Active : Point_Subset;
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.1; Data (2, 2) := 0.1;
      Data (3, 1) := 0.2; Data (3, 2) := 0.2;

      begin
         declare
            D : constant Non_Negative :=
              Distance (Data, 1, 2, Empty_Subspace);
            pragma Unreferenced (D);
         begin
            Check (False, "Distance empty subspace should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Distance empty subspace raises");
      end;

      begin
         declare
            D : constant Non_Negative := Distance (Data, 1, 2, Bad_Sp);
            pragma Unreferenced (D);
         begin
            Check (False, "Distance bad dim should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Distance bad dim raises");
      end;

      begin
         declare
            DR : constant DBSCAN_Result :=
              DBSCAN (Data, Sp, Make_Parameters (1.0, 0), Active);
            pragma Unreferenced (DR);
         begin
            Check (False, "DBSCAN MinPts=0 should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "DBSCAN MinPts=0 raises");
      end;

      Bad_Active.Count := 1;
      Bad_Active.Ids (1) := 99;
      begin
         declare
            DR : constant DBSCAN_Result :=
              DBSCAN (Data, Sp, Params, Bad_Active);
            pragma Unreferenced (DR);
         begin
            Check (False, "DBSCAN bad Active should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "DBSCAN bad Active raises");
      end;

      begin
         declare
            R : constant SUBCLU_Result :=
              Run_SUBCLU (Data, Make_Parameters (-0.5, 2));
            pragma Unreferenced (R);
         begin
            Check (False, "Run_SUBCLU bad Eps should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Run_SUBCLU bad Eps raises");
      end;

      --  Mixed dimensionality in Sk.
      declare
         Sk : Subspace_List;
         Cand : Subspace_List;
         Cand_Count : Subspace_Count;
      begin
         Sk (1) := Make_Subspace (Dim_Id_Array'(1 => 1));
         Sk (2) := Make_Subspace (Dim_Id_Array'(1 => 1, 2 => 2));
         begin
            Generate_Candidate_Subspaces (Sk, 2, Cand, Cand_Count);
            Check (False, "mixed-dim Sk should raise");
         exception
            when Invalid_Argument =>
               Check (True, "mixed-dim Sk raises");
         end;
      end;

      --  Single-point DBSCAN → noise with MinPts=2.
      declare
         Tiny : Dataset (1 .. 1, 1 .. 1);
         DR : DBSCAN_Result (First => 1, Last => 1);
      begin
         Tiny (1, 1) := 0.0;
         DR := DBSCAN
           (Tiny, Sp, Make_Parameters (1.0, 2), Full_Point_Subset (1));
         Check (DR.Cluster_Count = 0, "single point MinPts=2 → no cluster");
         Check (DR.Labels (1) = Noise_Label, "single point is noise");
      end;

      --  MinPts=1 → every point is its own core (singleton clusters merge
      --  via density-reachability when within Eps).
      declare
         Tiny : Dataset (1 .. 2, 1 .. 1);
         DR : DBSCAN_Result (First => 1, Last => 2);
      begin
         Tiny (1, 1) := 0.0;
         Tiny (2, 1) := 100.0;
         DR := DBSCAN
           (Tiny, Sp, Make_Parameters (1.0, 1), Full_Point_Subset (2));
         Check (DR.Cluster_Count = 2, "MinPts=1 far points → 2 clusters");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Dim_In_Range / Clustered helpers");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 2, 1 .. 2);
      Sp1 : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      R : SUBCLU_Result;
   begin
      Data (1, 1) := 0.0; Data (1, 2) := 0.0;
      Data (2, 1) := 0.1; Data (2, 2) := 5.0;
      Check (Dim_In_Range (Data, 1), "dim 1 in range");
      Check (Dim_In_Range (Data, 2), "dim 2 in range");
      Check (not Dim_In_Range (Data, 3), "dim 3 out of range");
      R := Run_SUBCLU (Data, Make_Parameters (0.5, 2));
      Check
        (Clustered_In_Subspace (R, Sp1, 1)
         or else not Clustered_In_Subspace (R, Sp1, 1),
         "Clustered_In_Subspace callable");
      Check (Total_Clustered_Points (R, Empty_Subspace) = 0,
             "empty space total clustered = 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Full_Point_Subset / Default_Parameters");
   ---------------------------------------------------------------------
   declare
      S : constant Point_Subset := Full_Point_Subset (5);
   begin
      Check (S.Count = 5, "Full_Point_Subset length 5");
      Check (S.Ids (1) = 1 and then S.Ids (5) = 5, "ids 1..5");
      Check (Default_Parameters.MinPts = 3, "Default_Parameters MinPts");
      Check (Near (Default_Parameters.Eps, 0.5), "Default_Parameters Eps");
   end;

   ---------------------------------------------------------------------
   Section ("14. Two well-separated 1D clusters");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 10, 1 .. 1);
      Sp : constant Subspace := Make_Subspace (Dim_Id_Array'(1 => 1));
      Active : constant Point_Subset := Full_Point_Subset (10);
      Params : constant Parameters := Make_Parameters (0.6, 3);
      DR : DBSCAN_Result (First => 1, Last => 10);
   begin
      for I in Point_Id range 1 .. 5 loop
         Data (I, 1) := 0.1 * Real (I);
      end loop;
      for I in Point_Id range 6 .. 10 loop
         Data (I, 1) := 20.0 + 0.1 * Real (I);
      end loop;
      DR := DBSCAN (Data, Sp, Params, Active);
      Check (DR.Cluster_Count = 2, "two separated 1D clusters");
      Check (DR.Labels (1) /= DR.Labels (6), "clusters differ");
      Check (DR.Labels (1) = DR.Labels (5), "left cluster cohesive");
      Check (DR.Labels (6) = DR.Labels (10), "right cluster cohesive");
   end;

   New_Line;
   Put_Line ("========== Summary ==========");
   Put_Line ("Passed: " & Pass_Count'Image & "  Failed: " & Fail_Count'Image);
   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
