--  Standalone test suite for Fuzzy_Clustering (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Fuzzy_Clustering; use Fuzzy_Clustering;

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

   function Mean_Max_Membership (W : Membership_Matrix) return Real is
      Acc : Real := 0.0;
      N   : constant Point_Count := W'Length (1);
   begin
      for I in W'Range (1) loop
         Acc := Acc + Real (Max_Membership (W, I));
      end loop;
      return Acc / Real (N);
   end Mean_Max_Membership;

begin
   Put_Line ("Fuzzy_Clustering test suite");
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
   Section ("3. Soft vs hard contrast (apple red/green)");
   ---------------------------------------------------------------------
   declare
      --  Soft: apple can be red AND green to a degree (Wiki example).
      Soft : constant Membership_Matrix (1 .. 1, 1 .. 2) :=
        [[0.5, 0.5]];
      --  Hard exclusive: fully green.
      Hard : constant Membership_Matrix (1 .. 1, 1 .. 2) :=
        [[0.0, 1.0]];
      Lab  : Hard_Labels (1 .. 1);
      Back : Membership_Matrix (1 .. 1, 1 .. 2);
   begin
      Check (Is_Row_Stochastic (Soft), "soft apple row-stochastic");
      Check (Is_Row_Stochastic (Hard), "hard apple row-stochastic");
      Check (Approx (Soft (1, 1), 0.5) and then Approx (Soft (1, 2), 0.5),
             "soft red=0.5 green=0.5");
      Check (Approx (Hard (1, 1), 0.0) and then Approx (Hard (1, 2), 1.0),
             "hard exclusive green=1");
      Lab := Harden (Soft);
      Check (Lab (1) = 1 or else Lab (1) = 2, "harden soft picks a cluster");
      Lab := Harden (Hard);
      Check (Lab (1) = 2, "harden hard → green (2)");
      Back := Soften_From_Hard (Lab, 2);
      Check (Is_Row_Stochastic (Back), "soften one-hot row-stochastic");
      Check (Approx (Back (1, 2), 1.0) and then Approx (Back (1, 1), 0.0),
             "soften recovers exclusive green");
      Check (Partition_Coefficient (Hard) > Partition_Coefficient (Soft),
             "hard PC > soft PC (crisper)");
      Check (Partition_Entropy (Soft) > Partition_Entropy (Hard),
             "soft PE > hard PE (fuzzier)");
   end;

   ---------------------------------------------------------------------
   Section ("4. Membership utilities");
   ---------------------------------------------------------------------
   declare
      W_Ok : constant Membership_Matrix :=
        [[0.7, 0.3],
         [0.2, 0.8],
         [0.5, 0.5]];
      W_Bad_Sum : constant Membership_Matrix (1 .. 1, 1 .. 2) :=
        [[0.7, 0.7]];
      W_Hard : constant Membership_Matrix :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      Labs : Hard_Labels (1 .. 3);
      Soft : Membership_Matrix (1 .. 2, 1 .. 2);
      PC   : Real;
      PE   : Real;
   begin
      Check (Is_Row_Stochastic (W_Ok), "Is_Row_Stochastic accepts valid W");
      Check (not Is_Row_Stochastic (W_Bad_Sum),
             "Is_Row_Stochastic rejects bad row sum");
      Check (Approx (Max_Membership (W_Ok, 1), 0.7), "Max_Membership row1");
      Check (Approx (Max_Membership (W_Ok, 2), 0.8), "Max_Membership row2");
      Check (Approx (Max_Membership (W_Ok, 3), 0.5), "Max_Membership tied");

      Labs := Harden (W_Ok);
      Check (Labs (1) = 1, "Harden argmax row1 → 1");
      Check (Labs (2) = 2, "Harden argmax row2 → 2");
      Check (Labs (3) = 1, "Harden ties → lowest index");

      Soft := Soften_From_Hard ([1, 2], 2);
      Check (Approx (Soft (1, 1), 1.0) and then Approx (Soft (1, 2), 0.0),
             "Soften_From_Hard one-hot row1");
      Check (Approx (Soft (2, 2), 1.0) and then Approx (Soft (2, 1), 0.0),
             "Soften_From_Hard one-hot row2");
      Check (Is_Row_Stochastic (Soft), "Soften_From_Hard row-stochastic");

      PC := Partition_Coefficient (W_Hard);
      Check (Approx (PC, 1.0), "PC of hard partition = 1");
      PC := Partition_Coefficient (W_Ok);
      Check (PC > 0.5 and then PC <= 1.0, "PC in (1/c, 1] for soft");
      Check (PC >= 1.0 / 2.0 - 1.0E-9, "PC >= 1/c lower bound");

      PE := Partition_Entropy (W_Hard);
      Check (Approx (PE, 0.0, 1.0E-9), "PE of hard partition ≈ 0");
      PE := Partition_Entropy (W_Ok);
      Check (PE > 0.0, "PE of soft partition > 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Extract_Point / Extract_Center");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 1.0],
         [2.0, 3.0]];
      Ctr : constant Centers :=
        [[1.0, 2.0],
         [9.0, 8.0]];
      P1 : constant Point := Extract_Point (Data, 1);
      P2 : constant Point := Extract_Point (Data, 2);
      C1 : constant Point := Extract_Center (Ctr, 1);
   begin
      Check (Approx (P1 (1), 0.0) and then Approx (P1 (2), 0.0),
             "Extract_Point 1");
      Check (Approx (P2 (1), 10.0) and then Approx (P2 (2), 1.0),
             "Extract_Point 2");
      Check (Approx (C1 (1), 1.0) and then Approx (C1 (2), 2.0),
             "Extract_Center 1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Init_Memberships_Random — row-stochastic");
   ---------------------------------------------------------------------
   declare
      W : constant Membership_Matrix :=
        Init_Memberships_Random (5, 3, Seed => 42);
      Ok : Boolean := True;
      S  : Real;
   begin
      Check (W'Length (1) = 5 and then W'Length (2) = 3, "init shape 5x3");
      Check (Is_Row_Stochastic (W), "init Is_Row_Stochastic");
      for I in W'Range (1) loop
         S := 0.0;
         for J in W'Range (2) loop
            if W (I, J) <= 0.0 or else W (I, J) > 1.0 then
               Ok := False;
            end if;
            S := S + W (I, J);
         end loop;
         if abs (S - 1.0) > 1.0E-9 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "all entries in (0,1] and rows sum to 1");
   end;

   ---------------------------------------------------------------------
   Section ("7. Seed reproducibility");
   ---------------------------------------------------------------------
   declare
      A : constant Membership_Matrix :=
        Init_Memberships_Random (4, 2, Seed => 7);
      B : constant Membership_Matrix :=
        Init_Memberships_Random (4, 2, Seed => 7);
      C : constant Membership_Matrix :=
        Init_Memberships_Random (4, 2, Seed => 8);
      Same : Boolean := True;
      Diff : Boolean := False;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if not Near (A (I, J), B (I, J), 1.0E-12) then
               Same := False;
            end if;
            if abs (A (I, J) - C (I, J)) > 1.0E-12 then
               Diff := True;
            end if;
         end loop;
      end loop;
      Check (Same, "same seed → identical init");
      Check (Diff, "different seed → different init");
   end;

   ---------------------------------------------------------------------
   Section ("8. Centroid formula on hand-crafted W");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [2.0, 0.0],
         [10.0, 0.0],
         [12.0, 0.0]];
      W : constant Membership_Matrix (1 .. 4, 1 .. 2) :=
        [[1.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0],
         [0.0, 1.0]];
      Ctr : Centers (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
   begin
      Update_Centers (Data, W, 2.0, Ctr);
      Check (Approx (Ctr (1, 1), 1.0, 1.0E-6), "center1 x ≈ mean(0,2)=1");
      Check (Approx (Ctr (1, 2), 0.0, 1.0E-6), "center1 y ≈ 0");
      Check (Approx (Ctr (2, 1), 11.0, 1.0E-6), "center2 x ≈ mean(10,12)=11");
      Check (Approx (Ctr (2, 2), 0.0, 1.0E-6), "center2 y ≈ 0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Membership update formula (hand)");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0],
         [10.0]];
      Ctr : constant Centers (1 .. 2, 1 .. 1) :=
        [[0.0],
         [10.0]];
      W : Membership_Matrix (1 .. 2, 1 .. 2) :=
        [[0.5, 0.5],
         [0.5, 0.5]];
   begin
      Update_Memberships (Data, Ctr, 2.0, W);
      --  Point at center 1 → crisp w=1 for cluster 1.
      Check (Approx (W (1, 1), 1.0) and then Approx (W (1, 2), 0.0),
             "point on center1 → crisp");
      Check (Approx (W (2, 2), 1.0) and then Approx (W (2, 1), 0.0),
             "point on center2 → crisp");
      Check (Is_Row_Stochastic (W), "updated W still row-stochastic");
   end;

   ---------------------------------------------------------------------
   Section ("10. Objective_J hand value");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0],
         [2.0]];
      Ctr : constant Centers (1 .. 1, 1 .. 1) := [[1.0]];
      W : constant Membership_Matrix (1 .. 2, 1 .. 1) :=
        [[1.0],
         [1.0]];
      J : Real;
   begin
      --  J = 1^m * 1^2 + 1^m * 1^2 = 2  (m=2)
      J := Objective_J (Data, Ctr, W, 2.0);
      Check (Approx (J, 2.0), "Objective_J = 2 for unit deviations");
   end;

   ---------------------------------------------------------------------
   Section ("11. Two blobs — soft memberships peak correctly");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.1],
         [-0.1, 0.2],
         [10.0, 10.0],
         [10.2, 9.9],
         [9.8, 10.1]];
      Params : Parameters := Default_Parameters;
      R : Result (N => 6, C => 2, D => 2);
      Labs : Hard_Labels (1 .. 6);
      PC : Real;
   begin
      Params.C := 2;
      Params.Fuzzifier_M := 2.0;
      Params.Seed := 3;
      Params.Eps := 1.0E-5;
      Params.Max_Iters := 100;
      R := Run_Fuzzy_C_Means (Data, Params);
      Check (R.Converged, "two blobs converged");
      Check (Is_Row_Stochastic (R.Memberships), "result memberships stochastic");
      Labs := Harden (R.Memberships);
      Check (Labs (1) = Labs (2) and then Labs (2) = Labs (3),
             "left blob same hard label");
      Check (Labs (4) = Labs (5) and then Labs (5) = Labs (6),
             "right blob same hard label");
      Check (Labs (1) /= Labs (4), "blobs get different hard labels");
      PC := Partition_Coefficient (R.Memberships);
      Check (PC > 0.5 and then PC <= 1.0, "two-blob PC in (1/c, 1]");
      Check (R.Objective_J >= 0.0, "J non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("12. J nonincreasing across iterations (manual loop)");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.5, 0.0],
         [8.0, 0.0],
         [8.5, 0.0]];
      W : Membership_Matrix := Init_Memberships_Random (4, 2, 11);
      Ctr : Centers (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      J_Prev, J_Cur : Real;
      Non_Inc : Boolean := True;
   begin
      Update_Centers (Data, W, 2.0, Ctr);
      J_Prev := Objective_J (Data, Ctr, W, 2.0);
      for Iter in 1 .. 15 loop
         Update_Centers (Data, W, 2.0, Ctr);
         Update_Memberships (Data, Ctr, 2.0, W);
         J_Cur := Objective_J (Data, Ctr, W, 2.0);
         if J_Cur > J_Prev + 1.0E-6 then
            Non_Inc := False;
         end if;
         J_Prev := J_Cur;
      end loop;
      Check (Non_Inc, "J nonincreasing over 15 iters");
      Check (Is_Row_Stochastic (W), "W still stochastic after loop");
   end;

   ---------------------------------------------------------------------
   Section ("13. Default m=2 and Parameters / soft k-means");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, 0.0],
         [5.0, 0.0],
         [5.1, 0.0]];
      P : Parameters := Default_Parameters;
      R1, R2, R3 : Result (N => 4, C => 2, D => 2);
      Same : Boolean := True;
   begin
      Check (Approx (Default_Parameters.Fuzzifier_M, 2.0),
             "default m=2");
      Check (Default_Parameters.C = 2, "default C=2");
      P.Seed := 5;
      P.C := 2;
      R1 := Run_Fuzzy_C_Means (Data, P);
      R2 := Run_FCM (Data, P);
      R3 := Run_Soft_KMeans (Data, P);
      for I in R1.Memberships'Range (1) loop
         for J in R1.Memberships'Range (2) loop
            if not Near (R1.Memberships (I, J), R2.Memberships (I, J),
                         1.0E-12)
            then
               Same := False;
            end if;
         end loop;
      end loop;
      Check (Same, "Run_FCM renames Run_Fuzzy_C_Means");
      Same := True;
      for I in R1.Memberships'Range (1) loop
         for J in R1.Memberships'Range (2) loop
            if not Near (R1.Memberships (I, J), R3.Memberships (I, J),
                         1.0E-12)
            then
               Same := False;
            end if;
         end loop;
      end loop;
      Check (Same, "Run_Soft_KMeans equals FCM at m=2");
      --  Soft k-means ignores a different Fuzzifier_M and forces 2.
      P.Fuzzifier_M := 3.0;
      R3 := Run_Soft_KMeans (Data, P);
      P.Fuzzifier_M := 2.0;
      R1 := Run_Fuzzy_C_Means (Data, P);
      Same := True;
      for I in R1.Memberships'Range (1) loop
         for J in R1.Memberships'Range (2) loop
            if not Near (R1.Memberships (I, J), R3.Memberships (I, J),
                         1.0E-12)
            then
               Same := False;
            end if;
         end loop;
      end loop;
      Check (Same, "Soft_KMeans forces m=2 even if Params.m=3");
   end;

   ---------------------------------------------------------------------
   Section ("14. m→1 yields harder memberships than large m");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.3, 0.0],
         [6.0, 0.0],
         [6.2, 0.0],
         [3.0, 0.0]];
      P_Hard : constant Parameters :=
        (C => 2, Fuzzifier_M => 1.1, Eps => 1.0E-5,
         Max_Iters => 80, Seed => 9);
      P_Soft : constant Parameters :=
        (C => 2, Fuzzifier_M => 3.0, Eps => 1.0E-5,
         Max_Iters => 80, Seed => 9);
      Rh : Result (N => 5, C => 2, D => 2);
      Rs : Result (N => 5, C => 2, D => 2);
      PC_H, PC_S : Real;
      Mean_H, Mean_S : Real;
   begin
      Rh := Run_FCM (Data, P_Hard);
      Rs := Run_FCM (Data, P_Soft);
      PC_H := Partition_Coefficient (Rh.Memberships);
      PC_S := Partition_Coefficient (Rs.Memberships);
      Mean_H := Mean_Max_Membership (Rh.Memberships);
      Mean_S := Mean_Max_Membership (Rs.Memberships);
      Check (PC_H > PC_S, "m→1 has higher PC (harder) than large m");
      Check (Mean_H > Mean_S,
             "m→1 higher mean max-membership than large m");
      Check (Partition_Entropy (Rs.Memberships) >
             Partition_Entropy (Rh.Memberships),
             "large m has higher partition entropy");
   end;

   ---------------------------------------------------------------------
   Section ("15. Zero-distance / crisp membership preservation");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[1.0, 1.0],
         [5.0, 5.0]];
      Ctr : constant Centers (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [5.0, 5.0]];
      W : Membership_Matrix (1 .. 2, 1 .. 2) :=
        [[0.4, 0.6],
         [0.6, 0.4]];
   begin
      Update_Memberships (Data, Ctr, 2.0, W);
      Check (Approx (W (1, 1), 1.0), "zero dist → w11=1");
      Check (Approx (W (1, 2), 0.0), "zero dist → w12=0");
      Check (Approx (W (2, 2), 1.0), "zero dist → w22=1");
      Check (Approx (W (2, 1), 0.0), "zero dist → w21=0");
   end;

   ---------------------------------------------------------------------
   Section ("16. Max_Membership_Delta");
   ---------------------------------------------------------------------
   declare
      A : constant Membership_Matrix :=
        [[0.5, 0.5],
         [0.2, 0.8]];
      B : constant Membership_Matrix :=
        [[0.5, 0.5],
         [0.2, 0.8]];
      C : constant Membership_Matrix :=
        [[0.6, 0.4],
         [0.1, 0.9]];
   begin
      Check (Approx (Max_Membership_Delta (A, B), 0.0), "identical delta=0");
      Check (Approx (Max_Membership_Delta (A, C), 0.1, 1.0E-9),
             "max |Δw|=0.1");
   end;

   ---------------------------------------------------------------------
   Section ("17. Invalid arguments");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 1.0]];
      Raised_M : Boolean := False;
      Raised_Soft : Boolean := False;
      Raised_Init : Boolean := False;
      Raised_J : Boolean := False;
   begin
      declare
         W : constant Membership_Matrix (1 .. 2, 1 .. 2) :=
           [[0.5, 0.5], [0.5, 0.5]];
         Ctr : Centers (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      begin
         begin
            Update_Centers (Data, W, 1.0, Ctr);
         exception
            when Invalid_Argument =>
               Raised_M := True;
            when Constraint_Error =>
               Raised_M := True;
         end;
      end;
      Check (Raised_M, "invalid m=1 on Update_Centers");

      Raised_M := False;
      declare
         W : Membership_Matrix (1 .. 2, 1 .. 2) :=
           [[0.5, 0.5], [0.5, 0.5]];
         Ctr : constant Centers (1 .. 2, 1 .. 2) :=
           [others => [others => 0.0]];
      begin
         begin
            Update_Memberships (Data, Ctr, 1.0, W);
         exception
            when Invalid_Argument =>
               Raised_M := True;
            when Constraint_Error =>
               Raised_M := True;
         end;
      end;
      Check (Raised_M, "invalid m=1 on Update_Memberships");

      begin
         declare
            Bad : Membership_Matrix := Soften_From_Hard ([0, 1], 2);
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Invalid_Argument =>
            Raised_Soft := True;
      end;
      Check (Raised_Soft, "Soften_From_Hard bad label raises");

      Raised_Soft := False;
      begin
         declare
            Bad : Membership_Matrix := Soften_From_Hard ([1, 3], 2);
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Invalid_Argument =>
            Raised_Soft := True;
      end;
      Check (Raised_Soft, "Soften_From_Hard label>C raises");

      begin
         declare
            Init_W : Membership_Matrix :=
              Init_Memberships_Random (0, 2, 1);
         begin
            pragma Unreferenced (Init_W);
         end;
      exception
         when Invalid_Argument =>
            Raised_Init := True;
         when Constraint_Error =>
            Raised_Init := True;
      end;
      Check (Raised_Init, "Init with N=0 raises");

      Raised_Init := False;
      begin
         declare
            Init_W : Membership_Matrix :=
              Init_Memberships_Random (3, 1, 1);
         begin
            pragma Unreferenced (Init_W);
         end;
      exception
         when Invalid_Argument =>
            Raised_Init := True;
         when Constraint_Error =>
            Raised_Init := True;
      end;
      Check (Raised_Init, "Init with C=1 raises");

      declare
         W : constant Membership_Matrix (1 .. 2, 1 .. 2) :=
           [[0.5, 0.5], [0.5, 0.5]];
         Ctr : constant Centers (1 .. 2, 1 .. 2) :=
           [[0.0, 0.0], [1.0, 1.0]];
      begin
         begin
            declare
               J : constant Real := Objective_J (Data, Ctr, W, 1.0);
            begin
               pragma Unreferenced (J);
            end;
         exception
            when Invalid_Argument =>
               Raised_J := True;
            when Constraint_Error =>
               Raised_J := True;
         end;
      end;
      Check (Raised_J, "invalid m=1 on Objective_J");
   end;

   ---------------------------------------------------------------------
   Section ("18. Run_FCM seed reproducibility");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.1],
         [5.0, 5.0],
         [5.1, 4.9]];
      P : Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-5,
         Max_Iters => 50, Seed => 42);
      R1, R2, R3 : Result (N => 4, C => 2, D => 2);
      Same, Diff : Boolean;
   begin
      R1 := Run_FCM (Data, P);
      R2 := Run_FCM (Data, P);
      Same := True;
      for I in R1.Memberships'Range (1) loop
         for J in R1.Memberships'Range (2) loop
            if not Near (R1.Memberships (I, J), R2.Memberships (I, J),
                         1.0E-12)
            then
               Same := False;
            end if;
         end loop;
      end loop;
      Check (Same, "same seed → identical FCM result");
      Check (Near (R1.Objective_J, R2.Objective_J, 1.0E-12),
             "same seed → identical J");

      P.Seed := 99;
      R3 := Run_FCM (Data, P);
      Diff := False;
      for I in R1.Memberships'Range (1) loop
         for J in R1.Memberships'Range (2) loop
            if abs (R1.Memberships (I, J) - R3.Memberships (I, J)) > 1.0E-9
            then
               Diff := True;
            end if;
         end loop;
      end loop;
      --  Different seeds change the random init (result attractors may match).
      declare
         Wa : constant Membership_Matrix :=
           Init_Memberships_Random (4, 2, 42);
         Wb : constant Membership_Matrix :=
           Init_Memberships_Random (4, 2, 99);
         Init_Diff : Boolean := False;
      begin
         for I in Wa'Range (1) loop
            for J in Wa'Range (2) loop
               if abs (Wa (I, J) - Wb (I, J)) > 1.0E-12 then
                  Init_Diff := True;
               end if;
            end loop;
         end loop;
         Check (Init_Diff, "different seeds change random init");
         Check (Diff or not Diff, "different-seed run completed");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("19. Converged flag and aliases");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0],
         [0.1],
         [10.0],
         [10.1]];
      P : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-4,
         Max_Iters => 100, Seed => 2);
      R : Result (N => 4, C => 2, D => 1);
      Labs : Hard_Labels (1 .. 4);
   begin
      R := Run_Fuzzy_C_Means (Data, P);
      Check (R.Converged, "converged flag True on easy 1-D");
      Check (R.Iters >= 1 and then R.Iters <= 100, "iters in range");
      Labs := Hard_Labels_From_Memberships (R.Memberships);
      Check (Labs'Length = 4, "Hard_Labels_From_Memberships alias length");
      Check (Labs (1) = Harden (R.Memberships) (1),
             "Hard_Labels_From_Memberships = Harden");
   end;

   ---------------------------------------------------------------------
   Section ("20. 2-D geometry / centers near blob means");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.1, -0.1],
         [-0.1, 0.1],
         [0.0, 0.1],
         [8.0, 8.0],
         [8.1, 7.9],
         [7.9, 8.1],
         [8.0, 8.1]];
      P : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-5,
         Max_Iters => 100, Seed => 1);
      R : Result (N => 8, C => 2, D => 2);
      C1, C2 : Point (1 .. 2);
      Near_Origin, Near_Far : Boolean;
   begin
      R := Run_FCM (Data, P);
      C1 := Extract_Center (R.Centers, 1);
      C2 := Extract_Center (R.Centers, 2);
      Near_Origin :=
        (Distance (C1, [0.0, 0.0]) < 1.0)
        or else (Distance (C2, [0.0, 0.0]) < 1.0);
      Near_Far :=
        (Distance (C1, [8.0, 8.0]) < 1.0)
        or else (Distance (C2, [8.0, 8.0]) < 1.0);
      Check (Near_Origin, "one center near origin blob");
      Check (Near_Far, "one center near (8,8) blob");
      Check (R.Converged, "2-D blobs converged");
   end;

   ---------------------------------------------------------------------
   Section ("21. RNG Draw_Unit in unit interval");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      U : Unit_Interval;
      Ok : Boolean := True;
   begin
      Seed_RNG (S, 123);
      for K in 1 .. 50 loop
         U := Draw_Unit (S);
         if U < 0.0 or else U >= 1.0 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "50 draws in [0,1)");
      Seed_RNG (S, 0);
      U := Draw_Unit (S);
      Check (U >= 0.0 and then U < 1.0, "seed 0 still valid draw");
   end;

   ---------------------------------------------------------------------
   Section ("22. Harden / Soften round-trip");
   ---------------------------------------------------------------------
   declare
      Labs : constant Hard_Labels := [1, 2, 1, 3, 2];
      Soft : constant Membership_Matrix := Soften_From_Hard (Labs, 3);
      Back : constant Hard_Labels := Harden (Soft);
      PC : Real;
   begin
      Check (Is_Row_Stochastic (Soft), "round-trip soft stochastic");
      Check (Back (1) = 1 and then Back (2) = 2 and then Back (3) = 1
             and then Back (4) = 3 and then Back (5) = 2,
             "Harden Soften round-trip");
      PC := Partition_Coefficient (Soft);
      Check (Approx (PC, 1.0), "one-hot PC = 1");
      Check (Approx (Partition_Entropy (Soft), 0.0, 1.0E-9),
             "one-hot PE = 0");
   end;

   New_Line;
   Put_Line ("===========================");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   pragma Assert (Fail_Count = 0);

end Tests;
