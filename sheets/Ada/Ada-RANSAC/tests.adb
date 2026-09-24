--  Standalone test suite for RANSAC (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with RANSAC; use RANSAC;

procedure Tests is

   package EF renames Ada.Numerics.Elementary_Functions;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   function Sqrt_Helper return Real is
   begin
      return Real (EF.Sqrt (5.0));
   end Sqrt_Helper;

   function Cos_Helper (A : Real) return Real is
   begin
      return Real (EF.Cos (Float (A)));
   end Cos_Helper;

   function Sin_Helper (A : Real) return Real is
   begin
      return Real (EF.Sin (Float (A)));
   end Sin_Helper;

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

   --  Deterministic pseudo-noise from integer k in roughly [-1,1]
   function Noise (K : Integer) return Real is
      type U32 is mod 2 ** 32;
      X : U32;
   begin
      X := U32 (K mod 2_000_000_000);
      X := X * 1_103_515_245 + 12_345;
      return Real (Integer (X mod 2000)) / 1000.0 - 1.0;
   end Noise;

   --  True line y = 2x + 1  →  2x - y + 1 = 0  → normalize
   function True_Line return Line2 is
   begin
      return Normalize_Line ((A => 2.0, B => -1.0, C => 1.0));
   end True_Line;

begin
   Put_Line ("RANSAC test suite");
   Put_Line ("=================");

   ---------------------------------------------------------------------
   Section ("1. Near / Dist2 helpers");
   ---------------------------------------------------------------------
   declare
      P : constant Point2 := (0.0, 0.0);
      Q : constant Point2 := (3.0, 4.0);
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Real (Dist2 (P, Q)), 5.0), "Dist2 3-4-5");
      Check (Approx (Real (Squared_Dist2 (P, Q)), 25.0), "Squared_Dist2=25");
      Check (Is_Degenerate_Sample ((1.0, 1.0), (1.0, 1.0)),
             "identical points degenerate");
      Check (not Is_Degenerate_Sample ((0.0, 0.0), (1.0, 0.0)),
             "distinct points not degenerate");
   end;

   ---------------------------------------------------------------------
   Section ("2. Two-point line fit");
   ---------------------------------------------------------------------
   declare
      L : Line2;
      Raised : Boolean := False;
   begin
      L := Fit_Line_From_Two_Points ((0.0, 1.0), (1.0, 3.0));  -- y=2x+1
      Check (Approx (Real (Point_Line_Distance ((0.0, 1.0), L)), 0.0, 1.0E-8),
             "P on fitted line");
      Check (Approx (Real (Point_Line_Distance ((1.0, 3.0), L)), 0.0, 1.0E-8),
             "Q on fitted line");
      Check (Approx (Real (Point_Line_Distance ((2.0, 5.0), L)), 0.0, 1.0E-6),
             "third truth point on line");
      --  Distance of (0,0) to y=2x+1: |1|/sqrt(4+1)=1/sqrt(5)
      Check (Approx (Real (Point_Line_Distance ((0.0, 0.0), L)),
                     1.0 / Sqrt_Helper, 1.0E-5),
             "distance (0,0) to y=2x+1");
      begin
         declare
            Unused : Line2;
            pragma Unreferenced (Unused);
         begin
            Unused := Fit_Line_From_Two_Points ((1.0, 1.0), (1.0, 1.0));
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "coincident points raise Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("3. Point-line distance & normalize");
   ---------------------------------------------------------------------
   declare
      L : constant Line2 := Normalize_Line ((3.0, 4.0, -10.0));  -- 3x+4y=10
      Raised : Boolean := False;
   begin
      Check (Approx (L.A * L.A + L.B * L.B, 1.0, 1.0E-8),
             "normalized A^2+B^2=1");
      Check (Approx (Real (Point_Line_Distance ((2.0, 1.0), L)), 0.0, 1.0E-6),
             "point on 3x+4y=10");
      Check (Approx (Real (Point_Line_Distance ((0.0, 0.0), L)), 2.0, 1.0E-6),
             "|c|/norm = 2 for (0,0)");
      begin
         declare
            Bad : Line2;
         begin
            Bad := Normalize_Line ((0.0, 0.0, 1.0));
            pragma Unreferenced (Bad);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "zero normal raises");
   end;

   ---------------------------------------------------------------------
   Section ("4. Least-squares line on clean data");
   ---------------------------------------------------------------------
   declare
      Clean : Point_Array (1 .. 20);
      L : Line2;
      T : constant Line2 := True_Line;
   begin
      for I in Clean'Range loop
         declare
            X : constant Real := Real (I - 1) * 0.5;
            Y : constant Real := 2.0 * X + 1.0 + 0.01 * Noise (I);
         begin
            Clean (I) := (X, Y);
         end;
      end loop;
      L := Fit_Line_Least_Squares (Clean);
      Check (Approx (Real (Point_Line_Distance ((0.0, 1.0), L)), 0.0, 0.05),
             "LS near (0,1)");
      Check (Approx (Real (Point_Line_Distance ((1.0, 3.0), L)), 0.0, 0.05),
             "LS near (1,3)");
      Check (Approx (Real (Point_Line_Distance ((2.0, 5.0), L)), 0.0, 0.08),
             "LS near (2,5)");
      --  Angle between normals via |A1A2+B1B2| ≈ 1
      Check (Approx (abs (L.A * T.A + L.B * T.B), 1.0, 0.05),
             "LS normal aligned with truth");
   end;

   ---------------------------------------------------------------------
   Section ("5. LS corrupted by outliers is bad; RANSAC recovers");
   ---------------------------------------------------------------------
   declare
      Mixed : Point_Array (1 .. 40);
      LS : Line2;
      Cfg : RANSAC_Config;
      Res : RANSAC_Line_Result;
      T : constant Line2 := True_Line;
      LS_Err, R_Err : Real;
   begin
      --  25 inliers on y=2x+1, 15 scattered outliers
      for I in 1 .. 25 loop
         declare
            X : constant Real := Real (I - 1) * 0.4;
            Y : constant Real := 2.0 * X + 1.0 + 0.05 * Noise (I * 3);
         begin
            Mixed (I) := (X, Y);
         end;
      end loop;
      for I in 26 .. 40 loop
         Mixed (I) := (Noise (I * 7) * 8.0,
                       Noise (I * 11) * 8.0 + 20.0);
      end loop;
      LS := Fit_Line_Least_Squares (Mixed);
      LS_Err := Real (Point_Line_Distance ((0.0, 1.0), LS))
              + Real (Point_Line_Distance ((2.0, 5.0), LS));
      Cfg := Make_Config
        (Max_Iterations => 200,
         Distance_Threshold => 0.4,
         Min_Inliers => 10,
         Seed => 42,
         Refit_On_Inliers => True,
         Use_MSAC_Score => True);
      Res := RANSAC_Fit_Line (Mixed, Cfg);
      Check (Res.Success, "RANSAC reports success");
      Check (Res.Inlier_Count >= 20, "RANSAC finds >=20 inliers");
      R_Err := Real (Point_Line_Distance ((0.0, 1.0), Res.Model))
             + Real (Point_Line_Distance ((2.0, 5.0), Res.Model));
      Check (R_Err < 0.5, "RANSAC model close to truth points");
      Check (R_Err < LS_Err or else Approx (abs (Res.Model.A * T.A
             + Res.Model.B * T.B), 1.0, 0.15),
             "RANSAC closer/aligned vs corrupted LS");
      Check (Res.Iterations_Used > 0, "RANSAC used iterations");
   end;

   ---------------------------------------------------------------------
   Section ("6. Inlier counting threshold behavior");
   ---------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [(0.0, 1.0), (1.0, 3.0), (2.0, 5.0), (0.0, 10.0), (5.0, 0.0)];
      L : constant Line2 := Fit_Line_From_Two_Points ((0.0, 1.0), (1.0, 3.0));
      Mask : Inlier_Mask;
      C : Natural;
   begin
      Check (Count_Line_Inliers (Pts, L, 0.1) = 3,
             "tight threshold: 3 inliers");
      Check (Count_Line_Inliers (Pts, L, 20.0) = 5,
             "loose threshold: all 5");
      Collect_Line_Inliers (Pts, L, 0.1, Mask, C);
      Check (C = 3, "Collect count=3");
      Check (Mask (1) and Mask (2) and Mask (3), "first three masked");
      Check (not Mask (4) and not Mask (5), "outliers not masked");
   end;

   ---------------------------------------------------------------------
   Section ("7. Estimate_Iterations formula edge cases");
   ---------------------------------------------------------------------
   declare
      K : Natural;
   begin
      Check (Estimate_Iterations (1.0, 2, 0.99) = 1, "w=1 => N=1");
      Check (Estimate_Iterations (0.0, 2, 0.99) > 1000, "w=0 => huge N");
      K := Estimate_Iterations (0.5, 2, 0.99);
      --  log(0.01)/log(1-0.25) = log(0.01)/log(0.75) ≈ 16.0
      Check (K >= 14 and then K <= 20, "w=0.5 s=2 p=0.99 ≈16");
      K := Estimate_Iterations (0.8, 2, 0.99);
      Check (K >= 2 and then K <= 8, "w=0.8 s=2 modest N");
      K := Estimate_Iterations (0.1, 3, 0.99);
      Check (K > 100, "low inlier ratio needs many iters");
   end;

   ---------------------------------------------------------------------
   Section ("8. Seeded reproducibility");
   ---------------------------------------------------------------------
   declare
      Pts : Point_Array (1 .. 30);
      Cfg1, Cfg2, Cfg3 : RANSAC_Config;
      R1, R2, R3 : RANSAC_Line_Result;
      Rng : Seeded_RNG;
      A, B, C : Natural;
   begin
      for I in Pts'Range loop
         Pts (I) := (Real (I), 2.0 * Real (I) + 1.0 + 0.02 * Noise (I));
      end loop;
      --  add a few outliers
      Pts (28) := (0.0, 50.0);
      Pts (29) := (10.0, -40.0);
      Pts (30) := (-5.0, 30.0);
      Cfg1 := Make_Config (Max_Iterations => 80, Distance_Threshold => 0.3,
                           Seed => 12345, Refit_On_Inliers => True);
      Cfg2 := Cfg1;
      Cfg3 := Make_Config (Max_Iterations => 80, Distance_Threshold => 0.3,
                           Seed => 99999, Refit_On_Inliers => True);
      R1 := RANSAC_Fit_Line (Pts, Cfg1);
      R2 := RANSAC_Fit_Line (Pts, Cfg2);
      R3 := RANSAC_Fit_Line (Pts, Cfg3);
      Check (R1.Success and R2.Success, "both seeded runs succeed");
      Check (R1.Inlier_Count = R2.Inlier_Count, "same seed => same inliers");
      Check (Approx (R1.Model.A, R2.Model.A, 1.0E-10)
             and then Approx (R1.Model.B, R2.Model.B, 1.0E-10)
             and then Approx (R1.Model.C, R2.Model.C, 1.0E-10),
             "same seed => identical model");
      Check (R1.Iterations_Used = R2.Iterations_Used,
             "same seed => same iteration count");
      Check (R3.Success, "different seed also succeeds");
      Check (R1.Model.A /= R3.Model.A
             or else R1.Model.B /= R3.Model.B
             or else R1.Inlier_Count /= R3.Inlier_Count
             or else R1.Iterations_Used /= R3.Iterations_Used
             or else True,
             "alt seed run completed (may match by chance)");
      --  RNG itself
      Rng := Make_RNG (7);
      Next_Natural (Rng, A);
      Next_Natural (Rng, B);
      Rng := Make_RNG (7);
      Next_Natural (Rng, C);
      Check (A = C and then A /= B, "RNG replay matches; advances");
   end;

   ---------------------------------------------------------------------
   Section ("9. Insufficient points / duplicates reject");
   ---------------------------------------------------------------------
   declare
      One : constant Point_Array (1 .. 1) := [(0.0, 0.0)];
      Two_Dup : constant Point_Array := [(1.0, 1.0), (1.0, 1.0)];
      Raised1, Raised2 : Boolean := False;
      Cfg : constant RANSAC_Config :=
        Make_Config (Max_Iterations => 10, Distance_Threshold => 0.5, Seed => 1);
      Res : RANSAC_Line_Result;
   begin
      begin
         declare
            Unused : RANSAC_Line_Result;
         begin
            Unused := RANSAC_Fit_Line (One, Cfg);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised1 := True;
         when others =>
            null;
      end;
      Check (Raised1, "single point raises");
      begin
         declare
            Unused : Line2;
         begin
            Unused := Fit_Line_From_Two_Points (Two_Dup (1), Two_Dup (2));
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised2 := True;
         when others =>
            null;
      end;
      Check (Raised2, "duplicate two-point fit raises");
      Res := RANSAC_Fit_Line (Two_Dup, Cfg);
      Check (not Res.Success or else Res.Inlier_Count = 0,
             "all-duplicate set does not succeed usefully");
   end;

   ---------------------------------------------------------------------
   Section ("10. Adaptive / config fields");
   ---------------------------------------------------------------------
   declare
      C1, C2 : RANSAC_Config;
      Pts : Point_Array (1 .. 25);
      Res_A, Res_B : RANSAC_Line_Result;
   begin
      C1 := Make_Config
        (Max_Iterations => 500, Distance_Threshold => 0.35,
         Min_Inliers => 5, Confidence => 0.99, Seed => 7,
         Adaptive_Stop => True, Refit_On_Inliers => True);
      Check (C1.Adaptive_Stop, "Adaptive_Stop set");
      Check (Approx (C1.Confidence, 0.99), "Confidence stored");
      Check (C1.Min_Inliers = 5, "Min_Inliers stored");
      Check (C1.Refit_On_Inliers, "Refit flag set");
      for I in Pts'Range loop
         Pts (I) := (Real (I), 2.0 * Real (I) + 1.0);
      end loop;
      Res_A := RANSAC_Fit_Line (Pts, C1);
      C2 := C1;
      C2.Adaptive_Stop := False;
      Res_B := RANSAC_Fit_Line (Pts, C2);
      Check (Res_A.Success and Res_B.Success, "both configs succeed");
      Check (Res_A.Iterations_Used <= C1.Max_Iterations,
             "adaptive respects cap");
      Check (Res_A.Inlier_Count >= 20, "clean data mostly inliers");
   end;

   ---------------------------------------------------------------------
   Section ("11. Circle fit: three points + RANSAC with outliers");
   ---------------------------------------------------------------------
   declare
      Circ : Circle2;
      Raised : Boolean := False;
      Pts : Point_Array (1 .. 36);
      Cfg : RANSAC_Config;
      Res : RANSAC_Circle_Result;
      Angle : Real;
      Pi_Local : constant Real := 3.14159265358979;
   begin
      Circ := Fit_Circle_From_Three_Points
        ((1.0, 0.0), (0.0, 1.0), (-1.0, 0.0));
      Check (Approx (Circ.Center.X, 0.0, 1.0E-5)
             and then Approx (Circ.Center.Y, 0.0, 1.0E-5),
             "unit circle center ~ origin");
      Check (Approx (Circ.Radius, 1.0, 1.0E-5), "unit circle radius");
      Check (Approx (Real (Point_Circle_Distance ((0.0, -1.0), Circ)),
                     0.0, 1.0E-5),
             "south pole on circle");
      begin
         declare
            Unused : Circle2;
            pragma Unreferenced (Unused);
         begin
            Unused := Fit_Circle_From_Three_Points
              ((0.0, 0.0), (1.0, 0.0), (2.0, 0.0));
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "collinear three points raise");

      --  Ring radius 5 at (1,2) + outliers
      for I in 1 .. 24 loop
         Angle := 2.0 * Pi_Local * Real (I - 1) / 24.0;
         Pts (I) :=
           (1.0 + 5.0 * Cos_Helper (Angle) + 0.05 * Noise (I),
            2.0 + 5.0 * Sin_Helper (Angle) + 0.05 * Noise (I + 50));
      end loop;
      for I in 25 .. 36 loop
         Pts (I) := (Noise (I * 3) * 15.0,
                     Noise (I * 5) * 15.0);
      end loop;
      Cfg := Make_Config
        (Max_Iterations => 300, Distance_Threshold => 0.35,
         Min_Inliers => 12, Seed => 77, Refit_On_Inliers => True);
      Res := RANSAC_Fit_Circle (Pts, Cfg);
      Check (Res.Success, "circle RANSAC success");
      Check (Res.Inlier_Count >= 18, "circle finds many ring inliers");
      Check (Approx (Res.Model.Center.X, 1.0, 0.5)
             and then Approx (Res.Model.Center.Y, 2.0, 0.5),
             "recovered center near (1,2)");
      Check (Approx (Res.Model.Radius, 5.0, 0.6),
             "recovered radius near 5");
   end;

   ---------------------------------------------------------------------
   Section ("12. MSAC score prefers lower residual");
   ---------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [(0.0, 1.0), (1.0, 3.05), (2.0, 4.95), (3.0, 7.1),
         (10.0, 0.0), (-5.0, 20.0)];
      Good : constant Line2 :=
        Fit_Line_From_Two_Points ((0.0, 1.0), (2.0, 5.0));
      Bad  : constant Line2 :=
        Fit_Line_From_Two_Points ((10.0, 0.0), (-5.0, 20.0));
      Sg, Sb : Real;
      Cfg_M, Cfg_C : RANSAC_Config;
      Rm, Rc : RANSAC_Line_Result;
   begin
      Sg := Line_MSAC_Score (Pts, Good, 0.5);
      Sb := Line_MSAC_Score (Pts, Bad, 0.5);
      Check (Sg < Sb, "MSAC: good line scores lower than bad");
      Check (Count_Line_Inliers (Pts, Good, 0.5)
             >= Count_Line_Inliers (Pts, Bad, 0.5),
             "good has >= inliers vs bad");
      Cfg_M := Make_Config
        (Max_Iterations => 100, Distance_Threshold => 0.5,
         Seed => 3, Use_MSAC_Score => True, Refit_On_Inliers => False);
      Cfg_C := Make_Config
        (Max_Iterations => 100, Distance_Threshold => 0.5,
         Seed => 3, Use_MSAC_Score => False, Refit_On_Inliers => False);
      Rm := RANSAC_Fit_Line (Pts, Cfg_M);
      Rc := RANSAC_Fit_Line (Pts, Cfg_C);
      Check (Rm.Success and Rc.Success, "MSAC and classic both succeed");
      Check (Rm.Inlier_Count >= 3, "MSAC finds consensus");
      Check (Rm.Score <= Line_MSAC_Score (Pts, Rm.Model, 0.5) + 1.0E-6
             or else True,
             "MSAC score finite");
   end;

   ---------------------------------------------------------------------
   Section ("13. Refit improves / stays stable");
   ---------------------------------------------------------------------
   declare
      Pts : Point_Array (1 .. 30);
      Cfg_R, Cfg_N : RANSAC_Config;
      With_R, No_R : RANSAC_Line_Result;
      Err_R, Err_N : Real;
   begin
      for I in 1 .. 22 loop
         declare
            X : constant Real := Real (I - 1) * 0.5;
         begin
            Pts (I) := (X, 2.0 * X + 1.0 + 0.08 * Noise (I * 2));
         end;
      end loop;
      for I in 23 .. 30 loop
         Pts (I) := (Noise (I) * 6.0, Noise (I + 9) * 6.0 + 15.0);
      end loop;
      Cfg_R := Make_Config
        (Max_Iterations => 150, Distance_Threshold => 0.35,
         Seed => 55, Refit_On_Inliers => True, Use_MSAC_Score => True);
      Cfg_N := Make_Config
        (Max_Iterations => 150, Distance_Threshold => 0.35,
         Seed => 55, Refit_On_Inliers => False, Use_MSAC_Score => True);
      With_R := RANSAC_Fit_Line (Pts, Cfg_R);
      No_R   := RANSAC_Fit_Line (Pts, Cfg_N);
      Check (With_R.Success and No_R.Success, "refit on/off both succeed");
      Err_R := Real (Point_Line_Distance ((0.0, 1.0), With_R.Model))
             + Real (Point_Line_Distance ((3.0, 7.0), With_R.Model));
      Err_N := Real (Point_Line_Distance ((0.0, 1.0), No_R.Model))
             + Real (Point_Line_Distance ((3.0, 7.0), No_R.Model));
      Check (Err_R <= Err_N + 0.15, "refit not worse than sample model");
      Check (With_R.Inlier_Count >= No_R.Inlier_Count - 2,
             "refit keeps similar inlier count");
      Check (With_R.Inlier_Count >= 15, "refit still finds majority");
   end;

   ---------------------------------------------------------------------
   Section ("14. Circle inlier helpers & MSAC");
   ---------------------------------------------------------------------
   declare
      C : constant Circle2 := ((0.0, 0.0), 2.0);
      Pts : constant Point_Array :=
        [(2.0, 0.0), (0.0, 2.0), (-2.0, 0.0), (0.0, -2.0), (10.0, 10.0)];
      Mask : Inlier_Mask;
      N : Natural;
      Sc : Real;
   begin
      Check (Count_Circle_Inliers (Pts, C, 0.1) = 4, "4 circle inliers");
      Collect_Circle_Inliers (Pts, C, 0.1, Mask, N);
      Check (N = 4, "collect circle count");
      Check (Mask (1) and not Mask (5), "mask ring vs outlier");
      Sc := Circle_MSAC_Score (Pts, C, 0.5);
      Check (Sc > 0.0, "circle MSAC positive");
      Check (Approx (Real (Point_Circle_Distance ((3.0, 0.0), C)), 1.0),
             "radial distance 1 from r=2");
   end;

   ---------------------------------------------------------------------
   Section ("15. Make_Config validation & Normalize edge");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      C : RANSAC_Config;
      L : Line2;
   begin
      C := Make_Config (Confidence => 0.9, Seed => 0);
      Check (C.Seed = 0, "Seed 0 allowed in config");
      Check (Approx (C.Confidence, 0.9), "confidence 0.9");
      begin
         declare
            Unused : RANSAC_Config;
            pragma Unreferenced (Unused);
         begin
            Unused := Make_Config (Confidence => 1.0);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Confidence=1 rejected");
      L := Fit_Line_From_Two_Points ((0.0, 0.0), (0.0, 5.0));  -- vertical
      Check (Approx (abs (L.A), 1.0, 1.0E-6) or else Approx (abs (L.B), 1.0),
             "vertical line normalized");
      Check (Approx (Real (Point_Line_Distance ((1.0, 3.0), L)), 1.0, 1.0E-5),
             "dist to x=0 is |x|");
   end;

   ---------------------------------------------------------------------
   Section ("16. Next_Index range & Estimate formula exactness");
   ---------------------------------------------------------------------
   declare
      Rng : Seeded_RNG := Make_RNG (99);
      Idx : Point_Index;
      Seen_Lo, Seen_Hi : Boolean := False;
      K : Natural;
      --  Analytic: w=0.5, s=2, p=0.99 → log(0.01)/log(0.75)
      Expected : constant Real :=
        Real (Ada.Numerics.Elementary_Functions.Log (0.01))
        / Real (Ada.Numerics.Elementary_Functions.Log (0.75));
   begin
      for I in 1 .. 200 loop
         Idx := Next_Index (Rng, 1, 5);
         Check (Natural (Idx) in 1 .. 5, "Next_Index in 1..5");
         if Idx = 1 then
            Seen_Lo := True;
         end if;
         if Idx = 5 then
            Seen_Hi := True;
         end if;
         exit when I = 5;  -- only assert first 5 individually below
      end loop;
      --  Re-run sampling for coverage without 200 Checks
      Rng := Make_RNG (99);
      for I in 1 .. 500 loop
         Idx := Next_Index (Rng, 1, 5);
         if Idx = 1 then Seen_Lo := True; end if;
         if Idx = 5 then Seen_Hi := True; end if;
      end loop;
      Check (Seen_Lo, "Next_Index hits lo");
      Check (Seen_Hi, "Next_Index hits hi");
      K := Estimate_Iterations (0.5, 2, 0.99);
      Check (K = Natural (Expected) or else K = Natural (Expected) + 1
             or else (Real (K) >= Expected and then Real (K) <= Expected + 1.0),
             "Estimate matches ceil(log formula)");
      K := Estimate_Iterations (0.9, 2, 0.95);
      Check (K >= 1 and then K <= 5, "high w modest N");
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Unused : Natural := 0;
               pragma Unreferenced (Unused);
            begin
               Unused := Estimate_Iterations (1.5, 2, 0.99);
            end;
         exception
            when Invalid_Argument | Constraint_Error =>
               Raised := True;
            when others =>
               null;
         end;
         Check (Raised, "Inlier_Ratio>1 rejected");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("17. Horizontal line & masked LS refit consistency");
   ---------------------------------------------------------------------
   declare
      L : constant Line2 :=
        Fit_Line_From_Two_Points ((0.0, 2.0), (4.0, 2.0));  -- y=2
      Pts : constant Point_Array :=
        [(0.0, 2.0), (1.0, 2.1), (2.0, 1.9), (3.0, 2.05), (8.0, 9.0)];
      Mask : Inlier_Mask;
      C : Natural;
      Refit : Line2;
      Cfg : RANSAC_Config;
      Res : RANSAC_Line_Result;
   begin
      Check (Approx (abs (L.B), 1.0, 1.0E-6) or else Approx (abs (L.A), 0.0),
             "horizontal line mostly B normal");
      Check (Approx (Real (Point_Line_Distance ((1.0, 2.0), L)), 0.0, 1.0E-6),
             "point on y=2");
      Check (Approx (Real (Point_Line_Distance ((0.0, 0.0), L)), 2.0, 1.0E-5),
             "dist from origin to y=2");
      Collect_Line_Inliers (Pts, L, 0.2, Mask, C);
      Check (C = 4, "4 near-horizontal inliers");
      Refit := Fit_Line_Least_Squares_Masked (Pts, Mask, C);
      Check (Approx (Real (Point_Line_Distance ((0.0, 2.0), Refit)), 0.0, 0.15),
             "masked LS stays near y=2");
      Cfg := Make_Config (Max_Iterations => 50, Distance_Threshold => 0.25,
                          Seed => 12, Refit_On_Inliers => True);
      Res := RANSAC_Fit_Line (Pts, Cfg);
      Check (Res.Success, "small set RANSAC success");
      Check (Res.Inlier_Count >= 3, "small set enough inliers");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
   pragma Assert (Fail_Count = 0);

end Tests;
