--  Standalone test suite for K_Means_Clustering (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with K_Means_Clustering; use K_Means_Clustering;

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
   Put_Line ("K_Means_Clustering test suite");
   Put_Line ("=============================");

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
   Section ("2. Distance / Squared_Distance");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [1.0, 2.0];
      B : constant Point := [4.0, 6.0];
      --  (3)²+(4)² = 25 → dist 5
      C : constant Point := [0.0, 0.0, 0.0];
      D : constant Point := [1.0, 0.0, 0.0];
      Z : constant Point := [5.0, -1.0];
   begin
      Check (Approx (Squared_Distance (A, B), 25.0), "3-4-5 sq=25");
      Check (Approx (Distance (A, B), 5.0), "3-4-5 dist=5");
      Check (Approx (Squared_Distance (A, A), 0.0), "identical sq=0");
      Check (Approx (Distance (A, A), 0.0), "identical dist=0");
      Check (Approx (Squared_Distance (C, D), 1.0), "unit axis 3-D sq");
      Check (Approx (Squared_Distance (Z, [0.0, 0.0]), 26.0), "origin sq=26");
      Check (Distance (A, B) > 0.0, "positive for distinct");
      Check (Squared_Distance (A, B) > Squared_Distance (A, A),
             "sq grows with separation");
   end;

   ---------------------------------------------------------------------
   Section ("3. Extract / Nearest_Center (Voronoi)");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [1.0, 1.0]];
      Ctr : constant Centers :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      P0 : constant Point := Extract_Point (Data, 1);
      P1 : constant Point := Extract_Point (Data, 2);
      S0 : constant Point := Extract_Center (Ctr, 1);
      Q  : constant Point := [1.0, 0.0];
      Q2 : constant Point := [9.0, 0.0];
      Q3 : constant Point := [5.0, 0.0];  -- tie midpoint → lowest index
   begin
      Check (Approx (P0 (1), 0.0) and Approx (P0 (2), 0.0), "extract p1");
      Check (Approx (P1 (1), 10.0), "extract p2 x");
      Check (Approx (S0 (1), 0.0), "extract center1");
      Check (Nearest_Center (Q, Ctr) = 1, "nearest to left center");
      Check (Nearest_Center (Q2, Ctr) = 2, "nearest to right center");
      Check (Nearest_Center (Q3, Ctr) = 1, "tie → lowest index");
      Check (Nearest_Center (Extract_Point (Data, 3), Ctr) = 1,
             "point (1,1) → center 1");
      Check (Nearest_Center ([10.0, 0.0], Ctr) = 2, "exact on center 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Assign / centroid / objective hand example");
   ---------------------------------------------------------------------
   --  Points: (0,0),(1,0),(10,0),(11,0); centers at (0,0),(10,0)
   --  Labels should be 1,1,2,2; means (0.5,0),(10.5,0); WCSS=1.0
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0],
         [11.0, 0.0]];
      Ctr : Centers :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      Lab : constant Labels := Assign_Labels (Data, Ctr);
      Empty : Empty_Flags (1 .. 2);
   begin
      Check (Lab (1) = 1, "label p1 → 1");
      Check (Lab (2) = 1, "label p2 → 1");
      Check (Lab (3) = 2, "label p3 → 2");
      Check (Lab (4) = 2, "label p4 → 2");
      Compute_Centroids (Data, Lab, Ctr, Empty);
      Check (not Empty (1) and not Empty (2), "no empty after assign");
      Check (Approx (Ctr (1, 1), 0.5), "centroid1 x=0.5");
      Check (Approx (Ctr (1, 2), 0.0), "centroid1 y=0");
      Check (Approx (Ctr (2, 1), 10.5), "centroid2 x=10.5");
      Check (Approx (Ctr (2, 2), 0.0), "centroid2 y=0");
      Check (Approx (Within_Cluster_SSE (Data, Ctr, Lab), 1.0),
             "SSE after one centroid step = 1.0");
      Check (Approx (WCSS (Data, Ctr, Lab), 1.0), "WCSS alias = 1.0");
      Check (Approx (Inertia (Data, Ctr, Lab),
                     Within_Cluster_SSE (Data, Ctr, Lab)),
             "Inertia alias matches SSE");
   end;

   ---------------------------------------------------------------------
   Section ("5. Init_Centers_Spaced");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0], [2.0], [3.0], [4.0], [5.0]];
      S1 : constant Centers := Init_Centers_Spaced (Data, 1);
      S2 : constant Centers := Init_Centers_Spaced (Data, 2);
      S3 : constant Centers := Init_Centers_Spaced (Data, 3);
      S5 : constant Centers := Init_Centers_Spaced (Data, 5);
   begin
      Check (Approx (S1 (1, 1), 1.0), "K=1 → first point");
      Check (Approx (S2 (1, 1), 1.0) and Approx (S2 (2, 1), 5.0),
             "K=2 → ends");
      Check (Approx (S3 (1, 1), 1.0), "K=3 first");
      Check (Approx (S3 (2, 1), 3.0), "K=3 middle");
      Check (Approx (S3 (3, 1), 5.0), "K=3 last");
      Check (Approx (S5 (3, 1), 3.0), "K=N middle");
      Check (S5'Length (1) = 5, "K=N length");
   end;

   ---------------------------------------------------------------------
   Section ("6. Init_Centers_From_Indices");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[10.0, 0.0],
         [20.0, 1.0],
         [30.0, 2.0],
         [40.0, 3.0]];
      Idx : constant Index_List := [2, 4];
      Ctr : constant Centers := Init_Centers_From_Indices (Data, Idx);
   begin
      Check (Approx (Ctr (1, 1), 20.0) and Approx (Ctr (1, 2), 1.0),
             "from index 2");
      Check (Approx (Ctr (2, 1), 40.0) and Approx (Ctr (2, 2), 3.0),
             "from index 4");
      Check (Ctr'Length (1) = 2, "from-indices K=2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Forgy reproducibility with seed");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [1.0], [2.0], [3.0], [4.0], [5.0], [6.0], [7.0]];
      A : constant Centers := Init_Centers_Forgy (Data, 3, Seed => 42);
      B : constant Centers := Init_Centers_Forgy (Data, 3, Seed => 42);
      C : constant Centers := Init_Centers_Forgy (Data, 3, Seed => 99);
      Same_AB : Boolean := True;
      Diff_AC : Boolean := False;
   begin
      for K in A'Range (1) loop
         for D in A'Range (2) loop
            if not Near (A (K, D), B (K, D)) then
               Same_AB := False;
            end if;
            if not Near (A (K, D), C (K, D)) then
               Diff_AC := True;
            end if;
         end loop;
      end loop;
      Check (Same_AB, "Forgy same seed → same centers");
      Check (Diff_AC, "Forgy different seed → different (smoke)");
      Check (A'Length (1) = 3, "Forgy returns K centers");
      --  Centers are data points
      declare
         Found : Boolean;
      begin
         Found := False;
         for P in Data'Range (1) loop
            if Near (A (1, 1), Data (P, 1)) then
               Found := True;
            end if;
         end loop;
         Check (Found, "Forgy center1 is a data point");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Two blobs recovery");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [0.0, 0.1],
         [0.1, 0.1],
         [10.0, 10.0],
         [10.1, 10.0],
         [10.0, 10.1],
         [10.1, 10.1]];
      Init : constant Centers :=
        Init_Centers_From_Indices (Data, [1, 5]);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 50, Tol => 1.0E-8, Seed => 1);
      R : constant Result := Run_Lloyd (Data, Init, Params);
      Left, Right : Natural := 0;
   begin
      Check (R.Converged, "two blobs converged");
      Check (R.Iters >= 1, "two blobs ran ≥1 iter");
      Check (Approx (R.Centers (1, 1), 0.05, 0.05)
             or Approx (R.Centers (2, 1), 0.05, 0.05),
             "one center near left blob");
      Check (Approx (R.Centers (1, 1), 10.05, 0.05)
             or Approx (R.Centers (2, 1), 10.05, 0.05),
             "one center near right blob");
      for P in 1 .. 4 loop
         if R.Lab (P) = R.Lab (1) then
            Left := Left + 1;
         end if;
      end loop;
      for P in 5 .. 8 loop
         if R.Lab (P) = R.Lab (5) then
            Right := Right + 1;
         end if;
      end loop;
      Check (Left = 4, "left blob same cluster");
      Check (Right = 4, "right blob same cluster");
      Check (R.Lab (1) /= R.Lab (5), "blobs in different clusters");
      Check (R.WCSS < 1.0, "two blobs low WCSS");
      Check (Near (R.WCSS, R.Inertia), "Result.WCSS = Result.Inertia");
   end;

   ---------------------------------------------------------------------
   Section ("9. WCSS nonincreasing under Lloyd");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0],
         [8.0, 8.0],
         [9.0, 8.0],
         [8.0, 9.0]];
      Init : Centers := Init_Centers_Spaced (Data, 2);
      Lab : Labels (1 .. 6);
      Empty : Empty_Flags (1 .. 2);
      Prev_W, Curr_W : Real;
      Noninc : Boolean := True;
   begin
      Lab := Assign_Labels (Data, Init);
      Prev_W := WCSS (Data, Init, Lab);
      for Step in 1 .. 10 loop
         Compute_Centroids (Data, Lab, Init, Empty);
         Lab := Assign_Labels (Data, Init);
         Curr_W := WCSS (Data, Init, Lab);
         if Curr_W > Prev_W + 1.0E-9 then
            Noninc := False;
         end if;
         Prev_W := Curr_W;
      end loop;
      Check (Noninc, "WCSS nonincreasing over 10 Lloyd steps");
      Check (Curr_W >= 0.0, "final WCSS nonnegative");
   end;

   ---------------------------------------------------------------------
   Section ("10. Convergence / Max_Iters");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [0.1], [5.0], [5.1]];
      Init : constant Centers :=
        Init_Centers_From_Indices (Data, [1, 3]);
      P_Loose : constant Parameters :=
        (K => 2, Max_Iters => 100, Tol => 1.0E-6, Seed => 1);
      P_Tight : constant Parameters :=
        (K => 2, Max_Iters => 1, Tol => 0.0, Seed => 1);
      R1 : constant Result := Run_KMeans (Data, Init, P_Loose);
      R2 : constant Result := Run_Lloyd (Data, Init, P_Tight);
   begin
      Check (R1.Converged, "loose Tol converges");
      Check (R1.Iters <= 100, "iters within Max_Iters");
      Check (R2.Iters = 1, "Max_Iters=1 stops after 1");
      Check (R1.WCSS <= R2.WCSS + 1.0E-6,
             "more iters ≤ worse-or-equal WCSS");
   end;

   ---------------------------------------------------------------------
   Section ("11. Empty cluster keep previous mean");
   ---------------------------------------------------------------------
   declare
      --  All points near origin; second center far away with no points
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [0.0, 0.1]];
      Ctr : Centers :=
        [[0.0, 0.0],
         [100.0, 100.0]];
      Lab : Labels (1 .. 3);
      Empty : Empty_Flags (1 .. 2);
      Kept_X : Real;
      Kept_Y : Real;
   begin
      Lab := Assign_Labels (Data, Ctr);
      Check (Lab (1) = 1 and Lab (2) = 1 and Lab (3) = 1,
             "all points → center 1 (Voronoi)");
      Kept_X := Ctr (2, 1);
      Kept_Y := Ctr (2, 2);
      Compute_Centroids (Data, Lab, Ctr, Empty);
      Check (Empty (2), "cluster 2 marked empty");
      Check (not Empty (1), "cluster 1 nonempty");
      Check (Near (Ctr (2, 1), Kept_X) and Near (Ctr (2, 2), Kept_Y),
             "empty cluster keeps previous mean");
      Check (Approx (Ctr (1, 1), (0.0 + 0.1 + 0.0) / 3.0),
             "nonempty mean updated");
   end;

   ---------------------------------------------------------------------
   Section ("12. Invalid K / arguments");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset := [[0.0], [1.0], [2.0]];
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            C : Centers := Init_Centers_Spaced (Data, 4);
            pragma Unreferenced (C);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Init_Centers_Spaced K>N raises Invalid_Argument");

      Raised := False;
      begin
         declare
            C : Centers := Init_Centers_Forgy (Data, 0, 1);
            pragma Unreferenced (C);
         begin
            null;
         end;
      exception
         when Constraint_Error | Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Init_Centers_Forgy K=0 raises");

      Raised := False;
      begin
         declare
            Bad : constant Index_List := [1, 99];
            C : Centers := Init_Centers_From_Indices (Data, Bad);
            pragma Unreferenced (C);
         begin
            null;
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "From_Indices out-of-range raises");
   end;

   ---------------------------------------------------------------------
   Section ("13. Identical points");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[3.0, 3.0],
         [3.0, 3.0],
         [3.0, 3.0],
         [3.0, 3.0]];
      Init : constant Centers :=
        Init_Centers_From_Indices (Data, [1, 2]);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 20, Tol => 1.0E-9, Seed => 1);
      R : constant Result := Run_Lloyd (Data, Init, Params);
   begin
      Check (Approx (R.WCSS, 0.0), "identical points → WCSS=0");
      Check (Approx (R.Centers (1, 1), 3.0), "center x=3");
      Check (Approx (R.Centers (1, 2), 3.0), "center y=3");
      Check (R.Converged or R.Iters >= 1, "identical points terminates");
   end;

   ---------------------------------------------------------------------
   Section ("14. 1-D means");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [1.0], [2.0], [10.0], [11.0], [12.0]];
      Init : constant Centers :=
        Init_Centers_From_Indices (Data, [1, 4]);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 50, Tol => 1.0E-9, Seed => 1);
      R : constant Result := Run_KMeans (Data, Init, Params);
   begin
      Check (R.Converged, "1-D converged");
      Check
        ((Approx (R.Centers (1, 1), 1.0) and Approx (R.Centers (2, 1), 11.0))
         or
         (Approx (R.Centers (1, 1), 11.0) and Approx (R.Centers (2, 1), 1.0)),
         "1-D means at 1 and 11");
      Check (Approx (R.WCSS, 4.0), "1-D WCSS=4");
   end;

   ---------------------------------------------------------------------
   Section ("15. Pairwise WCSS equivalence smoke");
   ---------------------------------------------------------------------
   --  Manual Σ ||x−μ||² vs Within_Cluster_SSE / WCSS / Inertia
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [2.0, 0.0],
         [0.0, 2.0]];
      Ctr : constant Centers := [[0.0, 0.0]];
      Lab : constant Labels := [1, 1, 1];
      Manual : Real;
      P1 : constant Point := [0.0, 0.0];
      P2 : constant Point := [2.0, 0.0];
      P3 : constant Point := [0.0, 2.0];
      Mu : constant Point := [0.0, 0.0];
   begin
      Manual := Squared_Distance (P1, Mu)
        + Squared_Distance (P2, Mu)
        + Squared_Distance (P3, Mu);
      Check (Approx (Manual, 8.0), "manual pairwise sum=8");
      Check (Approx (Within_Cluster_SSE (Data, Ctr, Lab), Manual),
             "SSE ≡ pairwise sum");
      Check (Approx (WCSS (Data, Ctr, Lab), Manual), "WCSS ≡ pairwise");
      Check (Approx (Inertia (Data, Ctr, Lab), Manual),
             "Inertia ≡ pairwise");
   end;

   ---------------------------------------------------------------------
   Section ("16. One-shot Run_KMeans with Forgy");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.0],
         [0.0, 0.2],
         [5.0, 5.0],
         [5.2, 5.0],
         [5.0, 5.2]];
      Params : constant Parameters :=
        (K => 2, Max_Iters => 50, Tol => 1.0E-8, Seed => 7);
      R1 : constant Result := Run_KMeans (Data, Params);
      R2 : constant Result := Run_KMeans (Data, Params);
      R3 : constant Result := Run_Lloyd (Data, Params);
   begin
      Check (R1.Converged, "Forgy one-shot converged");
      Check (Near (R1.WCSS, R2.WCSS) and Near (R1.Centers (1, 1),
             R2.Centers (1, 1)),
             "Forgy one-shot reproducible with Seed");
      Check (Near (R1.WCSS, R3.WCSS), "Run_Lloyd(Params) ≡ Run_KMeans");
      Check (R1.Empty'Length = 2, "Empty flags length = K");
      Check (not (R1.Empty (1) and R1.Empty (2)),
             "not both clusters empty");
   end;

   ---------------------------------------------------------------------
   Section ("17. Run_KMeans alias of Run_Lloyd with Init");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0, 1.0],
         [1.1, 1.0],
         [9.0, 9.0],
         [9.1, 9.0]];
      Init : constant Centers := Init_Centers_Spaced (Data, 2);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 30, Tol => 1.0E-8, Seed => 0);
      Ra : constant Result := Run_Lloyd (Data, Init, Params);
      Rb : constant Result := Run_KMeans (Data, Init, Params);
   begin
      Check (Near (Ra.WCSS, Rb.WCSS), "Run_KMeans ≡ Run_Lloyd WCSS");
      Check (Ra.Iters = Rb.Iters, "Run_KMeans ≡ Run_Lloyd Iters");
      Check (Ra.Converged = Rb.Converged, "Run_KMeans ≡ Run_Lloyd Conv");
      Check (Ra.Lab (1) = Rb.Lab (1) and Ra.Lab (4) = Rb.Lab (4),
             "Run_KMeans ≡ Run_Lloyd labels");
   end;

   ---------------------------------------------------------------------
   Section ("18. RNG Draw_Index bounds");
   ---------------------------------------------------------------------
   declare
      State : RNG_State;
      Idx : Point_Index;
      In_Range : Boolean := True;
   begin
      Seed_RNG (State, 123);
      for I in 1 .. 40 loop
         Idx := Draw_Index (State, 1, 5);
         if Idx > 5 then
            In_Range := False;
         end if;
      end loop;
      Check (In_Range, "Draw_Index stays in [1,5]");
      Check (Draw_Unit (State) >= 0.0 and Draw_Unit (State) < 1.0,
             "Draw_Unit in [0,1)");
   end;

   ---------------------------------------------------------------------
   Section ("19. K=1 trivial clustering");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0, 2.0],
         [3.0, 4.0],
         [5.0, 6.0]];
      Init : constant Centers := Init_Centers_Spaced (Data, 1);
      Params : constant Parameters :=
        (K => 1, Max_Iters => 10, Tol => 1.0E-9, Seed => 1);
      R : constant Result := Run_Lloyd (Data, Init, Params);
   begin
      Check (R.Lab (1) = 1 and R.Lab (2) = 1 and R.Lab (3) = 1,
             "K=1 all labels = 1");
      Check (Approx (R.Centers (1, 1), 3.0), "K=1 mean x=3");
      Check (Approx (R.Centers (1, 2), 4.0), "K=1 mean y=4");
      Check (Approx (R.WCSS, 16.0), "K=1 WCSS=16");
      --  (1,2),(3,4),(5,6) vs (3,4): 8+0+8=16
   end;

   ---------------------------------------------------------------------
   Section ("20. Squared vs Euclidean ordering");
   ---------------------------------------------------------------------
   --  Argmin of squared distance equals argmin of Euclidean distance
   declare
      Ctr : constant Centers :=
        [[0.0, 0.0],
         [3.0, 4.0]];
      Q : constant Point := [1.0, 1.0];
      NSq : constant Site_Index := Nearest_Center (Q, Ctr);
      D0 : constant Real := Distance (Q, Extract_Center (Ctr, 1));
      D1 : constant Real := Distance (Q, Extract_Center (Ctr, 2));
   begin
      Check (NSq = 1, "nearest by sq is center 1");
      Check (D0 < D1, "Euclidean agrees with squared ordering");
      Check (Squared_Distance (Q, Extract_Center (Ctr, 1))
             < Squared_Distance (Q, Extract_Center (Ctr, 2)),
             "squared distances ordered");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0);
end Tests;
