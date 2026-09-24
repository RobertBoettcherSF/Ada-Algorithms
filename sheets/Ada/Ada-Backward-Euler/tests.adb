--  Standalone test suite for Backward_Euler (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Backward_Euler; use Backward_Euler;

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

   Newton_Decay : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Decay'Access);
   Newton_Stiff : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Stiff'Access);
   Newton_Growth : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Growth'Access);
   Newton_Decay_2 : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Decay_2'Access);
   Newton_Logistic : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Logistic'Access);
   Newton_Square : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Square'Access);
   FP_Cfg : constant Config :=
     (Max_Iterations => 80, Tol => 1.0E-12, DF_DY => null);

   Raised : Boolean;
   Dummy  : Real;

begin
   Put_Line ("Backward_Euler test suite");
   Put_Line ("=========================");

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
   Check (Near (Exact_Exponential (-50.0, 0.0), 1.0), "stiff exact at t=0");

   ---------------------------------------------------------------------
   Section ("3. Amplification R(z)=1/(1−z)");
   ---------------------------------------------------------------------
   Check (Near (Amplification (0.0), 1.0), "R(0)=1");
   Check (Near (Amplification (-1.0), 0.5), "R(-1)=1/2");
   Check (Near (Amplification (-2.0), 1.0 / 3.0), "R(-2)=1/3");
   Check (Near (Amplification (0.5), 2.0), "R(0.5)=2");
   Check (Near (Amplification (-0.5), 1.0 / 1.5), "R(-0.5)=2/3");
   Check (Near (Amplification (-9.0), 0.1), "R(-9)=0.1");
   Check (Near (Amplification (-99.0), 0.01), "R(-99)=0.01");
   --  Singularity at Z=1
   Raised := False;
   begin
      Dummy := Amplification (1.0);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Amplification rejects Z=1 pole");

   ---------------------------------------------------------------------
   Section ("4. A-stability / Amplification_Bounded / L-stability");
   ---------------------------------------------------------------------
   --  Samples with Re(z) ≤ 0 (here real z ≤ 0): |R| ≤ 1.
   Check (Amplification_Bounded (0.0), "bounded at 0");
   Check (Amplification_Bounded (-0.1), "bounded at -0.1");
   Check (Amplification_Bounded (-1.0), "bounded at -1");
   Check (Amplification_Bounded (-2.0), "bounded at -2");
   Check (Amplification_Bounded (-10.0), "bounded at -10");
   Check (Amplification_Bounded (-50.0), "bounded at -50");
   Check (Amplification_Bounded (-100.0), "bounded at -100");
   Check (abs (Amplification (-0.5)) <= 1.0, "|R(-0.5)| ≤ 1");
   Check (abs (Amplification (-5.0)) <= 1.0, "|R(-5)| ≤ 1");
   Check (abs (Amplification (-50.0)) <= 1.0, "|R(-50)| ≤ 1");
   --  Outside left half-plane can exceed 1 (e.g. z=0.5 → R=2).
   Check (not Amplification_Bounded (0.5), "R(0.5)=2 not bounded");
   Check (not Amplification_Bounded (1.0), "pole not bounded");
   --  L-stable: R → 0 as |z| → ∞ on negative real axis.
   Check (abs (Amplification (-1.0E3)) < 1.0E-2, "L-stable R(-1e3) tiny");
   Check (abs (Amplification (-1.0E6)) < 1.0E-5, "L-stable R(-1e6) → 0");
   Check (Near (Amplification (-1.0E6), 0.0, 1.0E-5),
          "L-stable Near R(−∞)≈0");

   ---------------------------------------------------------------------
   Section ("5. Forward Euler contrast helpers");
   ---------------------------------------------------------------------
   Check (Near (Forward_Euler_Amplification (0.0), 1.0), "FE R(0)=1");
   Check (Near (Forward_Euler_Amplification (-1.0), 0.0), "FE R(-1)=0");
   Check (Near (Forward_Euler_Amplification (-2.0), -1.0), "FE R(-2)=-1");
   Check (abs (Forward_Euler_Amplification (-5.0)) > 1.0,
          "FE |R(-5)|=4 > 1 unstable");
   Check (abs (Forward_Euler_Amplification (-50.0 * 0.1)) > 1.0,
          "FE stiff h=0.1 outside disk");
   Check (Near (Forward_Euler_Step (F_Decay'Access, 0.0, 1.0, 0.1), 0.9),
          "FE step decay = 1−h");

   ---------------------------------------------------------------------
   Section ("6. Sample ODE evaluations");
   ---------------------------------------------------------------------
   Check (Near (F_Decay (0.0, 1.0), -1.0), "F_Decay(0,1)=-1");
   Check (Near (DF_Decay (0.0, 1.0), -1.0), "DF_Decay=-1");
   Check (Near (F_Growth (0.0, 3.0), 3.0), "F_Growth");
   Check (Near (DF_Growth (0.0, 3.0), 1.0), "DF_Growth");
   Check (Near (F_Decay_2 (0.0, 4.0), -8.0), "F_Decay_2");
   Check (Near (DF_Decay_2 (0.0, 4.0), -2.0), "DF_Decay_2");
   Check (Near (F_Stiff (0.0, 1.0), -50.0), "F_Stiff");
   Check (Near (DF_Stiff (0.0, 1.0), -50.0), "DF_Stiff");
   Check (Near (F_Logistic (0.0, 0.5), 0.25), "F_Logistic at 0.5");
   Check (Near (DF_Logistic (0.0, 0.5), 0.0), "DF_Logistic at 0.5");
   Check (Near (F_Square (0.0, 2.0), 4.0), "F_Square");
   Check (Near (DF_Square (0.0, 2.0), 4.0), "DF_Square");

   ---------------------------------------------------------------------
   Section ("7. Step: decay y'=-y (closed form 1/(1+h))");
   ---------------------------------------------------------------------
   declare
      H          : constant Real := 0.1;
      Y_Next     : Real;
      Exact_Next : constant Real := Exact_Exponential (-1.0, H);
      Closed     : constant Real := 1.0 / (1.0 + H);
   begin
      Y_Next := Step (F_Decay'Access, 0.0, 1.0, H, Newton_Decay);
      Check (Near (Y_Next, Closed), "Newton decay step = 1/(1+h)");
      Check (Near (Y_Next, Amplification (H * (-1.0))),
             "decay step = R(hλ)");
      Check (Near (Y_Next, Exact_Next, 1.0E-2),
             "decay step ≈ e^{-h}");
      Check (Y_Next > 0.0, "decay step positive");

      Y_Next := Step (F_Decay'Access, 0.0, 1.0, H, FP_Cfg);
      Check (Near (Y_Next, Closed, 1.0E-10),
             "fixed-point decay step = 1/(1+h)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Step: growth y'=y");
   ---------------------------------------------------------------------
   declare
      H          : constant Real := 0.05;
      Y_Next     : Real;
      Exact_Next : constant Real := Exact_Exponential (1.0, H);
      Closed     : constant Real := 1.0 / (1.0 - H);
   begin
      Y_Next := Step (F_Growth'Access, 0.0, 1.0, H, Newton_Growth);
      Check (Near (Y_Next, Closed), "growth step = 1/(1−h)");
      Check (Near (Y_Next, Amplification (H)), "growth = R(h)");
      Check (Near (Y_Next, Exact_Next, 5.0E-3), "growth step ≈ e^{h}");
   end;

   ---------------------------------------------------------------------
   Section ("9. Integrate decay [0,1]: O(h) refinement");
   ---------------------------------------------------------------------
   declare
      Y_Coarse, Y_Fine, Exact : Real;
      Err_C, Err_F            : Real;
   begin
      Exact    := Exact_Exponential (-1.0, 1.0);
      Y_Coarse := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 10, Newton_Decay);
      Y_Fine   := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 100, Newton_Decay);
      Err_C    := Abs_Error (Y_Coarse, Exact);
      Err_F    := Abs_Error (Y_Fine, Exact);
      Check (Near (Y_Coarse, Exact, 5.0E-2), "N=10 decay ≈ e^{-1}");
      Check (Near (Y_Fine, Exact, 5.0E-3), "N=100 decay ≈ e^{-1}");
      Check (Err_F < Err_C, "refine h → smaller global error");
      Check (Err_F < 1.0E-2, "fine Abs_Error < 1e-2");
      --  First-order: Err_C / Err_F roughly ~ 10 when N×10
      Check (Err_C / Err_F > 5.0, "roughly O(h) ratio > 5");
      Check (Y_Fine > 0.0, "decay stays positive");
   end;

   ---------------------------------------------------------------------
   Section ("10. Integrate growth and λ=-2");
   ---------------------------------------------------------------------
   declare
      Yg, Exact_G, Y2, Exact2 : Real;
   begin
      Exact_G := Exact_Exponential (1.0, 1.0);
      Yg := Integrate
        (F_Growth'Access, 0.0, 1.0, 1.0, 100, Newton_Growth);
      Check (Near (Yg, Exact_G, 2.0E-2), "growth N=100 ≈ e");
      Check (Yg > 2.0, "growth exceeds 2");

      Exact2 := Exact_Exponential (-2.0, 1.0);
      Y2 := Integrate
        (F_Decay_2'Access, 0.0, 1.0, 1.0, 80, Newton_Decay_2);
      Check (Near (Y2, Exact2, 2.0E-2), "λ=-2 integrate");
   end;

   ---------------------------------------------------------------------
   Section ("11. Stiff y'=-50y: BE stable for large h");
   ---------------------------------------------------------------------
   declare
      H_Large     : constant Real := 0.1;  -- FE unstable: |1−5|=4
      T_End       : constant Real := 1.0;
      Y_BE, Exact : Real;
      Y_FE        : Real;
      R_BE, R_FE  : Real;
   begin
      Exact := Exact_Exponential (-50.0, T_End);
      R_BE  := Amplification (H_Large * (-50.0));
      R_FE  := Forward_Euler_Amplification (H_Large * (-50.0));
      Check (abs (R_BE) <= 1.0, "BE |R(-5)| ≤ 1 for h=0.1");
      Check (abs (R_FE) > 1.0, "FE |R(-5)| > 1 for h=0.1");

      Y_BE := Integrate
        (F_Stiff'Access, 0.0, 1.0, T_End, 10, Newton_Stiff);
      --  N=10 ⇒ h=0.1; solution should decay, stay bounded
      Check (abs (Y_BE) < 1.0, "BE stiff |Y|<1 at t=1");
      Check (Y_BE >= 0.0, "BE stiff non-negative");
      Check (Near (Y_BE, Exact, 0.15) or else Y_BE < 0.05,
             "BE stiff near exact or tiny");

      Y_FE := Forward_Euler_Integrate
        (F_Stiff'Access, 0.0, 1.0, 0.5, 5);
      --  FE with h=0.1 on stiff: blows up / oscillates
      Check (abs (Y_FE) > 1.0,
             "FE stiff with large h grows/oscillates");
      Check (abs (Y_FE) > abs (Y_BE),
             "FE |Y| >> BE |Y| in stiff regime");
   end;

   ---------------------------------------------------------------------
   Section ("12. Nonlinear logistic with Newton");
   ---------------------------------------------------------------------
   declare
      Y0    : constant Real := 0.1;
      T_End : constant Real := 2.0;
      --  Exact logistic: y(t) = Y0 e^{t} / (1 + Y0 (e^{t} − 1))
      Exact, Y_Num : Real;
      E_T : Real;
   begin
      E_T   := Exact_Exponential (1.0, T_End);
      Exact := (Y0 * E_T) / (1.0 + Y0 * (E_T - 1.0));
      Y_Num := Integrate
        (F_Logistic'Access, 0.0, Y0, T_End, 80, Newton_Logistic);
      Check (Near (Y_Num, Exact, 2.0E-2), "logistic Newton ≈ exact");
      Check (Y_Num > Y0, "logistic grows from 0.1");
      Check (Y_Num < 1.0, "logistic stays below K=1");
   end;

   ---------------------------------------------------------------------
   Section ("13. Nonlinear y'=y² with Newton");
   ---------------------------------------------------------------------
   declare
      Y0    : constant Real := 0.5;
      T_End : constant Real := 0.5;  -- exact = 0.5/(1-0.25)=2/3
      Exact : constant Real := Y0 / (1.0 - Y0 * T_End);
      Y_Num : Real;
   begin
      Y_Num := Integrate
        (F_Square'Access, 0.0, Y0, T_End, 40, Newton_Square);
      Check (Near (Y_Num, Exact, 2.0E-2), "y'=y² Newton ≈ exact");
      Check (Y_Num > Y0, "y² grows");
      --  One step check
      declare
         H : constant Real := 0.01;
         Ys : Real;
      begin
         Ys := Step (F_Square'Access, 0.0, Y0, H, Newton_Square);
         Check (Ys > Y0, "square one-step increases");
         Check (Near (Ys, Y0 + H * (Ys * Ys), 1.0E-8),
                "square satisfies residual");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Fixed-point on mild problems");
   ---------------------------------------------------------------------
   declare
      Y_FP, Y_N : Real;
   begin
      Y_FP := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 40, FP_Cfg);
      Y_N := Integrate
        (F_Decay'Access, 0.0, 1.0, 1.0, 40, Newton_Decay);
      Check (Near (Y_FP, Y_N, 1.0E-8), "FP ≈ Newton on decay");
      Check (Near (Y_FP, Exact_Exponential (-1.0, 1.0), 2.0E-2),
             "FP decay ≈ e^{-1}");
   end;

   ---------------------------------------------------------------------
   Section ("15. Invalid_Argument edges");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      Dummy := Step (null, 0.0, 1.0, 0.1, Newton_Decay);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Step rejects null F");

   Raised := False;
   begin
      Dummy := Step (F_Decay'Access, 0.0, 1.0, 0.0, Newton_Decay);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Step rejects H=0");

   Raised := False;
   begin
      Dummy := Step (F_Decay'Access, 0.0, 1.0, -0.1, Newton_Decay);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Step rejects H<0");

   Raised := False;
   begin
      Dummy := Integrate
        (F_Decay'Access, 0.0, 1.0, 0.0, 10, Newton_Decay);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Integrate rejects T1≤T0");

   Raised := False;
   begin
      Dummy := Integrate (null, 0.0, 1.0, 1.0, 10, Newton_Decay);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Integrate rejects null F");

   Raised := False;
   begin
      Dummy := Forward_Euler_Step (null, 0.0, 1.0, 0.1);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "FE Step rejects null F");

   Raised := False;
   begin
      Dummy := Forward_Euler_Step (F_Decay'Access, 0.0, 1.0, -1.0);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "FE Step rejects H<0");

   Raised := False;
   begin
      Dummy := Forward_Euler_Integrate
        (F_Decay'Access, 1.0, 1.0, 0.0, 5);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "FE Integrate rejects T1≤T0");

   --  Non-convergence: tiny Max_Iterations on stiff with fixed-point
   Raised := False;
   declare
      Tight : constant Config :=
        (Max_Iterations => 1, Tol => 1.0E-30, DF_DY => null);
   begin
      Dummy := Step (F_Stiff'Access, 0.0, 1.0, 0.5, Tight);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "non-convergence raises Invalid_Argument");

   ---------------------------------------------------------------------
   Section ("16. Multi-sample Amplification Re z ≤ 0");
   ---------------------------------------------------------------------
   declare
      Samples : constant array (1 .. 8) of Real :=
        [0.0, -0.01, -0.25, -1.0, -2.0, -8.0, -20.0, -200.0];
   begin
      for Z of Samples loop
         Check (Amplification_Bounded (Z),
                "A-stable sample |R|≤1");
         Check (abs (Amplification (Z)) <= 1.0 + 1.0E-14,
                "direct |R|≤1");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("17. Closed-form multi-step identity");
   ---------------------------------------------------------------------
   declare
      H     : constant Real := 0.25;
      Y     : Real := 1.0;
      Pred  : Real;
   begin
      --  After k steps on y'=-y: y = 1/(1+h)^k
      for K in 1 .. 4 loop
         Y := Step (F_Decay'Access, Real (K - 1) * H, Y, H, Newton_Decay);
         Pred := 1.0;
         for J in 1 .. K loop
            Pred := Pred / (1.0 + H);
         end loop;
         Check (Near (Y, Pred), "multi-step closed form");
      end loop;
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
