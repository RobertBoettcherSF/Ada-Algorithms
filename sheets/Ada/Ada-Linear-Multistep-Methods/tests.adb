--  Standalone test suite for Linear_Multistep_Methods (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Linear_Multistep_Methods; use Linear_Multistep_Methods;

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

   Newton_Cfg : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, Solver => Newton);
   FP_Cfg : constant Config :=
     (Max_Iterations => 80, Tol => 1.0E-12, Solver => Fixed_Point);

   Raised : Boolean;

begin
   Put_Line ("Linear_Multistep_Methods test suite");
   Put_Line ("===================================");

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
   Section ("2. Exact_Exponential + sample ODEs");
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
   Check (Near (F_Decay (0.0, 1.0), -1.0), "F_Decay(0,1)=-1");
   Check (Near (F_Growth (0.0, 3.0), 3.0), "F_Growth(0,3)=3");
   Check (Near (F_Decay_2 (0.0, 4.0), -8.0), "F_Decay_2");
   Check (Near (F_Stiff (0.0, 1.0), -50.0), "F_Stiff");
   Check (Near (F_Logistic (0.0, 0.5), 0.25), "F_Logistic at 0.5");
   Check (Near (DF_Decay (0.0, 1.0), -1.0), "DF_Decay");
   Check (Near (DF_Growth (0.0, 1.0), 1.0), "DF_Growth");
   Check (Near (DF_Stiff (0.0, 1.0), -50.0), "DF_Stiff");
   Check (Near (DF_Logistic (0.0, 0.5), 0.0), "DF_Logistic at 0.5");

   ---------------------------------------------------------------------
   Section ("3. Taxonomy Order / Explicit / Implicit / Step_Number");
   ---------------------------------------------------------------------
   Check (Is_Explicit (AB2) and Is_Explicit (AB3) and Is_Explicit (AB4),
          "AB family explicit");
   Check (Is_Implicit (AM2_Trapezoid) and Is_Implicit (AM3),
          "AM family implicit");
   Check (Is_Implicit (BDF1) and Is_Implicit (BDF2), "BDF implicit");
   Check (not Is_Explicit (BDF1), "BDF1 not explicit");
   Check (not Is_Implicit (AB2), "AB2 not implicit");
   Check (Order (AB2) = 2, "Order AB2=2");
   Check (Order (AB3) = 3, "Order AB3=3");
   Check (Order (AB4) = 4, "Order AB4=4");
   Check (Order (AM2_Trapezoid) = 2, "Order AM2=2");
   Check (Order (AM3) = 3, "Order AM3=3");
   Check (Order (BDF1) = 1, "Order BDF1=1");
   Check (Order (BDF2) = 2, "Order BDF2=2");
   Check (Step_Number (AB2) = 2, "k AB2=2");
   Check (Step_Number (AB3) = 3, "k AB3=3");
   Check (Step_Number (AB4) = 4, "k AB4=4");
   Check (Step_Number (AM2_Trapezoid) = 1, "k AM2=1");
   Check (Step_Number (AM3) = 2, "k AM3=2");
   Check (Step_Number (BDF1) = 1, "k BDF1=1");
   Check (Step_Number (BDF2) = 2, "k BDF2=2");
   Check (Method_Name (AB2)'Length > 0, "Method_Name AB2 nonempty");
   Check (Method_Name (BDF1)'Length > 0, "Method_Name BDF1 nonempty");

   ---------------------------------------------------------------------
   Section ("4. Coefficient constants");
   ---------------------------------------------------------------------
   Check (Near (AB2_Beta_N + AB2_Beta_Nm1, 1.0), "AB2 β sum = 1");
   Check (Near (AB3_Beta_N + AB3_Beta_Nm1 + AB3_Beta_Nm2, 1.0),
          "AB3 β sum = 1");
   Check (Near (AB4_Beta_N + AB4_Beta_Nm1 + AB4_Beta_Nm2 + AB4_Beta_Nm3,
                1.0),
          "AB4 β sum = 1");
   Check (Near (AM2_Beta_Np1 + AM2_Beta_N, 1.0), "AM2 β sum = 1");
   Check (Near (AM3_Beta_Np1 + AM3_Beta_N + AM3_Beta_Nm1, 1.0),
          "AM3 β sum = 1");
   Check (Near (BDF1_Alpha_Np1 + BDF1_Alpha_N, 0.0), "BDF1 α sum = 0");
   Check (Near (BDF2_Alpha_Np1 + BDF2_Alpha_N + BDF2_Alpha_Nm1, 0.0),
          "BDF2 α sum = 0");

   ---------------------------------------------------------------------
   Section ("5. Adams_Bashforth_2_Step hand values");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.1;
      F_Prev : constant Real := F_Decay (0.0, 1.0);  -- −1 at t=0,y=1
      --  After one Euler step to seed: y1 = 1 − h = 0.9, f0 = −1
      Y1     : constant Real := 0.9;
      T1     : constant Real := H;
      Y2     : Real;
      Exact  : constant Real := Exact_Exponential (-1.0, 2.0 * H);
   begin
      --  AB2 from (t1,y1) with F_Prev=f0: f1=−0.9
      --  y2 = 0.9 + h(1.5*(−0.9) − 0.5*(−1)) = 0.9 + 0.1(−1.35+0.5)
      --      = 0.9 − 0.085 = 0.815
      Y2 := Adams_Bashforth_2_Step
        (F_Decay'Access, T1, Y1, F_Prev, H);
      Check (Near (Y2, 0.815), "AB2 decay hand value");
      Check (Near (Y2, Exact, 5.0E-3), "AB2 one-step ≈ e^{-0.2}");
      Check (Near (Adams_Bashforth_2_Step
                     (F_Growth'Access, 0.1, 1.1, 1.0, H),
                   1.1 + H * (1.5 * 1.1 - 0.5 * 1.0)),
             "AB2 growth formula");
   end;

   ---------------------------------------------------------------------
   Section ("6. Adams_Bashforth_3 / AB4 history lengths");
   ---------------------------------------------------------------------
   declare
      H    : constant Real := 0.05;
      Hist : History (1 .. 2);
      Y    : Real;
   begin
      --  Exact history on y'=-y, y(0)=1 at t=0.10 with prev f at 0.05,0.00
      Hist := [F_Decay (0.05, Exact_Exponential (-1.0, 0.05)),
               F_Decay (0.0, 1.0)];
      Y := Adams_Bashforth_3_Step
        (F_Decay'Access, 0.10, Exact_Exponential (-1.0, 0.10), Hist, H);
      Check (Near (Y, Exact_Exponential (-1.0, 0.15), 1.0E-4),
             "AB3 from exact history ≈ e^{-0.15}");
   end;
   declare
      H    : constant Real := 0.05;
      Hist : History (1 .. 3);
      Y    : Real;
   begin
      Hist :=
        [F_Decay (0.10, Exact_Exponential (-1.0, 0.10)),
         F_Decay (0.05, Exact_Exponential (-1.0, 0.05)),
         F_Decay (0.0, 1.0)];
      Y := Adams_Bashforth_4_Step
        (F_Decay'Access, 0.15, Exact_Exponential (-1.0, 0.15), Hist, H);
      Check (Near (Y, Exact_Exponential (-1.0, 0.20), 1.0E-5),
             "AB4 from exact history ≈ e^{-0.20}");
   end;
   --  Full-length history overload (incl. f_n)
   declare
      H    : constant Real := 0.1;
      Hist : History (1 .. 3);
      Y    : Real;
      F_N  : constant Real := F_Decay (0.2, Exact_Exponential (-1.0, 0.2));
   begin
      Hist :=
        [F_N,
         F_Decay (0.1, Exact_Exponential (-1.0, 0.1)),
         F_Decay (0.0, 1.0)];
      Y := Adams_Bashforth_3_Step
        (F_Decay'Access, 0.2, Exact_Exponential (-1.0, 0.2), Hist, H);
      Check (Near (Y, Exact_Exponential (-1.0, 0.3), 5.0E-4),
             "AB3 length-3 history path");
   end;

   ---------------------------------------------------------------------
   Section ("7. Advance_AB2/3/4 convergence on y'=-y");
   ---------------------------------------------------------------------
   declare
      Exact              : constant Real := Exact_Exponential (-1.0, 1.0);
      Y_C, Y_F           : Real;
      Err_C, Err_F       : Real;
   begin
      Y_C   := Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 20);
      Y_F   := Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 80);
      Err_C := Abs_Error (Y_C, Exact);
      Err_F := Abs_Error (Y_F, Exact);
      Check (Near (Y_F, Exact, 5.0E-4), "AB2 N=80 ≈ e^{-1}");
      Check (Err_F < Err_C, "AB2 refine h → smaller error");
      Check (Y_F > 0.0, "AB2 decay stays positive");

      Y_C   := Advance_AB3 (F_Decay'Access, 0.0, 1.0, 1.0, 30);
      Y_F   := Advance_AB3 (F_Decay'Access, 0.0, 1.0, 1.0, 120);
      Err_C := Abs_Error (Y_C, Exact);
      Err_F := Abs_Error (Y_F, Exact);
      Check (Near (Y_F, Exact, 1.0E-4), "AB3 N=120 ≈ e^{-1}");
      Check (Err_F < Err_C, "AB3 refine h → smaller error");

      Y_C   := Advance_AB4 (F_Decay'Access, 0.0, 1.0, 1.0, 40);
      Y_F   := Advance_AB4 (F_Decay'Access, 0.0, 1.0, 1.0, 160);
      Err_C := Abs_Error (Y_C, Exact);
      Err_F := Abs_Error (Y_F, Exact);
      Check (Near (Y_F, Exact, 5.0E-5), "AB4 N=160 ≈ e^{-1}");
      Check (Err_F < Err_C, "AB4 refine h → smaller error");
   end;

   ---------------------------------------------------------------------
   Section ("8. Advance_AB growth y'=y → e");
   ---------------------------------------------------------------------
   declare
      Exact : constant Real := Exact_Exponential (1.0, 1.0);
      Y2, Y3, Y4 : Real;
   begin
      Y2 := Advance_AB2 (F_Growth'Access, 0.0, 1.0, 1.0, 100);
      Y3 := Advance_AB3 (F_Growth'Access, 0.0, 1.0, 1.0, 100);
      Y4 := Advance_AB4 (F_Growth'Access, 0.0, 1.0, 1.0, 100);
      Check (Near (Y2, Exact, 5.0E-3), "AB2 growth ≈ e");
      Check (Near (Y3, Exact, 1.0E-3), "AB3 growth ≈ e");
      Check (Near (Y4, Exact, 5.0E-4), "AB4 growth ≈ e");
      Check (Abs_Error (Y4, Exact) < Abs_Error (Y2, Exact),
             "AB4 error < AB2 error (same N)");
   end;

   ---------------------------------------------------------------------
   Section ("9. AM2 trapezoid step + Advance");
   ---------------------------------------------------------------------
   declare
      H     : constant Real := 0.1;
      Y     : Real;
      Exact : constant Real := Exact_Exponential (-1.0, H);
   begin
      Y := Adams_Moulton_2_Step
        (F_Decay'Access, 0.0, 1.0, H, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y, Exact, 1.0E-4), "AM2 Newton one-step ≈ e^{-h}");
      --  Closed form for linear: R(z)=(1+z/2)/(1-z/2), z=-h
      declare
         Z : constant Real := -H;
         R : constant Real := (1.0 + Z / 2.0) / (1.0 - Z / 2.0);
      begin
         Check (Near (Y, R), "AM2 matches R(z) amplification");
      end;
      Y := Adams_Moulton_2_Step
        (F_Decay'Access, 0.0, 1.0, H, FP_Cfg, null);
      Check (Near (Y, Exact, 1.0E-4), "AM2 fixed-point ≈ e^{-h}");
   end;
   declare
      Exact        : constant Real := Exact_Exponential (-1.0, 1.0);
      Y_C, Y_F     : Real;
      Err_C, Err_F : Real;
   begin
      Y_C   := Advance_AM2
        (F_Decay'Access, 0.0, 1.0, 1.0, 20, Newton_Cfg, DF_Decay'Access);
      Y_F   := Advance_AM2
        (F_Decay'Access, 0.0, 1.0, 1.0, 80, Newton_Cfg, DF_Decay'Access);
      Err_C := Abs_Error (Y_C, Exact);
      Err_F := Abs_Error (Y_F, Exact);
      Check (Near (Y_F, Exact, 1.0E-4), "AM2 N=80 ≈ e^{-1}");
      Check (Err_F < Err_C, "AM2 refine h → smaller error");
   end;

   ---------------------------------------------------------------------
   Section ("10. AM3 + BDF1 + BDF2");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.1;
      F_Prev : constant Real := F_Decay (0.0, 1.0);
      Y1     : constant Real := Exact_Exponential (-1.0, H);
      Y2     : Real;
   begin
      Y2 := Adams_Moulton_3_Step
        (F_Decay'Access, H, Y1, F_Prev, H, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y2, Exact_Exponential (-1.0, 2.0 * H), 1.0E-4),
             "AM3 one-step from exact seed");
   end;
   declare
      Exact : constant Real := Exact_Exponential (-1.0, 1.0);
      Y     : Real;
   begin
      Y := Advance_AM3
        (F_Decay'Access, 0.0, 1.0, 1.0, 50, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y, Exact, 1.0E-4), "Advance_AM3 N=50 ≈ e^{-1}");
   end;
   declare
      H     : constant Real := 0.1;
      Y     : Real;
      Exact : constant Real := Exact_Exponential (-1.0, H);
      --  BDF1 on y'=-y: y_new = y / (1+h)
   begin
      Y := BDF1_Step
        (F_Decay'Access, 0.0, 1.0, H, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y, 1.0 / (1.0 + H)), "BDF1 closed form 1/(1+h)");
      Check (Near (Y, Exact, 5.0E-3), "BDF1 ≈ e^{-h}");
   end;
   declare
      Exact        : constant Real := Exact_Exponential (-1.0, 1.0);
      Y_C, Y_F     : Real;
      Err_C, Err_F : Real;
   begin
      Y_C   := Advance_BDF1
        (F_Decay'Access, 0.0, 1.0, 1.0, 20, Newton_Cfg, DF_Decay'Access);
      Y_F   := Advance_BDF1
        (F_Decay'Access, 0.0, 1.0, 1.0, 80, Newton_Cfg, DF_Decay'Access);
      Err_C := Abs_Error (Y_C, Exact);
      Err_F := Abs_Error (Y_F, Exact);
      Check (Near (Y_F, Exact, 5.0E-3), "BDF1 N=80 ≈ e^{-1}");
      Check (Err_F < Err_C, "BDF1 refine h → smaller error");
   end;
   declare
      Exact : constant Real := Exact_Exponential (-1.0, 1.0);
      Y     : Real;
   begin
      Y := Advance_BDF2
        (F_Decay'Access, 0.0, 1.0, 1.0, 40, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y, Exact, 1.0E-3), "Advance_BDF2 N=40 ≈ e^{-1}");
   end;

   ---------------------------------------------------------------------
   Section ("11. Stiff-ish −λy with moderate λ (AM2 / BDF)");
   ---------------------------------------------------------------------
   declare
      --  y' = −50 y, y(0)=1 → e^{-50} at t=1 is tiny; use t=0.2
      T_End : constant Real := 0.2;
      Exact : constant Real := Exact_Exponential (-50.0, T_End);
      Y_AM, Y_B1, Y_B2 : Real;
   begin
      Y_AM := Advance_AM2
        (F_Stiff'Access, 0.0, 1.0, T_End, 40, Newton_Cfg, DF_Stiff'Access);
      Y_B1 := Advance_BDF1
        (F_Stiff'Access, 0.0, 1.0, T_End, 40, Newton_Cfg, DF_Stiff'Access);
      Y_B2 := Advance_BDF2
        (F_Stiff'Access, 0.0, 1.0, T_End, 40, Newton_Cfg, DF_Stiff'Access);
      Check (Near (Y_AM, Exact, 5.0E-3), "AM2 stiff λ=−50 at t=0.2");
      Check (Near (Y_B1, Exact, 5.0E-2), "BDF1 stiff λ=−50 at t=0.2");
      Check (Near (Y_B2, Exact, 1.0E-2), "BDF2 stiff λ=−50 at t=0.2");
      Check (Y_AM > 0.0 and Y_B1 > 0.0 and Y_B2 > 0.0,
             "stiff advances stay positive");
   end;

   ---------------------------------------------------------------------
   Section ("12. Logistic nonlinear");
   ---------------------------------------------------------------------
   declare
      --  y' = y(1−y), y(0)=0.1; exact y(t)=1/(1+9 e^{-t})
      function Exact_Log (T : Real) return Real is
      begin
         return 1.0 / (1.0 + 9.0 * Exact_Exponential (-1.0, T) / 1.0);
         --  Exact_Exponential(-1,T)=e^{-T};  y= y0 e^{t}/(1-y0+y0 e^{t})
         --  with y0=0.1: y = 0.1 e^t / (0.9 + 0.1 e^t) = 1/(1+9 e^{-t})
      end Exact_Log;
      Y_AB, Y_AM, Exact : Real;
   begin
      Exact := Exact_Log (2.0);
      Y_AB  := Advance_AB2 (F_Logistic'Access, 0.0, 0.1, 2.0, 80);
      Y_AM  := Advance_AM2
        (F_Logistic'Access, 0.0, 0.1, 2.0, 80, Newton_Cfg,
         DF_Logistic'Access);
      Check (Near (Y_AB, Exact, 5.0E-3), "AB2 logistic t=2");
      Check (Near (Y_AM, Exact, 1.0E-3), "AM2 logistic t=2");
      Check (Y_AB > 0.1 and Y_AB < 1.0, "logistic AB2 in (0.1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("13. Zero-stability / root condition");
   ---------------------------------------------------------------------
   Check (Characteristic_Polynomial_Roots_OK (AB2), "AB2 root condition");
   Check (Characteristic_Polynomial_Roots_OK (BDF2), "BDF2 root condition");
   Check (Characteristic_Polynomial_Roots_OK (AM2_Trapezoid),
          "AM2 root condition");
   Check (Characteristic_Polynomial_Roots_OK (BDF1), "BDF1 root condition");
   Check (Characteristic_Polynomial_Roots_OK (AB3), "AB3 root condition");
   Check (Characteristic_Polynomial_Roots_OK (AB4), "AB4 root condition");
   Check (Characteristic_Polynomial_Roots_OK (AM3), "AM3 root condition");

   ---------------------------------------------------------------------
   Section ("14. Invalid_Argument guards");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Adams_Bashforth_2_Step
           (F_Decay'Access, 0.0, 1.0, -1.0, 0.0);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "AB2 rejects H=0");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Adams_Bashforth_2_Step
           (F_Decay'Access, 0.0, 1.0, -1.0, -0.1);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "AB2 rejects H<0");

   Raised := False;
   begin
      declare
         Dummy : Real;
         Bad   : constant History (1 .. 1) := [1 => 0.0];
      begin
         Dummy := Adams_Bashforth_3_Step
           (F_Decay'Access, 0.0, 1.0, Bad, 0.1);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "AB3 rejects inconsistent history length");

   Raised := False;
   begin
      declare
         Dummy : Real;
         Bad   : constant History (1 .. 2) := [0.0, 0.0];
      begin
         Dummy := Adams_Bashforth_4_Step
           (F_Decay'Access, 0.0, 1.0, Bad, 0.1);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "AB4 rejects inconsistent history length");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 1);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Advance_AB2 rejects N<2");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Advance_AB3 (F_Decay'Access, 1.0, 1.0, 0.0, 10);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Advance rejects T1≤T0");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := BDF1_Step
           (F_Decay'Access, 0.0, 1.0, 0.0, Newton_Cfg, DF_Decay'Access);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "BDF1 rejects H=0");

   Raised := False;
   begin
      declare
         Dummy : Real;
      begin
         Dummy := Adams_Moulton_2_Step
           (null, 0.0, 1.0, 0.1, Newton_Cfg, null);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
      when others =>
         Raised := True;  -- Pre => F /= null may raise Assert_Failure
   end;
   Check (Raised, "AM2 rejects null F");

   ---------------------------------------------------------------------
   Section ("15. Order-ish error ratios (refine h)");
   ---------------------------------------------------------------------
   declare
      Exact : constant Real := Exact_Exponential (-1.0, 1.0);
      E20, E40, E80 : Real;
      R_AB2, R_AB3  : Real;
   begin
      E20 := Abs_Error
        (Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 20), Exact);
      E40 := Abs_Error
        (Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 40), Exact);
      E80 := Abs_Error
        (Advance_AB2 (F_Decay'Access, 0.0, 1.0, 1.0, 80), Exact);
      Check (E40 < E20 and E80 < E40, "AB2 monotone error drop");
      if E40 > 0.0 then
         R_AB2 := E20 / E40;
      else
         R_AB2 := 4.0;
      end if;
      --  Order 2 ⇒ halving h ≈ 4× smaller error (roughly)
      Check (R_AB2 > 2.5, "AB2 error ratio roughly order 2");

      E20 := Abs_Error
        (Advance_AB3 (F_Decay'Access, 0.0, 1.0, 1.0, 30), Exact);
      E40 := Abs_Error
        (Advance_AB3 (F_Decay'Access, 0.0, 1.0, 1.0, 60), Exact);
      if E40 > 0.0 then
         R_AB3 := E20 / E40;
      else
         R_AB3 := 8.0;
      end if;
      Check (R_AB3 > 4.0, "AB3 error ratio roughly order 3");
      Check (E80 < 1.0E-2, "AB2 fine error under 1e-2");
   end;

   ---------------------------------------------------------------------
   Section ("16. BDF2 single step + growth AM2");
   ---------------------------------------------------------------------
   declare
      H      : constant Real := 0.05;
      Y0     : constant Real := 1.0;
      Y1     : constant Real := Exact_Exponential (-1.0, H);
      Y2     : Real;
      Exact2 : constant Real := Exact_Exponential (-1.0, 2.0 * H);
   begin
      --  Exact Y1 seed isolates BDF2 local accuracy (order 2).
      Y2 := BDF2_Step
        (F_Decay'Access, H, Y1, Y0, H, Newton_Cfg, DF_Decay'Access);
      Check (Near (Y2, Exact2, 1.0E-4), "BDF2 with exact seed");
      --  Also exercise BDF1→BDF2 chain coarsely.
      declare
         Y1b, Y2b : Real;
      begin
         Y1b := BDF1_Step
           (F_Decay'Access, 0.0, Y0, H, Newton_Cfg, DF_Decay'Access);
         Y2b := BDF2_Step
           (F_Decay'Access, H, Y1b, Y0, H, Newton_Cfg, DF_Decay'Access);
         Check (Near (Y2b, Exact2, 2.0E-3), "BDF2 after BDF1 seed");
      end;
   end;
   declare
      Exact : constant Real := Exact_Exponential (1.0, 0.5);
      Y     : Real;
   begin
      Y := Advance_AM2
        (F_Growth'Access, 0.0, 1.0, 0.5, 40, Newton_Cfg, DF_Growth'Access);
      Check (Near (Y, Exact, 1.0E-4), "AM2 growth to t=0.5");
   end;
   declare
      Exact : constant Real := Exact_Exponential (-2.0, 0.5);
      Y     : Real;
   begin
      Y := Advance_BDF2
        (F_Decay_2'Access, 0.0, 1.0, 0.5, 40, Newton_Cfg, DF_Decay_2'Access);
      Check (Near (Y, Exact, 5.0E-3), "BDF2 on λ=−2");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("===================================");
   Put_Line
     ("Result:"
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
