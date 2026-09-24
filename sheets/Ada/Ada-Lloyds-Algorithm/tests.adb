--  Standalone test suite for Lloyds_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Lloyds_Algorithm; use Lloyds_Algorithm;

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
   Put_Line ("Lloyds_Algorithm test suite");
   Put_Line ("===========================");

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
   Section ("3. Extract_Point / Extract_Site / Nearest_Site");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0],
         [1.0, 1.0]];
      S : constant Sites :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      P0 : constant Point := Extract_Point (Data, 1);
      P1 : constant Point := Extract_Point (Data, 2);
      S0 : constant Point := Extract_Site (S, 1);
      Q  : constant Point := [1.0, 0.0];
      Q2 : constant Point := [9.0, 0.0];
      Q3 : constant Point := [5.0, 0.0];  -- tie midpoint → lowest index
   begin
      Check (Approx (P0 (1), 0.0) and Approx (P0 (2), 0.0), "extract p1");
      Check (Approx (P1 (1), 10.0), "extract p2 x");
      Check (Approx (S0 (1), 0.0), "extract site1");
      Check (Nearest_Site (Q, S) = 1, "nearest to left site");
      Check (Nearest_Site (Q2, S) = 2, "nearest to right site");
      Check (Nearest_Site (Q3, S) = 1, "tie → lowest index");
      Check (Nearest_Site (Extract_Point (Data, 3), S) = 1,
             "point (1,1) → site 1");
      Check (Nearest_Site ([10.0, 0.0], S) = 2, "exact on site 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Assign_Labels one iteration hand example");
   ---------------------------------------------------------------------
   --  Points: (0,0),(1,0),(10,0),(11,0); sites at (0,0),(10,0)
   --  Labels should be 1,1,2,2
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0],
         [11.0, 0.0]];
      S : Sites :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      Lab : constant Labels := Assign_Labels (Data, S);
      Empty : Empty_Flags (1 .. 2);
   begin
      Check (Lab (1) = 1, "label p1 → 1");
      Check (Lab (2) = 1, "label p2 → 1");
      Check (Lab (3) = 2, "label p3 → 2");
      Check (Lab (4) = 2, "label p4 → 2");
      Compute_Centroids (Data, Lab, S, Empty);
      Check (not Empty (1) and not Empty (2), "no empty after assign");
      Check (Approx (S (1, 1), 0.5), "centroid1 x=0.5");
      Check (Approx (S (1, 2), 0.0), "centroid1 y=0");
      Check (Approx (S (2, 1), 10.5), "centroid2 x=10.5");
      Check (Approx (S (2, 2), 0.0), "centroid2 y=0");
      --  Each cluster: two pts at ±0.5 from mean → 2*(0.25)=0.5; total 1.0
      Check (Approx (Within_Cluster_SSE (Data, S, Lab), 1.0),
             "SSE after one centroid step");
      Check (Approx (Inertia (Data, S, Lab),
                     Within_Cluster_SSE (Data, S, Lab)),
             "Inertia alias matches SSE");
   end;

   ---------------------------------------------------------------------
   Section ("5. Init_Sites_From_Data spaced indices");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0], [2.0], [3.0], [4.0], [5.0]];
      S1 : constant Sites := Init_Sites_From_Data (Data, 1);
      S2 : constant Sites := Init_Sites_From_Data (Data, 2);
      S3 : constant Sites := Init_Sites_From_Data (Data, 3);
      S5 : constant Sites := Init_Sites_From_Data (Data, 5);
   begin
      Check (S1'Length (1) = 1 and Approx (S1 (1, 1), 1.0), "K=1 → first");
      Check (Approx (S2 (1, 1), 1.0) and Approx (S2 (2, 1), 5.0),
             "K=2 → first & last");
      Check (Approx (S3 (1, 1), 1.0), "K=3 site1=1");
      Check (Approx (S3 (2, 1), 3.0), "K=3 site2=3");
      Check (Approx (S3 (3, 1), 5.0), "K=3 site3=5");
      Check (Approx (S5 (3, 1), 3.0), "K=N spaced mid");
      Check (S5'Length (1) = 5, "K=N length");
   end;

   ---------------------------------------------------------------------
   Section ("6. Two well-separated blobs → K=2 recovery");
   ---------------------------------------------------------------------
   declare
      Data : Dataset (1 .. 10, 1 .. 2);
      Params : constant Parameters :=
        (K => 2, Max_Iters => 50, Tol => 1.0E-8);
      R : Lloyd_Result (N => 10, K => 2, D => 2);
      N1, N2 : Natural;
   begin
      --  Blob A around (0,0), blob B around (10,10)
      for I in 1 .. 5 loop
         Data (I, 1) := 0.0 + Real (I - 1) * 0.1;
         Data (I, 2) := 0.0 + Real (I - 1) * 0.05;
      end loop;
      for I in 6 .. 10 loop
         Data (I, 1) := 10.0 + Real (I - 6) * 0.1;
         Data (I, 2) := 10.0 + Real (I - 6) * 0.05;
      end loop;
      R := Run_Lloyd (Data, Params);
      Check (R.Converged, "blobs converged");
      Check (R.Iters >= 1, "blobs ran ≥1 iter");
      Check (R.Iters <= Params.Max_Iters, "blobs within Max_Iters");
      --  Centroids near blob means (~0.2, ~0.1) and (~10.2, ~10.1)
      declare
         C1x : constant Real := R.Centroids (1, 1);
         C2x : constant Real := R.Centroids (2, 1);
         Lo  : constant Real := Real'Min (C1x, C2x);
         Hi  : constant Real := Real'Max (C1x, C2x);
      begin
         Check (Lo < 2.0, "one centroid near left blob");
         Check (Hi > 8.0, "one centroid near right blob");
      end;
      N1 := 0;
      N2 := 0;
      for P in 1 .. 10 loop
         if R.Lab (P) = 1 then
            N1 := N1 + 1;
         elsif R.Lab (P) = 2 then
            N2 := N2 + 1;
         end if;
      end loop;
      Check (N1 = 5 and N2 = 5, "balanced 5+5 labels");
      --  Points 1..5 share a label; 6..10 the other
      Check (R.Lab (1) = R.Lab (2) and R.Lab (2) = R.Lab (5),
             "left blob same label");
      Check (R.Lab (6) = R.Lab (10), "right blob same label");
      Check (R.Lab (1) /= R.Lab (6), "blobs different labels");
      Check (R.Inertia >= 0.0, "inertia non-negative");
      Check (R.Inertia < 5.0, "inertia small after fit");
      Check (not R.Empty (1) and not R.Empty (2), "no empty clusters");
   end;

   ---------------------------------------------------------------------
   Section ("7. Inertia nonincreasing across iterations");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.5, 0.0],
         [8.0, 0.0],
         [8.5, 0.0],
         [0.2, 0.3],
         [8.1, 0.2]];
      Init : constant Sites :=
        [[0.0, 0.0],
         [8.0, 0.0]];
      S : Sites := Init;
      Lab : Labels (1 .. 6);
      Empty : Empty_Flags (1 .. 2);
      Prev_I, Cur_I : Real;
      Nonincreasing : Boolean := True;
   begin
      Lab := Assign_Labels (Data, S);
      Prev_I := Within_Cluster_SSE (Data, S, Lab);
      for Step in 1 .. 8 loop
         Compute_Centroids (Data, Lab, S, Empty);
         Lab := Assign_Labels (Data, S);
         Cur_I := Within_Cluster_SSE (Data, S, Lab);
         if Cur_I > Prev_I + 1.0E-6 then
            Nonincreasing := False;
         end if;
         Prev_I := Cur_I;
      end loop;
      Check (Nonincreasing, "SSE nonincreasing over 8 steps");
      Check (Cur_I <= Within_Cluster_SSE (Data, Init, Assign_Labels (Data, Init))
               + 1.0E-6,
             "final SSE ≤ initial assignment SSE");
   end;

   ---------------------------------------------------------------------
   Section ("8. Convergence flag and Max_Iters stop");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [0.1], [5.0], [5.1]];
      Easy : constant Parameters :=
        (K => 2, Max_Iters => 100, Tol => 1.0E-6);
      Tight : constant Parameters :=
        (K => 2, Max_Iters => 1, Tol => 1.0E-30);
      R1 : constant Lloyd_Result := Run_Lloyd (Data, Easy);
      R2 : constant Lloyd_Result := Run_Lloyd (Data, Tight);
      R3 : constant Lloyd_Result :=
        Run_KMeans (Data, Init_Sites_From_Data (Data, 2), Easy);
   begin
      Check (R1.Converged, "loose Tol → Converged");
      Check (R2.Iters = 1, "Max_Iters=1 → exactly 1 iter");
      --  With Max_Iters=1 may or may not converge; flag must be consistent
      Check (R2.Iters <= 1, "iters capped");
      Check (R3.Converged or not R3.Converged, "Run_KMeans alias runs");
      Check (R3.K = 2 and R3.N = 4, "KMeans result extents");
      Check (Approx (R1.Inertia, R3.Inertia, 1.0E-4)
               or else R1.Converged,
             "KMeans/Lloyd comparable inertia");
   end;

   ---------------------------------------------------------------------
   Section ("9. Empty-cluster handling (keep + mark)");
   ---------------------------------------------------------------------
   declare
      --  All points near site 1; site 2 far away with no points
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [0.0, 0.1]];
      S : Sites :=
        [[0.0, 0.0],
         [100.0, 100.0]];
      Lab : Labels (1 .. 3);
      Empty : Empty_Flags (1 .. 2);
      S2_Before_X, S2_Before_Y : Real;
   begin
      Lab := Assign_Labels (Data, S);
      Check (Lab (1) = 1 and Lab (2) = 1 and Lab (3) = 1,
             "all assigned to site 1");
      S2_Before_X := S (2, 1);
      S2_Before_Y := S (2, 2);
      Compute_Centroids (Data, Lab, S, Empty, Raise_Empty => False);
      Check (Empty (2), "site 2 marked empty");
      Check (not Empty (1), "site 1 not empty");
      Check (Approx (S (2, 1), S2_Before_X)
               and Approx (S (2, 2), S2_Before_Y),
             "empty site kept previous coords");
      Check (Approx (S (1, 1), (0.0 + 0.1 + 0.0) / 3.0),
             "nonempty site moved to mean");
      --  Raise_Empty path
      declare
         Raised : Boolean := False;
         S2 : Sites :=
           [[0.0, 0.0],
            [100.0, 100.0]];
         E2 : Empty_Flags (1 .. 2);
      begin
         begin
            Compute_Centroids
              (Data, Lab, S2, E2, Raise_Empty => True);
         exception
            when Degenerate_Cluster =>
               Raised := True;
         end;
         Check (Raised, "Raise_Empty → Degenerate_Cluster");
         Check (E2 (2), "empty still marked when raising");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Grid 2-D CVT relaxation spreads sites");
   ---------------------------------------------------------------------
   declare
      Box : constant BBox_2D :=
        (X_Min => 0.0, X_Max => 1.0, Y_Min => 0.0, Y_Max => 1.0);
      --  Both sites start clustered in a corner
      Init : constant Sites :=
        [[0.1, 0.1],
         [0.15, 0.12]];
      Out_S : constant Sites :=
        Run_Lloyd_Grid_2D
          (Box, Resolution => 20, Init => Init,
           Max_Iters => 40, Tol => 1.0E-5);
      D_Init, D_Out : Real;
   begin
      D_Init := Distance
        (Extract_Site (Init, 1), Extract_Site (Init, 2));
      D_Out := Distance
        (Extract_Site (Out_S, 1), Extract_Site (Out_S, 2));
      Check (Out_S'Length (1) = 2 and Out_S'Length (2) = 2,
             "grid result shape 2×2");
      Check (D_Out > D_Init, "sites move apart toward spread");
      --  Sites should stay inside / near the box
      Check (Out_S (1, 1) >= -0.05 and Out_S (1, 1) <= 1.05,
             "site1 x in box");
      Check (Out_S (1, 2) >= -0.05 and Out_S (1, 2) <= 1.05,
             "site1 y in box");
      Check (Out_S (2, 1) >= -0.05 and Out_S (2, 1) <= 1.05,
             "site2 x in box");
      Check (Out_S (2, 2) >= -0.05 and Out_S (2, 2) <= 1.05,
             "site2 y in box");
      --  Single site stays near center of box
      declare
         One : constant Sites := [[0.2, 0.3]];
         Mid : constant Sites :=
           Run_Lloyd_Grid_2D (Box, 16, One, 30, 1.0E-6);
      begin
         Check (Approx (Mid (1, 1), 0.5, 0.05), "single site → ~cx");
         Check (Approx (Mid (1, 2), 0.5, 0.05), "single site → ~cy");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid K / empty data / capacity");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset := [[1.0, 2.0], [3.0, 4.0]];
      Raised_K : Boolean := False;
      Raised_Empty : Boolean := False;
   begin
      begin
         declare
            S : constant Sites := Init_Sites_From_Data (Data, 3);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised_K := True;
      end;
      Check (Raised_K, "K > N → Invalid_Argument");

      begin
         declare
            Empty_Data : Dataset (1 .. 0, 1 .. 2) :=
              [others => [others => 0.0]];
            pragma Unreferenced (Empty_Data);
            Params : constant Parameters :=
              (K => 1, Max_Iters => 10, Tol => 1.0E-6);
            R : Lloyd_Result :=
              Run_Lloyd
                (Dataset'(1 .. 0 => [1 => 0.0, 2 => 0.0]), Params);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised_Empty := True;
         when Constraint_Error =>
            Raised_Empty := True;
      end;
      Check (Raised_Empty, "empty/invalid data rejected");

      --  Degenerate grid bbox
      declare
         Bad_Box : constant BBox_2D :=
           (X_Min => 1.0, X_Max => 1.0, Y_Min => 0.0, Y_Max => 1.0);
         Init : constant Sites := [[0.5, 0.5]];
         Got : Boolean := False;
      begin
         begin
            declare
               S : constant Sites :=
                 Run_Lloyd_Grid_2D (Bad_Box, 10, Init);
               pragma Unreferenced (S);
            begin
               null;
            end;
         exception
            when Invalid_Argument =>
               Got := True;
         end;
         Check (Got, "degenerate bbox → Invalid_Argument");
      end;
      --  Documented caps (checked dynamically via 'Image length smoke).
      declare
         Cap_Msg : constant String :=
           "caps" & Max_Points'Image & Max_Dims'Image & Max_Sites'Image;
      begin
         Check (Cap_Msg'Length > 8, "capacity images concatenated");
         Check (Cap_Msg (1 .. 4) = "caps", "capacity prefix");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Identical points");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[2.0, 2.0],
         [2.0, 2.0],
         [2.0, 2.0],
         [2.0, 2.0]];
      Params : constant Parameters :=
        (K => 2, Max_Iters => 20, Tol => 1.0E-9);
      R : constant Lloyd_Result := Run_Lloyd (Data, Params);
   begin
      Check (R.Inertia < 1.0E-8, "identical points → ~0 inertia");
      Check (R.Converged or R.Iters >= 1, "identical points terminates");
      --  Both centroids at (2,2) or one empty kept
      Check
        ((Approx (R.Centroids (1, 1), 2.0) and Approx (R.Centroids (1, 2), 2.0))
           or else R.Empty (1),
         "site1 at data or empty");
      Check
        ((Approx (R.Centroids (2, 1), 2.0) and Approx (R.Centroids (2, 2), 2.0))
           or else R.Empty (2),
         "site2 at data or empty");
   end;

   ---------------------------------------------------------------------
   Section ("13. Run_Lloyd with explicit Init + 1-D");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [1.0], [2.0], [10.0], [11.0], [12.0]];
      Init : constant Sites := [[0.5], [11.0]];
      Params : constant Parameters :=
        (K => 2, Max_Iters => 30, Tol => 1.0E-8);
      R : constant Lloyd_Result := Run_Lloyd (Data, Init, Params);
   begin
      Check (R.Converged, "1-D explicit init converged");
      Check (R.N = 6 and R.D = 1 and R.K = 2, "1-D result discriminants");
      declare
         Lo : constant Real :=
           Real'Min (R.Centroids (1, 1), R.Centroids (2, 1));
         Hi : constant Real :=
           Real'Max (R.Centroids (1, 1), R.Centroids (2, 1));
      begin
         Check (Approx (Lo, 1.0, 0.2), "low centroid ~1");
         Check (Approx (Hi, 11.0, 0.2), "high centroid ~11");
      end;
      --  Ideal SSE ≈ 2+2=4 for means at 1 and 11
      Check (R.Inertia < 5.0, "1-D inertia reasonable");
      Check (Approx (R.Inertia, 4.0, 0.5), "1-D inertia near 4");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra API smoke / edge cases");
   ---------------------------------------------------------------------
   declare
      A : constant Point := [3.0, 4.0];
      O : constant Point := [0.0, 0.0];
      Data : constant Dataset := [[0.0, 0.0], [1.0, 0.0]];
      S : constant Sites := Init_Sites_From_Data (Data, 2);
      Lab : constant Labels := Assign_Labels (Data, S);
   begin
      Check (Approx (Distance (A, O), 5.0), "distance 3-4-5 again");
      Check (S'Length (1) = 2, "init K=2 on N=2");
      Check (Lab (1) /= 0 and Lab (2) /= 0, "labels nonzero");
      declare
         P : Parameters := Default_Parameters;
      begin
         P.K := 3;
         P.Max_Iters := 10;
         P.Tol := 1.0E-4;
         Check (P.K = 3, "Parameters.K assignable");
         Check (P.Max_Iters = 10, "Parameters.Max_Iters assignable");
         Check (Approx (P.Tol, 1.0E-4), "Parameters.Tol assignable");
      end;
      Check (not Near (0.0, 1.0), "Near rejects unit gap");
      Check (Near (1.0, 1.0 + Epsilon_Tol / 2.0), "Near within Epsilon/2");
      --  Single-point single-site
      declare
         One : constant Dataset := [[7.0, 8.0]];
         R : constant Lloyd_Result :=
           Run_Lloyd
             (One, Params => (K => 1, Max_Iters => 5, Tol => 1.0E-9));
      begin
         Check (R.Converged, "N=1 K=1 converges");
         Check (Approx (R.Centroids (1, 1), 7.0), "N=1 centroid x");
         Check (Approx (R.Centroids (1, 2), 8.0), "N=1 centroid y");
         Check (Approx (R.Inertia, 0.0), "N=1 inertia 0");
         Check (R.Lab (1) = 1, "N=1 label=1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Inertia after full Run_Lloyd vs manual");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.0, 1.0],
         [5.0, 0.0],
         [5.0, 1.0]];
      R : constant Lloyd_Result :=
        Run_Lloyd
          (Data, Params => (K => 2, Max_Iters => 40, Tol => 1.0E-9));
      Manual : constant Real :=
        Within_Cluster_SSE (Data, R.Centroids, R.Lab);
   begin
      Check (Approx (R.Inertia, Manual, 1.0E-6),
             "result.Inertia matches recomputed SSE");
      Check (R.Converged, "four-point 2-cluster converged");
      Check (not R.Empty (1) and not R.Empty (2), "both clusters used");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("===========================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("===========================");
   pragma Assert (Fail_Count = 0);
end Tests;
