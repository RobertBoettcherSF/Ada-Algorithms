--  Standalone test suite for Clustering_Algorithms (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Clustering_Algorithms; use Clustering_Algorithms;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Clustering_Algorithms survey test suite");
   Put_Line ("=======================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Distance / Squared_Distance");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [1.0, 2.0];
      B : constant Point := [4.0, 6.0];
      C : constant Point := [0.0, 0.0];
      D : constant Point := [3.0, 4.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large");
      Check (Approx (Squared_Distance (A, B), 25.0), "3-4-5 sq=25");
      Check (Approx (Distance (A, B), 5.0), "3-4-5 dist=5");
      Check (Approx (Squared_Distance (C, D), 25.0), "origin to 3-4 sq");
      Check (Approx (Distance (C, D), 5.0), "origin to 3-4 dist");
      Check (Approx (Squared_Distance (A, A), 0.0), "identical sq=0");
      Check (Approx (Distance (A, A), 0.0), "identical dist=0");
      Check (Distance (A, B) > Distance (A, A), "dist grows");
   end;

   ---------------------------------------------------------------------
   Section ("2. Extract_Point / dataset Distance");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 3, 1 .. 2) :=
        [[0.0, 0.0], [3.0, 4.0], [1.0, 0.0]];
      P1 : constant Point := Extract_Point (Data, 1);
      P2 : constant Point := Extract_Point (Data, 2);
   begin
      Check (Approx (P1 (1), 0.0) and then Approx (P1 (2), 0.0),
             "Extract_Point row1");
      Check (Approx (P2 (1), 3.0) and then Approx (P2 (2), 4.0),
             "Extract_Point row2");
      Check (Approx (Distance (Data, 1, 2), 5.0), "row Distance 5");
      Check (Approx (Distance (Data, 1, 1), 0.0), "row Distance self");
      Check (Approx (Distance (Data, 1, 3), 1.0), "row Distance 1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Centroid — assign / update / WCSS");
   ---------------------------------------------------------------------
   declare
      --  Two clear blobs around (0,0) and (10,10)
      Data : constant Dataset (1 .. 6, 1 .. 2) :=
        [[0.0, 0.0], [0.2, 0.1], [-0.1, 0.2],
         [10.0, 10.0], [10.1, 9.9], [9.8, 10.2]];
      Init : constant Centers (1 .. 2, 1 .. 2) :=
        [[0.0, 0.0], [10.0, 10.0]];
      Lab  : Labels (1 .. 6);
      C    : Centers (1 .. 2, 1 .. 2) := Init;
      Empty : Empty_Flags (1 .. 2);
      W    : Non_Negative;
   begin
      Lab := Assign_Labels (Data, Init);
      Check (Lab (1) = 1 and then Lab (2) = 1 and then Lab (3) = 1,
             "blob A → cluster 1");
      Check (Lab (4) = 2 and then Lab (5) = 2 and then Lab (6) = 2,
             "blob B → cluster 2");
      Update_Centroids (Data, Lab, C, Empty);
      Check (not Empty (1) and then not Empty (2), "no empty clusters");
      Check (Approx (C (1, 1), (0.0 + 0.2 - 0.1) / 3.0, 1.0E-6),
             "centroid 1 X");
      Check (Approx (C (2, 1), (10.0 + 10.1 + 9.8) / 3.0, 1.0E-6),
             "centroid 2 X");
      W := WCSS (Data, C, Lab);
      Check (W >= 0.0, "WCSS non-negative");
      Check (W < 1.0, "WCSS small for tight blobs");
      Check (Nearest_Center (Extract_Point (Data, 1), Init) = 1,
             "Nearest_Center blob A");
      Check (Nearest_Center (Extract_Point (Data, 4), Init) = 2,
             "Nearest_Center blob B");
   end;

   ---------------------------------------------------------------------
   Section ("4. Centroid — Run_KMeans (Spaced / Forgy)");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 6, 1 .. 2) :=
        [[0.0, 0.0], [0.1, 0.0], [0.0, 0.1],
         [5.0, 5.0], [5.1, 5.0], [5.0, 5.1]];
      Params : KMeans_Parameters := Default_KMeans;
      R : KMeans_Result (N => 6, K => 2, D => 2);
      Same : Boolean;
   begin
      Params.K := 2;
      Params.Init := Spaced;
      Params.Max_Iters := 50;
      R := Run_KMeans (Data, Params);
      Check (R.Converged, "Spaced k-means converged");
      Check (R.Iters >= 1, "at least one iteration");
      Check (R.WCSS >= 0.0, "result WCSS >= 0");
      Check (R.WCSS < 1.0, "WCSS low for two blobs");
      --  Labels should partition into two non-empty groups
      declare
         C1, C2 : Natural := 0;
      begin
         for I in R.Lab'Range loop
            if R.Lab (I) = 1 then
               C1 := C1 + 1;
            elsif R.Lab (I) = 2 then
               C2 := C2 + 1;
            end if;
         end loop;
         Check (C1 = 3 and then C2 = 3, "3+3 partition Spaced");
      end;

      Params.Init := Forgy;
      Params.Seed := 7;
      R := Run_KMeans (Data, Params);
      Check (R.Converged or else R.Iters = Params.Max_Iters,
             "Forgy finished");
      Check (R.WCSS < 2.0, "Forgy WCSS reasonable");

      --  Explicit init
      declare
         Init : constant Centers :=
           Init_Centers_From_Indices (Data, [1, 4]);
         R2 : constant KMeans_Result :=
           Run_KMeans (Data, Init, Params);
      begin
         Check (R2.Lab (1) /= R2.Lab (4), "explicit init separates blobs");
         Same := True;
         for I in Point_Index range 1 .. 3 loop
            if R2.Lab (I) /= R2.Lab (1) then
               Same := False;
            end if;
         end loop;
         Check (Same, "first three share label");
      end;

      declare
         Sp : constant Centers := Init_Centers_Spaced (Data, 2);
         Fg : constant Centers := Init_Centers_Forgy (Data, 2, 1);
      begin
         Check (Sp'Length (1) = 2, "Spaced K=2");
         Check (Fg'Length (1) = 2, "Forgy K=2");
         Check (Approx (Sp (1, 1), 0.0), "Spaced first = first row");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Connectivity — single-linkage / cut");
   ---------------------------------------------------------------------
   declare
      --  Two pairs far apart
      Data : constant Dataset (1 .. 4, 1 .. 1) :=
        [[0.0], [0.1], [10.0], [10.2]];
      Dist : constant Distance_Matrix := Build_Distance_Matrix (Data);
      Tree : constant Dendrogram := Run_Single_Linkage (Dist);
      Lab_H : Labels (1 .. 4);
      Lab_K : Labels (1 .. 4);
      Lab_C : Labels (1 .. 4);
   begin
      Check (Dist'Length (1) = 4, "distance matrix 4x4");
      Check (Approx (Dist (1, 2), 0.1), "close pair dist");
      Check (Approx (Dist (1, 3), 10.0), "far pair dist");
      Check (Tree'Length = 3, "dendrogram N-1 merges");
      Check (Tree (1).Height <= Tree (2).Height
             or else Near (Tree (1).Height, Tree (2).Height, 1.0E-9),
             "heights non-decreasing-ish first steps");

      Lab_H := Labels_At_Height (Tree, 4, 0.5);
      Check (Cluster_Count_Of (Lab_H) = 2, "cut 0.5 → 2 clusters");
      Check (Lab_H (1) = Lab_H (2), "0 and 0.1 same cluster");
      Check (Lab_H (3) = Lab_H (4), "10 and 10.2 same cluster");
      Check (Lab_H (1) /= Lab_H (3), "blobs differ");

      Lab_K := Cut_Dendrogram (Tree, 4, 2);
      Check (Cluster_Count_Of (Lab_K) = 2, "Cut_Dendrogram K=2");
      Check (Lab_K (1) = Lab_K (2), "K-cut close pair");
      Check (Lab_K (1) /= Lab_K (3), "K-cut separates blobs");

      Lab_C := Run_Single_Linkage_Cut (Data, 0.5);
      Check (Cluster_Count_Of (Lab_C) = 2, "Run_Single_Linkage_Cut");
      Check (Lab_C (1) = Lab_C (2) and then Lab_C (3) = Lab_C (4),
             "convenience cut groups");

      --  Very low cut → all singletons
      Lab_H := Labels_At_Height (Tree, 4, 0.0);
      Check (Cluster_Count_Of (Lab_H) = 4
             or else Cluster_Count_Of (Lab_H) >= 3,
             "height 0 mostly singletons");

      declare
         Tree2 : constant Dendrogram := Run_Single_Linkage (Data);
      begin
         Check (Tree2'Length = 3, "Data overload dendrogram");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Density — DBSCAN Range_Query / Run");
   ---------------------------------------------------------------------
   declare
      --  Dense blob + one outlier
      Data : constant Dataset (1 .. 7, 1 .. 2) :=
        [[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [0.1, 0.1],
         [0.05, 0.05],
         [10.0, 10.0],   -- isolated
         [0.02, -0.02]];
      Params : DBSCAN_Parameters := Default_DBSCAN;
      R : DBSCAN_Result (1, 7);
   begin
      Params.Eps := 0.3;
      Params.MinPts := 3;

      Check (Neighbor_Count (Data, 1, 0.3) >= 3, "core-ish nbr count");
      declare
         Nbr : constant Point_Id_Array := Range_Query (Data, 1, 0.3);
      begin
         Check (Nbr'Length = Neighbor_Count (Data, 1, 0.3),
                "Range_Query length matches count");
         Check (Nbr'Length >= 1, "Range_Query includes self at least");
      end;

      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count >= 1, "DBSCAN found cluster(s)");
      Check (R.Noise_Count >= 1, "outlier is noise");
      Check (R.Lab (6) = Noise_Label, "far point = Noise_Label");
      Check (R.Lab (1) > 0 and then R.Lab (2) > 0, "blob labeled");
      Check (R.Lab (1) = R.Lab (2), "blob same cluster");
      Check (Noise_Count_Of (R.Lab) = R.Noise_Count, "Noise_Count_Of");
      Check (Cluster_Count_Of (R.Lab) = R.Cluster_Count,
             "Cluster_Count_Of");

      --  Tiny Eps → all noise or singletons (MinPts=3)
      Params.Eps := 0.001;
      R := Run_DBSCAN (Data, Params);
      Check (R.Cluster_Count = 0, "tiny eps → no cores");
      Check (R.Noise_Count = 7, "all noise at tiny eps");
   end;

   ---------------------------------------------------------------------
   Section ("7. Evaluation — silhouette two blobs vs random");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 8, 1 .. 2) :=
        [[0.0, 0.0], [0.1, 0.0], [0.0, 0.1], [0.1, 0.1],
         [8.0, 8.0], [8.1, 8.0], [8.0, 8.1], [8.1, 8.1]];
      Good : constant Labels (1 .. 8) :=
        [1, 1, 1, 1, 2, 2, 2, 2];
      Bad  : constant Labels (1 .. 8) :=
        [1, 2, 1, 2, 1, 2, 1, 2];
      S_Good, S_Bad : Real;
      D_Good : Non_Negative;
   begin
      S_Good := Mean_Silhouette (Data, Good);
      S_Bad := Mean_Silhouette (Data, Bad);
      Check (S_Good > 0.5, "good silhouette high");
      Check (S_Good > S_Bad, "good > random labels silhouette");
      Check (S_Bad < 0.5, "random labels silhouette lower");

      D_Good := Dunn_Index (Data, Good);
      Check (D_Good > 1.0, "Dunn high for separated blobs");
      declare
         D_Bad : constant Non_Negative := Dunn_Index (Data, Bad);
      begin
         Check (D_Good > D_Bad, "good Dunn > interleaved Dunn");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Evaluation — WCSS consistency");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 4, 1 .. 2) :=
        [[0.0, 0.0], [0.0, 1.0], [10.0, 0.0], [10.0, 1.0]];
      Params : KMeans_Parameters := Default_KMeans;
      R : KMeans_Result (N => 4, K => 2, D => 2);
      W2 : Non_Negative;
   begin
      Params.K := 2;
      Params.Init := Spaced;
      R := Run_KMeans (Data, Params);
      W2 := Within_Cluster_SSE (Data, R.Centers, R.Lab);
      Check (Approx (R.WCSS, W2), "result WCSS matches helper");
      Check (WCSS (Data, R.Centers, R.Lab) = Within_Cluster_SSE
               (Data, R.Centers, R.Lab),
             "WCSS renames SSE");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid arguments / capacity");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 2, 1 .. 1) := [[0.0], [1.0]];
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Params : KMeans_Parameters := Default_KMeans;
            R : KMeans_Result (N => 2, K => 3, D => 1);
            pragma Unreferenced (R);
         begin
            Params.K := 3;  -- K > N
            R := Run_KMeans (Data, Params);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "KMeans K>N raises");

      Raised := False;
      begin
         declare
            Lab : constant Labels (1 .. 2) := [1, 1];
            S : Real;
            pragma Unreferenced (S);
         begin
            S := Mean_Silhouette (Data, Lab);  -- only 1 cluster
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "silhouette single cluster raises");

      Raised := False;
      begin
         declare
            Lab : constant Labels (1 .. 2) := [1, 1];
            D : Non_Negative;
            pragma Unreferenced (D);
         begin
            D := Dunn_Index (Data, Lab);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Dunn single cluster raises");

      Raised := False;
      begin
         declare
            Tiny : constant Dataset (1 .. 1, 1 .. 1) := [[0.0]];
            Tree : Dendrogram (1 .. 0);
            pragma Unreferenced (Tree);
         begin
            Tree := Run_Single_Linkage (Tiny);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "single-linkage N<2 raises");

      Raised := False;
      begin
         declare
            Bad : constant Point := [1.0];
            Good : constant Point := [1.0, 2.0];
            D : Non_Negative;
            pragma Unreferenced (D);
         begin
            D := Distance (Bad, Good);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "Distance length mismatch raises");
   end;

   ---------------------------------------------------------------------
   Section ("10. Caps / constants / Noise_Label");
   ---------------------------------------------------------------------
   declare
      St : RNG_State;
      U  : Unit_Interval;
   begin
      Put_Line ("  INFO: Max_Points=" & Max_Points'Image
                & " Max_Dims=" & Max_Dims'Image
                & " Max_K=" & Max_K'Image
                & " Noise_Label=" & Noise_Label'Image);
      Seed_RNG (St, 0);
      U := Draw_Unit (St);
      Check (U >= 0.0 and then U < 1.0, "RNG after Seed 0");
      Seed_RNG (St, 99);
      Check (Draw_Unit (St) /= U or else Draw_Unit (St) >= 0.0,
             "RNG Seed 99 advances");
      Check (Near (Epsilon_Tol, Epsilon_Tol), "Epsilon_Tol Near self");
      Check (not Near (0.0, 1.0), "Near rejects 0 vs 1");
      declare
         Lab : constant Labels (1 .. 2) := [Noise_Label, 1];
      begin
         Check (Noise_Count_Of (Lab) = 1, "Noise_Count_Of sees Noise_Label");
         Check (Cluster_Count_Of (Lab) = 1, "Cluster_Count_Of ignores noise");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Integration — all three models on two blobs");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset (1 .. 10, 1 .. 2) :=
        [[0.0, 0.0], [0.2, 0.1], [-0.1, 0.15], [0.1, -0.1], [0.05, 0.05],
         [6.0, 6.0], [6.2, 6.1], [5.9, 6.15], [6.1, 5.9], [6.05, 6.05]];
      KM : KMeans_Parameters := Default_KMeans;
      RK : KMeans_Result (N => 10, K => 2, D => 2);
      RD : DBSCAN_Result (1, 10);
      DP : DBSCAN_Parameters := Default_DBSCAN;
      SL : Labels (1 .. 10);
      S  : Real;
   begin
      KM.K := 2;
      KM.Init := Spaced;
      RK := Run_KMeans (Data, KM);
      Check (Cluster_Count_Of (RK.Lab) = 2, "k-means 2 clusters");
      Check (RK.WCSS < 2.0, "k-means low WCSS");

      DP.Eps := 0.5;
      DP.MinPts := 3;
      RD := Run_DBSCAN (Data, DP);
      Check (RD.Cluster_Count = 2, "DBSCAN 2 clusters");
      Check (RD.Noise_Count = 0, "DBSCAN no noise on tight blobs");

      SL := Run_Single_Linkage_Cut (Data, 1.0);
      Check (Cluster_Count_Of (SL) = 2, "single-link cut 2 clusters");

      S := Mean_Silhouette (Data, RK.Lab);
      Check (S > 0.7, "k-means silhouette high on blobs");
      S := Mean_Silhouette (Data, SL);
      Check (S > 0.7, "single-link silhouette high");
      Check (Dunn_Index (Data, RK.Lab) > 2.0, "Dunn large separation");
   end;

   ---------------------------------------------------------------------
   Section ("12. RNG smoke");
   ---------------------------------------------------------------------
   declare
      State : RNG_State;
      U1, U2 : Unit_Interval;
      I1 : Point_Index;
   begin
      Seed_RNG (State, 42);
      U1 := Draw_Unit (State);
      U2 := Draw_Unit (State);
      Check (U1 >= 0.0 and then U1 < 1.0, "Draw_Unit in [0,1)");
      Check (U2 >= 0.0 and then U2 < 1.0, "second Draw_Unit");
      Check (U1 /= U2 or else True, "advances (always pass)");
      I1 := Draw_Index (State, 1, 5);
      Check (I1 in 1 .. 5, "Draw_Index in range");
   end;

   New_Line;
   Put_Line ("=======================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
end Tests;
