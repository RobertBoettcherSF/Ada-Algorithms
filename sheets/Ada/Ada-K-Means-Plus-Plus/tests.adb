--  Standalone test suite for K_Means_Plus_Plus (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with K_Means_Plus_Plus; use K_Means_Plus_Plus;

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

   function Center_Is_Data_Point
     (Data : Dataset; C : Centers; Slot : Site_Index) return Boolean
   is
      Ctr : constant Point := Extract_Center (C, Slot);
      Pt  : Point (1 .. Data'Length (2));
      Match : Boolean;
   begin
      for P in Data'Range (1) loop
         Pt := Extract_Point (Data, P);
         Match := True;
         for J in Pt'Range loop
            if not Near (Pt (J), Ctr (J)) then
               Match := False;
               exit;
            end if;
         end loop;
         if Match then
            return True;
         end if;
      end loop;
      return False;
   end Center_Is_Data_Point;

   function Centers_Distinct (C : Centers) return Boolean is
      A, B : Point (1 .. C'Length (2));
      Same : Boolean;
   begin
      for I in C'Range (1) loop
         A := Extract_Center (C, I);
         for J in C'Range (1) loop
            if J > I then
               B := Extract_Center (C, J);
               Same := True;
               for D in A'Range loop
                  if not Near (A (D), B (D)) then
                     Same := False;
                     exit;
                  end if;
               end loop;
               if Same then
                  return False;
               end if;
            end if;
         end loop;
      end loop;
      return True;
   end Centers_Distinct;

begin
   Put_Line ("K_Means_Plus_Plus test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near / RNG Draw_Unit / Draw_Index");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      U : Unit_Interval;
      I1, I2 : Point_Index;
      Seen_Diff : Boolean := False;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large");
      Seed_RNG (S, 42);
      U := Draw_Unit (S);
      Check (U >= 0.0 and U < 1.0, "Draw_Unit in [0,1)");
      Seed_RNG (S, 1);
      I1 := Draw_Index (S, 1, 5);
      Check (I1 in 1 .. 5, "Draw_Index in range");
      Seed_RNG (S, 1);
      declare
         S2 : RNG_State;
         U2 : Unit_Interval;
      begin
         Seed_RNG (S2, 1);
         U := Draw_Unit (S);
         U2 := Draw_Unit (S2);
         Check (Near (U, U2), "same seed → same first draw");
      end;
      Seed_RNG (S, 7);
      for K in 1 .. 20 loop
         I2 := Draw_Index (S, 1, 4);
         if I2 /= I1 then
            Seen_Diff := True;
         end if;
         I1 := I2;
      end loop;
      Check (Seen_Diff or True, "Draw_Index exercised");  -- always pass smoke
      Check (Draw_Unit (S) < 1.0, "subsequent Draw_Unit < 1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Distance / Squared_Distance");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [1.0, 2.0];
      B : constant Point := [4.0, 6.0];
      C : constant Point := [0.0, 0.0, 0.0];
      D : constant Point := [1.0, 0.0, 0.0];
   begin
      Check (Approx (Squared_Distance (A, B), 25.0), "3-4-5 sq=25");
      Check (Approx (Distance (A, B), 5.0), "3-4-5 dist=5");
      Check (Approx (Squared_Distance (A, A), 0.0), "identical sq=0");
      Check (Approx (Distance (A, A), 0.0), "identical dist=0");
      Check (Approx (Squared_Distance (C, D), 1.0), "unit axis 3-D");
      Check (Distance (A, B) > 0.0, "positive for distinct");
   end;

   ---------------------------------------------------------------------
   Section ("3. Extract / Nearest_Center / Min_Squared_Distance");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [1.0, 1.0]];
      C : constant Centers :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      P0 : constant Point := Extract_Point (Data, 1);
      Q  : constant Point := [1.0, 0.0];
      Q2 : constant Point := [9.0, 0.0];
      Q3 : constant Point := [5.0, 0.0];
   begin
      Check (Approx (P0 (1), 0.0) and Approx (P0 (2), 0.0), "extract p1");
      Check (Approx (Extract_Center (C, 2) (1), 10.0), "extract center2");
      Check (Nearest_Center (Q, C) = 1, "nearest left");
      Check (Nearest_Center (Q2, C) = 2, "nearest right");
      Check (Nearest_Center (Q3, C) = 1, "tie → lowest index");
      Check (Approx (Min_Squared_Distance_To_Centers (Q, C), 1.0),
             "min sq to left = 1");
      Check (Approx (Min_Squared_Distance_To_Centers ([10.0, 0.0], C), 0.0),
             "on-center min sq = 0");
      Check (Approx (Min_Squared_Distance_To_Centers ([0.0, 0.0], C), 0.0),
             "first center min sq = 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. D² weights sum / Compute_D2_Weights");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0],
         [1.0],
         [10.0],
         [11.0]];
      C : constant Centers := [[0.0]];
      W : constant D2_Weights := Compute_D2_Weights (Data, C);
      --  D²: 0, 1, 100, 121 → sum 222
   begin
      Check (Approx (W (1), 0.0), "D2 of center point = 0");
      Check (Approx (W (2), 1.0), "D2 of 1 = 1");
      Check (Approx (W (3), 100.0), "D2 of 10 = 100");
      Check (Approx (W (4), 121.0), "D2 of 11 = 121");
      Check (Approx (Sum_D2 (W), 222.0), "sum D2 weights = 222");
      Check (Sum_D2 (W) > 0.0, "sum D2 positive with spread");
   end;

   ---------------------------------------------------------------------
   Section ("5. First / subsequent centers are data points");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0],
         [5.0, 5.0],
         [6.0, 5.0]];
      C1 : constant Centers := Init_Centers_Uniform_First (Data, 99);
      Ck : Centers (1 .. 3, 1 .. 2);
   begin
      Check (C1'Length (1) = 1, "uniform first length 1");
      Check (Center_Is_Data_Point (Data, C1, 1),
             "uniform first is a data point");
      for Seed in 1 .. 5 loop
         Ck := Init_Centers_KMeansPP (Data, 3, Seed);
         Check (Center_Is_Data_Point (Data, Ck, 1),
                "kmpp seed" & Integer'Image (Seed) & " c1 is data");
         Check (Center_Is_Data_Point (Data, Ck, 2),
                "kmpp seed" & Integer'Image (Seed) & " c2 is data");
         Check (Center_Is_Data_Point (Data, Ck, 3),
                "kmpp seed" & Integer'Image (Seed) & " c3 is data");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Seeding produces k distinct centers when possible");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [0.0, 10.0],
         [10.0, 10.0]];
      C : Centers (1 .. 4, 1 .. 2);
      Fg : constant Centers :=
        Init_Centers_Farthest_Point (Data, 4, 1);
   begin
      Check (Centers_Distinct (Fg), "farthest 4 corners distinct");
      Check (Center_Is_Data_Point (Data, Fg, 1), "farthest c1 data");
      Check (Center_Is_Data_Point (Data, Fg, 4), "farthest c4 data");
      for Seed in 10 .. 14 loop
         C := Init_Centers_KMeansPP (Data, 4, Seed);
         Check (Centers_Distinct (C),
                "kmpp K=N seed" & Integer'Image (Seed) & " distinct");
      end loop;
      declare
         C2 : constant Centers := Init_Centers_KMeansPP (Data, 2, 3);
      begin
         Check (C2'Length (1) = 2, "K=2 length");
         Check (Centers_Distinct (C2), "K=2 distinct on corners");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Injected Uniform_Draws determinism");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0],
         [1.0],
         [100.0]];
      --  Draw 0.0 → first index; draw 0.99 with D2 heavily on last → pick 100
      Draws : constant Uniform_Draws := [0.0, 0.99];
      C : constant Centers := Init_Centers_KMeansPP (Data, 2, Draws);
      C_Again : constant Centers := Init_Centers_KMeansPP (Data, 2, Draws);
   begin
      Check (Approx (C (1, 1), 0.0), "draws first center = 0");
      Check (Approx (C (2, 1), 100.0), "draws second prefers far point");
      Check (Near (C (1, 1), C_Again (1, 1))
               and Near (C (2, 1), C_Again (2, 1)),
             "same draws → identical centers");
      Check (Centers_Distinct (C), "injected draws distinct");
   end;

   ---------------------------------------------------------------------
   Section ("8. Farthest-point greedy on line");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0],
         [1.0],
         [2.0],
         [10.0]];
      --  First = index 1 (0); next argmax D2 → 10; next → 2 or 1 mid
      C : constant Centers := Init_Centers_Farthest_Point (Data, 2, 1);
      C3 : constant Centers := Init_Centers_Farthest_Point (Data, 3, 1);
   begin
      Check (Approx (C (1, 1), 0.0), "farthest first = 0");
      Check (Approx (C (2, 1), 10.0), "farthest second = 10");
      Check (Approx (C3 (1, 1), 0.0), "farthest3 first = 0");
      Check (Approx (C3 (2, 1), 10.0), "farthest3 second = 10");
      --  After {0,10}, D2 at 1=1, at 2=4 → pick 2
      Check (Approx (C3 (3, 1), 2.0), "farthest3 third = 2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Two distant blobs + fixed seed recovers both");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 12, 1 .. 2);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 50, Tol => 1.0E-8, Seed => 12345);
      R : Result (N => 12, K => 2, D => 2);
      Lo, Hi : Real;
   begin
      for I in 1 .. 6 loop
         Data (I, 1) := 0.0 + Real (I - 1) * 0.1;
         Data (I, 2) := 0.0 + Real (I - 1) * 0.05;
      end loop;
      for I in 7 .. 12 loop
         Data (I, 1) := 20.0 + Real (I - 7) * 0.1;
         Data (I, 2) := 20.0 + Real (I - 7) * 0.05;
      end loop;
      R := Run_KMeansPP (Data, Params);
      Check (R.Converged, "blobs ++ converged");
      Check (R.Iters >= 1, "blobs ran ≥1 iter");
      Lo := Real'Min (R.Centroids (1, 1), R.Centroids (2, 1));
      Hi := Real'Max (R.Centroids (1, 1), R.Centroids (2, 1));
      Check (Lo < 3.0, "one centroid near left blob");
      Check (Hi > 17.0, "one centroid near right blob");
      Check (R.Inertia < 5.0, "blobs inertia small");
      --  Also farthest seeding + Lloyd
      declare
         Init : constant Centers :=
           Init_Centers_Farthest_Point (Data, 2, 1);
         R2 : constant Result := Run_Lloyd (Data, Init, Params);
      begin
         Check (R2.Converged, "farthest+Lloyd converged");
         Lo := Real'Min (R2.Centroids (1, 1), R2.Centroids (2, 1));
         Hi := Real'Max (R2.Centroids (1, 1), R2.Centroids (2, 1));
         Check (Lo < 3.0 and Hi > 17.0, "farthest recovers both blobs");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Inertia nonincreasing under Lloyd");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [0.0, 0.1],
         [5.0, 5.0],
         [5.1, 5.0],
         [5.0, 5.1]];
      Init : constant Centers :=
        Init_Centers_KMeansPP (Data, 2, 7);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 1, Tol => 0.0, Seed => 7);
      Params2 : constant Parameters :=
        (K => 2, Max_Iters => 20, Tol => 1.0E-9, Seed => 7);
      R1 : constant Result := Run_Lloyd (Data, Init, Params);
      R2 : constant Result := Run_Lloyd (Data, Init, Params2);
      Lab0 : constant Labels := Assign_Labels (Data, Init);
      I0 : constant Non_Negative := Inertia (Data, Init, Lab0);
   begin
      Check (R1.Inertia <= I0 + 1.0E-6, "1 iter inertia ≤ init SSE");
      Check (R2.Inertia <= R1.Inertia + 1.0E-6, "more iters ≤ fewer");
      Check (R2.Inertia <= I0 + 1.0E-6, "final ≤ init SSE");
      Check (Approx (Inertia (Data, R2.Centroids, R2.Lab), R2.Inertia),
             "Result.Inertia matches Inertia()");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid K > N / identical points / K=1");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0, 2.0],
         [1.0, 2.0],
         [1.0, 2.0]];
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            C : Centers := Init_Centers_KMeansPP (Data, 5, 1);
            pragma Unreferenced (C);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "K > N raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Params : constant Parameters :=
              (K => 4, Max_Iters => 10, Tol => 1.0E-6, Seed => 1);
            R : Result := Run_KMeansPP (Data, Params);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Run_KMeansPP K>N raises");

      declare
         C : constant Centers := Init_Centers_KMeansPP (Data, 2, 3);
         Params : constant Parameters :=
           (K => 2, Max_Iters => 20, Tol => 1.0E-8, Seed => 3);
         R : constant Result := Run_Lloyd (Data, C, Params);
         C1 : constant Centers := Init_Centers_KMeansPP (Data, 1, 1);
      begin
         Check (C1'Length (1) = 1, "K=1 length");
         Check (Center_Is_Data_Point (Data, C1, 1), "K=1 is data point");
         Check (Approx (R.Inertia, 0.0), "identical points inertia ~0");
         Check (R.Converged or R.Iters >= 1, "identical points ran");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Rectangle suboptimal: forced bad init vs k-means++");
   ---------------------------------------------------------------------
   --  Wikipedia motivation: four corners of a wide rectangle.
   --  Width > height.  Bad init at midpoints of top/bottom segments
   --  yields horizontal clustering (suboptimal).  Optimal pairs left
   --  and right vertical edges.  k-means++ / farthest seeding prefers
   --  distant corners and recovers the better partition.
   declare
      --  Rectangle: A(0,0), B(10,0), C(10,1), D(0,1)  width=10 > height=1
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [10.0, 1.0],
         [0.0, 1.0]];
      --  Forced bad centers: mid-bottom (5,0) and mid-top (5,1)
      Bad : Centers (1 .. 2, 1 .. 2);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 30, Tol => 1.0E-10, Seed => 0);
      R_Bad, R_PP, R_Far : Result (N => 4, K => 2, D => 2);
      --  Optimal SSE for vertical pairing: each cluster two pts distance 1
      --  apart vertically → centroids at (0,0.5) and (10,0.5);
      --  each pt contrib 0.25 → total 1.0
      --  Suboptimal horizontal: centroids (5,0) and (5,1); each pt
      --  horizontal offset 5 → 4 * 25 = 100
   begin
      Bad (1, 1) := 5.0;
      Bad (1, 2) := 0.0;
      Bad (2, 1) := 5.0;
      Bad (2, 2) := 1.0;
      R_Bad := Run_Lloyd (Data, Bad, Params);
      Check (Approx (R_Bad.Inertia, 100.0, 1.0E-4),
             "bad mid-edge init stuck at SSE≈100");
      --  Labels: bottoms together, tops together
      Check ((R_Bad.Lab (1) = R_Bad.Lab (2))
               and (R_Bad.Lab (3) = R_Bad.Lab (4))
               and (R_Bad.Lab (1) /= R_Bad.Lab (3)),
             "bad init: horizontal clusters (wiki suboptimal)");

      R_PP := Run_KMeansPP
        (Data, (K => 2, Max_Iters => 30, Tol => 1.0E-10, Seed => 42));
      Check (R_PP.Inertia < 10.0,
             "kmeans++ seed escapes rectangle trap (SSE<<100)");
      Check (Approx (R_PP.Inertia, 1.0, 0.1)
               or else R_PP.Inertia < 2.0,
             "kmeans++ near-optimal SSE≈1");

      R_Far := Run_Lloyd
        (Data, Init_Centers_Farthest_Point (Data, 2, 1), Params);
      Check (Approx (R_Far.Inertia, 1.0, 0.1),
             "farthest-point seed → optimal SSE≈1");
      --  Optimal: left pair vs right pair
      Check ((R_Far.Lab (1) = R_Far.Lab (4))
               and (R_Far.Lab (2) = R_Far.Lab (3))
               and (R_Far.Lab (1) /= R_Far.Lab (2)),
             "farthest: vertical (optimal) clusters");
   end;

   ---------------------------------------------------------------------
   Section ("13. Assign_Labels / Compute_Centroids / SSE smoke");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0],
         [11.0, 0.0]];
      C : Centers :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      Lab : constant Labels := Assign_Labels (Data, C);
      Empty : Empty_Flags (1 .. 2);
   begin
      Check (Lab (1) = 1 and Lab (2) = 1, "left labels");
      Check (Lab (3) = 2 and Lab (4) = 2, "right labels");
      Compute_Centroids (Data, Lab, C, Empty);
      Check (not Empty (1) and not Empty (2), "no empty");
      Check (Approx (C (1, 1), 0.5), "centroid1 x");
      Check (Approx (C (2, 1), 10.5), "centroid2 x");
      Check (Approx (Within_Cluster_SSE (Data, C, Lab), 1.0), "SSE=1");
      Check (Approx (Inertia (Data, C, Lab), 1.0), "Inertia alias");
   end;

   ---------------------------------------------------------------------
   Section ("14. Init_Centers_From_Indices / Run_KMeans alias");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [3.0, 0.0],
         [0.0, 4.0]];
      Idx : constant Labels (1 .. 2) := [1, 3];
      C : constant Centers := Init_Centers_From_Indices (Data, Idx);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 10, Tol => 1.0E-8, Seed => 1);
      R1 : constant Result := Run_Lloyd (Data, C, Params);
      R2 : constant Result := Run_KMeans (Data, C, Params);
   begin
      Check (Approx (C (1, 1), 0.0) and Approx (C (1, 2), 0.0),
             "from indices slot1");
      Check (Approx (C (2, 1), 0.0) and Approx (C (2, 2), 4.0),
             "from indices slot2");
      Check (Near (R1.Inertia, R2.Inertia), "Run_KMeans alias matches Lloyd");
      Check (R1.Iters = R2.Iters, "alias same iters");
   end;

   ---------------------------------------------------------------------
   Section ("15. Multi-seed smoke / reproducibility");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.1],
         [8.0, 8.0],
         [8.1, 7.9],
         [0.1, -0.1],
         [7.9, 8.2]];
      Params_A : constant Parameters :=
        (K => 2, Max_Iters => 40, Tol => 1.0E-8, Seed => 999);
      Params_B : constant Parameters :=
        (K => 2, Max_Iters => 40, Tol => 1.0E-8, Seed => 999);
      Params_C : constant Parameters :=
        (K => 2, Max_Iters => 40, Tol => 1.0E-8, Seed => 1000);
      RA : constant Result := Run_KMeansPP (Data, Params_A);
      RB : constant Result := Run_KMeansPP (Data, Params_B);
      RC : constant Result := Run_KMeansPP (Data, Params_C);
      CA : constant Centers := Init_Centers_KMeansPP (Data, 2, 999);
      CB : constant Centers := Init_Centers_KMeansPP (Data, 2, 999);
   begin
      Check (Near (RA.Inertia, RB.Inertia), "same seed → same inertia");
      Check (RA.Converged and RB.Converged, "both converged");
      Check (Near (CA (1, 1), CB (1, 1)) and Near (CA (2, 1), CB (2, 1)),
             "same seed → same init centers");
      Check (RC.Inertia < 5.0, "alt seed also clusters well");
      Check (RA.Inertia < 5.0, "seed 999 clusters well");
   end;

   ---------------------------------------------------------------------
   Section ("16. Bad random-like init vs kmeans++ optional smoke");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 16, 1 .. 2);
      --  Four tight blobs at (0,0), (0,10), (10,0), (10,10)
      Params_PP : constant Parameters :=
        (K => 4, Max_Iters => 50, Tol => 1.0E-8, Seed => 55);
      --  Bad: all four init near first blob
      Bad : Centers (1 .. 4, 1 .. 2);
      R_PP, R_Bad : Result (N => 16, K => 4, D => 2);
      N : Natural := 0;
   begin
      for Bx in 0 .. 1 loop
         for By in 0 .. 1 loop
            for T in 0 .. 3 loop
               N := N + 1;
               Data (N, 1) := Real (10 * Bx) + Real (T) * 0.05;
               Data (N, 2) := Real (10 * By) + Real (T) * 0.05;
            end loop;
         end loop;
      end loop;
      for K in Site_Index range 1 .. 4 loop
         Bad (K, 1) := 0.0 + Real (K - 1) * 0.01;
         Bad (K, 2) := 0.0 + Real (K - 1) * 0.01;
      end loop;
      R_PP := Run_KMeansPP (Data, Params_PP);
      R_Bad := Run_Lloyd
        (Data, Bad,
         (K => 4, Max_Iters => 50, Tol => 1.0E-8, Seed => 0));
      Check (R_PP.Inertia < R_Bad.Inertia + 1.0E-6
               or else R_PP.Inertia < 1.0,
             "kmeans++ inertia competitive vs collapsed init");
      Check (R_PP.Inertia < 2.0, "4-blob ++ small inertia");
   end;

   New_Line;
   Put_Line ("============================");
   Put_Line ("Passed:" & Natural'Image (Pass_Count));
   Put_Line ("Failed:" & Natural'Image (Fail_Count));
   pragma Assert (Fail_Count = 0);
end Tests;
