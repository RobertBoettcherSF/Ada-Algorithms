--  Standalone test suite for Nonlinear_Optimization (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nonlinear_Optimization; use Nonlinear_Optimization;

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

   Cfg_Armijo : constant Config :=
     (Max_Iterations  => 200,
      Grad_Tol        => 1.0E-8,
      Step_Tol        => 1.0E-12,
      Fd_Eps          => 1.0E-7,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 40,
      Step_Size       => 0.1,
      Use_Armijo      => True);

   Cfg_Fixed : constant Config :=
     (Max_Iterations  => 500,
      Grad_Tol        => 1.0E-8,
      Step_Tol        => 1.0E-14,
      Fd_Eps          => 1.0E-7,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 30,
      Step_Size       => 0.25,
      Use_Armijo      => False);

begin
   Put_Line ("Nonlinear_Optimization test suite");
   Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Point_Near / vector helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Point (1 .. 2) := [1.0, 2.0];
      B : constant Point (1 .. 2) := [1.0, 2.0];
      C : constant Point (1 .. 2) := [1.0, 3.0];
      D : constant Point (1 .. 3) := [3.0, 4.0, 0.0];
      Z : constant Point (1 .. 2) := [0.0, 0.0];
      S : Point (1 .. 2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Point_Near (A, B), "Point_Near equal");
      Check (not Point_Near (A, C), "Point_Near rejects");
      Check (Point_Near (A, C, 1.5), "Point_Near loose Tol");
      Check (Approx (Real (Norm2 (D)), 5.0, 1.0E-12), "Norm2(3,4,0)=5");
      Check (Approx (Real (Norm2 (Z)), 0.0), "Norm2 zero");
      Check (Approx (Dot (A, C), 7.0), "Dot product");
      S := Add (A, C);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 5.0), "Add");
      S := Sub (C, A);
      Check (Approx (S (1), 0.0) and then Approx (S (2), 1.0), "Sub");
      S := Scale (2.0, A);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 4.0), "Scale");
      Check (Approx (Dot (A, A), 5.0), "Dot self");
      Check (Approx (Real (Norm2 (A)) ** 2, 5.0, 1.0E-12), "Norm2^2");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Mat_Vec / Solve_SPD");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      I3 : constant Matrix := Identity (3);
      V  : constant Point (1 .. 2) := [3.0, 4.0];
      W  : Point (1 .. 2);
      SPD : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0], [1.0, 2.0]];
      Rhs : constant Point (1 .. 2) := [1.0, 1.0];
      X   : Point (1 .. 2);
      Raised : Boolean;
   begin
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0),
             "Identity 2 diag");
      Check (Approx (I2 (1, 2), 0.0) and then Approx (I2 (2, 1), 0.0),
             "Identity 2 off-diag");
      Check (Approx (I3 (3, 3), 1.0) and then Approx (I3 (1, 3), 0.0),
             "Identity 3 corners");
      W := Mat_Vec (I2, V);
      Check (Point_Near (W, V, 1.0E-12), "Mat_Vec I·v = v");
      X := Solve_SPD (I2, [5.0, -3.0]);
      Check (Approx (X (1), 5.0) and then Approx (X (2), -3.0),
             "Solve_SPD identity");
      X := Solve_SPD (SPD, Rhs);
      --  (2 1; 1 2)(x)= (1;1) → x=(1/3,1/3)
      Check (Approx (X (1), 1.0 / 3.0, 1.0E-12), "Solve_SPD SPD x1");
      Check (Approx (X (2), 1.0 / 3.0, 1.0E-12), "Solve_SPD SPD x2");
      declare
         A1 : constant Matrix (1 .. 1, 1 .. 1) := [[0.5]];
         B1 : constant Point (1 .. 1) := [2.0];
         X1 : Point (1 .. 1);
      begin
         X1 := Solve_SPD (A1, B1);
         Check (Approx (X1 (1), 4.0), "Solve_SPD 1-D");
      end;
      Raised := False;
      begin
         X := Solve_SPD ([[1.0, 1.0], [2.0, 2.0]], [1.0, 2.0]);
      exception
         when Singular_System =>
            Raised := True;
      end;
      Check (Raised, "Solve_SPD singular raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Demo objectives at known minima");
   ---------------------------------------------------------------------
   declare
      O  : constant Point (1 .. 3) := [0.0, 0.0, 0.0];
      R1 : constant Point (1 .. 2) := [1.0, 1.0];
      Hb : constant Point (1 .. 2) := [3.0, 2.0];
      Hb2 : constant Point (1 .. 2) := [-2.805118, 3.131312];
      Q  : constant Point (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      Check (Approx (Sphere (O), 0.0), "Sphere(0)=0");
      Check (Approx (Real (Norm2 (Sphere_Grad (O))), 0.0),
             "Sphere grad at 0");
      Check (Approx (Sphere ([1.0, 2.0]), 5.0), "Sphere(1,2)=5");
      Check (Approx (Rosenbrock (R1), 0.0, 1.0E-14), "Rosenbrock(1,1)=0");
      Check (Approx (Real (Norm2 (Rosenbrock_Grad (R1))), 0.0, 1.0E-12),
             "Rosenbrock grad at min");
      Check (Approx (Quadratic_Bowl (O), 0.0), "Quadratic_Bowl(0)=0");
      Check (Approx (Quadratic_Bowl (Q),
             0.5 * (1.0 * 1.0 + 2.0 * 4.0 + 3.0 * 9.0), 1.0E-12),
             "Quadratic_Bowl value");
      Check (Approx (Himmelblau (Hb), 0.0, 1.0E-12), "Himmelblau(3,2)=0");
      Check (Approx (Real (Norm2 (Himmelblau_Grad (Hb))), 0.0, 1.0E-10),
             "Himmelblau grad at (3,2)");
      Check (Approx (Himmelblau (Hb2), 0.0, 1.0E-4),
             "Himmelblau second min ≈0");
      Check (Approx (Himmelblau ([-3.779310, -3.283186]), 0.0, 1.0E-4),
             "Himmelblau third min ≈0");
      Check (Approx (Himmelblau ([3.584428, -1.848126]), 0.0, 1.0E-4),
             "Himmelblau fourth min ≈0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Analytical grads vs FD");
   ---------------------------------------------------------------------
   declare
      X2 : constant Point (1 .. 2) := [0.3, -0.7];
      X3 : constant Point (1 .. 3) := [0.5, -0.2, 0.8];
      Ga, Gf : Point (1 .. 2);
      Gb, Gg : Point (1 .. 3);
   begin
      Ga := Sphere_Grad (X2);
      Gf := Finite_Difference_Gradient (Sphere'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-5), "FD≈analytical Sphere");
      Ga := Rosenbrock_Grad (X2);
      Gf := Finite_Difference_Gradient (Rosenbrock'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-4), "FD≈analytical Rosenbrock");
      Ga := Himmelblau_Grad (X2);
      Gf := Finite_Difference_Gradient (Himmelblau'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-4), "FD≈analytical Himmelblau");
      Gb := Quadratic_Bowl_Grad (X3);
      Gg := Finite_Difference_Gradient (Quadratic_Bowl'Access, X3);
      Check (Point_Near (Gb, Gg, 1.0E-5), "FD≈analytical Quadratic_Bowl");
   end;

   ---------------------------------------------------------------------
   Section ("5. Analytical Hessians / FD Hessian / Newton direction");
   ---------------------------------------------------------------------
   declare
      X2 : constant Point (1 .. 2) := [0.4, -0.3];
      Hs : constant Matrix := Sphere_Hess (X2);
      Hq : constant Matrix := Quadratic_Bowl_Hess ([1.0, 2.0, 3.0]);
      Hr : constant Matrix := Rosenbrock_Hess (X2);
      Hf : Matrix (1 .. 2, 1 .. 2);
      G  : Point (1 .. 2);
      P  : Point (1 .. 2);
   begin
      Check (Approx (Hs (1, 1), 2.0) and then Approx (Hs (2, 2), 2.0),
             "Sphere Hess diag 2");
      Check (Approx (Hs (1, 2), 0.0), "Sphere Hess off 0");
      Check (Approx (Hq (1, 1), 1.0) and then Approx (Hq (2, 2), 2.0)
             and then Approx (Hq (3, 3), 3.0),
             "Quadratic_Bowl Hess diag");
      Check (Approx (Hr (2, 2), 200.0), "Rosenbrock H22=2b");
      Hf := Finite_Difference_Hessian (Sphere'Access, X2);
      Check (Approx (Hf (1, 1), 2.0, 1.0E-3)
             and then Approx (Hf (2, 2), 2.0, 1.0E-3),
             "FD Hessian Sphere diag");
      Check (Approx (Hf (1, 2), 0.0, 1.0E-3), "FD Hessian Sphere off");
      G := Sphere_Grad (X2);
      P := Newton_Direction (Hs, G);
      --  For Sphere, Newton step = -H^{-1}(2x) = -0.5*(2x) = -x → to origin
      Check (Point_Near (Add (X2, P), [0.0, 0.0], 1.0E-10),
             "Newton Sphere lands on 0 in one step");
   end;

   ---------------------------------------------------------------------
   Section ("6. Armijo / Line_Search");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.0, 1.0];
      G : constant Point := Sphere_Grad (X);
      P : constant Point := Scale (-1.0, G);
      F : constant Real := Sphere (X);
      A : Positive_Real;
   begin
      Check (Armijo_Accept (0.0, 2.0, 1.0, 1.0E-4, -4.0),
             "Armijo accepts large decrease");
      Check (not Armijo_Accept (3.0, 2.0, 1.0, 1.0E-4, -4.0),
             "Armijo rejects increase");
      A := Line_Search
        (Sphere'Access, X, F, G, P, 1.0E-4, 0.5, 30);
      Check (A > 0.0, "Line_Search returns positive α");
      Check (Sphere (Add (X, Scale (Real (A), P))) < F,
             "Line_Search decreases f");
   end;

   ---------------------------------------------------------------------
   Section ("7. Stationarity / Project_Box");
   ---------------------------------------------------------------------
   declare
      Z : constant Point (1 .. 2) := [0.0, 0.0];
      G : constant Point := Sphere_Grad ([0.1, 0.0]);
      Lo : constant Point (1 .. 2) := [-1.0, 0.0];
      Hi : constant Point (1 .. 2) := [1.0, 2.0];
      Bx : constant Box := Make_Box (Lo, Hi);
      Xp : Point (1 .. 2);
   begin
      Check (Is_Stationary (Sphere_Grad (Z)), "Stationary at Sphere min");
      Check (not Is_Stationary (G, 1.0E-8), "Not stationary away");
      Check (Approx (Real (Grad_Norm (G)), 0.2, 1.0E-12), "Grad_Norm");
      Xp := Project_Box ([2.0, -1.0], Bx);
      Check (Approx (Xp (1), 1.0) and then Approx (Xp (2), 0.0),
             "Project_Box clamps both");
      Xp := Project_Box ([0.5, 1.0], Bx);
      Check (Point_Near (Xp, [0.5, 1.0]), "Project_Box interior");
      Xp := Projected_Gradient_Step ([0.5, 1.0], [1.0, 0.0], 1.0, Bx);
      Check (Approx (Xp (1), -0.5) and then Approx (Xp (2), 1.0),
             "Projected_Gradient_Step");
      Xp := Gradient_Descent_Step ([1.0, 1.0], [2.0, 2.0], 0.25);
      Check (Approx (Xp (1), 0.5) and then Approx (Xp (2), 0.5),
             "Gradient_Descent_Step");
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize_GD Sphere / Quadratic_Bowl / Rosenbrock");
   ---------------------------------------------------------------------
   declare
      R : Result;
      X0 : constant Point (1 .. 3) := [1.5, -2.0, 0.5];
      Xr : constant Point (1 .. 2) := [-1.2, 1.0];
      Cfg_R : Config := Cfg_Armijo;
   begin
      R := Minimize_GD
        (Sphere'Access, X0, Sphere_Grad'Access, Cfg_Armijo);
      Check (R.Success, "GD Sphere Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-10), "GD Sphere f≈0");
      Check (R.Final_Grad_Norm <= 1.0E-7, "GD Sphere ‖g‖");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-5)
             and then Approx (R.Final_Point (2), 0.0, 1.0E-5),
             "GD Sphere near origin");

      R := Minimize_GD
        (Quadratic_Bowl'Access, X0, Quadratic_Bowl_Grad'Access,
         Cfg_Armijo);
      Check (R.Success, "GD Bowl Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8), "GD Bowl f≈0");

      R := Minimize_GD
        (Sphere'Access, [2.0, -1.0], null, Cfg_Armijo);
      Check (R.Success, "GD Sphere FD grad Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8), "GD Sphere FD f≈0");

      R := Minimize_GD
        (Sphere'Access, [1.0, 1.0], Sphere_Grad'Access, Cfg_Fixed);
      Check (R.Success, "GD Sphere fixed-step Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8), "GD Sphere fixed f≈0");

      --  Plain GD is slow on the Rosenbrock valley; allow a looser
      --  stationarity tol and many iterations (Newton/BFGS siblings
      --  are the practical solvers — see README).
      Cfg_R.Max_Iterations := 8000;
      Cfg_R.Grad_Tol := 1.0E-2;
      R := Minimize_GD
        (Rosenbrock'Access, Xr, Rosenbrock_Grad'Access, Cfg_R);
      Check (R.Success, "GD Rosenbrock Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-3), "GD Rosenbrock f≈0");
      Check (Approx (R.Final_Point (1), 1.0, 5.0E-2)
             and then Approx (R.Final_Point (2), 1.0, 5.0E-2),
             "GD Rosenbrock near (1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("9. Minimize_Newton Sphere / Bowl / Rosenbrock");
   ---------------------------------------------------------------------
   declare
      R : Result;
      X0 : constant Point (1 .. 2) := [3.0, -2.0];
      Xr : constant Point (1 .. 2) := [-1.2, 1.0];
      Cfg_N : Config := Cfg_Armijo;
   begin
      R := Minimize_Newton
        (Sphere'Access, X0, Sphere_Grad'Access, Sphere_Hess'Access,
         Cfg_Armijo);
      Check (R.Success, "Newton Sphere Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-12), "Newton Sphere f≈0");
      Check (R.Iterations <= 3, "Newton Sphere few iters");

      R := Minimize_Newton
        (Quadratic_Bowl'Access, [2.0, -1.0, 0.5],
         Quadratic_Bowl_Grad'Access, Quadratic_Bowl_Hess'Access,
         Cfg_Armijo);
      Check (R.Success, "Newton Bowl Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-12), "Newton Bowl f≈0");
      Check (R.Iterations <= 3, "Newton Bowl few iters (quadratic)");

      Cfg_N.Max_Iterations := 50;
      R := Minimize_Newton
        (Rosenbrock'Access, Xr, Rosenbrock_Grad'Access,
         Rosenbrock_Hess'Access, Cfg_N);
      Check (R.Success, "Newton Rosenbrock Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Newton Rosenbrock f≈0");
      Check (Approx (R.Final_Point (1), 1.0, 1.0E-3)
             and then Approx (R.Final_Point (2), 1.0, 1.0E-3),
             "Newton Rosenbrock near (1,1)");

      --  FD Hessian path
      R := Minimize_Newton
        (Sphere'Access, [1.0, -1.0], Sphere_Grad'Access, null,
         Cfg_Armijo);
      Check (R.Success, "Newton Sphere FD Hess Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Newton FD Hess f≈0");
   end;

   ---------------------------------------------------------------------
   Section ("10. Himmelblau GD / Newton local mins");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Xh : constant Point (1 .. 2) := [0.0, 0.0];
      Cfg_H : Config := Cfg_Armijo;
   begin
      Cfg_H.Max_Iterations := 300;
      R := Minimize_GD
        (Himmelblau'Access, Xh, Himmelblau_Grad'Access, Cfg_H);
      Check (R.Success, "GD Himmelblau Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4), "GD Himmelblau f≈0");

      R := Minimize_Newton
        (Himmelblau'Access, [3.5, 2.5], Himmelblau_Grad'Access,
         null, Cfg_H);
      Check (R.Success, "Newton Himmelblau Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4), "Newton Himmelblau f≈0");
      Check (Approx (R.Final_Point (1), 3.0, 0.05)
             and then Approx (R.Final_Point (2), 2.0, 0.05),
             "Newton Himmelblau → (3,2)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Projected GD box constraints");
   ---------------------------------------------------------------------
   declare
      R : Result;
      --  Sphere min at 0 is outside box [1,2]×[1,2] → expect corner (1,1)
      Bx : constant Box := Make_Box ([1.0, 1.0], [2.0, 2.0]);
      Cfg_P : Config := Cfg_Armijo;
   begin
      Cfg_P.Max_Iterations := 100;
      R := Minimize_Projected_GD
        (Sphere'Access, [1.5, 1.8], Bx, Sphere_Grad'Access, Cfg_P);
      Check (R.Success, "Projected GD Success");
      Check (Approx (R.Final_Point (1), 1.0, 1.0E-4)
             and then Approx (R.Final_Point (2), 1.0, 1.0E-4),
             "Projected GD → (1,1) corner");
      Check (Approx (R.Final_Value, 2.0, 1.0E-3),
             "Projected GD f(1,1)=2");

      --  Interior min: box contains origin
      declare
         Bi : constant Box := Make_Box ([-2.0, -2.0], [2.0, 2.0]);
      begin
         R := Minimize_Projected_GD
           (Sphere'Access, [1.0, -1.0], Bi, Sphere_Grad'Access, Cfg_P);
         Check (R.Success, "Projected GD interior Success");
         Check (Approx (R.Final_Value, 0.0, 1.0E-6),
                "Projected GD interior f≈0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Method catalog / Classify_Method");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
      DF_Count : Natural := 0;
      Grad_Count : Natural := 0;
      Hess_Count : Natural := 0;
   begin
      Check (Method_Count = 7, "Method_Count=7");
      Info := Classify_Method (Gradient_Descent);
      Check (Info.Needs_Gradient and then not Info.Needs_Hessian
             and then not Info.Derivative_Free,
             "GD flags");
      Info := Classify_Method (Newton);
      Check (Info.Needs_Gradient and then Info.Needs_Hessian
             and then not Info.Derivative_Free,
             "Newton flags");
      Info := Classify_Method (Quasi_Newton_BFGS);
      Check (Info.Needs_Gradient and then not Info.Needs_Hessian,
             "BFGS needs grad, not Hess");
      Info := Classify_Method (Nelder_Mead);
      Check (Info.Derivative_Free and then not Info.Needs_Gradient,
             "Nelder-Mead derivative-free");
      Info := Classify_Method (Simulated_Annealing);
      Check (Info.Derivative_Free, "SA derivative-free");
      Info := Classify_Method (Gauss_Newton);
      Check (Info.Needs_Gradient, "GN needs gradient");
      Info := Classify_Method (Levenberg_Marquardt);
      Check (Info.Needs_Gradient, "LM needs gradient");
      Check (Method_Name (Gradient_Descent) = "Gradient Descent",
             "Method_Name GD");
      Check (Method_Name (Newton) = "Newton", "Method_Name Newton");
      Check (Method_Name (Quasi_Newton_BFGS) = "Quasi-Newton BFGS",
             "Method_Name BFGS");
      Check (Method_Name (Nelder_Mead) = "Nelder-Mead",
             "Method_Name NM");
      for K in Method_Kind loop
         Info := Classify_Method (K);
         if Info.Derivative_Free then
            DF_Count := DF_Count + 1;
         end if;
         if Info.Needs_Gradient then
            Grad_Count := Grad_Count + 1;
         end if;
         if Info.Needs_Hessian then
            Hess_Count := Hess_Count + 1;
         end if;
         Check (Info.Kind = K, "Classify Kind matches " & Method_Name (K));
      end loop;
      Check (DF_Count = 2, "Two derivative-free methods");
      Check (Grad_Count = 5, "Five gradient-based methods");
      Check (Hess_Count = 1, "One explicit-Hessian method (Newton)");
   end;

   ---------------------------------------------------------------------
   Section ("13. Compare_Fixed_Step_GD");
   ---------------------------------------------------------------------
   declare
      Steps : constant Point (1 .. 3) := [0.05, 0.25, 0.4];
      T : constant Compare_Table :=
        Compare_Fixed_Step_GD
          (Sphere'Access, [2.0, -1.0], Sphere_Grad'Access, Steps,
           Max_Iters => 200, Grad_Tol => 1.0E-8);
   begin
      Check (T'Length = 3, "Compare table length 3");
      Check (T (1).Step_Size = 0.05, "Compare step 0.05");
      Check (T (2).Step_Size = 0.25, "Compare step 0.25");
      Check (T (3).Success, "Compare largest useful step Success");
      Check (Approx (T (3).Final_Value, 0.0, 1.0E-6),
             "Compare final f≈0");
      Check (T (2).Success, "Compare mid step Success");
      --  Smaller step typically needs more iterations than mid step
      --  (for Sphere exact rate depends on α; just check all ran).
      Check (T (1).Iterations >= 1, "Compare small step ran");
      Check (T (1).Success, "Compare small step Success");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra edge / consistency checks");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Raised : Boolean;
      Bx : Box;
   begin
      Check (Approx (Sphere ([0.0]), 0.0), "Sphere 1-D zero");
      Check (Approx (Sphere_Grad ([3.0]) (1), 6.0), "Sphere_Grad 1-D");
      R := Minimize_GD
        (Sphere'Access, [4.0], Sphere_Grad'Access, Cfg_Armijo);
      Check (R.Success and then Approx (R.Final_Value, 0.0, 1.0E-10),
             "GD 1-D Sphere");
      R := Minimize_Newton
        (Sphere'Access, [4.0], Sphere_Grad'Access, Sphere_Hess'Access,
         Cfg_Armijo);
      Check (R.Success and then R.Iterations <= 2, "Newton 1-D Sphere");
      declare
         Dummy : Real;
      begin
         Raised := False;
         Dummy := Rosenbrock ([1.0]);
         Raised := Dummy < 0.0;  -- unreachable if raise works
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock 1-D raises");
      begin
         Raised := False;
         Bx := Make_Box ([1.0, 2.0], [0.0, 3.0]);
         Raised := Bx.Dim = 2;  -- unreachable if raise works
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Box Lo>Hi raises");
      Check (Armijo_Accept (1.0, 1.0, 0.0, 0.5, -1.0),
             "Armijo α=0 boundary");
      Check (not Is_Stationary (Sphere_Grad ([1.0E-3, 0.0]), 1.0E-8),
             "Near-zero but not stationary");
      Check (Is_Stationary (Sphere_Grad ([1.0E-10, 0.0]), 1.0E-8),
             "Tiny grad stationary");
      declare
         H : constant Matrix := Sphere_Hess ([1.0, 2.0, 3.0]);
      begin
         Check (H'Length (1) = 3 and then Approx (H (3, 3), 2.0),
                "Sphere Hess 3-D");
      end;
      declare
         X : constant Point (1 .. 2) := [0.2, 0.3];
         Ha : constant Matrix := Rosenbrock_Hess (X);
         Hf : constant Matrix :=
           Finite_Difference_Hessian (Rosenbrock'Access, X, 1.0E-5);
      begin
         Check (Approx (Ha (1, 1), Hf (1, 1), 5.0E-2),
                "FD≈analytical Rosenbrock H11");
         Check (Approx (Ha (1, 2), Hf (1, 2), 5.0E-2),
                "FD≈analytical Rosenbrock H12");
         Check (Approx (Ha (2, 2), Hf (2, 2), 5.0E-2),
                "FD≈analytical Rosenbrock H22");
      end;
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   pragma Assert (Pass_Count >= 100);
end Tests;
