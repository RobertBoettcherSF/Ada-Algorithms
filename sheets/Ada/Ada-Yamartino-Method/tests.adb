--  Standalone test suite for Yamartino_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Yamartino_Method; use Yamartino_Method;

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

   function Approx_Ang
     (A, B : Angle_Radians; Tol : Real := 1.0E-4) return Boolean
   is
   begin
      return Near_Angle (A, B, Tol);
   end Approx_Ang;

   --  √3 reference for π/√3 checks (avoid depending on package Math).
   Sqrt_Ref : constant Real := 1.73205080757;

begin
   Put_Line ("Yamartino_Method test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. To_Radians / To_Degrees / Normalize");
   ---------------------------------------------------------------------
   declare
      R0   : constant Angle_Radians := To_Radians (0.0);
      R90  : constant Angle_Radians := To_Radians (90.0);
      R180 : constant Angle_Radians := To_Radians (180.0);
   begin
      Check (Approx (R0, 0.0), "0 deg -> 0 rad");
      Check (Approx (R90, Pi / 2.0), "90 deg -> pi/2");
      Check (Approx (R180, Pi), "180 deg -> pi");
      Check (Approx (To_Degrees (Pi), 180.0), "pi -> 180 deg");
      Check (Approx (To_Degrees (Pi / 2.0), 90.0), "pi/2 -> 90 deg");
      Check (Approx (Normalize_Angle (0.0), 0.0), "normalize 0");
      Check (Approx_Ang (Normalize_Angle (3.0 * Pi), Pi),
             "normalize 3pi -> pi");
      Check (Approx_Ang (Normalize_Angle (-3.0 * Pi / 2.0), Pi / 2.0),
             "normalize -3pi/2 -> pi/2");
      Check (Approx (Normalize_Degrees (361.0), 1.0), "normalize 361 deg");
      Check (Approx (Normalize_Degrees (-10.0), 350.0), "normalize -10 deg");
      Check (Approx (Normalize_Degrees (720.0), 0.0), "normalize 720 deg");
   end;

   ---------------------------------------------------------------------
   Section ("2. Near / Near_Angle / empty raises");
   ---------------------------------------------------------------------
   declare
      Raised_Empty : Boolean := False;
      Raised_Deg   : Boolean := False;
      Acc          : constant Running_Yamartino := Make_Empty;
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near_Angle (0.01, -0.01, 0.05), "Near_Angle across zero");
      Check (Near_Angle (Pi - 0.01, -Pi + 0.01, 0.05),
             "Near_Angle across ±pi");
      Check (not Near_Angle (0.0, Pi / 2.0), "Near_Angle rejects far");
      Check (Yamartino_Method.Count (Acc) = 0, "Make_Empty count 0");
      begin
         declare
            Unused : Yamartino_Result;
         begin
            Unused := Finalize (Acc);
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_Sample =>
            Raised_Empty := True;
         when others =>
            Raised_Empty := False;
      end;
      Check (Raised_Empty, "Finalize empty raises Empty_Sample");
      begin
         declare
            Empty_A : Angle_Array (1 .. 0);
            Unused  : Yamartino_Result;
         begin
            Unused := Yamartino (Empty_A);
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_Sample =>
            Raised_Deg := True;
         when Constraint_Error =>
            Raised_Deg := True;
         when others =>
            null;
      end;
      Check (Raised_Deg, "Yamartino empty array raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Single sample");
   ---------------------------------------------------------------------
   declare
      Samples : constant Angle_Array := [To_Radians (45.0)];
      Res     : constant Yamartino_Result := Yamartino (Samples);
      Acc     : Running_Yamartino := Make_Empty;
      Res2    : Yamartino_Result;
   begin
      Check (Res.Count = 1, "single count 1");
      Check (Approx_Ang (Res.Mean, To_Radians (45.0)), "single mean = sample");
      Check (Approx (Res.Std_Dev, 0.0), "single std ≈ 0");
      Check (Approx (Res.Epsilon, 0.0), "single epsilon ≈ 0");
      Check (Approx (Res.Resultant, 1.0), "single R ≈ 1");
      Add_Degrees (Acc, 45.0);
      Res2 := Finalize (Acc);
      Check (Approx_Ang (Res2.Mean, Res.Mean), "running single matches batch");
      Check (Approx (Res2.Std_Dev, 0.0), "running single std 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Constant wind direction");
   ---------------------------------------------------------------------
   declare
      Samples : Angle_Array (1 .. 8);
      Res     : Yamartino_Result;
   begin
      for I in Samples'Range loop
         Samples (I) := To_Radians (120.0);
      end loop;
      Res := Yamartino (Samples);
      Check (Res.Count = 8, "constant count 8");
      Check (Approx_Ang (Res.Mean, To_Radians (120.0), 1.0E-5),
             "constant mean 120 deg");
      Check (Approx (Res.Std_Dev, 0.0, 1.0E-6), "constant std ≈ 0");
      Check (Approx (Res.Epsilon, 0.0, 1.0E-6), "constant ε ≈ 0");
      Check (Approx (Res.Resultant, 1.0, 1.0E-6), "constant R ≈ 1");
      Check (Approx (Mean_Degrees (Res), 120.0, 1.0E-4),
             "Mean_Degrees 120");
      Check (Approx (Std_Dev_Degrees (Res), 0.0, 1.0E-4),
             "Std_Dev_Degrees 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wrap-around 1° / 359° (meteorological)");
   ---------------------------------------------------------------------
   declare
      Degs : constant Degree_Array := [1.0, 359.0];
      Res  : constant Yamartino_Result := Yamartino_Degrees (Degs);
      Naive_Samples : constant Angle_Array :=
        [To_Radians (1.0), To_Radians (359.0)];
      Naive_Mu : constant Angle_Radians :=
        Naive_Linear_Mean (Naive_Samples);
   begin
      Check (Res.Count = 2, "wrap count 2");
      Check (Approx_Ang (Res.Mean, 0.0, 1.0E-3)
               or else Approx_Ang (Res.Mean, To_Radians (0.0), 1.0E-3),
             "wrap mean near 0° not 180°");
      Check (abs (Mean_Degrees (Res)) < 2.0
               or else abs (Mean_Degrees (Res) - 360.0) < 2.0,
             "Mean_Degrees near 0 or 360");
      Check (Res.Std_Dev > 0.0, "wrap has positive std");
      Check (Res.Std_Dev < To_Radians (5.0), "wrap std small (<5°)");
      --  Naive linear mean of 1° and 359° is 180° — absurd.
      Check (Approx_Ang (Naive_Mu, To_Radians (180.0), 1.0E-3),
             "naive linear mean wrongly ~180°");
      Check (not Approx_Ang (Res.Mean, To_Radians (180.0), 0.5),
             "Yamartino not ~180°");
   end;

   ---------------------------------------------------------------------
   Section ("6. Small dispersion vs two-pass closeness");
   ---------------------------------------------------------------------
   declare
      Samples : constant Angle_Array :=
        [To_Radians (10.0), To_Radians (12.0), To_Radians (11.0),
         To_Radians (9.0),  To_Radians (11.5)];
      Res     : constant Yamartino_Result := Yamartino (Samples);
      CMean   : constant Angle_Radians := Circular_Mean (Samples);
      CStd    : constant Non_Negative :=
        Circular_Std_Dev_Angular (Samples);
      CStd2   : constant Non_Negative :=
        Circular_Std_Dev_Two_Pass (Samples);
   begin
      Check (Approx_Ang (Res.Mean, CMean, 1.0E-6),
             "Yamartino mean = circular mean");
      Check (Approx_Ang (CMean, To_Radians (10.7), 0.5),
             "mean near 10.7°");
      Check (Res.Std_Dev > 0.0, "small dispersion std > 0");
      Check (Res.Epsilon < 0.1, "small dispersion ε small");
      --  For small dispersion Yamartino ≈ angular RMS.
      Check (abs (Res.Std_Dev - CStd) < 0.05,
             "Yamartino close to angular RMS");
      Check (CStd2 >= 0.0, "two-pass R-based std non-negative");
      Check (Res.Resultant > 0.95, "small disp high R");
   end;

   ---------------------------------------------------------------------
   Section ("7. Opposing winds / high dispersion");
   ---------------------------------------------------------------------
   declare
      Opp : constant Angle_Array :=
        [To_Radians (0.0), To_Radians (180.0)];
      Res : constant Yamartino_Result := Yamartino (Opp);
      Uni : Angle_Array (1 .. 8);
      RU  : Yamartino_Result;
   begin
      Check (Approx (Res.Resultant, 0.0, 1.0E-5), "opposite R ≈ 0");
      Check (Approx (Res.Epsilon, 1.0, 1.0E-5), "opposite ε ≈ 1");
      --  arcsin(1)=π/2, factor (1+(2/√3-1)*1) = 2/√3 ≈ 1.1547
      --  → σ ≈ π/√3 ≈ 1.8138
      Check (Approx (Res.Std_Dev, Pi / Sqrt_Ref, 0.05),
             "opposite σ near π/√3");
      for I in Uni'Range loop
         Uni (I) := To_Radians (Real (I - 1) * 45.0);
      end loop;
      RU := Yamartino (Uni);
      Check (RU.Epsilon > 0.9, "uniform-ish ε large");
      Check (RU.Std_Dev > 1.0, "uniform-ish σ large");
      Check (RU.Resultant < 0.2, "uniform-ish R small");
   end;

   ---------------------------------------------------------------------
   Section ("8. Running accumulator equals batch");
   ---------------------------------------------------------------------
   declare
      Degs : constant Degree_Array :=
        [0.0, 10.0, 20.0, 15.0, 5.0, 350.0, 355.0];
      Batch : constant Yamartino_Result := Yamartino_Degrees (Degs);
      Acc   : Running_Yamartino := Make_Empty;
      Run   : Yamartino_Result;
   begin
      for I in Degs'Range loop
         Add_Degrees (Acc, Degs (I));
      end loop;
      Run := Finalize (Acc);
      Check (Yamartino_Method.Count (Acc) = Degs'Length, "running count matches");
      Check (Run.Count = Batch.Count, "finalize count = batch");
      Check (Approx_Ang (Run.Mean, Batch.Mean, 1.0E-8),
             "running mean = batch");
      Check (Approx (Run.Std_Dev, Batch.Std_Dev, 1.0E-8),
             "running std = batch");
      Check (Approx (Run.Epsilon, Batch.Epsilon, 1.0E-8),
             "running ε = batch");
      Check (Approx (Run.Sa, Batch.Sa, 1.0E-8), "running sa = batch");
      Check (Approx (Run.Ca, Batch.Ca, 1.0E-8), "running ca = batch");
      Reset (Acc);
      Check (Yamartino_Method.Count (Acc) = 0, "Reset clears");
   end;

   ---------------------------------------------------------------------
   Section ("9. Degree API / Mean_Degrees / Std_Dev_Degrees");
   ---------------------------------------------------------------------
   declare
      Degs : constant Degree_Array := [90.0, 100.0, 80.0];
      Res  : constant Yamartino_Result := Yamartino_Degrees (Degs);
      Acc  : Running_Yamartino := Make_Empty;
   begin
      Check (Approx (Mean_Degrees (Res), 90.0, 1.0), "mean ~90°");
      Check (Std_Dev_Degrees (Res) > 0.0, "std deg > 0");
      Check (Std_Dev_Degrees (Res) < 20.0, "std deg < 20");
      Add_Degrees (Acc, 270.0);
      Add_Degrees (Acc, 280.0);
      Add_Degrees (Acc, 260.0);
      declare
         R2 : constant Yamartino_Result := Finalize (Acc);
      begin
         Check (Approx (Mean_Degrees (R2), 270.0, 2.0), "mean ~270°");
         Check (R2.Count = 3, "degree API count 3");
         Check (Approx_Ang (R2.Mean, To_Radians (270.0), 0.05),
                "mean rad ~270°");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. ε formula pieces / Yamartino_Sigma");
   ---------------------------------------------------------------------
   declare
      R1   : constant Non_Negative := Mean_Resultant_Length (0.0, 1.0);
      R0   : constant Non_Negative := Mean_Resultant_Length (0.0, 0.0);
      E0   : constant Non_Negative := Epsilon_From_Resultant (1.0);
      E1   : constant Non_Negative := Epsilon_From_Resultant (0.0);
      Sig0 : constant Non_Negative := Yamartino_Sigma (0.0);
      Sig1 : constant Non_Negative := Yamartino_Sigma (1.0);
      --  At ε=1: arcsin(1)*(2/√3) = (π/2)*(2/√3) = π/√3
      Expected_Max : constant Real := Pi / Sqrt_Ref;
      Half : constant Non_Negative :=
        Epsilon_From_Resultant
          (Mean_Resultant_Length (0.5, 0.5));
   begin
      Check (Approx (R1, 1.0), "R(0,1)=1");
      Check (Approx (R0, 0.0), "R(0,0)=0");
      Check (Approx (E0, 0.0), "ε(R=1)=0");
      Check (Approx (E1, 1.0), "ε(R=0)=1");
      Check (Approx (Sig0, 0.0), "σ(ε=0)=0");
      Check (Approx (Sig1, Expected_Max, 1.0E-5), "σ(ε=1)=π/√3");
      Check (Half > 0.0 and then Half < 1.0, "ε mid in (0,1)");
      Check (Yamartino_Sigma (Half) > 0.0, "σ mid > 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Naive linear fails wrap-around; Yamartino succeeds");
   ---------------------------------------------------------------------
   declare
      --  Classic Wikipedia example: 1° and 359°.
      S : constant Angle_Array :=
        [To_Radians (1.0), To_Radians (359.0)];
      Y : constant Yamartino_Result := Yamartino (S);
      NMu : constant Angle_Radians := Naive_Linear_Mean (S);
      NSd : constant Non_Negative := Naive_Linear_Std_Dev (S);
      --  Another wrap: 350°, 355°, 5°, 10°.
      S2 : constant Angle_Array :=
        [To_Radians (350.0), To_Radians (355.0),
         To_Radians (5.0),   To_Radians (10.0)];
      Y2 : constant Yamartino_Result := Yamartino (S2);
      N2 : constant Angle_Radians := Naive_Linear_Mean (S2);
   begin
      Check (Approx_Ang (NMu, Pi, 0.01), "naive mean ~180° (wrong)");
      Check (NSd > To_Radians (100.0), "naive std huge (wrong)");
      Check (Approx_Ang (Y.Mean, 0.0, 0.05), "Yamartino mean ~0°");
      Check (Y.Std_Dev < To_Radians (10.0), "Yamartino std small");
      Check (Approx_Ang (Y2.Mean, 0.0, 0.2)
               or else abs (Mean_Degrees (Y2)) < 15.0
               or else abs (Mean_Degrees (Y2) - 360.0) < 15.0,
             "cluster around north: Yamartino ~0°");
      Check (not Approx_Ang (N2, 0.0, 0.5),
             "naive mean of wrap cluster not near 0");
      Check (Y2.Std_Dev < To_Radians (30.0),
             "Yamartino wrap-cluster std modest");
   end;

   ---------------------------------------------------------------------
   Section ("12. High-n synthetic / incremental stability");
   ---------------------------------------------------------------------
   declare
      N    : constant Positive := 200;
      Acc  : Running_Yamartino := Make_Empty;
      Res  : Yamartino_Result;
      Batch : Angle_Array (1 .. N);
      --  Mild Gaussian-ish around 45° via discrete steps.
      Base : constant Angle_Radians := To_Radians (45.0);
   begin
      for I in 1 .. N loop
         declare
            --  Spread ±5° in a deterministic pattern.
            Off : constant Real :=
              To_Radians (Real ((I mod 11) - 5) * 0.5);
            Th  : constant Angle_Radians := Base + Off;
         begin
            Batch (I) := Th;
            Add_Sample (Acc, Th);
         end;
      end loop;
      Res := Finalize (Acc);
      declare
         BRes : constant Yamartino_Result := Yamartino (Batch);
      begin
         Check (Res.Count = N, "high-n count");
         Check (Approx_Ang (Res.Mean, BRes.Mean, 1.0E-9),
                "high-n running = batch mean");
         Check (Approx (Res.Std_Dev, BRes.Std_Dev, 1.0E-9),
                "high-n running = batch std");
         Check (Approx_Ang (Res.Mean, Base, 0.05), "high-n mean ~45°");
         Check (Res.Std_Dev > 0.0, "high-n std > 0");
         Check (Res.Std_Dev < To_Radians (5.0), "high-n std < 5°");
         Check (Res.Resultant > 0.9, "high-n high R");
         Check (abs (Res.Std_Dev -
                  Circular_Std_Dev_Angular (Batch)) < 0.02,
                "high-n close to angular RMS");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Degenerates / edge fixtures");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      Acc    : constant Running_Yamartino := Make_Empty;
      --  All same after wrap: 0 and 360 degrees.
      Same : constant Degree_Array := [0.0, 360.0, 720.0];
      RS   : constant Yamartino_Result := Yamartino_Degrees (Same);
      --  Negative degrees.
      Neg  : constant Degree_Array := [-5.0, 5.0];
      RN   : constant Yamartino_Result := Yamartino_Degrees (Neg);
      --  Cardinal directions mean.
      Card : constant Degree_Array := [0.0, 90.0, 180.0, 270.0];
      RC   : constant Yamartino_Result := Yamartino_Degrees (Card);
   begin
      Check (Approx (RS.Std_Dev, 0.0, 1.0E-5),
             "0/360/720 equivalent → σ≈0");
      Check (Approx_Ang (RS.Mean, 0.0, 1.0E-5), "equiv angles mean 0");
      Check (Approx_Ang (RN.Mean, 0.0, 0.05), "±5° mean ~0");
      Check (RN.Std_Dev > 0.0, "±5° std > 0");
      Check (Approx (RC.Resultant, 0.0, 1.0E-5), "cardinals R≈0");
      Check (RC.Epsilon > 0.99, "cardinals ε≈1");
      Check (Approx (RC.Std_Dev, Pi / Sqrt_Ref, 0.05),
             "cardinals σ≈π/√3");
      begin
         declare
            U : Yamartino_Result;
         begin
            U := Finalize (Acc);
            pragma Unreferenced (U);
         end;
      exception
         when Empty_Sample | Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "empty still raises after other tests");
      Check (Near (Pi, 3.14159265358, 1.0E-8), "Pi constant sane");
   end;

   ---------------------------------------------------------------------
   Section ("14. Circular_Mean / two-pass vs Yamartino identity");
   ---------------------------------------------------------------------
   declare
      S : constant Angle_Array :=
        [To_Radians (30.0), To_Radians (40.0), To_Radians (50.0)];
      Y : constant Yamartino_Result := Yamartino (S);
      M : constant Angle_Radians := Circular_Mean (S);
      A : constant Non_Negative := Circular_Std_Dev_Angular (S);
      T : constant Non_Negative := Circular_Std_Dev_Two_Pass (S);
   begin
      Check (Approx_Ang (Y.Mean, M, 1.0E-9), "mean identity");
      Check (Approx_Ang (M, To_Radians (40.0), 0.01), "mean ~40°");
      Check (A > 0.0 and then A < To_Radians (15.0), "angular std band");
      Check (T > 0.0, "R-based two-pass > 0");
      Check (abs (Y.Std_Dev - A) < 0.05, "Yamartino ≈ angular for small");
      Check (Y.Sa * Y.Sa + Y.Ca * Y.Ca <= 1.0 + 1.0E-9,
             "sa²+ca² ≤ 1");
      Check (Approx (Y.Epsilon,
                     Epsilon_From_Resultant (Y.Resultant), 1.0E-9),
             "ε matches accessor");
      Check (Approx (Y.Std_Dev, Yamartino_Sigma (Y.Epsilon), 1.0E-9),
             "σ matches Yamartino_Sigma");
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("=================================");

   pragma Assert (Fail_Count = 0);

exception
   when others =>
      Put_Line ("UNEXPECTED EXCEPTION in test suite");
      raise;
end Tests;
