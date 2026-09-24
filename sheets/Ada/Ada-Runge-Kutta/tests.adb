--  Standalone test suite for Runge_Kutta (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Runge_Kutta; use Runge_Kutta;

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
   Put_Line ("Runge_Kutta test suite");
   Put_Line ("======================");

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
   Section ("2. Exact_Exponential");
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
   Check (Near (Exact_Exponential (1.0, 0.0, 7.0), 7.0), "exact t=0 Y0=7");
   Check (Exact_Exponential (-2.0, 1.0) < Exact_Exponential (-1.0, 1.0),
          "faster decay smaller value");

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
   Check (Near (F_Growth (10.0, -2.0), -2.0), "F_Growth ignores t");

   ---------------------------------------------------------------------
   Section ("4. Step_Euler (RK1 catalogue)");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.1;
      Y_Next : Real;
   begin
      Y_Next := Step_Euler (F_Decay'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, 1.0 - H), "Euler decay = 1 − h");
      Check (Near (Y_Next, Exact_Exponential (-1.0, H), 1.0E-2),
             "Euler decay ≈ e^{-h}");
      Y_Next := Step_Euler (F_Growth'Access, 0.0, 1.0, 0.05);
      Check (Near (Y_Next, 1.05), "Euler growth = 1 + h");
      Check (Near (Step_Euler (F_Decay'Access, 0.0, 0.0, 0.1), 0.0),
             "Euler y0=0 stays 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Step_Midpoint (RK2)");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.1;
      Y_Next : Real;
      Exact  : constant Real := Exact_Exponential (-1.0, H);
   begin
      --  Midpoint on y'=-y: k1=-1, k2=-(1 − h/2)=-(1-0.05)=-0.95
      --  y_new = 1 + h*(-0.95) = 1 - 0.095 = 0.905
      Y_Next := Step_Midpoint (F_Decay'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, 0.905), "midpoint decay hand value");
      Check (Abs_Error (Y_Next, Exact) < Abs_Error
               (Step_Euler (F_Decay'Access, 0.0, 1.0, H), Exact),
             "midpoint more accurate than Euler");
      Check (Near (Y_Next, Exact, 5.0E-4), "midpoint ≈ e^{-h}");
      Y_Next := Step_Midpoint (F_Growth'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, Exact_Exponential (1.0, H), 5.0E-4),
             "midpoint growth ≈ e^{h}");
   end;

   ---------------------------------------------------------------------
   Section ("6. Step_Heun (improved Euler RK2)");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.1;
      Y_Next : Real;
      Exact  : constant Real := Exact_Exponential (-1.0, H);
   begin
      --  Heun on y'=-y: k1=-1, k2=-(1-h)=-(0.9)=-0.9
      --  y_new = 1 + (h/2)(-1-0.9) = 1 - 0.095 = 0.905
      Y_Next := Step_Heun (F_Decay'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, 0.905), "Heun decay hand value");
      Check (Near (Y_Next,
                   Step_Midpoint (F_Decay'Access, 0.0, 1.0, H), 1.0E-14),
             "Heun = Midpoint on linear y'=-y");
      Check (Abs_Error (Y_Next, Exact) < Abs_Error
               (Step_Euler (F_Decay'Access, 0.0, 1.0, H), Exact),
             "Heun more accurate than Euler");
      Y_Next := Step_Heun (F_Growth'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, Exact_Exponential (1.0, H), 5.0E-4),
             "Heun growth ≈ e^{h}");
   end;

   ---------------------------------------------------------------------
   Section ("7. Step_RK4 classic");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.1;
      Y_Next : Real;
      Exact  : constant Real := Exact_Exponential (-1.0, H);
      Err_RK4, Err_Eul, Err_Mid : Real;
   begin
      Y_Next := Step_RK4 (F_Decay'Access, 0.0, 1.0, H);
      Err_RK4 := Abs_Error (Y_Next, Exact);
      Err_Eul := Abs_Error (Step_Euler (F_Decay'Access, 0.0, 1.0, H), Exact);
      Err_Mid := Abs_Error
        (Step_Midpoint (F_Decay'Access, 0.0, 1.0, H), Exact);
      Check (Near (Y_Next, Exact, 1.0E-6), "RK4 one-step ≈ e^{-h}");
      Check (Err_RK4 < Err_Mid, "RK4 error < Midpoint error");
      Check (Err_RK4 < Err_Eul, "RK4 error ≪ Euler error");
      Check (Err_RK4 < 1.0E-7, "RK4 Abs_Error very small");
      Y_Next := Step_RK4 (F_Growth'Access, 0.0, 1.0, H);
      Check (Near (Y_Next, Exact_Exponential (1.0, H), 1.0E-6),
             "RK4 growth ≈ e^{h}");
      Check (Near (Step_RK4 (F_Decay'Access, 0.0, 0.0, H), 0.0),
             "RK4 y0=0 stays 0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Integrate_RK4 decay / growth");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Exact : Real;
      Err_C, Err_F            : Real;
   begin
      Exact    := Exact_Exponential (-1.0, 1.0);
      Y_Coarse := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 10);
      Y_Fine   := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 100);
      Err_C    := Abs_Error (Y_Coarse, Exact);
      Err_F    := Abs_Error (Y_Fine, Exact);
      Check (Near (Y_Coarse, Exact, 1.0E-5), "RK4 N=10 ≈ e^{-1}");
      Check (Near (Y_Fine, Exact, 1.0E-10), "RK4 N=100 ≈ e^{-1}");
      Check (Err_F < Err_C, "RK4 smaller h → smaller error");
      Check (Y_Fine > 0.0, "RK4 decay stays positive");

      Exact    := Exact_Exponential (1.0, 1.0);
      Y_Coarse := Integrate_RK4 (F_Growth'Access, 0.0, 1.0, 1.0, 20);
      Y_Fine   := Integrate_RK4 (F_Growth'Access, 0.0, 1.0, 1.0, 200);
      Check (Near (Y_Coarse, Exact, 1.0E-6), "RK4 N=20 ≈ e");
      Check (Near (Y_Fine, Exact, 1.0E-10), "RK4 N=200 ≈ e");
      Check (Y_Fine > 2.0, "RK4 growth exceeds 2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Integrate Midpoint / Heun / Euler");
   ---------------------------------------------------------------------
   declare
      Exact : constant Real := Exact_Exponential (-1.0, 1.0);
      Ym, Yh, Ye, Yr : Real;
      Em, Eh, Ee, Er : Real;
   begin
      Ym := Integrate_Midpoint (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Yh := Integrate_Heun (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Ye := Integrate_Euler (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Yr := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Em := Abs_Error (Ym, Exact);
      Eh := Abs_Error (Yh, Exact);
      Ee := Abs_Error (Ye, Exact);
      Er := Abs_Error (Yr, Exact);
      Check (Near (Ym, Exact, 5.0E-3), "Midpoint N=40 ≈ e^{-1}");
      Check (Near (Yh, Exact, 5.0E-3), "Heun N=40 ≈ e^{-1}");
      Check (Near (Ye, Exact, 5.0E-2), "Euler N=40 ≈ e^{-1}");
      Check (Near (Yr, Exact, 1.0E-8), "RK4 N=40 ≈ e^{-1}");
      Check (Er < Em, "RK4 err < Midpoint err (same N)");
      Check (Er < Eh, "RK4 err < Heun err (same N)");
      Check (Er < Ee, "RK4 err ≪ Euler err (same N)");
      Check (Em < Ee, "Midpoint err < Euler err");
      Check (Eh < Ee, "Heun err < Euler err");
      Check (Near (Ym, Yh, 1.0E-10), "Midpoint≈Heun on linear decay");
   end;

   ---------------------------------------------------------------------
   Section ("10. RK4 ≪ Euler same-h comparison");
   ---------------------------------------------------------------------
   declare
      Exact : constant Real := Exact_Exponential (-1.0, 2.0);
      N     : constant Positive := 20;
      Yr, Ye : Real;
      Er, Ee : Real;
   begin
      Yr := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 2.0, N);
      Ye := Integrate_Euler (F_Decay'Access, 0.0, 1.0, 2.0, N);
      Er := Abs_Error (Yr, Exact);
      Ee := Abs_Error (Ye, Exact);
      Check (Er * 100.0 < Ee, "RK4 error < 1% of Euler error");
      Check (Er < 1.0E-5, "RK4 N=20 at t=2 very accurate");
      Check (Ee > 1.0E-3, "Euler N=20 still visibly wrong");
      Check (Near (Yr, Exact, 1.0E-6), "RK4 near exact at t=2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Order / refinement study");
   ---------------------------------------------------------------------
   declare
      Exact : constant Real := Exact_Exponential (-1.0, 1.0);
      E10, E20, E40 : Real;
      Err10, Err20, Err40 : Real;
   begin
      --  RK4: order 4 → halving h cuts error by ~16.
      E10   := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 10);
      E20   := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 20);
      E40   := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Err10 := Abs_Error (E10, Exact);
      Err20 := Abs_Error (E20, Exact);
      Err40 := Abs_Error (E40, Exact);
      Check (Err20 < Err10, "RK4 N=20 error < N=10");
      Check (Err40 < Err20, "RK4 N=40 error < N=20");
      Check (Err10 / Err40 > 50.0, "RK4 rough O(h^4) factor N10/N40");
      Check (Near (E40, Exact, 1.0E-8), "RK4 N=40 machine-close");

      --  Midpoint: order 2 → factor ~4 when h halved twice.
      E10   := Integrate_Midpoint (F_Decay'Access, 0.0, 1.0, 1.0, 10);
      E40   := Integrate_Midpoint (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Err10 := Abs_Error (E10, Exact);
      Err40 := Abs_Error (E40, Exact);
      Check (Err40 < Err10, "Midpoint refinement reduces error");
      Check (Err10 / Err40 > 8.0, "Midpoint rough O(h^2) factor");
   end;

   ---------------------------------------------------------------------
   Section ("12. λ=-2 and growth Y0≠1");
   ---------------------------------------------------------------------
   declare
      Y2, Exact2, Yg : Real;
   begin
      Exact2 := Exact_Exponential (-2.0, 1.0);
      Y2     := Integrate_RK4 (F_Decay_2'Access, 0.0, 1.0, 1.0, 40);
      Check (Near (Y2, Exact2, 1.0E-7), "RK4 λ=-2");
      Check (Abs_Error (Y2, Exact2) < 1.0E-7, "RK4 λ=-2 Abs_Error");

      Yg := Integrate_RK4 (F_Growth'Access, 0.0, 2.0, 0.5, 20);
      Check (Near (Yg, Exact_Exponential (1.0, 0.5, 2.0), 1.0E-8),
             "RK4 growth Y0=2");

      Y2 := Integrate_Heun (F_Decay_2'Access, 0.0, 1.0, 0.5, 40);
      Check (Near (Y2, Exact_Exponential (-2.0, 0.5), 1.0E-3),
             "Heun λ=-2 short");
   end;

   ---------------------------------------------------------------------
   Section ("13. Logistic nonlinear");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Yr, Ye : Real;
   begin
      Y_Coarse := Integrate_RK4 (F_Logistic'Access, 0.0, 0.1, 5.0, 50);
      Y_Fine   := Integrate_RK4 (F_Logistic'Access, 0.0, 0.1, 5.0, 200);
      Check (Y_Coarse > 0.1, "logistic grew from 0.1");
      Check (Y_Coarse < 1.0 + 1.0E-6, "logistic ≤ 1");
      Check (Y_Coarse > 0.8, "logistic approaching capacity");
      Check (Y_Fine > 0.9, "fine logistic near 1");
      Check (Y_Fine < 1.0 + 1.0E-6, "fine logistic ≤ 1");
      Check (Near (Y_Coarse, Y_Fine, 1.0E-3), "RK4 logistic converged");

      Yr := Integrate_RK4 (F_Logistic'Access, 0.0, 0.25, 1.0, 40);
      Ye := Integrate_Euler (F_Logistic'Access, 0.0, 0.25, 1.0, 40);
      Check (Yr > 0.25, "RK4 logistic short grew");
      Check (Ye > 0.25, "Euler logistic short grew");
      Check (Yr < 1.0, "RK4 logistic short < 1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Invalid_Argument cases");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Step_RK4 (F_Decay'Access, 0.0, 1.0, 0.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "RK4 H=0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Step_RK4 (F_Decay'Access, 0.0, 1.0, -0.1);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "RK4 H<0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Step_Midpoint (F_Decay'Access, 0.0, 1.0, 0.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Midpoint H=0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Step_Heun (F_Decay'Access, 0.0, 1.0, -0.5);
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
         Dummy := Step_Euler (F_Decay'Access, 0.0, 1.0, 0.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Euler H=0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Integrate_RK4 (F_Decay'Access, 1.0, 1.0, 0.0, 10);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Integrate_RK4 T1<T0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Integrate_Midpoint (F_Decay'Access, 0.0, 1.0, 0.0, 5);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Integrate_Midpoint T1=T0 raises");

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
   Check (Raised, "Integrate_Heun T1<T0 raises");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Integrate_Euler (F_Decay'Access, 0.5, 1.0, 0.5, 2);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Integrate_Euler T1=T0 raises");

   ---------------------------------------------------------------------
   Section ("15. Consistency / edge values");
   ---------------------------------------------------------------------
   declare
      Y : Real;
      H : constant Real := 0.01;
   begin
      Y := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, H, 1);
      Check (Near (Y, Step_RK4 (F_Decay'Access, 0.0, 1.0, H), 1.0E-14),
             "Integrate_RK4 N=1 = Step_RK4");

      Y := Integrate_Midpoint (F_Decay'Access, 0.0, 1.0, H, 1);
      Check (Near (Y, Step_Midpoint (F_Decay'Access, 0.0, 1.0, H), 1.0E-14),
             "Integrate_Midpoint N=1 = Step");

      Y := Integrate_Heun (F_Growth'Access, 0.0, 1.0, H, 1);
      Check (Near (Y, Step_Heun (F_Growth'Access, 0.0, 1.0, H), 1.0E-14),
             "Integrate_Heun N=1 = Step");

      Y := Integrate_Euler (F_Decay'Access, 0.0, 1.0, H, 1);
      Check (Near (Y, Step_Euler (F_Decay'Access, 0.0, 1.0, H), 1.0E-14),
             "Integrate_Euler N=1 = Step");

      Y := Integrate_RK4 (F_Growth'Access, 0.0, 1.0, 1.0E-4, 2);
      Check (Near (Y, Exact_Exponential (1.0, 1.0E-4), 1.0E-12),
             "tiny interval RK4 growth");

      Y := Step_RK4 (F_Decay'Access, 3.0, Exact_Exponential (-1.0, 3.0), 0.1);
      Check (Near (Y, Exact_Exponential (-1.0, 3.1), 1.0E-6),
             "RK4 mid-trajectory accuracy");
   end;

   ---------------------------------------------------------------------
   Section ("16. Stiff contrast and extra spot checks");
   ---------------------------------------------------------------------
   declare
      Exact : Real;
      Yr, Ye, Ym, Yh : Real;
   begin
      Exact := Exact_Exponential (-50.0, 0.2);
      --  h = 0.2/40 = 0.005; for Euler stability need h ≤ 2/50 = 0.04.
      Yr := Integrate_RK4 (F_Stiff'Access, 0.0, 1.0, 0.2, 40);
      Ye := Integrate_Euler (F_Stiff'Access, 0.0, 1.0, 0.2, 40);
      Check (Near (Yr, Exact, 1.0E-4), "RK4 stiff short interval");
      Check (Abs_Error (Yr, Exact) < Abs_Error (Ye, Exact),
             "RK4 beats Euler on stiff (stable h)");
      Check (Yr >= 0.0, "RK4 stiff non-negative");

      Exact := Exact_Exponential (-1.0, 0.5);
      Yr := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 0.5, 25);
      Ym := Integrate_Midpoint (F_Decay'Access, 0.0, 1.0, 0.5, 25);
      Yh := Integrate_Heun (F_Decay'Access, 0.0, 1.0, 0.5, 25);
      Check (Near (Yr, Exact, 1.0E-8), "RK4 t=0.5 N=25");
      Check (Near (Ym, Exact, 1.0E-3), "Midpoint t=0.5");
      Check (Near (Yh, Exact, 1.0E-3), "Heun t=0.5");
      Check (Abs_Error (Yr, Exact) < Abs_Error (Ym, Exact),
             "RK4 < Midpoint at t=0.5");

      --  Heun = Midpoint on linear autonomous y'=λy (same N).
      Check (Near
               (Integrate_Heun (F_Growth'Access, 0.0, 1.0, 1.0, 30),
                Integrate_Midpoint (F_Growth'Access, 0.0, 1.0, 1.0, 30),
                1.0E-12),
             "Heun=Midpoint on growth linear");
   end;

   ---------------------------------------------------------------------
   Section ("17. Hand-checked RK4 stages on y'=-y");
   ---------------------------------------------------------------------
   declare
      --  For y'=-y, y0=1, h=0.2:
      --  k1 = -1
      --  k2 = -(1 + 0.1*(-1)) = -0.9
      --  k3 = -(1 + 0.1*(-0.9)) = -0.91
      --  k4 = -(1 + 0.2*(-0.91)) = -0.818
      --  y1 = 1 + (0.2/6)(-1 + 2*(-0.9) + 2*(-0.91) + (-0.818))
      --     = 1 + (0.2/6)(-4.538) = 1 - 0.1512666... ≈ 0.8487333...
      H      : constant Real := 0.2;
      Y_Next : constant Real :=
        Step_RK4 (F_Decay'Access, 0.0, 1.0, H);
      Expected : constant Real :=
        1.0 + (H / 6.0) *
          (-1.0 + 2.0 * (-0.9) + 2.0 * (-0.91) + (-0.818));
   begin
      Check (Near (Y_Next, Expected, 1.0E-12), "RK4 hand stage formula");
      Check (Near (Y_Next, Exact_Exponential (-1.0, H), 1.0E-5),
             "RK4 h=0.2 ≈ e^{-0.2}");
      Check (Y_Next > 0.8 and then Y_Next < 0.9, "RK4 h=0.2 in (0.8,0.9)");
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
