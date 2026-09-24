--  Standalone test suite for Gauss_Newton (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Gauss_Newton; use Gauss_Newton;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Default_Cfg : constant Config :=
     (Max_Iterations  => 200,
      Step_Tol        => 1.0E-10,
      Cost_Tol        => 1.0E-12,
      Fd_Eps          => 1.0E-7,
      Use_Line_Search => True,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 20);

begin
   Put_Line ("Gauss_Newton test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Near / Params_Near / Residuals_Near / vector helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Parameter_Vector (1 .. 2) := [1.0, 2.0];
      B : constant Parameter_Vector (1 .. 2) := [1.0, 2.0];
      C : constant Parameter_Vector (1 .. 2) := [1.0, 3.0];
      D : constant Parameter_Vector (1 .. 3) := [3.0, 4.0, 0.0];
      Z : constant Parameter_Vector (1 .. 2) := [0.0, 0.0];
      S : Parameter_Vector (1 .. 2);
      R1 : constant Residual_Vector (1 .. 3) := [1.0, 2.0, 3.0];
      R2 : constant Residual_Vector (1 .. 3) := [1.0, 2.0, 3.0];
      R3 : constant Residual_Vector (1 .. 3) := [1.0, 2.0, 4.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Params_Near (A, B), "Params_Near equal");
      Check (not Params_Near (A, C), "Params_Near rejects");
      Check (Params_Near (A, C, 1.5), "Params_Near loose Tol");
      Check (Residuals_Near (R1, R2), "Residuals_Near equal");
      Check (not Residuals_Near (R1, R3), "Residuals_Near rejects");
      Check (Approx (Real (Norm2 (D)), 5.0, 1.0E-12), "Norm2(3,4,0)=5");
      Check (Approx (Real (Norm2 (Z)), 0.0), "Norm2 zero");
      Check (Approx (Dot (A, C), 1.0 * 1.0 + 2.0 * 3.0), "Dot product");
      S := Add (A, C);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 5.0), "Add");
      S := Sub (C, A);
      Check (Approx (S (1), 0.0) and then Approx (S (2), 1.0), "Sub");
      S := Scale (2.0, A);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 4.0), "Scale");
      Check (Approx (Residual_Dot (R1, R2), 14.0), "Residual_Dot");
      Check (Approx (Real (Residual_Norm2 (R1)),
                     3.741_657_386_773_941, 1.0E-9),
             "Residual_Norm2");
      Check (Approx (Real (Cost (R1)), 0.5 * 14.0, 1.0E-12),
             "Cost = 1/2 ||r||^2");
      Check (Approx (Real (Cost ([0.0, 0.0])), 0.0), "Cost zero");
   end;

   ---------------------------------------------------------------------
   Section ("2. JTJ / JTr / Mat_Vec / Solve_SPD");
   ---------------------------------------------------------------------
   declare
      --  J = [[1, 0], [0, 2], [1, 1]]  →  JTJ = [[2,1],[1,5]]
      J : constant Jacobian (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [1.0, 1.0]];
      A : Square_Matrix (1 .. 2, 1 .. 2);
      G : Parameter_Vector (1 .. 2);
      R : constant Residual_Vector (1 .. 3) := [1.0, 2.0, 3.0];
      --  Jᵀ r = [1*1+0*2+1*3, 0*1+2*2+1*3] = [4, 7]
      X, Y : Parameter_Vector (1 .. 2);
      I2 : constant Square_Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0], [0.0, 1.0]];
      SPD : constant Square_Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0], [1.0, 3.0]];
      Rhs : constant Parameter_Vector (1 .. 2) := [1.0, 2.0];
      --  Solve [[4,1],[1,3]] x = [1,2] → x = [1/11, 7/11]
   begin
      A := JTJ (J);
      Check (Approx (A (1, 1), 2.0), "JTJ(1,1)=2");
      Check (Approx (A (1, 2), 1.0), "JTJ(1,2)=1");
      Check (Approx (A (2, 1), 1.0), "JTJ(2,1)=1");
      Check (Approx (A (2, 2), 5.0), "JTJ(2,2)=5");
      G := JTr (J, R);
      Check (Approx (G (1), 4.0), "JTr(1)=4");
      Check (Approx (G (2), 7.0), "JTr(2)=7");
      X := [3.0, 4.0];
      Y := Mat_Vec (I2, X);
      Check (Approx (Y (1), 3.0) and then Approx (Y (2), 4.0),
             "Mat_Vec identity");
      Y := Mat_Vec (A, [1.0, 0.0]);
      Check (Approx (Y (1), 2.0) and then Approx (Y (2), 1.0),
             "Mat_Vec JTJ e1");
      X := Solve_SPD (I2, [5.0, -3.0]);
      Check (Approx (X (1), 5.0) and then Approx (X (2), -3.0),
             "Solve_SPD identity");
      X := Solve_SPD (SPD, Rhs);
      Check (Approx (X (1), 1.0 / 11.0, 1.0E-12), "Solve_SPD x1=1/11");
      Check (Approx (X (2), 7.0 / 11.0, 1.0E-12), "Solve_SPD x2=7/11");
      --  1-D
      declare
         A1 : constant Square_Matrix (1 .. 1, 1 .. 1) := [[2.0]];
         B1 : constant Parameter_Vector (1 .. 1) := [8.0];
         X1 : Parameter_Vector (1 .. 1);
      begin
         X1 := Solve_SPD (A1, B1);
         Check (Approx (X1 (1), 4.0), "Solve_SPD 1-D");
      end;
      --  Singular should raise
      declare
         Sing : constant Square_Matrix (1 .. 2, 1 .. 2) :=
           [[1.0, 2.0], [2.0, 4.0]];
         Raised : Boolean := False;
      begin
         begin
            X := Solve_SPD (Sing, [1.0, 2.0]);
         exception
            when Singular_System =>
               Raised := True;
         end;
         Check (Raised, "Solve_SPD singular raises");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Backtrack_Alpha geometric schedule");
   ---------------------------------------------------------------------
   declare
      A : Positive_Real;
   begin
      A := Backtrack_Alpha (1.0, 0.5, 0);
      Check (Approx (Real (A), 1.0), "Backtrack k=0 → 1");
      A := Backtrack_Alpha (1.0, 0.5, 1);
      Check (Approx (Real (A), 0.5), "Backtrack k=1 → 0.5");
      A := Backtrack_Alpha (1.0, 0.5, 2);
      Check (Approx (Real (A), 0.25), "Backtrack k=2 → 0.25");
      A := Backtrack_Alpha (1.0, 0.5, 3);
      Check (Approx (Real (A), 0.125), "Backtrack k=3 → 0.125");
      A := Backtrack_Alpha (2.0, 0.5, 1);
      Check (Approx (Real (A), 1.0), "Backtrack Alpha0=2 k=1");
      A := Backtrack_Alpha (1.0, 0.1, 2);
      Check (Approx (Real (A), 0.01, 1.0E-15), "Backtrack Rho=0.1 k=2");
      A := Backtrack_Alpha (1.0E-16, 0.5, 5);
      Check (Real (A) >= 1.0E-16, "Backtrack floors tiny α");
   end;

   ---------------------------------------------------------------------
   Section ("4. Finite-difference vs analytical Jacobian");
   ---------------------------------------------------------------------
   declare
      B_Lin : constant Parameter_Vector (1 .. 2) := [1.5, 2.5];
      B_Exp : constant Parameter_Vector (1 .. 2) := [4.0, 0.3];
      B_Ros : constant Parameter_Vector (1 .. 2) := [0.5, 0.8];
      Ja, Jf : Jacobian (1 .. 8, 1 .. 2);
      Jr_A, Jr_F : Jacobian (1 .. 2, 1 .. 2);
      Ok : Boolean;
   begin
      Ja := Linear_Jacobian (B_Lin);
      Jf := Finite_Difference_Jacobian
        (Linear_Residuals'Access, B_Lin, 1.0E-7);
      Ok := True;
      for I in 1 .. 8 loop
         for J in 1 .. 2 loop
            if abs (Ja (I, J) - Jf (I, J)) > 1.0E-5 then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "FD vs analytical Linear Jacobian");

      Ja := Exp_Decay_Jacobian (B_Exp);
      Jf := Finite_Difference_Jacobian
        (Exp_Decay_Residuals'Access, B_Exp, 1.0E-7);
      Ok := True;
      for I in 1 .. 8 loop
         for J in 1 .. 2 loop
            if abs (Ja (I, J) - Jf (I, J)) > 1.0E-4 then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "FD vs analytical Exp Jacobian");

      Jr_A := Rosenbrock_Jacobian (B_Ros);
      Jr_F := Finite_Difference_Jacobian
        (Rosenbrock_Residuals'Access, B_Ros, 1.0E-7);
      Ok := True;
      for I in 1 .. 2 loop
         for J in 1 .. 2 loop
            if abs (Jr_A (I, J) - Jr_F (I, J)) > 1.0E-4 then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "FD vs analytical Rosenbrock Jacobian");

      --  Quadratic FD vs analytical
      declare
         Bq : constant Parameter_Vector (1 .. 3) := [0.5, -1.0, 0.25];
         Jqa : Jacobian (1 .. 8, 1 .. 3);
         Jqf : Jacobian (1 .. 8, 1 .. 3);
      begin
         Jqa := Quadratic_Jacobian (Bq);
         Jqf := Finite_Difference_Jacobian
           (Quadratic_Residuals'Access, Bq, 1.0E-7);
         Ok := True;
         for I in 1 .. 8 loop
            for J in 1 .. 3 loop
               if abs (Jqa (I, J) - Jqf (I, J)) > 1.0E-5 then
                  Ok := False;
               end if;
            end loop;
         end loop;
         Check (Ok, "FD vs analytical Quadratic Jacobian");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Built-in residual models at truth");
   ---------------------------------------------------------------------
   declare
      Lin_T : constant Parameter_Vector (1 .. 2) := [2.0, 3.0];
      Quad_T : constant Parameter_Vector (1 .. 3) := [1.0, -2.0, 0.5];
      Exp_T : constant Parameter_Vector (1 .. 2) := [5.0, 0.4];
      Ros_T : constant Parameter_Vector (1 .. 2) := [1.0, 1.0];
      Sph_T : constant Parameter_Vector (1 .. 3) := [0.0, 0.0, 0.0];
      R : Residual_Vector (1 .. 8);
      Rr : Residual_Vector (1 .. 2);
      Rs : Residual_Vector (1 .. 3);
   begin
      R := Linear_Residuals (Lin_T);
      Check (Approx (Real (Residual_Norm2 (R)), 0.0, 1.0E-12),
             "Linear residuals zero at truth");
      R := Quadratic_Residuals (Quad_T);
      Check (Approx (Real (Residual_Norm2 (R)), 0.0, 1.0E-12),
             "Quadratic residuals zero at truth");
      R := Exp_Decay_Residuals (Exp_T);
      Check (Approx (Real (Residual_Norm2 (R)), 0.0, 1.0E-9),
             "Exp residuals near zero at truth");
      Rr := Rosenbrock_Residuals (Ros_T);
      Check (Approx (Real (Residual_Norm2 (Rr)), 0.0, 1.0E-12),
             "Rosenbrock residuals zero at (1,1)");
      Rs := Sphere_Residuals (Sph_T);
      Check (Approx (Real (Residual_Norm2 (Rs)), 0.0),
             "Sphere residuals zero at origin");
      Check (Approx (Real (Cost (R)), 0.0, 1.0E-9),
             "Cost zero at Exp truth");
   end;

   ---------------------------------------------------------------------
   Section ("6. Exact linear fit (analytical Jacobian)");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 2) := [0.0, 0.0];
      Res : Result;
   begin
      Res := Fit (Linear_Residuals'Access, B0,
                  Linear_Jacobian'Access, Default_Cfg);
      Check (Res.Success, "Linear Fit Success");
      Check (Approx (Res.Final_Params (1), 2.0, 1.0E-6), "Linear a=2");
      Check (Approx (Res.Final_Params (2), 3.0, 1.0E-6), "Linear b=3");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-10),
             "Linear Final_Cost≈0");
      Check (Res.Iterations >= 1, "Linear took ≥1 iter");
      Check (Res.N_Params = 2, "Linear N_Params=2");
      Check (Res.N_Residuals = 8, "Linear N_Residuals=8");
   end;

   ---------------------------------------------------------------------
   Section ("7. Exact linear fit (finite-difference Jacobian)");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 2) := [1.0, 1.0];
      Res : Result;
   begin
      Res := Fit (Linear_Residuals'Access, B0, null, Default_Cfg);
      Check (Res.Success, "Linear FD Fit Success");
      Check (Approx (Res.Final_Params (1), 2.0, 1.0E-5), "Linear FD a=2");
      Check (Approx (Res.Final_Params (2), 3.0, 1.0E-5), "Linear FD b=3");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-8),
             "Linear FD cost≈0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Exact quadratic fit");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 3) := [0.0, 0.0, 0.0];
      Res : Result;
   begin
      Res := Fit (Quadratic_Residuals'Access, B0,
                  Quadratic_Jacobian'Access, Default_Cfg);
      Check (Res.Success, "Quadratic Fit Success");
      Check (Approx (Res.Final_Params (1), 1.0, 1.0E-5), "Quadratic a=1");
      Check (Approx (Res.Final_Params (2), -2.0, 1.0E-5), "Quadratic b=-2");
      Check (Approx (Res.Final_Params (3), 0.5, 1.0E-5), "Quadratic c=0.5");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-8),
             "Quadratic cost≈0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Exponential decay recovery");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 2) := [3.0, 0.2];
      Res : Result;
      Cfg : Config := Default_Cfg;
   begin
      Cfg.Max_Iterations := 500;
      Res := Fit (Exp_Decay_Residuals'Access, B0,
                  Exp_Decay_Jacobian'Access, Cfg);
      Check (Res.Success, "Exp Fit Success");
      Check (Approx (Res.Final_Params (1), 5.0, 1.0E-4), "Exp a≈5");
      Check (Approx (Res.Final_Params (2), 0.4, 1.0E-4), "Exp b≈0.4");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-8), "Exp cost≈0");

      --  FD path
      Res := Fit (Exp_Decay_Residuals'Access, B0, null, Cfg);
      Check (Res.Success, "Exp FD Fit Success");
      Check (Approx (Res.Final_Params (1), 5.0, 5.0E-3), "Exp FD a≈5");
      Check (Approx (Res.Final_Params (2), 0.4, 5.0E-3), "Exp FD b≈0.4");
   end;

   ---------------------------------------------------------------------
   Section ("10. Rosenbrock least-squares");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 2) := [-1.2, 1.0];
      Res : Result;
      Cfg : Config := Default_Cfg;
   begin
      Cfg.Max_Iterations := 500;
      Res := Fit (Rosenbrock_Residuals'Access, B0,
                  Rosenbrock_Jacobian'Access, Cfg);
      Check (Res.Success, "Rosenbrock Fit Success");
      Check (Approx (Res.Final_Params (1), 1.0, 1.0E-4), "Rosenbrock x=1");
      Check (Approx (Res.Final_Params (2), 1.0, 1.0E-4), "Rosenbrock y=1");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-8),
             "Rosenbrock cost≈0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Sphere residual stack");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 4) := [1.0, -2.0, 3.0, -0.5];
      Res : Result;
   begin
      Res := Fit (Sphere_Residuals'Access, B0, null, Default_Cfg);
      Check (Res.Success, "Sphere Fit Success");
      Check (Approx (Res.Final_Params (1), 0.0, 1.0E-6), "Sphere p1=0");
      Check (Approx (Res.Final_Params (2), 0.0, 1.0E-6), "Sphere p2=0");
      Check (Approx (Res.Final_Params (3), 0.0, 1.0E-6), "Sphere p3=0");
      Check (Approx (Res.Final_Params (4), 0.0, 1.0E-6), "Sphere p4=0");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-10),
             "Sphere cost≈0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Minimize alias / already-optimal start");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 2) := [2.0, 3.0];
      Res : Result;
   begin
      Res := Minimize (Linear_Residuals'Access, B0,
                       Linear_Jacobian'Access, Default_Cfg);
      Check (Res.Success, "Minimize alias Success at truth");
      Check (Approx (Res.Final_Params (1), 2.0, 1.0E-8),
             "Minimize keeps a");
      Check (Approx (Res.Final_Params (2), 3.0, 1.0E-8),
             "Minimize keeps b");
      Check (Approx (Real (Res.Final_Cost), 0.0, 1.0E-12),
             "Minimize cost 0 at truth");
   end;

   ---------------------------------------------------------------------
   Section ("13. Edge cases / failure modes");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      B2 : constant Parameter_Vector (1 .. 2) := [1.0, 1.0];
      B1 : constant Parameter_Vector (1 .. 1) := [1.0];
      Res : Result;
      Cfg : Config := Default_Cfg;
   begin
      Raised := False;
      begin
         declare
            Unused : Residual_Vector := Linear_Residuals (B1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Linear_Residuals rejects short Beta");

      Raised := False;
      begin
         declare
            Unused : Jacobian := Linear_Jacobian (B1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Linear_Jacobian rejects short Beta");

      Raised := False;
      begin
         declare
            Unused : Residual_Vector := Quadratic_Residuals (B2);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Quadratic_Residuals rejects short Beta");

      Raised := False;
      begin
         declare
            Unused : Residual_Vector := Rosenbrock_Residuals (B1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock_Residuals rejects short Beta");

      Raised := False;
      begin
         declare
            Unused : Residual_Vector := Exp_Decay_Residuals (B1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exp_Decay_Residuals rejects short Beta");

      --  Max_Iterations = 1 from a bad start may not fully converge
      Cfg.Max_Iterations := 1;
      Res := Fit (Rosenbrock_Residuals'Access,
                  [-1.2, 1.0], Rosenbrock_Jacobian'Access, Cfg);
      Check (Res.Iterations <= 1, "Respects Max_Iterations=1");

      --  Very tight step tol from truth → success quickly
      Cfg := Default_Cfg;
      Cfg.Step_Tol := 1.0E-3;
      Res := Fit (Linear_Residuals'Access, [2.0, 3.0],
                  Linear_Jacobian'Access, Cfg);
      Check (Res.Success, "Already optimal Success");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra linear-algebra / helper coverage");
   ---------------------------------------------------------------------
   declare
      --  3×3 SPD
      A3 : constant Square_Matrix (1 .. 3, 1 .. 3) :=
        [[6.0, 1.0, 1.0],
         [1.0, 5.0, 1.0],
         [1.0, 1.0, 4.0]];
      B3 : constant Parameter_Vector (1 .. 3) := [1.0, 2.0, 3.0];
      X3 : Parameter_Vector (1 .. 3);
      Y3 : Parameter_Vector (1 .. 3);
      J1 : constant Jacobian (1 .. 2, 1 .. 1) := [[2.0], [3.0]];
      A1 : Square_Matrix (1 .. 1, 1 .. 1);
      G1 : Parameter_Vector (1 .. 1);
      P : Parameter_Vector (1 .. 2);
   begin
      X3 := Solve_SPD (A3, B3);
      Y3 := Mat_Vec (A3, X3);
      Check (Approx (Y3 (1), B3 (1), 1.0E-10), "3×3 Solve check row1");
      Check (Approx (Y3 (2), B3 (2), 1.0E-10), "3×3 Solve check row2");
      Check (Approx (Y3 (3), B3 (3), 1.0E-10), "3×3 Solve check row3");
      A1 := JTJ (J1);
      Check (Approx (A1 (1, 1), 13.0), "JTJ 2×1 → 13");
      G1 := JTr (J1, [1.0, 1.0]);
      Check (Approx (G1 (1), 5.0), "JTr 2×1 → 5");
      P := Scale (-1.0, [2.0, -4.0]);
      Check (Approx (P (1), -2.0) and then Approx (P (2), 4.0),
             "Scale negative");
      Check (Params_Near ([1.0], [1.0 + 1.0E-12]), "Params_Near 1-D");
      Check (Residuals_Near ([0.0], [0.0]), "Residuals_Near 1-D");
      Check (Approx (Dot ([1.0, 0.0], [0.0, 1.0]), 0.0), "Dot orthogonal");
      Check (not Near (1.0, 1.1, 0.05), "Near reject mid Tol");
      Check (Near (1.0, 1.01, 0.05), "Near accept mid Tol");
   end;

   ---------------------------------------------------------------------
   Section ("15. Line search on/off / no-damping contrast");
   ---------------------------------------------------------------------
   declare
      B0 : constant Parameter_Vector (1 .. 2) := [0.0, 0.0];
      Res_LS, Res_Full : Result;
      Cfg_LS, Cfg_Full : Config := Default_Cfg;
   begin
      Cfg_LS.Use_Line_Search := True;
      Cfg_Full.Use_Line_Search := False;
      Res_LS := Fit (Linear_Residuals'Access, B0,
                     Linear_Jacobian'Access, Cfg_LS);
      Res_Full := Fit (Linear_Residuals'Access, B0,
                       Linear_Jacobian'Access, Cfg_Full);
      Check (Res_LS.Success, "GN with line search succeeds (linear)");
      Check (Res_Full.Success, "GN full step succeeds (linear exact)");
      Check (Approx (Res_LS.Final_Params (1), 2.0, 1.0E-5),
             "LS recovers a");
      Check (Approx (Res_Full.Final_Params (2), 3.0, 1.0E-5),
             "Full-step recovers b");
      --  Linear least squares: GN finds optimum in one iteration
      Check (Res_Full.Iterations <= 2, "Linear GN ≤2 iters (exact LS)");

      --  Quadratic FD with line search
      Res_LS := Fit (Quadratic_Residuals'Access, [0.0, 0.0, 0.0],
                     null, Default_Cfg);
      Check (Res_LS.Success, "Quadratic FD + LS Success");
      Check (Approx (Res_LS.Final_Params (1), 1.0, 1.0E-4),
             "Quadratic FD a");
      Check (Approx (Res_LS.Final_Params (3), 0.5, 1.0E-4),
             "Quadratic FD c");
   end;

   ---------------------------------------------------------------------
   Section ("16. Analytical Jacobian values / residual signs");
   ---------------------------------------------------------------------
   declare
      B : constant Parameter_Vector (1 .. 2) := [0.0, 0.0];
      J : Jacobian (1 .. 8, 1 .. 2);
      R : Residual_Vector (1 .. 8);
      Bq : constant Parameter_Vector (1 .. 3) := [0.0, 0.0, 0.0];
      Jq : Jacobian (1 .. 8, 1 .. 3);
   begin
      J := Linear_Jacobian (B);
      Check (Approx (J (1, 1), -1.0), "Linear J(1,1)=-1");
      Check (Approx (J (1, 2), 0.0), "Linear J(1,2)=0 at x=0");
      Check (Approx (J (3, 2), -1.0), "Linear J(3,2)=-1 at x=1");
      R := Linear_Residuals (B);
      Check (Approx (R (1), 2.0), "Linear r1=y1 at β=0");
      Check (Approx (R (3), 5.0), "Linear r3=y3 at β=0");
      Jq := Quadratic_Jacobian (Bq);
      Check (Approx (Jq (1, 3), 0.0), "Quad J ∂r/∂c at x=0");
      Check (Approx (Jq (3, 3), -1.0), "Quad J ∂r/∂c at x=1");
      Check (Approx (Jq (5, 3), -4.0), "Quad J ∂r/∂c at x=2");
   end;

   New_Line;
   Put_Line ("======================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
