--  Standalone test suite for Algorithms_For_Calculating_Variance (main).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Algorithms_For_Calculating_Variance;
use Algorithms_For_Calculating_Variance;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Algorithms_For_Calculating_Variance test suite");
   Put_Line ("==============================================");

   ---------------------------------------------------------------------
   Section ("1. Hand example [2,4,4,4,5,5,7,9]");
   ---------------------------------------------------------------------
   --  Classic Wikipedia / textbook set: mean=5, M2=32,
   --  population variance=4, sample variance=32/7.
   declare
      Data : constant Real_Array :=
        [1 => 2.0, 2 => 4.0, 3 => 4.0, 4 => 4.0,
         5 => 5.0, 6 => 5.0, 7 => 7.0, 8 => 9.0];
      W    : constant Welford_State := From_Array (Data);
      Expected_Sample : constant Real := 32.0 / 7.0;
   begin
      Check (W.Count = 8, "hand: Count = 8");
      Check (Approx (W.Mean, 5.0), "hand: Mean = 5");
      Check (Approx (Real (W.M2), 32.0), "hand: M2 = 32");
      Check (Approx (Sample_Variance (W), Expected_Sample),
             "hand: sample var = 32/7");
      Check (Approx (Population_Variance (W), 4.0),
             "hand: population var = 4");
      Check (Approx (Two_Pass_Sample_Variance (Data), Expected_Sample),
             "hand: two-pass sample = 32/7");
      Check (Approx (Two_Pass_Population_Variance (Data), 4.0),
             "hand: two-pass population = 4");
      Check (Approx (Naive_Sample_Variance (Data), Expected_Sample),
             "hand: naive sample = 32/7 (stable here)");
      Check (Approx (Naive_Population_Variance (Data), 4.0),
             "hand: naive population = 4");
      Check (Approx (Shifted_Sample_Variance (Data, 5.0), Expected_Sample),
             "hand: shifted K=5 sample = 32/7");
      Check (Approx (Shifted_Sample_Variance (Data, 0.0), Expected_Sample),
             "hand: shifted K=0 sample = 32/7");
      Check (Approx (Std_Dev (W, Sample => True), Sqrt_Nonneg (Expected_Sample)),
             "hand: sample std_dev");
      Check (Approx (Std_Dev (W, Sample => False), 2.0),
             "hand: population std_dev = 2");
      Check (Approx (Two_Pass_Mean (Data), 5.0), "hand: two-pass mean = 5");
   end;

   ---------------------------------------------------------------------
   Section ("2. Small set [1,2,3] Bessel / population");
   ---------------------------------------------------------------------
   declare
      Data : constant Real_Array := [1 => 1.0, 2 => 2.0, 3 => 3.0];
      W    : constant Welford_State := From_Array (Data);
   begin
      Check (Approx (W.Mean, 2.0), "[1,2,3] mean = 2");
      Check (Approx (Real (W.M2), 2.0), "[1,2,3] M2 = 2");
      Check (Approx (Sample_Variance (W), 1.0),
             "[1,2,3] sample var = 1 (Bessel n-1)");
      Check (Approx (Population_Variance (W), 2.0 / 3.0),
             "[1,2,3] population var = 2/3");
      Check (Approx (Two_Pass_Sample_Variance (Data), 1.0),
             "[1,2,3] two-pass sample = 1");
      Check (Approx (Two_Pass_Population_Variance (Data), 2.0 / 3.0),
             "[1,2,3] two-pass population = 2/3");
      Check (Sample_Variance (W) > Population_Variance (W),
             "Bessel: sample > population for n>1 non-constant");
   end;

   ---------------------------------------------------------------------
   Section ("3. Constant data => zero variance");
   ---------------------------------------------------------------------
   declare
      Data : constant Real_Array :=
        [1 => 7.0, 2 => 7.0, 3 => 7.0, 4 => 7.0, 5 => 7.0];
      W    : constant Welford_State := From_Array (Data);
   begin
      Check (Approx (W.Mean, 7.0), "constant mean = 7");
      Check (Approx (Real (W.M2), 0.0), "constant M2 = 0");
      Check (Approx (Sample_Variance (W), 0.0), "constant sample var = 0");
      Check (Approx (Population_Variance (W), 0.0),
             "constant population var = 0");
      Check (Approx (Two_Pass_Sample_Variance (Data), 0.0),
             "constant two-pass sample = 0");
      Check (Approx (Std_Dev (W), 0.0), "constant std_dev = 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Welford ≡ two-pass within tolerance");
   ---------------------------------------------------------------------
   declare
      Data : constant Real_Array :=
        [1 => 1.5, 2 => -2.0, 3 => 0.25, 4 => 10.0,
         5 => 3.3, 6 => -4.4, 7 => 8.8, 8 => 0.0,
         9 => 1.1, 10 => 2.2];
      W : constant Welford_State := From_Array (Data);
      TP_S : constant Non_Negative := Two_Pass_Sample_Variance (Data);
      TP_P : constant Non_Negative := Two_Pass_Population_Variance (Data);
      Sh_S : constant Non_Negative :=
        Shifted_Sample_Variance (Data, Data (1));
   begin
      Check (Approx (Sample_Variance (W), TP_S, 1.0E-12),
             "Welford sample ≡ two-pass");
      Check (Approx (Population_Variance (W), TP_P, 1.0E-12),
             "Welford population ≡ two-pass");
      Check (Approx (W.Mean, Two_Pass_Mean (Data), 1.0E-12),
             "Welford mean ≡ two-pass mean");
      Check (Approx (Sh_S, TP_S, 1.0E-12),
             "shifted K=first ≡ two-pass sample");
      Check (Approx (Shifted_Population_Variance (Data, 0.0), TP_P, 1.0E-12),
             "shifted K=0 population ≡ two-pass");
   end;

   ---------------------------------------------------------------------
   Section ("5. Chan merge of splits ≡ full Welford");
   ---------------------------------------------------------------------
   declare
      Full : constant Real_Array :=
        [1 => 3.0, 2 => 1.0, 3 => 4.0, 4 => 1.0,
         5 => 5.0, 6 => 9.0, 7 => 2.0, 8 => 6.0,
         9 => 5.0, 10 => 3.0, 11 => 5.0, 12 => 8.0];
      Left  : constant Real_Array := Full (1 .. 5);
      Right : constant Real_Array := Full (6 .. 12);
      Mid_A : constant Real_Array := Full (1 .. 4);
      Mid_B : constant Real_Array := Full (5 .. 8);
      Mid_C : constant Real_Array := Full (9 .. 12);
      W_Full  : constant Welford_State := From_Array (Full);
      W_Merged : constant Welford_State :=
        Merge (From_Array (Left), From_Array (Right));
      W_Triple : constant Welford_State :=
        Merge (Merge (From_Array (Mid_A), From_Array (Mid_B)),
               From_Array (Mid_C));
      Empty : constant Welford_State := Make_Empty;
   begin
      Check (W_Merged.Count = W_Full.Count, "merge: count matches full");
      Check (Approx (W_Merged.Mean, W_Full.Mean, 1.0E-12),
             "merge: mean ≡ full");
      Check (Approx (Real (W_Merged.M2), Real (W_Full.M2), 1.0E-10),
             "merge: M2 ≡ full");
      Check (Approx (Sample_Variance (W_Merged), Sample_Variance (W_Full),
                     1.0E-12),
             "merge: sample var ≡ full");
      Check (Approx (W_Triple.Mean, W_Full.Mean, 1.0E-12),
             "triple merge: mean ≡ full");
      Check (Approx (Real (W_Triple.M2), Real (W_Full.M2), 1.0E-10),
             "triple merge: M2 ≡ full");
      Check (Merge (Empty, W_Full).Count = W_Full.Count,
             "merge empty+full = full");
      Check (Merge (W_Full, Empty).Count = W_Full.Count,
             "merge full+empty = full");
      Check (Merge (Empty, Empty).Count = 0, "merge empty+empty = empty");
   end;

   ---------------------------------------------------------------------
   Section ("6. Online Update / Reset / Update_Many");
   ---------------------------------------------------------------------
   declare
      S : Welford_State := Make_Empty;
      Data : constant Real_Array :=
        [1 => 10.0, 2 => 12.0, 3 => 14.0];
   begin
      Check (S.Count = 0, "Make_Empty Count=0");
      Update (S, 10.0);
      Check (S.Count = 1, "after 1 update Count=1");
      Check (Approx (S.Mean, 10.0), "after 1 update Mean=10");
      Check (Approx (Real (S.M2), 0.0), "after 1 update M2=0");
      Update (S, 12.0);
      Update (S, 14.0);
      Check (S.Count = 3, "after 3 updates Count=3");
      Check (Approx (S.Mean, 12.0), "after 3 updates Mean=12");
      Check (Approx (Sample_Variance (S), 4.0),
             "online [10,12,14] sample var = 4");
      Reset (S);
      Check (S.Count = 0 and then Approx (S.Mean, 0.0), "Reset clears state");
      Update_Many (S, Data);
      Check (S.Count = 3, "Update_Many Count=3");
      Check (Approx (Sample_Variance (S), 4.0), "Update_Many sample var=4");
   end;

   ---------------------------------------------------------------------
   Section ("7. Edge cases: empty / n=1");
   ---------------------------------------------------------------------
   declare
      Empty_Arr : Real_Array (1 .. 0);
      One       : constant Real_Array := [1 => 42.0];
      Raised    : Boolean;
      W1        : Welford_State;
   begin
      Raised := False;
      begin
         declare
            Unused_V : Real := Two_Pass_Mean (Empty_Arr);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Empty_Sample => Raised := True;
         when others => null;
      end;
      Check (Raised, "two-pass mean empty raises Empty_Sample");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Population_Variance (Make_Empty);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Empty_Sample => Raised := True;
         when others => null;
      end;
      Check (Raised, "population var empty Welford raises Empty_Sample");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Sample_Variance (Make_Empty);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Degenerate => Raised := True;
         when others => null;
      end;
      Check (Raised, "sample var empty raises Degenerate");

      W1 := From_Array (One);
      Check (W1.Count = 1, "n=1 Count=1");
      Check (Approx (W1.Mean, 42.0), "n=1 Mean=42");
      Check (Approx (Population_Variance (W1), 0.0), "n=1 population var=0");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Sample_Variance (W1);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Degenerate => Raised := True;
         when others => null;
      end;
      Check (Raised, "n=1 sample var raises Degenerate");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Two_Pass_Sample_Variance (One);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Degenerate => Raised := True;
         when others => null;
      end;
      Check (Raised, "n=1 two-pass sample raises Degenerate");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Naive_Sample_Variance (One);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Degenerate => Raised := True;
         when others => null;
      end;
      Check (Raised, "n=1 naive sample raises Degenerate");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Shifted_Sample_Variance (One, 0.0);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Degenerate => Raised := True;
         when others => null;
      end;
      Check (Raised, "n=1 shifted sample raises Degenerate");
   end;

   ---------------------------------------------------------------------
   Section ("8. Naïve instability (large mean, small variance)");
   ---------------------------------------------------------------------
   --  Values near 1e9 with tiny spread: SumSq and (Sum^2)/n nearly cancel.
   --  Welford / two-pass remain accurate; naïve may differ or collapse.
   declare
      Base : constant Real := 1.0E9;
      Data : constant Real_Array :=
        [1 => Base + 0.0,
         2 => Base + 1.0,
         3 => Base + 2.0,
         4 => Base + 3.0,
         5 => Base + 4.0,
         6 => Base + 5.0,
         7 => Base + 6.0,
         8 => Base + 7.0];
      --  Exact sample variance of 0..7 is same as of Base+0..Base+7:
      --  mean offset 3.5, M2 = sum (i-3.5)^2 for i=0..7 = 2*(0.5^2+1.5^2+
      --  2.5^2+3.5^2) = 2*(0.25+2.25+6.25+12.25)=42, sample=42/7=6.
      Expected : constant Real := 6.0;
      TP  : constant Non_Negative := Two_Pass_Sample_Variance (Data);
      W   : constant Non_Negative := Sample_Variance (From_Array (Data));
      Sh  : constant Non_Negative :=
        Shifted_Sample_Variance (Data, Base);
      Nv  : constant Non_Negative := Naive_Sample_Variance (Data);
      Diff_Naive : constant Real := abs (Real (Nv) - Expected);
      Diff_W     : constant Real := abs (Real (W) - Expected);
   begin
      Check (Approx (TP, Expected, 1.0E-9),
             "large-mean: two-pass ≈ 6");
      Check (Approx (W, Expected, 1.0E-9),
             "large-mean: Welford ≈ 6");
      Check (Approx (Sh, Expected, 1.0E-9),
             "large-mean: shifted K=Base ≈ 6");
      --  Document: naïve either differs substantially OR (rarely) lucks out;
      --  with digits 15 at 1e9 the cancellation is often visible.
      Check (Diff_W < 1.0E-6, "large-mean: Welford error tiny");
      Check (Diff_Naive > Diff_W or else Diff_Naive > 1.0E-6
             or else not Approx (Nv, Expected, 1.0E-12),
             "large-mean: naïve differs or is less precise than Welford");
      --  Stronger educational check: report that stable methods agree.
      Check (Approx (W, TP, 1.0E-12),
             "large-mean: Welford ≡ two-pass despite large mean");
      Check (Approx (Sh, TP, 1.0E-12),
             "large-mean: shifted ≡ two-pass despite large mean");
      Put_Line
        ("  INFO: naive sample var =" & Nv'Image &
         " expected=6 Welford=" & W'Image);
   end;

   ---------------------------------------------------------------------
   Section ("9. Weighted incremental (West)");
   ---------------------------------------------------------------------
   declare
      --  Equal weights of 1 on [1,2,3] should match unweighted.
      Data : constant Real_Array := [1 => 1.0, 2 => 2.0, 3 => 3.0];
      Wts  : constant Weight_Array := [1 => 1.0, 2 => 1.0, 3 => 1.0];
      WS   : Weighted_State := From_Weighted_Arrays (Data, Wts);
      --  Double-weight middle: (1,1), (2,2), (3,1)
      Data2 : constant Real_Array := [1 => 1.0, 2 => 2.0, 3 => 3.0];
      Wts2  : constant Weight_Array := [1 => 1.0, 2 => 2.0, 3 => 1.0];
      WS2   : Weighted_State;
      Raised : Boolean;
   begin
      Check (WS.Count = 3, "weighted equal: Count=3");
      Check (Approx (WS.Mean, 2.0), "weighted equal: mean=2");
      Check (Approx (Weighted_Population_Variance (WS), 2.0 / 3.0, 1.0E-12),
             "weighted equal: pop var = 2/3");
      Check (Approx (Weighted_Frequency_Sample_Variance (WS), 1.0, 1.0E-12),
             "weighted equal: freq sample var = 1");

      WS2 := From_Weighted_Arrays (Data2, Wts2);
      --  mean = (1+2*2+3)/4 = 8/4 = 2
      Check (Approx (WS2.Mean, 2.0), "weighted uneven: mean=2");
      Check (Approx (Real (WS2.W_Sum), 4.0), "weighted uneven: W_Sum=4");
      --  S = sum w (x-mean_old)(x-mean); population = S/W_Sum
      --  deviations: 1 and 3 weight 1, 2 weight 2 => M2-like = 1+0+1=2? 
      --  Actually with mean 2: sum w(x-2)^2 = 1*1 + 2*0 + 1*1 = 2
      --  West S equals that; pop = 2/4 = 0.5
      Check (Approx (Weighted_Population_Variance (WS2), 0.5, 1.0E-12),
             "weighted uneven: pop var = 0.5");
      Check (Approx (Weighted_Frequency_Sample_Variance (WS2),
                     2.0 / 3.0, 1.0E-12),
             "weighted uneven: freq sample = 2/(4-1)=2/3");
      --  reliability denom = W_Sum - W_Sum2/W_Sum = 4 - (1+4+1)/4 = 4 - 1.5 = 2.5
      Check (Approx (Weighted_Reliability_Sample_Variance (WS2),
                     2.0 / 2.5, 1.0E-12),
             "weighted uneven: reliability sample = 2/2.5");

      Reset_Weighted (WS);
      Check (WS.Count = 0, "Reset_Weighted clears");

      Raised := False;
      begin
         declare
            Unused_V : Non_Negative := Weighted_Population_Variance (Make_Empty_Weighted);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Empty_Sample => Raised := True;
         when others => null;
      end;
      Check (Raised, "empty weighted pop raises Empty_Sample");

      Raised := False;
      begin
         declare
            Bad : Weighted_State;
         begin
            Bad := From_Weighted_Arrays
              (Data, [1 => 1.0, 2 => 1.0]);  -- length mismatch
            pragma Unreferenced (Bad);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when others => null;
      end;
      Check (Raised, "weighted length mismatch raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("10. Online covariance");
   ---------------------------------------------------------------------
   declare
      --  X = [1,2,3], Y = [2,4,6] perfect positive linear => sample cov = 2
      --  (same as sample var of [1,2,3] scaled by 2)
      X : constant Real_Array := [1 => 1.0, 2 => 2.0, 3 => 3.0];
      Y : constant Real_Array := [1 => 2.0, 2 => 4.0, 3 => 6.0];
      CS : Covariance_State := Make_Empty_Covariance;
      TP : Real;
      Raised : Boolean;
   begin
      for I in X'Range loop
         Update_Covariance (CS, X (I), Y (I));
      end loop;
      TP := Two_Pass_Sample_Covariance (X, Y);
      Check (CS.Count = 3, "cov: Count=3");
      Check (Approx (CS.Mean_X, 2.0), "cov: Mean_X=2");
      Check (Approx (CS.Mean_Y, 4.0), "cov: Mean_Y=4");
      Check (Approx (Sample_Covariance (CS), 2.0, 1.0E-12),
             "cov: sample cov = 2");
      Check (Approx (Population_Covariance (CS), 4.0 / 3.0, 1.0E-12),
             "cov: population cov = 4/3");
      Check (Approx (Sample_Covariance (CS), TP, 1.0E-12),
             "cov: online ≡ two-pass");

      --  Independent-ish: Y reversed [3,2,1] => sample cov = -1
      Reset_Covariance (CS);
      declare
         Y2 : constant Real_Array := [1 => 3.0, 2 => 2.0, 3 => 1.0];
      begin
         for I in X'Range loop
            Update_Covariance (CS, X (I), Y2 (I));
         end loop;
         Check (Approx (Sample_Covariance (CS), -1.0, 1.0E-12),
                "cov: anti-correlated sample cov = -1");
         Check (Approx (Sample_Covariance (CS),
                        Two_Pass_Sample_Covariance (X, Y2), 1.0E-12),
                "cov: anti online ≡ two-pass");
      end;

      Raised := False;
      begin
         declare
            Unused_V : Real := Sample_Covariance (Make_Empty_Covariance);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Degenerate => Raised := True;
         when others => null;
      end;
      Check (Raised, "cov: empty sample cov raises Degenerate");

      Raised := False;
      begin
         declare
            Unused_V : Real := Population_Covariance (Make_Empty_Covariance);
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Empty_Sample => Raised := True;
         when others => null;
      end;
      Check (Raised, "cov: empty pop cov raises Empty_Sample");

      Raised := False;
      begin
         declare
            Unused_V : Real := Two_Pass_Sample_Covariance
              (X, [1 => 1.0, 2 => 2.0]);  -- length mismatch
         begin
            pragma Unreferenced (Unused_V);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when others => null;
      end;
      Check (Raised, "cov: length mismatch raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("11. Near helper / Std_Dev / misc");
   ---------------------------------------------------------------------
   declare
      Data : constant Real_Array := [1 => 0.0, 2 => 0.0, 3 => 0.0, 4 => 0.0];
      W : constant Welford_State := From_Array (Data);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near within default tol");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Approx (Sqrt_Nonneg (0.0), 0.0), "Sqrt_Nonneg(0)=0");
      Check (Approx (Sqrt_Nonneg (4.0), 2.0), "Sqrt_Nonneg(4)=2");
      Check (Approx (Std_Dev (W), 0.0), "zero data std_dev=0");
      Check (Approx (Shifted_Population_Variance (Data, 100.0), 0.0),
             "shifted pop constant zeros = 0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Bessel correction relation");
   ---------------------------------------------------------------------
   declare
      Data : constant Real_Array :=
        [1 => 4.0, 2 => 8.0, 3 => 6.0, 4 => 5.0, 5 => 7.0];
      W : constant Welford_State := From_Array (Data);
      N : constant Real := Real (W.Count);
      Sp : constant Non_Negative := Population_Variance (W);
      Ss : constant Non_Negative := Sample_Variance (W);
   begin
      --  sample = population * n / (n-1)
      Check (Approx (Ss, Sp * N / (N - 1.0), 1.0E-12),
             "Bessel: s^2 = sigma^2 * n/(n-1)");
      Check (Approx (Naive_Sample_Variance (Data), Ss, 1.0E-12),
             "Bessel: naive sample matches Welford on mild data");
      Check (Approx (Naive_Population_Variance (Data), Sp, 1.0E-12),
             "Bessel: naive population matches Welford on mild data");
   end;

   New_Line;
   Put_Line ("==============================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
end Tests;
