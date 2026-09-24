--  Standalone test suite for Fuzzy_C_Means (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Fuzzy_C_Means; use Fuzzy_C_Means;

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

   function Row_Sum
     (W : Membership_Matrix; I : Point_Index) return Real
   is
      S : Real := 0.0;
   begin
      for J in W'Range (2) loop
         S := S + W (I, J);
      end loop;
      return S;
   end Row_Sum;

begin
   Put_Line ("Fuzzy_C_Means test suite");
   Put_Line ("========================");

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
   Section ("3. Extract_Point / Extract_Center");
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
      Check (Approx (P1 (1), 0.0) and Approx (P1 (2), 0.0), "extract p1");
      Check (Approx (P2 (1), 10.0) and Approx (P2 (2), 1.0), "extract p2");
      Check (Approx (C1 (1), 1.0) and Approx (C1 (2), 2.0), "extract c1");
      Check (P1'Length = 2, "extract length 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Init_Memberships_Random — row-stochastic");
   ---------------------------------------------------------------------
   declare
      W : constant Membership_Matrix :=
        Init_Memberships_Random (N => 5, C => 3, Seed => 7);
      All_In_Unit : Boolean := True;
      All_Sum_1   : Boolean := True;
   begin
      Check (W'Length (1) = 5, "init N=5");
      Check (W'Length (2) = 3, "init C=3");
      for I in W'Range (1) loop
         if not Approx (Row_Sum (W, I), 1.0, 1.0E-9) then
            All_Sum_1 := False;
         end if;
         for J in W'Range (2) loop
            if W (I, J) < 0.0 or else W (I, J) > 1.0 then
               All_In_Unit := False;
            end if;
         end loop;
      end loop;
      Check (All_Sum_1, "all rows sum to 1");
      Check (All_In_Unit, "all memberships in [0,1]");
      Check (W (1, 1) > 0.0, "membership positive");
   end;

   ---------------------------------------------------------------------
   Section ("5. Seed reproducibility");
   ---------------------------------------------------------------------
   declare
      A : constant Membership_Matrix :=
        Init_Memberships_Random (4, 2, Seed => 42);
      B : constant Membership_Matrix :=
        Init_Memberships_Random (4, 2, Seed => 42);
      C : constant Membership_Matrix :=
        Init_Memberships_Random (4, 2, Seed => 99);
      Same_AB : Boolean := True;
      Diff_AC : Boolean := False;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if not Near (A (I, J), B (I, J)) then
               Same_AB := False;
            end if;
            if not Near (A (I, J), C (I, J)) then
               Diff_AC := True;
            end if;
         end loop;
      end loop;
      Check (Same_AB, "same seed → identical memberships");
      Check (Diff_AC, "different seed → different memberships");
   end;

   ---------------------------------------------------------------------
   Section ("6. Centroid formula on hand-crafted W");
   ---------------------------------------------------------------------
   --  Two points (0,0) and (10,0); C=2.
   --  W = [[1,0],[0,1]] hard → centers at the points themselves.
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      W : constant Membership_Matrix :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      Ctr : Centers :=
        [[5.0, 5.0],
         [5.0, 5.0]];
   begin
      Update_Centers (Data, W, 2.0, Ctr);
      Check (Approx (Ctr (1, 1), 0.0), "hard W → c1.x = 0");
      Check (Approx (Ctr (1, 2), 0.0), "hard W → c1.y = 0");
      Check (Approx (Ctr (2, 1), 10.0), "hard W → c2.x = 10");
      Check (Approx (Ctr (2, 2), 0.0), "hard W → c2.y = 0");
   end;

   --  Equal memberships → both centers at data mean (5, 0).
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      W : constant Membership_Matrix :=
        [[0.5, 0.5],
         [0.5, 0.5]];
      Ctr : Centers :=
        [[0.0, 0.0],
         [0.0, 0.0]];
   begin
      Update_Centers (Data, W, 2.0, Ctr);
      Check (Approx (Ctr (1, 1), 5.0), "equal W → c1.x = mean");
      Check (Approx (Ctr (2, 1), 5.0), "equal W → c2.x = mean");
      Check (Approx (Ctr (1, 2), 0.0), "equal W → c1.y = 0");
   end;

   --  Soft weights: w1=[0.8,0.2], w2=[0.2,0.8], m=2
   --  For cluster 1: num = 0.8^2*(0) + 0.2^2*(10) = 0.4; den = 0.64+0.04=0.68
   --  c1.x = 0.4/0.68 ≈ 0.588235
   declare
      Data : constant Dataset :=
        [[0.0],
         [10.0]];
      W : constant Membership_Matrix :=
        [[0.8, 0.2],
         [0.2, 0.8]];
      Ctr : Centers := [[0.0], [0.0]];
      Expected : constant Real := 0.4 / 0.68;
   begin
      Update_Centers (Data, W, 2.0, Ctr);
      Check (Approx (Ctr (1, 1), Expected, 1.0E-6),
             "soft W m=2 centroid formula c1");
      Check (Approx (Ctr (2, 1), 10.0 - Expected, 1.0E-6),
             "soft W m=2 centroid formula c2 symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("7. Membership update formula (hand)");
   ---------------------------------------------------------------------
   --  Point at 0; centers at 0 and 10; m=2 → exp = 2/(2-1)=2
   --  d1=0 → zero-distance case → w=[1,0]
   declare
      Data : constant Dataset := [[0.0]];
      Ctr  : constant Centers := [[0.0], [10.0]];
      W    : Membership_Matrix (1 .. 1, 1 .. 2) := [[0.5, 0.5]];
   begin
      Update_Memberships (Data, Ctr, 2.0, W);
      Check (Approx (W (1, 1), 1.0), "zero-dist → w_i1=1");
      Check (Approx (W (1, 2), 0.0), "zero-dist → w_i2=0");
   end;

   --  Point at 5 (midpoint); centers at 0 and 10; m=2
   --  d1=d2=5 → w = [0.5, 0.5]
   declare
      Data : constant Dataset := [[5.0]];
      Ctr  : constant Centers := [[0.0], [10.0]];
      W    : Membership_Matrix (1 .. 1, 1 .. 2) := [[0.1, 0.9]];
   begin
      Update_Memberships (Data, Ctr, 2.0, W);
      Check (Approx (W (1, 1), 0.5, 1.0E-6), "midpoint w1=0.5");
      Check (Approx (W (1, 2), 0.5, 1.0E-6), "midpoint w2=0.5");
      Check (Approx (Row_Sum (W, 1), 1.0), "midpoint row sum 1");
   end;

   --  Point at 1; centers at 0 and 10; m=2
   --  d1=1, d2=9
   --  w1 = 1 / ( (1/1)^2 + (1/9)^2 ) = 1 / (1 + 1/81) = 81/82 ≈ 0.987805
   --  w2 = 1 / ( (9/1)^2 + (9/9)^2 ) = 1 / (81 + 1) = 1/82 ≈ 0.012195
   declare
      Data : constant Dataset := [[1.0]];
      Ctr  : constant Centers := [[0.0], [10.0]];
      W    : Membership_Matrix (1 .. 1, 1 .. 2) := [[0.5, 0.5]];
      W1   : constant Real := 81.0 / 82.0;
      W2   : constant Real := 1.0 / 82.0;
   begin
      Update_Memberships (Data, Ctr, 2.0, W);
      Check (Approx (W (1, 1), W1, 1.0E-5), "hand formula w1 near c1");
      Check (Approx (W (1, 2), W2, 1.0E-5), "hand formula w2 far");
      Check (Approx (Row_Sum (W, 1), 1.0), "hand formula row sum");
   end;

   ---------------------------------------------------------------------
   Section ("8. Objective_J hand value");
   ---------------------------------------------------------------------
   --  Points (0),(10); centers (0),(10); W hard → J = 0
   declare
      Data : constant Dataset := [[0.0], [10.0]];
      Ctr  : constant Centers := [[0.0], [10.0]];
      W    : constant Membership_Matrix :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      J : constant Real := Objective_J (Data, Ctr, W, 2.0);
   begin
      Check (Approx (J, 0.0), "hard perfect fit J=0");
   end;

   --  Same data; equal W 0.5; centers at 0 and 10
   --  For i=1 (x=0): 0.5^2 * 0^2 + 0.5^2 * 10^2 = 0.25*100 = 25
   --  For i=2 (x=10): same 25 → J = 50
   declare
      Data : constant Dataset := [[0.0], [10.0]];
      Ctr  : constant Centers := [[0.0], [10.0]];
      W    : constant Membership_Matrix :=
        [[0.5, 0.5],
         [0.5, 0.5]];
      J : constant Real := Objective_J (Data, Ctr, W, 2.0);
   begin
      Check (Approx (J, 50.0, 1.0E-4), "equal soft W J=50");
   end;

   ---------------------------------------------------------------------
   Section ("9. Two blobs — soft memberships peak correctly");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.2, 0.1],
         [-0.1, 0.2],
         [10.0, 10.0],
         [10.2, 9.9],
         [9.8, 10.1]];
      Params : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-6,
         Max_Iters => 200, Seed => 3);
      R : constant Result := Run_FCM (Data, Params);
      Lab : constant Hard_Labels :=
        Hard_Labels_From_Memberships (R.Memberships);
      Left_Label  : Natural;
      Right_Label : Natural;
      Soft_OK     : Boolean := True;
   begin
      Check (R.Iters >= 1, "two-blob ran ≥1 iter");
      Check (R.Memberships'Length (1) = 6, "two-blob N=6");
      Check (R.Memberships'Length (2) = 2, "two-blob C=2");
      --  Row-stochastic after fit
      for I in R.Memberships'Range (1) loop
         Check (Approx (Row_Sum (R.Memberships, I), 1.0, 1.0E-5),
                "two-blob row sum @" & Integer'Image (I));
      end loop;
      --  Hard labels: first 3 same cluster, last 3 other
      Left_Label := Lab (1);
      Right_Label := Lab (4);
      Check (Left_Label /= Right_Label, "blobs get different hard labels");
      Check (Lab (2) = Left_Label and Lab (3) = Left_Label,
             "left blob same hard label");
      Check (Lab (5) = Right_Label and Lab (6) = Right_Label,
             "right blob same hard label");
      --  Soft: left points peak on Left_Label cluster
      for I in 1 .. 3 loop
         if R.Memberships (I, Cluster_Index (Left_Label)) < 0.7 then
            Soft_OK := False;
         end if;
      end loop;
      for I in 4 .. 6 loop
         if R.Memberships (I, Cluster_Index (Right_Label)) < 0.7 then
            Soft_OK := False;
         end if;
      end loop;
      Check (Soft_OK, "soft memberships peak on correct cluster (>0.7)");
      Check (R.Objective_J >= 0.0, "J non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("10. J nonincreasing across iterations (manual loop)");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [0.5], [1.0], [8.0], [8.5], [9.0]];
      W : Membership_Matrix :=
        Init_Memberships_Random (6, 2, Seed => 11);
      Ctr : Centers (1 .. 2, 1 .. 1) := [[0.0], [0.0]];
      J_Prev, J_Cur : Real;
      Non_Inc : Boolean := True;
      M : constant Fuzzifier := 2.0;
   begin
      Update_Centers (Data, W, M, Ctr);
      J_Prev := Objective_J (Data, Ctr, W, M);
      for Step in 1 .. 15 loop
         Update_Centers (Data, W, M, Ctr);
         Update_Memberships (Data, Ctr, M, W);
         J_Cur := Objective_J (Data, Ctr, W, M);
         --  Allow tiny numerical rise
         if J_Cur > J_Prev + 1.0E-6 then
            Non_Inc := False;
         end if;
         J_Prev := J_Cur;
      end loop;
      Check (Non_Inc, "J nonincreasing over 15 FCM steps");
      Check (J_Prev >= 0.0, "final J >= 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Default m=2 and Parameters");
   ---------------------------------------------------------------------
   declare
      P : constant Parameters := Default_Parameters;
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [10.0, 0.0],
         [11.0, 0.0]];
      R : constant Result := Run_Fuzzy_C_Means (Data);
   begin
      Check (Approx (P.Fuzzifier_M, 2.0), "default m=2");
      Check (P.C = 2, "default C=2");
      Check (P.Max_Iters = 100, "default Max_Iters=100");
      Check (R.C = 2, "Run default C=2");
      Check (R.Memberships'Length (2) = 2, "Run default memberships C");
      Check (R.Iters >= 1, "Run default did work");
      Check (R.Objective_J >= 0.0, "Run default J>=0");
   end;

   ---------------------------------------------------------------------
   Section ("12. m→1 yields harder memberships than large m");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [0.3], [0.6], [5.0], [5.3], [5.6]];
      Soft : constant Parameters :=
        (C => 2, Fuzzifier_M => 3.0, Eps => 1.0E-6,
         Max_Iters => 150, Seed => 5);
      Harder : constant Parameters :=
        (C => 2, Fuzzifier_M => 1.1, Eps => 1.0E-6,
         Max_Iters => 150, Seed => 5);
      R_Soft : constant Result := Run_FCM (Data, Soft);
      R_Hard : constant Result := Run_FCM (Data, Harder);
      PC_Soft : constant Real :=
        Partition_Coefficient (R_Soft.Memberships);
      PC_Hard : constant Real :=
        Partition_Coefficient (R_Hard.Memberships);
      Max_Soft, Max_Hard : Real := 0.0;
   begin
      for I in R_Soft.Memberships'Range (1) loop
         for J in R_Soft.Memberships'Range (2) loop
            if R_Soft.Memberships (I, J) > Max_Soft then
               Max_Soft := R_Soft.Memberships (I, J);
            end if;
         end loop;
      end loop;
      for I in R_Hard.Memberships'Range (1) loop
         for J in R_Hard.Memberships'Range (2) loop
            if R_Hard.Memberships (I, J) > Max_Hard then
               Max_Hard := R_Hard.Memberships (I, J);
            end if;
         end loop;
      end loop;
      Check (PC_Hard > PC_Soft, "m→1 higher partition coefficient");
      Check (Max_Hard >= Max_Soft - 1.0E-6,
             "m→1 peak membership >= softer m");
      Check (PC_Hard <= 1.0 + 1.0E-6, "PC <= 1");
      Check (PC_Soft >= 0.5 - 1.0E-3, "PC >= ~1/C for C=2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Zero-distance / crisp membership preservation");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      Ctr : constant Centers :=
        [[0.0, 0.0],
         [10.0, 0.0]];
      W : Membership_Matrix (1 .. 2, 1 .. 2) :=
        [[0.3, 0.7],
         [0.6, 0.4]];
   begin
      Update_Memberships (Data, Ctr, 2.0, W);
      Check (Approx (W (1, 1), 1.0), "point1 on c1 → w11=1");
      Check (Approx (W (1, 2), 0.0), "point1 on c1 → w12=0");
      Check (Approx (W (2, 2), 1.0), "point2 on c2 → w22=1");
      Check (Approx (W (2, 1), 0.0), "point2 on c2 → w21=0");
   end;

   ---------------------------------------------------------------------
   Section ("14. Hard labels match argmax");
   ---------------------------------------------------------------------
   declare
      W : constant Membership_Matrix :=
        [[0.1, 0.7, 0.2],
         [0.9, 0.05, 0.05],
         [0.2, 0.3, 0.5],
         [0.4, 0.4, 0.2]];  -- tie 0.4/0.4 → lowest index = 1
      Lab : constant Hard_Labels := Hard_Labels_From_Memberships (W);
   begin
      Check (Lab (1) = 2, "argmax row1 → 2");
      Check (Lab (2) = 1, "argmax row2 → 1");
      Check (Lab (3) = 3, "argmax row3 → 3");
      Check (Lab (4) = 1, "tie → lowest index 1");
      Check (Lab'Length = 4, "hard labels length");
   end;

   ---------------------------------------------------------------------
   Section ("15. Partition coefficient bounds");
   ---------------------------------------------------------------------
   declare
      Hard_W : constant Membership_Matrix :=
        [[1.0, 0.0],
         [0.0, 1.0],
         [1.0, 0.0]];
      Soft_W : constant Membership_Matrix :=
        [[0.5, 0.5],
         [0.5, 0.5],
         [0.5, 0.5]];
      PC_H : constant Real := Partition_Coefficient (Hard_W);
      PC_S : constant Real := Partition_Coefficient (Soft_W);
   begin
      Check (Approx (PC_H, 1.0), "hard partition PC=1");
      Check (Approx (PC_S, 0.5), "equal soft PC=1/C=0.5");
      Check (PC_H > PC_S, "harder PC > softer PC");
   end;

   ---------------------------------------------------------------------
   Section ("16. Max_Membership_Delta");
   ---------------------------------------------------------------------
   declare
      A : constant Membership_Matrix :=
        [[0.5, 0.5],
         [0.2, 0.8]];
      B : constant Membership_Matrix :=
        [[0.6, 0.4],
         [0.2, 0.8]];
      D0 : constant Real := Max_Membership_Delta (A, A);
      D1 : constant Real := Max_Membership_Delta (A, B);
   begin
      Check (Approx (D0, 0.0), "identical matrices delta=0");
      Check (Approx (D1, 0.1, 1.0E-9), "delta = 0.1");
   end;

   ---------------------------------------------------------------------
   Section ("17. Invalid arguments");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [1.0], [2.0]];
      Raised_M : Boolean := False;
      Raised_C : Boolean := False;
      Raised_C1 : Boolean := False;
   begin
      begin
         declare
            Bad : constant Parameters :=
              (C => 2, Fuzzifier_M => 1.0, Eps => 1.0E-5,
               Max_Iters => 10, Seed => 1);
            R : Result (3, 2, 1);
         begin
            --  m=1 is invalid; Pre may or may not fire at runtime depending
            --  on assertion policy — call body path that checks.
            R := Run_Fuzzy_C_Means (Data, Bad);
            pragma Unreferenced (R);
         exception
            when Invalid_Argument =>
               Raised_M := True;
            when others =>
               Raised_M := True;  -- Constraint_Error from subtype also OK
         end;
      end;
      --  Fuzzifier subtype range starts at 1.0; m=1.0 may pass subtype but
      --  Run checks M <= 1.0.  Also try m via Update which checks.
      declare
         W : constant Membership_Matrix :=
           [[0.5, 0.5], [0.5, 0.5], [0.5, 0.5]];
         Ctr : Centers := [[0.0], [1.0]];
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
      Check (Raised_M, "m<=1 raises Invalid_Argument/Constraint_Error");

      begin
         declare
            Bad_C : constant Parameters :=
              (C => 1, Fuzzifier_M => 2.0, Eps => 1.0E-5,
               Max_Iters => 10, Seed => 1);
            R : Result (3, 1, 1);
         begin
            R := Run_Fuzzy_C_Means (Data, Bad_C);
            pragma Unreferenced (R);
         exception
            when Invalid_Argument =>
               Raised_C := True;
            when Constraint_Error =>
               Raised_C := True;
            when others =>
               Raised_C := True;
         end;
      end;
      --  Also init with C=1
      begin
         declare
            W : Membership_Matrix :=
              Init_Memberships_Random (3, 1, 1);
         begin
            pragma Unreferenced (W);
         end;
      exception
         when Invalid_Argument =>
            Raised_C1 := True;
         when Constraint_Error =>
            Raised_C1 := True;
      end;
      Check (Raised_C or Raised_C1, "C<2 raises");
      --  C > N
      declare
         Raised_CN : Boolean := False;
      begin
         begin
            declare
               Bad : constant Parameters :=
                 (C => 4, Fuzzifier_M => 2.0, Eps => 1.0E-5,
                  Max_Iters => 10, Seed => 1);
               R : Result (3, 4, 1);
            begin
               R := Run_Fuzzy_C_Means (Data, Bad);
               pragma Unreferenced (R);
            end;
         exception
            when Invalid_Argument =>
               Raised_CN := True;
            when others =>
               Raised_CN := True;
         end;
         Check (Raised_CN, "C>N raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("18. Run_FCM seed reproducibility");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [0.5, 0.1],
         [8.0, 8.0],
         [8.2, 7.9],
         [0.2, -0.1],
         [7.8, 8.1]];
      P1 : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-5,
         Max_Iters => 80, Seed => 123);
      P2 : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-5,
         Max_Iters => 80, Seed => 123);
      P3 : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-5,
         Max_Iters => 80, Seed => 456);
      R1 : constant Result := Run_FCM (Data, P1);
      R2 : constant Result := Run_FCM (Data, P2);
      R3 : constant Result := Run_FCM (Data, P3);
      Same : Boolean := True;
      Diff : Boolean := False;
   begin
      Check (R1.Iters = R2.Iters, "same seed → same iter count");
      Check (Approx (R1.Objective_J, R2.Objective_J, 1.0E-8),
             "same seed → same J");
      for I in R1.Memberships'Range (1) loop
         for J in R1.Memberships'Range (2) loop
            if not Near (R1.Memberships (I, J), R2.Memberships (I, J)) then
               Same := False;
            end if;
            if not Near (R1.Memberships (I, J), R3.Memberships (I, J)) then
               Diff := True;
            end if;
         end loop;
      end loop;
      Check (Same, "same seed → identical memberships");
      Check (Diff, "diff seed can differ");
      Check (R1.Converged or R1.Iters = P1.Max_Iters,
             "stopped by eps or max iters");
   end;

   ---------------------------------------------------------------------
   Section ("19. Converged flag and aliases");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0], [0.1], [5.0], [5.1]];
      Easy : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-3,
         Max_Iters => 200, Seed => 2);
      Tight : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-30,
         Max_Iters => 3, Seed => 2);
      R1 : constant Result := Run_Fuzzy_C_Means (Data, Easy);
      R2 : constant Result := Run_FCM (Data, Tight);
   begin
      Check (R1.Converged, "loose eps converges");
      Check (R2.Iters = 3, "tight eps hits Max_Iters=3");
      Check (not R2.Converged or R2.Iters <= 3,
             "Max_Iters path recorded");
   end;

   ---------------------------------------------------------------------
   Section ("20. 2-D geometry / centers near blob means");
   ---------------------------------------------------------------------
   declare
      Data : constant Dataset :=
        [[0.0, 0.0],
         [1.0, 0.0],
         [0.0, 1.0],
         [1.0, 1.0],
         [10.0, 10.0],
         [11.0, 10.0],
         [10.0, 11.0],
         [11.0, 11.0]];
      Params : constant Parameters :=
        (C => 2, Fuzzifier_M => 2.0, Eps => 1.0E-6,
         Max_Iters => 200, Seed => 9);
      R : constant Result := Run_FCM (Data, Params);
      --  One center should be near (0.5,0.5), other near (10.5,10.5)
      Found_Low, Found_High : Boolean := False;
   begin
      for J in R.Centers'Range (1) loop
         if abs (R.Centers (J, 1) - 0.5) < 1.5
           and then abs (R.Centers (J, 2) - 0.5) < 1.5
         then
            Found_Low := True;
         end if;
         if abs (R.Centers (J, 1) - 10.5) < 1.5
           and then abs (R.Centers (J, 2) - 10.5) < 1.5
         then
            Found_High := True;
         end if;
      end loop;
      Check (Found_Low, "center near low blob mean");
      Check (Found_High, "center near high blob mean");
      Check (R.Objective_J < 20.0, "J reasonably small for tight blobs");
   end;

   ---------------------------------------------------------------------
   Section ("21. RNG Draw_Unit in unit interval");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      U : Unit_Interval;
      All_OK : Boolean := True;
   begin
      Seed_RNG (S, 0);
      for K in 1 .. 20 loop
         U := Draw_Unit (S);
         if U < 0.0 or else U >= 1.0 then
            All_OK := False;
         end if;
      end loop;
      Check (All_OK, "20 Draw_Unit samples in [0,1)");
      Seed_RNG (S, 1);
      Check (True, "Seed_RNG Seed=1 ok");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   Put_Line ("========================");
   pragma Assert (Fail_Count = 0);
end Tests;
