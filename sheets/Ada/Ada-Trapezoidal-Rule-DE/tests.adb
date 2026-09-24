--  Standalone test suite for Trapezoidal_Rule_DE (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Trapezoidal_Rule_DE; use Trapezoidal_Rule_DE;

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

   Default_Cfg : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, Solver => Fixed_Point);

   Newton_Cfg : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, Solver => Newton);

   Raised : Boolean;

begin
   Put_Line ("Trapezoidal_Rule_DE test suite");
   Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error helpers");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Abs_Error (1.0, 1.0) = 0.0, "Abs_Error zero");
   Check (Near (Abs_Error (3.0, 1.0), 2.0), "Abs_Error 3-1");
   Check (Near (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
   Check (Abs_Error (0.5, 0.5) = 0.0, "Abs_Error identical");

   ---------------------------------------------------------------------
   Section ("2. Exact_Exponential / Amplification");
   ---------------------------------------------------------------------
   Check (Near (Exact_Exponential (-1.0, 0.0), 1.0), "exact e^0 = 1");
   Check (Near (Exact_Exponential (0.0, 5.0), 1.0), "exact λ=0");
   Check (Near (Exact_Exponential (-1.0, 1.0),
                Exact_Exponential (-1.0, 1.0, 1.0)),
          "exact decay Y0=1");
   Check (Near (Exact_Exponential (1.0, 1.0),
                Exact_Exponential (-1.0, -1.0)),
          "e^{+1} = e^{−(−1)}");
   Check (Near (Exact_Exponential (-1.0, 2.0, 2.0),
                2.0 * Exact_Exponential (-1.0, 2.0)),
          "exact scales with Y0");
   Check (Near (Amplification (0.0), 1.0), "R(0)=1");
   Check (Near (Amplification (-2.0), 0.0, 1.0E-12), "R(-2)=0");
   --  For z < 0, |R(z)| < 1 (A-stability on negative reals).
   Check (abs (Amplification (-0.5)) < 1.0, "|R(-0.5)| < 1");
   Check (abs (Amplification (-1.0)) < 1.0, "|R(-1)| < 1");
   Check (abs (Amplification (-10.0)) < 1.0, "|R(-10)| < 1");
   Check (abs (Amplification (-100.0)) <= 1.0 + 1.0E-12,
          "|R(-100)| ≤ 1");
   --  Growth: R(z) > 1 for z > 0 (away from the pole at z=2).
   Check (Amplification (0.5) > 1.0, "R(0.5) > 1");
   Check (Amplification (1.0) > 1.0, "R(1) > 1");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Amplification (2.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Amplification pole z=2 raises");

   ---------------------------------------------------------------------
   Section ("3. Sample ODE evaluations");
   ---------------------------------------------------------------------
   Check (Near (F_Decay (0.0, 1.0), -1.0), "F_Decay(0,1)=-1");
   Check (Near (F_Decay (5.0, 2.0), -2.0), "F_Decay ignores t");
   Check (Near (DF_Decay (0.0, 1.0), -1.0), "DF_Decay=-1");
   Check (Near (F_Growth (0.0, 3.0), 3.0), "F_Growth(0,3)=3");
   Check (Near (DF_Growth (0.0, 0.0), 1.0), "DF_Growth=+1");
   Check (Near (F_Decay_2 (0.0, 4.0), -8.0), "F_Decay_2");
   Check (Near (DF_Decay_2 (1.0, 1.0), -2.0), "DF_Decay_2");
   Check (Near (F_Stiff (0.0, 1.0), -50.0), "F_Stiff");
   Check (Near (DF_Stiff (0.0, 1.0), -50.0), "DF_Stiff");
   Check (Near (F_Logistic (0.0, 0.5), 0.25), "F_Logistic at 0.5");
   Check (Near (DF_Logistic (0.0, 0.5), 0.0), "DF_Logistic at 0.5");
   Check (Near (F_Logistic (0.0, 0.0), 0.0), "F_Logistic at 0");
   Check (Near (F_Logistic (0.0, 1.0), 0.0), "F_Logistic at 1");

   ---------------------------------------------------------------------
   Section ("4. Step_Implicit: decay y'=-y");
   ---------------------------------------------------------------------
   declare
      R   : Step_Result;
      H   : constant Real := 0.1;
      Exact_Next : constant Real := Exact_Exponential (-1.0, H);
   begin
      R := Step_Implicit (F_Decay'Access, 0.0, 1.0, H, Default_Cfg);
      Check (R.Converged, "decay step converged (FP)");
      Check (R.Iterations >= 1, "decay step used ≥1 iter");
      Check (Near (R.Y_Next, Exact_Next, 1.0E-3),
             "decay step ≈ e^{-h} (tol 1e-3)");
      Check (Abs_Error (R.Y_Next, Exact_Next) < 1.0E-3,
             "decay Abs_Error < 1e-3");

      R := Step_Implicit
        (F_Decay'Access, 0.0, 1.0, H, Newton_Cfg, DF_Decay'Access);
      Check (R.Converged, "decay step converged (Newton)");
      Check (Near (R.Y_Next, Exact_Next, 1.0E-3),
             "Newton decay ≈ e^{-h}");
      --  Linear problem: one Newton step from Euler guess is essentially
      --  exact for the discrete equation (quadratic converge).
      Check (R.Iterations <= 5, "Newton linear converges fast");
   end;

   ---------------------------------------------------------------------
   Section ("5. Step_Implicit: growth y'=y");
   ---------------------------------------------------------------------
   declare
      R : Step_Result;
      H : constant Real := 0.05;
      Exact_Next : constant Real := Exact_Exponential (1.0, H);
   begin
      R := Step_Implicit (F_Growth'Access, 0.0, 1.0, H, Default_Cfg);
      Check (R.Converged, "growth step converged");
      Check (Near (R.Y_Next, Exact_Next, 5.0E-4),
             "growth step ≈ e^{h}");
      R := Step_Implicit
        (F_Growth'Access, 0.0, 1.0, H, Newton_Cfg, DF_Growth'Access);
      Check (R.Converged, "growth Newton converged");
      Check (Near (R.Y_Next, Exact_Next, 5.0E-4),
             "growth Newton ≈ e^{h}");
   end;

   ---------------------------------------------------------------------
   Section ("6. Step_Heun contrast");
   ---------------------------------------------------------------------
   declare
      Yh : Real;
      Yi : Step_Result;
      H  : constant Real := 0.1;
      Ex : constant Real := Exact_Exponential (-1.0, H);
   begin
      Yh := Step_Heun (F_Decay'Access, 0.0, 1.0, H);
      Yi := Step_Implicit (F_Decay'Access, 0.0, 1.0, H, Default_Cfg);
      Check (Near (Yh, Ex, 5.0E-3), "Heun decay ≈ exact");
      Check (Yi.Converged, "implicit for Heun contrast ok");
      --  Both second-order; for linear decay they are close.
      Check (Near (Yh, Yi.Y_Next, 5.0E-3), "Heun ≈ implicit one step");
      Check (Abs_Error (Yh, Ex) < 0.01, "Heun Abs_Error bound");
   end;

   ---------------------------------------------------------------------
   Section ("7. Integrate decay over [0,1]");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Y_Newton, Exact : Real;
      Err_C, Err_F : Real;
   begin
      Exact    := Exact_Exponential (-1.0, 1.0);
      Y_Coarse := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 10, Default_Cfg);
      Y_Fine   := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 100, Default_Cfg);
      Y_Newton := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 50, Newton_Cfg, DF_Decay'Access);
      Err_C := Abs_Error (Y_Coarse, Exact);
      Err_F := Abs_Error (Y_Fine, Exact);
      Check (Near (Y_Coarse, Exact, 1.0E-2), "N=10 decay ≈ e^{-1}");
      Check (Near (Y_Fine, Exact, 1.0E-4), "N=100 decay ≈ e^{-1}");
      Check (Near (Y_Newton, Exact, 1.0E-4), "Newton N=50 ≈ e^{-1}");
      Check (Err_F < Err_C, "smaller h → smaller error (decay)");
      Check (Err_F < 1.0E-5, "fine Abs_Error < 1e-5");
      Check (Y_Fine > 0.0, "decay stays positive");
   end;

   ---------------------------------------------------------------------
   Section ("8. Integrate growth over [0,1]");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Exact : Real;
      Err_C, Err_F : Real;
   begin
      Exact    := Exact_Exponential (1.0, 1.0);
      Y_Coarse := Integrate
        (F_Growth'Access, 0.0, 1.0, 1.0, 20, Default_Cfg);
      Y_Fine   := Integrate
        (F_Growth'Access, 0.0, 1.0, 1.0, 200, Default_Cfg);
      Err_C := Abs_Error (Y_Coarse, Exact);
      Err_F := Abs_Error (Y_Fine, Exact);
      Check (Near (Y_Coarse, Exact, 5.0E-3), "N=20 growth ≈ e");
      Check (Near (Y_Fine, Exact, 1.0E-4), "N=200 growth ≈ e");
      Check (Err_F < Err_C, "smaller h → smaller error (growth)");
      Check (Y_Fine > 2.0, "growth exceeds 2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Integrate λ=-2 and stiff λ=-50");
   ---------------------------------------------------------------------
   declare
      Y2, Exact2, Ys, Exact_S : Real;
   begin
      Exact2 := Exact_Exponential (-2.0, 1.0);
      Y2 := Integrate
        (F_Decay_2'Access, 0.0, 1.0, 1.0, 80, Default_Cfg,
         DF_Decay_2'Access);
      Check (Near (Y2, Exact2, 1.0E-3), "λ=-2 integrate");
      Check (Abs_Error (Y2, Exact2) < 1.0E-3, "λ=-2 Abs_Error");

      Exact_S := Exact_Exponential (-50.0, 1.0);
      --  Implicit trapezoidal is A-stable: large |hλ| still decays.
      Ys := Integrate
        (F_Stiff'Access, 0.0, 1.0, 1.0, 40, Newton_Cfg, DF_Stiff'Access);
      Check (Ys >= 0.0, "stiff solution non-negative");
      Check (Ys < 0.1, "stiff decays strongly by t=1");
      Check (Near (Ys, Exact_S, 1.0E-2) or else Ys < Exact_S + 1.0E-2,
             "stiff near exact or small");
      Check (Abs_Error (Ys, Exact_S) < 0.05, "stiff Abs_Error < 0.05");
   end;

   ---------------------------------------------------------------------
   Section ("10. Integrate_Heun vs Integrate");
   ---------------------------------------------------------------------
   declare
      Yi, Yh, Exact : Real;
   begin
      Exact := Exact_Exponential (-1.0, 1.0);
      Yi := Integrate (F_Decay'Access, 0.0, 1.0, 1.0, 50, Default_Cfg);
      Yh := Integrate_Heun (F_Decay'Access, 0.0, 1.0, 1.0, 50);
      Check (Near (Yi, Exact, 1.0E-3), "implicit N=50");
      Check (Near (Yh, Exact, 1.0E-3), "Heun N=50");
      Check (Near (Yi, Yh, 5.0E-3), "implicit ≈ Heun on mild problem");
      Check (Abs_Error (Yi, Exact) <= Abs_Error (Yh, Exact) + 1.0E-6
             or else Abs_Error (Yh, Exact) < 1.0E-3,
             "both accurate on decay");
   end;

   ---------------------------------------------------------------------
   Section ("11. Order / refinement study");
   ---------------------------------------------------------------------
   declare
      E10, E20, E40, Exact : Real;
      Err10, Err20, Err40 : Real;
   begin
      Exact := Exact_Exponential (-1.0, 2.0);
      E10 := Integrate (F_Decay'Access, 0.0, 1.0, 2.0, 10, Default_Cfg);
      E20 := Integrate (F_Decay'Access, 0.0, 1.0, 2.0, 20, Default_Cfg);
      E40 := Integrate (F_Decay'Access, 0.0, 1.0, 2.0, 40, Default_Cfg);
      Err10 := Abs_Error (E10, Exact);
      Err20 := Abs_Error (E20, Exact);
      Err40 := Abs_Error (E40, Exact);
      Check (Err20 < Err10, "N=20 error < N=10");
      Check (Err40 < Err20, "N=40 error < N=20");
      --  Second-order: halving h should cut error by ~4.
      Check (Err10 / Err40 > 8.0, "rough O(h^2) factor N10/N40");
      Check (Near (E40, Exact, 1.0E-4), "N=40 at t=2 accurate");
   end;

   ---------------------------------------------------------------------
   Section ("12. Logistic nonlinear + Newton FD Jacobian");
   ---------------------------------------------------------------------
   declare
      Y_FP, Y_N, Y_FD : Real;
      Cfg_FD : constant Config :=
        (Max_Iterations => 80, Tol => 1.0E-12, Solver => Newton);
   begin
      --  y'=y(1-y), y(0)=0.1; stays in (0,1), approaches 1.
      Y_FP := Integrate
        (F_Logistic'Access, 0.0, 0.1, 5.0, 100, Default_Cfg);
      Y_N := Integrate
        (F_Logistic'Access, 0.0, 0.1, 5.0, 100, Newton_Cfg,
         DF_Logistic'Access);
      Y_FD := Integrate
        (F_Logistic'Access, 0.0, 0.1, 5.0, 100, Cfg_FD, null);
      Check (Y_FP > 0.1, "logistic grew from 0.1");
      Check (Y_FP < 1.0 + 1.0E-6, "logistic ≤ 1");
      Check (Y_FP > 0.9, "logistic near carrying capacity");
      Check (Near (Y_FP, Y_N, 1.0E-4), "FP ≈ Newton logistic");
      Check (Near (Y_N, Y_FD, 1.0E-4), "Newton analytic ≈ FD");
   end;

   ---------------------------------------------------------------------
   Section ("13. Single-step matches Amplification on linear");
   ---------------------------------------------------------------------
   declare
      H : constant Real := 0.25;
      Z : constant Real := H * (-1.0);
      R : Step_Result;
      Pred : Real;
   begin
      --  Exact discrete map: y1 = R(hλ) y0.
      Pred := Amplification (Z);
      R := Step_Implicit
        (F_Decay'Access, 0.0, 1.0, H, Newton_Cfg, DF_Decay'Access);
      Check (R.Converged, "amp match converged");
      Check (Near (R.Y_Next, Pred, 1.0E-10),
             "step = R(hλ) for linear decay");
      R := Step_Implicit
        (F_Growth'Access, 0.0, 1.0, H, Newton_Cfg, DF_Growth'Access);
      Pred := Amplification (H * 1.0);
      Check (Near (R.Y_Next, Pred, 1.0E-10),
             "step = R(hλ) for linear growth");
   end;

   ---------------------------------------------------------------------
   Section ("14. Invalid_Argument cases");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         Dummy : Step_Result;
      begin
         Dummy := Step_Implicit (F_Decay'Access, 0.0, 1.0, 0.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "H=0 raises");

   Raised := False;
   begin
      declare
         Dummy : Step_Result;
      begin
         Dummy := Step_Implicit (F_Decay'Access, 0.0, 1.0, -0.1);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "H<0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Step_Heun (F_Decay'Access, 0.0, 1.0, -1.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Heun H<0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Integrate (F_Decay'Access, 1.0, 1.0, 0.0, 10);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "T1<T0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Integrate (F_Decay'Access, 0.0, 1.0, 0.0, 5);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "T1=T0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Integrate_Heun (F_Growth'Access, 2.0, 1.0, 1.0, 3);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Heun integrate T1<T0 raises");

   Raised := False;
   begin
      declare
         Tight : constant Config :=
           (Max_Iterations => 1, Tol => 1.0E-30, Solver => Fixed_Point);
         Dummy : Step_Result;
      begin
         --  One iteration with absurd Tol should fail to converge.
         Dummy := Step_Implicit
           (F_Logistic'Access, 0.0, 0.2, 0.5, Tight);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "failed convergence raises");

   ---------------------------------------------------------------------
   Section ("15. Consistency / edge values");
   ---------------------------------------------------------------------
   declare
      R : Step_Result;
      Y : Real;
   begin
      R := Step_Implicit (F_Decay'Access, 0.0, 0.0, 0.1, Default_Cfg);
      Check (R.Converged, "y0=0 converges");
      Check (Near (R.Y_Next, 0.0), "y0=0 stays 0 (linear homogeneous)");

      Y := Integrate (F_Decay'Access, 0.0, 1.0, 0.01, 1, Default_Cfg);
      Check (Near (Y,
                   Step_Implicit
                     (F_Decay'Access, 0.0, 1.0, 0.01, Default_Cfg).Y_Next,
                   1.0E-12),
             "Integrate N=1 = Step_Implicit");

      Y := Integrate_Heun (F_Decay'Access, 0.0, 1.0, 0.01, 1);
      Check (Near (Y, Step_Heun (F_Decay'Access, 0.0, 1.0, 0.01),
                   1.0E-12),
             "Integrate_Heun N=1 = Step_Heun");

      --  Tiny interval still works.
      Y := Integrate (F_Growth'Access, 0.0, 1.0, 1.0E-4, 2, Default_Cfg);
      Check (Near (Y, Exact_Exponential (1.0, 1.0E-4), 1.0E-8),
             "tiny interval growth");

      R := Step_Implicit
        (F_Decay'Access, 3.0, Exact_Exponential (-1.0, 3.0), 0.1,
         Newton_Cfg, DF_Decay'Access);
      Check (R.Converged, "mid-trajectory step ok");
      Check (Near (R.Y_Next, Exact_Exponential (-1.0, 3.1), 1.0E-3),
             "mid-trajectory accuracy");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra accuracy / A-stability spot checks");
   ---------------------------------------------------------------------
   declare
      Y : Real;
      Exact : Real;
      Z : Real;
   begin
      Exact := Exact_Exponential (-1.0, 0.5);
      Y := Integrate (F_Decay'Access, 0.0, 1.0, 0.5, 25, Default_Cfg);
      Check (Near (Y, Exact, 2.0E-5), "t=0.5 N=25");
      Y := Integrate
        (F_Decay'Access, 0.0, 1.0, 0.5, 25, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y, Exact, 2.0E-5), "t=0.5 Newton");

      --  Large negative z: |R| ≤ 1 (never grows).
      Z := -1.0E6;
      Check (abs (Amplification (Z)) <= 1.0 + 1.0E-9,
             "|R(-1e6)| ≤ 1");
      Check (Amplification (Z) < 0.0, "R(-1e6) negative (oscillatory)");

      Y := Integrate_Heun (F_Growth'Access, 0.0, 2.0, 0.5, 40);
      Check (Near (Y, Exact_Exponential (1.0, 0.5, 2.0), 1.0E-3),
             "Heun growth Y0=2");

      Y := Integrate
        (F_Decay_2'Access, 0.0, 3.0, 0.25, 20, Newton_Cfg,
         DF_Decay_2'Access);
      Check (Near (Y, Exact_Exponential (-2.0, 0.25, 3.0), 1.0E-4),
             "λ=-2 short interval");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
