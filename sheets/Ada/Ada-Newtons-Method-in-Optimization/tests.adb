--  Standalone test suite for Newtons_Method_Optimization (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Newtons_Method_Optimization; use Newtons_Method_Optimization;

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

   Pure_Cfg : constant Config :=
     (Max_Iterations         => 50,
      Grad_Tol               => 1.0E-10,
      Step_Tol               => 1.0E-14,
      Fd_Eps                 => 1.0E-7,
      Fd_Hess_Eps            => 1.0E-5,
      Armijo_C               => 1.0E-4,
      Line_Search_Rho        => 0.5,
      Max_Line_Search        => 30,
      Use_Line_Search        => False,
      Hessian_Regularization => False,
      Reg_Tau0               => 1.0E-6,
      Reg_Tau_Grow           => 10.0,
      Reg_Tau_Max            => 1.0E8);

   Damped_Cfg : constant Config :=
     (Max_Iterations         => 200,
      Grad_Tol               => 1.0E-8,
      Step_Tol               => 1.0E-12,
      Fd_Eps                 => 1.0E-7,
      Fd_Hess_Eps            => 1.0E-5,
      Armijo_C               => 1.0E-4,
      Line_Search_Rho        => 0.5,
      Max_Line_Search        => 30,
      Use_Line_Search        => True,
      Hessian_Regularization => True,
      Reg_Tau0               => 1.0E-6,
      Reg_Tau_Grow           => 10.0,
      Reg_Tau_Max            => 1.0E8);

begin
   Put_Line ("Newton's method in optimization — test suite");
   Put_Line ("============================================");

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
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
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
      Check (Approx (Dot (A, A), 5.0), "Dot self = ||A||^2");
      Check (Approx (Real (Norm2 (A)) ** 2, 5.0, 1.0E-12),
             "Norm2(1,2)^2 = 5");
      Check (Approx (Dot ([1.0, 0.0], [0.0, 1.0]), 0.0), "Dot orthogonal");
      Check (not Near (1.0, 2.0, 0.1), "Near reject mid");
      Check (Near (1.0, 1.05, 0.1), "Near accept mid");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Mat_Vec / Mat_Add / Mat_Scale / Quadratic_Form");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      I3 : constant Matrix := Identity (3);
      V  : constant Point (1 .. 2) := [3.0, 4.0];
      M  : Matrix (1 .. 2, 1 .. 2);
      W  : Point (1 .. 2);
      X  : constant Point (1 .. 2) := [1.0, 2.0];
   begin
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0),
             "Identity 2 diag");
      Check (Approx (I2 (1, 2), 0.0) and then Approx (I2 (2, 1), 0.0),
             "Identity 2 off-diag");
      Check (Approx (I3 (3, 3), 1.0) and then Approx (I3 (1, 3), 0.0),
             "Identity 3 corners");
      W := Mat_Vec (I2, V);
      Check (Point_Near (W, V, 1.0E-12), "Mat_Vec I·v = v");
      M := Mat_Add (I2, I2);
      Check (Approx (M (1, 1), 2.0) and then Approx (M (2, 2), 2.0),
             "Mat_Add I+I");
      M := Mat_Scale (0.5, M);
      Check (Approx (M (1, 1), 1.0) and then Approx (M (1, 2), 0.0),
             "Mat_Scale half");
      M := Mat_Scale (3.0, Identity (2));
      W := Mat_Vec (M, X);
      Check (Approx (W (1), 3.0) and then Approx (W (2), 6.0),
             "Mat_Vec (3I)·(1,2)");
      Check (Approx (Quadratic_Form (I2, X), 5.0, 1.0E-12),
             "Quadratic_Form I → ||x||^2");
      Check (Approx (Quadratic_Form (M, [1.0, 0.0]), 3.0),
             "Quadratic_Form 3I e1");
      declare
         Big : constant Matrix := Identity (Max_Dim);
      begin
         Check (Big'Length (1) = Max_Dim
                and then Approx (Big (Max_Dim, Max_Dim), 1.0),
                "Identity(Max_Dim) last diag");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Solve_Linear / Newton_Direction");
   ---------------------------------------------------------------------
   declare
      A : Matrix (1 .. 2, 1 .. 2);
      B : Point (1 .. 2);
      X : Point (1 .. 2);
      P2 : Point (1 .. 2);
      G2 : Point (1 .. 2);
      H2 : Matrix (1 .. 2, 1 .. 2);
      P3 : Point (1 .. 3);
      G3 : Point (1 .. 3);
      H3 : Matrix (1 .. 3, 1 .. 3);
   begin
      A := [[2.0, 0.0], [0.0, 4.0]];
      B := [2.0, 8.0];
      X := Solve_Linear (A, B);
      Check (Approx (X (1), 1.0) and then Approx (X (2), 2.0),
             "Solve diag 2x2");
      A := [[1.0, 2.0], [3.0, 4.0]];
      B := [5.0, 11.0];
      X := Solve_Linear (A, B);
      Check (Approx (X (1), 1.0, 1.0E-10) and then Approx (X (2), 2.0, 1.0E-10),
             "Solve general 2x2");
      H2 := Sphere_Hess ([1.0, 1.0]);
      G2 := Sphere_Grad ([3.0, -1.0]);
      P2 := Newton_Direction (H2, G2);
      Check (Approx (P2 (1), -3.0, 1.0E-10)
             and then Approx (P2 (2), 1.0, 1.0E-10),
             "Newton dir Sphere → −x");
      H3 := Quadratic_Bowl_Hess ([0.0, 0.0, 0.0]);
      G3 := Quadratic_Bowl_Grad ([2.0, 4.0, 6.0]);
      P3 := Newton_Direction (H3, G3);
      Check (Approx (P3 (1), -2.0, 1.0E-10)
             and then Approx (P3 (2), -4.0, 1.0E-10)
             and then Approx (P3 (3), -6.0, 1.0E-10),
             "Newton dir bowl → −x (exact quadratic)");
      begin
         A := [[0.0, 0.0], [0.0, 0.0]];
         X := Solve_Linear (A, [1.0, 1.0]);
         Check (False, "singular should raise");
      exception
         when Singular_System =>
            Check (True, "Singular_System on zero matrix");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Is_Symmetric / Is_Positive_Definite_Ish / Regularize");
   ---------------------------------------------------------------------
   declare
      H  : Matrix (1 .. 2, 1 .. 2);
      Hr : Matrix (1 .. 2, 1 .. 2);
      Used : aliased Boolean := False;
   begin
      H := Identity (2);
      Check (Is_Symmetric (H), "I is symmetric");
      Check (Is_Positive_Definite_Ish (H), "I is PD-ish");
      H := [[2.0, 1.0], [1.0, 2.0]];
      Check (Is_Symmetric (H), "SPD candidate symmetric");
      Check (Is_Positive_Definite_Ish (H), "[[2,1],[1,2]] PD");
      H := [[1.0, 2.0], [0.0, 1.0]];
      Check (not Is_Symmetric (H), "nonsymmetric rejected");
      H := [[-1.0, 0.0], [0.0, -1.0]];
      Check (not Is_Positive_Definite_Ish (H), "−I not PD");
      H := [[0.0, 0.0], [0.0, 1.0]];
      Check (not Is_Positive_Definite_Ish (H), "singular PSD not PD");
      Hr := Regularize_Hessian (H, 1.0);
      Check (Approx (Hr (1, 1), 1.0) and then Approx (Hr (2, 2), 2.0),
             "Regularize adds τ to diag");
      Check (Is_Positive_Definite_Ish (Hr), "regularized becomes PD");
      H := [[-2.0, 0.0], [0.0, -3.0]];
      Used := False;
      Hr := Make_PD_Hessian (H, 1.0, 2.0, 100.0, Used'Access);
      Check (Used, "Make_PD reports Used_Reg");
      Check (Is_Positive_Definite_Ish (Hr), "Make_PD yields PD");
      H := Identity (2);
      Used := True;
      Hr := Make_PD_Hessian (H, 1.0E-6, 10.0, 1.0E8, Used'Access);
      Check (not Used, "Make_PD no-op on already PD");
      Check (Approx (Hr (1, 1), 1.0), "Make_PD returns original PD");
   end;

   ---------------------------------------------------------------------
   Section ("5. Armijo_Accept / Line_Search");
   ---------------------------------------------------------------------
   declare
      Alpha : Positive_Real;
      X0 : constant Point (1 .. 1) := [5.0];
      G  : constant Point (1 .. 1) := Sphere_Grad (X0);
      P  : constant Point (1 .. 1) := Scale (-1.0, G);
      F  : constant Real := Sphere (X0);
   begin
      Check (Armijo_Accept (9.0, 10.0, 1.0, 0.1, -10.0),
             "Armijo accept boundary interior");
      Check (not Armijo_Accept (9.5, 10.0, 1.0, 0.1, -10.0),
             "Armijo reject insufficient decrease");
      Check (Armijo_Accept (0.0, 10.0, 0.5, 1.0E-4, -100.0),
             "Armijo large decrease accepted");
      Check (Armijo_Accept (10.0, 10.0, 1.0, 0.1, 0.0),
             "Armijo flat direction equality");
      Alpha := Line_Search
        (Sphere'Access, X0, F, G, P, 1.0E-4, 0.5, 30);
      Check (Alpha > 0.0, "Line_Search returns positive α");
      Check (Approx (Real (Alpha), 1.0) or else Real (Alpha) < 1.0,
             "Line_Search α ≤ 1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Finite_Difference_Gradient / Hessian");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [0.5, -0.3];
      Ga2, Gn2 : Point (1 .. 2);
      Ha2, Hn2 : Matrix (1 .. 2, 1 .. 2);
      X3 : constant Point (1 .. 3) := [1.0, -2.0, 0.5];
      Ga3, Gn3 : Point (1 .. 3);
      Ha3, Hn3 : Matrix (1 .. 3, 1 .. 3);
   begin
      Ga2 := Sphere_Grad (X);
      Gn2 := Finite_Difference_Gradient (Sphere'Access, X);
      Check (Point_Near (Ga2, Gn2, 1.0E-5), "FD grad ≈ Sphere analytical");
      Ha2 := Sphere_Hess (X);
      Hn2 := Finite_Difference_Hessian (Sphere'Access, X);
      Check (Approx (Hn2 (1, 1), Ha2 (1, 1), 1.0E-3)
             and then Approx (Hn2 (2, 2), Ha2 (2, 2), 1.0E-3),
             "FD Hess diag ≈ Sphere");
      Check (Approx (Hn2 (1, 2), 0.0, 1.0E-3)
             and then Approx (Hn2 (2, 1), 0.0, 1.0E-3),
             "FD Hess off-diag ≈ 0 Sphere");
      Ga3 := Quadratic_Bowl_Grad (X3);
      Gn3 := Finite_Difference_Gradient (Quadratic_Bowl'Access, X3);
      Check (Point_Near (Ga3, Gn3, 1.0E-5), "FD grad ≈ Bowl");
      Ha3 := Quadratic_Bowl_Hess (X3);
      Hn3 := Finite_Difference_Hessian (Quadratic_Bowl'Access, X3);
      Check (Approx (Hn3 (1, 1), Ha3 (1, 1), 1.0E-3)
             and then Approx (Hn3 (2, 2), Ha3 (2, 2), 1.0E-3)
             and then Approx (Hn3 (3, 3), Ha3 (3, 3), 1.0E-3),
             "FD Hess Bowl diag");
      Ga2 := Rosenbrock_Grad ([0.5, 0.25]);
      Gn2 := Finite_Difference_Gradient (Rosenbrock'Access, [0.5, 0.25]);
      Check (Point_Near (Ga2, Gn2, 1.0E-4), "FD grad ≈ Rosenbrock");
      Ha2 := Rosenbrock_Hess ([0.5, 0.25]);
      Hn2 := Finite_Difference_Hessian (Rosenbrock'Access, [0.5, 0.25]);
      Check (Approx (Hn2 (1, 1), Ha2 (1, 1), 5.0E-2)
             and then Approx (Hn2 (2, 2), Ha2 (2, 2), 5.0E-2),
             "FD Hess ≈ Rosenbrock (loose)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Demo objectives at known points");
   ---------------------------------------------------------------------
   declare
      Z2 : constant Point (1 .. 2) := [0.0, 0.0];
      M1 : constant Point (1 .. 2) := [1.0, 1.0];
   begin
      Check (Approx (Sphere (Z2), 0.0), "Sphere at origin = 0");
      Check (Approx (Sphere ([1.0, 2.0]), 5.0), "Sphere(1,2)=5");
      Check (Point_Near (Sphere_Grad (Z2), Z2), "Sphere grad at 0");
      Check (Approx (Sphere_Hess (Z2) (1, 1), 2.0), "Sphere Hess 2");
      Check (Approx (Quadratic_Bowl (Z2), 0.0), "Bowl at origin = 0");
      Check (Approx (Quadratic_Bowl ([1.0, 0.0]), 0.5), "Bowl(1,0)=0.5");
      Check (Approx (Quadratic_Bowl_Grad ([1.0, 0.0]) (1), 1.0),
             "Bowl grad ∂/∂x1");
      Check (Approx (Quadratic_Bowl_Grad ([0.0, 1.0]) (2), 2.0),
             "Bowl grad ∂/∂x2");
      Check (Approx (Quadratic_Bowl_Hess (Z2) (2, 2), 2.0), "Bowl Hess diag");
      Check (Approx (Rosenbrock (M1), 0.0), "Rosenbrock min");
      Check (Point_Near (Rosenbrock_Grad (M1), Z2, 1.0E-12),
             "Rosenbrock grad at min");
      Check (Approx (Himmelblau ([3.0, 2.0]), 0.0, 1.0E-12),
             "Himmelblau (3,2)");
      Check (Approx (Himmelblau ([-2.805118, 3.131312]), 0.0, 1.0E-4),
             "Himmelblau second min");
      Check (Approx (Himmelblau ([-3.779310, -3.283186]), 0.0, 1.0E-4),
             "Himmelblau third min");
      Check (Approx (Himmelblau ([3.584428, -1.848126]), 0.0, 1.0E-4),
             "Himmelblau fourth min");
      Check (Approx (Quartic_1D ([3.0]), 0.0), "Quartic at 3");
      Check (Approx (Quartic_1D_Grad ([3.0]) (1), 0.0), "Quartic grad at 3");
      Check (Approx (Quartic_1D_Hess ([3.0]) (1, 1), 0.0),
             "Quartic Hess vanishes at min");
      Check (Approx (Quartic_1D ([4.0]), 1.0), "Quartic(4)=1");
      Check (Approx (Quartic_1D_Grad ([4.0]) (1), 4.0), "Quartic grad(4)");
      Check (Approx (Quartic_1D_Hess ([4.0]) (1, 1), 12.0), "Quartic Hess(4)");
      Check (Approx (Shifted_Sphere (M1), 0.0), "Shifted at ones");
      Check (Point_Near (Shifted_Sphere_Grad (M1), Z2), "Shifted grad at min");
      Check (Approx (Shifted_Sphere_Hess (M1) (1, 1), 2.0), "Shifted Hess");
      begin
         declare
            Unused : Real := Rosenbrock ([1.0]);
         begin
            Check (Unused = Unused and then False, "Rosenbrock 1-D should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Rosenbrock raises on dim < 2");
      end;
      begin
         declare
            Unused : Real := Himmelblau ([1.0]);
         begin
            Check (Unused = Unused and then False, "Himmelblau 1-D should raise");
         end;
      exception
         when Invalid_Argument =>
            Check (True, "Himmelblau raises on dim < 2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Pure Newton: Quadratic_Bowl in one step");
   ---------------------------------------------------------------------
   declare
      R : Result;
      X0 : constant Point (1 .. 3) := [4.0, -2.0, 1.5];
   begin
      R := Minimize
        (Quadratic_Bowl'Access, X0,
         Quadratic_Bowl_Grad'Access, Quadratic_Bowl_Hess'Access,
         Pure_Cfg);
      Check (R.Success, "Bowl pure Newton success");
      Check (R.Iterations <= 1, "Bowl pure Newton ≤ 1 iteration");
      Check (Approx (R.Final_Value, 0.0, 1.0E-10), "Bowl final f ≈ 0");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-10)
             and then Approx (R.Final_Point (2), 0.0, 1.0E-10)
             and then Approx (R.Final_Point (3), 0.0, 1.0E-10),
             "Bowl final x ≈ 0");
      Check (R.Final_Grad_Norm <= 1.0E-10, "Bowl final ‖g‖ tiny");
      Check (not R.Regularized, "Bowl no regularization needed");
   end;

   ---------------------------------------------------------------------
   Section ("9. Pure Newton: Sphere / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Minimize
        (Sphere'Access, [3.0, -4.0],
         Sphere_Grad'Access, Sphere_Hess'Access, Pure_Cfg);
      Check (R.Success, "Sphere pure Newton success");
      Check (R.Iterations <= 1, "Sphere ≤ 1 iter (quadratic)");
      Check (Approx (R.Final_Value, 0.0, 1.0E-10), "Sphere f≈0");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-10)
             and then Approx (R.Final_Point (2), 0.0, 1.0E-10),
             "Sphere x≈0");

      R := Minimize
        (Shifted_Sphere'Access, [0.0, 0.0, 0.0],
         Shifted_Sphere_Grad'Access, Shifted_Sphere_Hess'Access,
         Pure_Cfg);
      Check (R.Success, "Shifted pure Newton success");
      Check (R.Iterations <= 1, "Shifted ≤ 1 iter");
      Check (Approx (R.Final_Point (1), 1.0, 1.0E-10)
             and then Approx (R.Final_Point (2), 1.0, 1.0E-10)
             and then Approx (R.Final_Point (3), 1.0, 1.0E-10),
             "Shifted → ones");
   end;

   ---------------------------------------------------------------------
   Section ("10. Damped Newton: Rosenbrock / Himmelblau");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Cfg : Config := Damped_Cfg;
   begin
      Cfg.Max_Iterations := 80;
      R := Minimize
        (Rosenbrock'Access, [-1.2, 1.0],
         Rosenbrock_Grad'Access, Rosenbrock_Hess'Access, Cfg);
      Check (R.Success, "Rosenbrock damped success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Rosenbrock f≈0");
      Check (Approx (R.Final_Point (1), 1.0, 1.0E-4)
             and then Approx (R.Final_Point (2), 1.0, 1.0E-4),
             "Rosenbrock → (1,1)");

      R := Minimize
        (Himmelblau'Access, [1.0, 1.0],
         Himmelblau_Grad'Access, Himmelblau_Hess'Access, Cfg);
      Check (R.Success, "Himmelblau damped success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Himmelblau f≈0");
      Check (R.Final_Grad_Norm <= 1.0E-5, "Himmelblau ‖g‖ small");
   end;

   ---------------------------------------------------------------------
   Section ("11. FD-only Minimize (null Grad/Hess)");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Cfg : Config := Damped_Cfg;
   begin
      Cfg.Max_Iterations := 40;
      R := Minimize (Sphere'Access, [2.0, -1.0], null, null, Cfg);
      Check (R.Success, "Sphere FD Minimize success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Sphere FD f≈0");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-4)
             and then Approx (R.Final_Point (2), 0.0, 1.0E-4),
             "Sphere FD x≈0");

      R := Minimize
        (Quadratic_Bowl'Access, [1.0, -1.0], null, null, Pure_Cfg);
      Check (R.Success, "Bowl FD pure success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-5), "Bowl FD f≈0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Quartic_1D with regularization / damping");
   ---------------------------------------------------------------------
   declare
      R : Result;
      Cfg : Config := Damped_Cfg;
   begin
      --  Start away from the flat minimizer; Hessian is PD there.
      Cfg.Max_Iterations := 100;
      Cfg.Grad_Tol := 1.0E-6;
      R := Minimize
        (Quartic_1D'Access, [5.0],
         Quartic_1D_Grad'Access, Quartic_1D_Hess'Access, Cfg);
      Check (R.Success, "Quartic damped success");
      Check (Approx (R.Final_Point (1), 3.0, 5.0E-3), "Quartic → 3");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Quartic f≈0");

      --  Near-singular start: regularization should engage.
      Cfg.Hessian_Regularization := True;
      R := Minimize
        (Quartic_1D'Access, [3.05],
         Quartic_1D_Grad'Access, Quartic_1D_Hess'Access, Cfg);
      Check (R.Success or else Approx (R.Final_Point (1), 3.0, 0.1),
             "Quartic near-min progresses toward 3");
   end;

   ---------------------------------------------------------------------
   Section ("13. Pure vs damped config flags");
   ---------------------------------------------------------------------
   declare
      R1, R2 : Result;
      C_Pure : Config := Pure_Cfg;
      C_Damp : Config := Damped_Cfg;
   begin
      C_Pure.Use_Line_Search := False;
      C_Damp.Use_Line_Search := True;
      R1 := Minimize
        (Sphere'Access, [1.0], Sphere_Grad'Access, Sphere_Hess'Access,
         C_Pure);
      R2 := Minimize
        (Sphere'Access, [1.0], Sphere_Grad'Access, Sphere_Hess'Access,
         C_Damp);
      Check (R1.Success and then R2.Success, "both configs succeed Sphere 1-D");
      Check (Approx (R1.Final_Point (1), 0.0, 1.0E-8), "pure → 0");
      Check (Approx (R2.Final_Point (1), 0.0, 1.0E-8), "damped → 0");
      Check (Default_Config.Use_Line_Search, "default uses line search");
      Check (Default_Config.Hessian_Regularization,
             "default enables Hessian regularization");
      Check (Default_Config.Max_Iterations = 100, "default Max_Iterations");
   end;

   ---------------------------------------------------------------------
   Section ("14. Himmelblau analytical Hessian vs FD");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.5, -0.5];
      Ha, Hn : Matrix (1 .. 2, 1 .. 2);
      Ga, Gn : Point (1 .. 2);
   begin
      Ga := Himmelblau_Grad (X);
      Gn := Finite_Difference_Gradient (Himmelblau'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-4), "Himmelblau FD grad");
      Ha := Himmelblau_Hess (X);
      Hn := Finite_Difference_Hessian (Himmelblau'Access, X);
      Check (Approx (Ha (1, 2), Ha (2, 1), 1.0E-12), "Himmelblau Hess sym");
      Check (Approx (Hn (1, 1), Ha (1, 1), 0.1)
             and then Approx (Hn (2, 2), Ha (2, 2), 0.1),
             "Himmelblau FD Hess approx");
      Check (Is_Symmetric (Ha), "Himmelblau Hess Is_Symmetric");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra coverage / edge cases");
   ---------------------------------------------------------------------
   declare
      R : Result;
      H : Matrix (1 .. 1, 1 .. 1);
      P : Point (1 .. 1);
      I1 : constant Matrix := Identity (1);
   begin
      Check (Approx (I1 (1, 1), 1.0), "Identity 1");
      Check (Is_Positive_Definite_Ish (I1), "1×1 I is PD");
      H := [[-0.5]];
      Check (not Is_Positive_Definite_Ish (H), "1×1 negative not PD");
      H := Regularize_Hessian (H, 1.0);
      Check (Is_Positive_Definite_Ish (H), "1×1 regularized PD");
      Check (Approx (Norm2 ([0.0, 0.0, 0.0]), 0.0), "Norm2 3-zero");
      Check (Approx (Sphere ([1.0]), 1.0), "Sphere 1-D");
      Check (Approx (Rosenbrock ([1.0, 1.0]), 0.0), "Rosenbrock min again");
      Check (Approx (Quadratic_Bowl ([0.0]), 0.0), "Bowl 1-D at 0");
      R := Minimize
        (Quadratic_Bowl'Access, [7.0],
         Quadratic_Bowl_Grad'Access, Quadratic_Bowl_Hess'Access,
         Pure_Cfg);
      Check (R.Success and then R.Iterations <= 1, "Bowl 1-D one Newton step");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-10), "Bowl 1-D → 0");
      P := Newton_Direction (Identity (1), [5.0]);
      Check (Approx (P (1), -5.0), "Newton_Direction 1-D I");
      Check (Approx (Quadratic_Form ([[4.0]], [3.0]), 36.0),
             "Quadratic_Form 1-D");
      Check (R.Dim = 1, "Result.Dim = 1");
      Check (not Near (0.0, 1.0), "Near false pair");
      Check (Point_Near ([1.0], [1.0 + 1.0E-12], 1.0E-9),
             "Point_Near 1-D loose");
      Check (Approx (Mat_Scale (0.0, Identity (2)) (1, 1), 0.0),
             "Mat_Scale zero");
      Check (Approx (Mat_Add (Identity (2), Mat_Scale (-1.0, Identity (2)))
                       (1, 1), 0.0),
             "Mat_Add I + (−I) = 0");
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
