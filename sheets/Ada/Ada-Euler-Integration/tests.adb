--  Standalone test suite for Euler_Integration (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Euler_Integration; use Euler_Integration;

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

   Raised : Boolean;

begin
   Put_Line ("Euler_Integration test suite");
   Put_Line ("============================");

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
   Check (Near (Amplification (-1.0), 0.0), "R(-1)=0");
   Check (Near (Amplification (-2.0), -1.0), "R(-2)=-1");
   Check (Near (Amplification (0.5), 1.5), "R(0.5)=1.5");
   Check (Near (Amplification (1.0), 2.0), "R(1)=2");
   Check (Near (Amplification (-0.5), 0.5), "R(-0.5)=0.5");
   --  Stability disk on the real axis: |R(z)| ≤ 1 iff z ∈ [-2, 0].
   Check (abs (Amplification (-0.5)) <= 1.0, "|R(-0.5)| ≤ 1");
   Check (abs (Amplification (-1.0)) <= 1.0, "|R(-1)| ≤ 1");
   Check (abs (Amplification (-2.0)) <= 1.0, "|R(-2)| ≤ 1");
   Check (abs (Amplification (-2.1)) > 1.0, "|R(-2.1)| > 1 unstable");
   Check (abs (Amplification (0.1)) > 1.0, "|R(0.1)| > 1 growth");

   ---------------------------------------------------------------------
   Section ("3. Sample ODE evaluations");
   ---------------------------------------------------------------------
   Check (Near (F_Decay (0.0, 1.0), -1.0), "F_Decay(0,1)=-1");
   Check (Near (F_Decay (5.0, 2.0), -2.0), "F_Decay ignores t");
   Check (Near (F_Growth (0.0, 3.0), 3.0), "F_Growth(0,3)=3");
   Check (Near (F_Decay_2 (0.0, 4.0), -8.0), "F_Decay_2");
   Check (Near (F_Stiff (0.0, 1.0), -50.0), "F_Stiff");
   Check (Near (F_Logistic (0.0, 0.5), 0.25), "F_Logistic at 0.5");
   Check (Near (F_Logistic (0.0, 0.0), 0.0), "F_Logistic at 0");
   Check (Near (F_Logistic (0.0, 1.0), 0.0), "F_Logistic at 1");
   Check (Near (G_Harmonic (1.0), -1.0), "G_Harmonic(1)=-1");
   Check (Near (G_Harmonic (-2.0), 2.0), "G_Harmonic(-2)=2");
   Check (Near (G_Harmonic (0.0), 0.0), "G_Harmonic(0)=0");

   ---------------------------------------------------------------------
   Section ("4. Step: decay y'=-y");
   ---------------------------------------------------------------------
   declare
      H          : constant Real := 0.1;
      Y_Next     : Real;
      Exact_Next : constant Real := Exact_Exponential (-1.0, H);
      Pred       : constant Real := Amplification (H * (-1.0));
   begin
      Y_Next := Step (F_Decay'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, 1.0 + H * (-1.0)), "decay step = 1 − h");
      Check (Near (Y_Next, Pred), "decay step = R(hλ)");
      Check (Near (Y_Next, Exact_Next, 1.0E-2),
             "decay step ≈ e^{-h} (tol 1e-2)");
      Check (Abs_Error (Y_Next, Exact_Next) < 0.01,
             "decay Abs_Error < 0.01");
      Check (Y_Next > 0.0, "decay step stays positive for h=0.1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Step: growth y'=y");
   ---------------------------------------------------------------------
   declare
      H          : constant Real := 0.05;
      Y_Next     : Real;
      Exact_Next : constant Real := Exact_Exponential (1.0, H);
   begin
      Y_Next := Step (F_Growth'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, 1.0 + H), "growth step = 1 + h");
      Check (Near (Y_Next, Amplification (H)), "growth = R(h)");
      Check (Near (Y_Next, Exact_Next, 5.0E-3), "growth step ≈ e^{h}");
      Check (Abs_Error (Y_Next, Exact_Next) < 0.005,
             "growth Abs_Error bound");
   end;

   ---------------------------------------------------------------------
   Section ("6. Integrate decay over [0,1]");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Exact : Real;
      Err_C, Err_F            : Real;
   begin
      Exact    := Exact_Exponential (-1.0, 1.0);
      Y_Coarse := Integrate (F_Decay'Access, 0.0, 1.0, 1.0, 10);
      Y_Fine   := Integrate (F_Decay'Access, 0.0, 1.0, 1.0, 100);
      Err_C    := Abs_Error (Y_Coarse, Exact);
      Err_F    := Abs_Error (Y_Fine, Exact);
      Check (Near (Y_Coarse, Exact, 5.0E-2), "N=10 decay ≈ e^{-1}");
      Check (Near (Y_Fine, Exact, 5.0E-3), "N=100 decay ≈ e^{-1}");
      Check (Err_F < Err_C, "smaller h → smaller error (decay)");
      Check (Err_F < 1.0E-2, "fine Abs_Error < 1e-2");
      Check (Y_Fine > 0.0, "decay stays positive");
      Check (Y_Coarse > 0.0, "coarse decay positive");
   end;

   ---------------------------------------------------------------------
   Section ("7. Integrate growth over [0,1]");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Exact : Real;
      Err_C, Err_F            : Real;
   begin
      Exact    := Exact_Exponential (1.0, 1.0);
      Y_Coarse := Integrate (F_Growth'Access, 0.0, 1.0, 1.0, 20);
      Y_Fine   := Integrate (F_Growth'Access, 0.0, 1.0, 1.0, 200);
      Err_C    := Abs_Error (Y_Coarse, Exact);
      Err_F    := Abs_Error (Y_Fine, Exact);
      Check (Near (Y_Coarse, Exact, 0.1), "N=20 growth ≈ e");
      Check (Near (Y_Fine, Exact, 1.0E-2), "N=200 growth ≈ e");
      Check (Err_F < Err_C, "smaller h → smaller error (growth)");
      Check (Y_Fine > 2.0, "growth exceeds 2");
   end;

   ---------------------------------------------------------------------
   Section ("8. Integrate λ=-2 and stiff λ=-50");
   ---------------------------------------------------------------------
   declare
      Y2, Exact2, Ys_Stable, Ys_Unstable : Real;
      H_Stable, H_Unstable               : Real;
   begin
      Exact2 := Exact_Exponential (-2.0, 1.0);
      Y2     := Integrate (F_Decay_2'Access, 0.0, 1.0, 1.0, 80);
      Check (Near (Y2, Exact2, 2.0E-2), "λ=-2 integrate");
      Check (Abs_Error (Y2, Exact2) < 0.05, "λ=-2 Abs_Error");

      --  For λ=-50, stability requires h ≤ 2/50 = 0.04.
      H_Stable   := 0.02;   -- inside disk
      H_Unstable := 0.1;    -- |1 + hλ| = |1 - 5| = 4 > 1
      Ys_Stable := Integrate
        (F_Stiff'Access, 0.0, 1.0, 1.0, Positive (Real'Rounding (1.0 / H_Stable)));
      Check (Ys_Stable >= 0.0, "stiff stable stays non-negative");
      Check (Ys_Stable < 0.1, "stiff stable decays by t=1");
      Check (Abs_Error (Ys_Stable, Exact_Exponential (-50.0, 1.0)) < 0.05
             or else Ys_Stable < 0.05,
             "stiff stable near exact or tiny");

      Ys_Unstable := Integrate
        (F_Stiff'Access, 0.0, 1.0, 0.5,
         Positive (Real'Rounding (0.5 / H_Unstable)));
      --  Unstable step: |R| > 1 so magnitude grows / oscillates.
      Check (abs (Amplification (H_Unstable * (-50.0))) > 1.0,
             "stiff h=0.1 outside stability disk");
      pragma Unreferenced (Ys_Unstable);
   end;

   ---------------------------------------------------------------------
   Section ("9. Order / refinement study (first-order)");
   ---------------------------------------------------------------------
   declare
      E10, E20, E40, Exact : Real;
      Err10, Err20, Err40  : Real;
   begin
      Exact := Exact_Exponential (-1.0, 2.0);
      E10   := Integrate (F_Decay'Access, 0.0, 1.0, 2.0, 10);
      E20   := Integrate (F_Decay'Access, 0.0, 1.0, 2.0, 20);
      E40   := Integrate (F_Decay'Access, 0.0, 1.0, 2.0, 40);
      Err10 := Abs_Error (E10, Exact);
      Err20 := Abs_Error (E20, Exact);
      Err40 := Abs_Error (E40, Exact);
      Check (Err20 < Err10, "N=20 error < N=10");
      Check (Err40 < Err20, "N=40 error < N=20");
      --  First-order: halving h should cut error by ~2.
      Check (Err10 / Err40 > 2.5, "rough O(h) factor N10/N40");
      Check (Near (E40, Exact, 5.0E-2), "N=40 at t=2 reasonable");
      Check (Err40 < 0.05, "N=40 Abs_Error < 0.05");
   end;

   ---------------------------------------------------------------------
   Section ("10. Logistic nonlinear");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine : Real;
   begin
      --  y'=y(1-y), y(0)=0.1; stays in (0,1), approaches 1.
      Y_Coarse := Integrate (F_Logistic'Access, 0.0, 0.1, 5.0, 50);
      Y_Fine   := Integrate (F_Logistic'Access, 0.0, 0.1, 5.0, 200);
      Check (Y_Coarse > 0.1, "logistic grew from 0.1");
      Check (Y_Coarse < 1.0 + 1.0E-6, "logistic ≤ 1");
      Check (Y_Coarse > 0.8, "logistic approaching capacity");
      Check (Y_Fine > Y_Coarse - 0.05, "fine also near capacity");
      Check (Y_Fine < 1.0 + 1.0E-6, "fine logistic ≤ 1");
      Check (Y_Fine > 0.9, "fine logistic near 1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Single-step matches Amplification on linear");
   ---------------------------------------------------------------------
   declare
      H    : constant Real := 0.25;
      Y_D  : Real;
      Y_G  : Real;
      Pred : Real;
   begin
      Pred := Amplification (H * (-1.0));
      Y_D  := Step (F_Decay'Access, 0.0, 1.0, H);
      Check (Near (Y_D, Pred, 1.0E-14), "step = R(hλ) for decay");
      Pred := Amplification (H * 1.0);
      Y_G  := Step (F_Growth'Access, 0.0, 1.0, H);
      Check (Near (Y_G, Pred, 1.0E-14), "step = R(hλ) for growth");
      Check (Near (Step (F_Decay_2'Access, 0.0, 1.0, 0.1),
                   Amplification (0.1 * (-2.0))),
             "step = R(hλ) for λ=-2");
   end;

   ---------------------------------------------------------------------
   Section ("12. Invalid_Argument cases");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Step (F_Decay'Access, 0.0, 1.0, 0.0);
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
         Dummy : Real;
      begin
         Dummy := Step (F_Decay'Access, 0.0, 1.0, -0.1);
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
         Dummy := Integrate (F_Growth'Access, 2.0, 1.0, 1.0, 3);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "growth integrate T1<T0 raises");

   Raised := False;
   begin
      declare
         Y : Real := 1.0;
         V : Real := 0.0;
      begin
         Step_Semi_Implicit (G_Harmonic'Access, Y, V, 0.0);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "semi-implicit H=0 raises");

   Raised := False;
   begin
      declare
         Y : Real := 1.0;
         V : Real := 0.0;
      begin
         Step_Semi_Implicit (G_Harmonic'Access, Y, V, -0.5);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "semi-implicit H<0 raises");

   ---------------------------------------------------------------------
   Section ("13. Consistency / edge values");
   ---------------------------------------------------------------------
   declare
      Y : Real;
   begin
      Y := Step (F_Decay'Access, 0.0, 0.0, 0.1);
      Check (Near (Y, 0.0), "y0=0 stays 0 (linear homogeneous)");

      Y := Integrate (F_Decay'Access, 0.0, 1.0, 0.01, 1);
      Check (Near (Y, Step (F_Decay'Access, 0.0, 1.0, 0.01), 1.0E-14),
             "Integrate N=1 = Step");

      Y := Integrate (F_Growth'Access, 0.0, 1.0, 1.0E-4, 2);
      Check (Near (Y, Exact_Exponential (1.0, 1.0E-4), 1.0E-7),
             "tiny interval growth");

      Y := Step (F_Decay'Access, 3.0, Exact_Exponential (-1.0, 3.0), 0.1);
      Check (Near (Y, Exact_Exponential (-1.0, 3.1), 2.0E-2),
             "mid-trajectory accuracy");

      --  Exact discrete product for N steps of decay: (1 − h)^N.
      declare
         N  : constant Positive := 20;
         H  : constant Real     := 1.0 / Real (N);
         Yn : Real              := 1.0;
      begin
         Yn := Integrate (F_Decay'Access, 0.0, 1.0, 1.0, N);
         Check (Near (Yn, (1.0 - H) ** N, 1.0E-12),
                "Integrate = (1−h)^N for decay");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Semi-implicit Euler harmonic sketch");
   ---------------------------------------------------------------------
   declare
      Y, V           : Real;
      Energy0, Energy : Real;
      Steps          : constant Positive := 200;
      H              : constant Real     := 0.05;
   begin
      Y := 1.0;
      V := 0.0;
      Energy0 := 0.5 * V * V + 0.5 * Y * Y;
      for I in 1 .. Steps loop
         Step_Semi_Implicit (G_Harmonic'Access, Y, V, H);
      end loop;
      Energy := 0.5 * V * V + 0.5 * Y * Y;
      --  Symplectic Euler nearly conserves energy (bounded oscillation).
      Check (Energy > 0.0, "harmonic energy positive");
      Check (abs (Energy - Energy0) < 0.5, "energy stays bounded");
      Check (abs (Y) < 3.0, "position bounded after many steps");
      Check (abs (V) < 3.0, "velocity bounded after many steps");

      --  One step hand-check: y=1, v=0, h=0.1 → v=-0.1, y=0.99
      Y := 1.0;
      V := 0.0;
      Step_Semi_Implicit (G_Harmonic'Access, Y, V, 0.1);
      Check (Near (V, -0.1), "semi-implicit v update");
      Check (Near (Y, 0.99), "semi-implicit y update");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra accuracy / stability spot checks");
   ---------------------------------------------------------------------
   declare
      Y     : Real;
      Exact : Real;
      Z     : Real;
   begin
      Exact := Exact_Exponential (-1.0, 0.5);
      Y     := Integrate (F_Decay'Access, 0.0, 1.0, 0.5, 25);
      Check (Near (Y, Exact, 1.0E-2), "t=0.5 N=25");

      Y := Integrate (F_Growth'Access, 0.0, 2.0, 0.5, 40);
      Check (Near (Y, Exact_Exponential (1.0, 0.5, 2.0), 2.0E-2),
             "growth Y0=2");

      Y := Integrate (F_Decay_2'Access, 0.0, 3.0, 0.25, 20);
      Check (Near (Y, Exact_Exponential (-2.0, 0.25, 3.0), 2.0E-2),
             "λ=-2 short interval");

      --  Boundary of stability disk on real axis.
      Z := -2.0;
      Check (Near (abs (Amplification (Z)), 1.0), "|R(-2)|=1 boundary");
      Z := -1.0;
      Check (Near (Amplification (Z), 0.0), "R(-1)=0 center of disk");

      --  Explicit formula: N steps of growth = (1+h)^N.
      declare
         N : constant Positive := 16;
         H : constant Real     := 0.5 / Real (N);
      begin
         Y := Integrate (F_Growth'Access, 0.0, 1.0, 0.5, N);
         Check (Near (Y, (1.0 + H) ** N, 1.0E-12),
                "Integrate growth = (1+h)^N");
      end;

      --  Compare coarse vs fine on logistic at short time.
      declare
         Yc, Yf : Real;
      begin
         Yc := Integrate (F_Logistic'Access, 0.0, 0.25, 1.0, 10);
         Yf := Integrate (F_Logistic'Access, 0.0, 0.25, 1.0, 100);
         Check (Yc > 0.25, "logistic short grew");
         Check (Yf > 0.25, "logistic fine grew");
         Check (Abs_Error (Yc, Yf) > 0.0 or else Near (Yc, Yf, 1.0E-3),
                "coarse/fine logistic differ or close");
         Check (Yf < 1.0, "logistic fine < 1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("16. Multi-step amplification product");
   ---------------------------------------------------------------------
   declare
      H     : constant Real     := 0.05;
      N     : constant Positive := 40;
      Y     : Real;
      Pred  : Real;
      Exact : Real;
   begin
      --  Forward Euler on y'=-y: y_N = (1 − h)^N.
      Pred  := Amplification (-H) ** N;
      Y     := Integrate (F_Decay'Access, 0.0, 1.0, Real (N) * H, N);
      Exact := Exact_Exponential (-1.0, Real (N) * H);
      Check (Near (Y, Pred, 1.0E-12), "N-step product R(z)^N");
      Check (Abs_Error (Y, Exact) < Abs_Error
               (Integrate (F_Decay'Access, 0.0, 1.0, Real (N) * H, N / 2),
                Exact),
             "more steps → smaller error vs exact");
      Check (Near (Y, Exact, 5.0E-2), "N=40 decay near exact");
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
