--  Standalone test suite for BFGS (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with BFGS;        use BFGS;

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
      Grad_Tol        => 1.0E-8,
      Step_Tol        => 1.0E-10,
      Fd_Eps          => 1.0E-7,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 30,
      Scale_Initial_H => True);

begin
   Put_Line ("BFGS test suite");
   Put_Line ("===============");

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
      Check (Approx (Dot (A, C), 1.0 * 1.0 + 2.0 * 3.0), "Dot product");
      S := Add (A, C);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 5.0), "Add");
      S := Sub (C, A);
      Check (Approx (S (1), 0.0) and then Approx (S (2), 1.0), "Sub");
      S := Scale (2.0, A);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 4.0), "Scale");
      Check (Approx (Dot (A, A), 5.0), "Dot self = ||A||^2");
      Check (Approx (Real (Norm2 (A)) ** 2, 5.0, 1.0E-12),
             "Norm2(1,2)^2 = 5");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Outer / Mat_Vec / Mat_Add / Mat_Scale");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      I3 : constant Matrix := Identity (3);
      U  : constant Point (1 .. 2) := [2.0, 0.0];
      V  : constant Point (1 .. 2) := [3.0, 4.0];
      M  : Matrix (1 .. 2, 1 .. 2);
      W  : Point (1 .. 2);
      X  : constant Point (1 .. 2) := [1.0, 1.0];
   begin
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0),
             "Identity 2 diag");
      Check (Approx (I2 (1, 2), 0.0) and then Approx (I2 (2, 1), 0.0),
             "Identity 2 off-diag");
      Check (Approx (I3 (3, 3), 1.0) and then Approx (I3 (1, 3), 0.0),
             "Identity 3 corners");
      M := Outer (U, V);
      Check (Approx (M (1, 1), 6.0) and then Approx (M (1, 2), 8.0),
             "Outer row1");
      Check (Approx (M (2, 1), 0.0) and then Approx (M (2, 2), 0.0),
             "Outer row2");
      W := Mat_Vec (I2, V);
      Check (Point_Near (W, V, 1.0E-12), "Mat_Vec I·v = v");
      W := Mat_Vec (M, X);
      Check (Approx (W (1), 14.0) and then Approx (W (2), 0.0),
             "Mat_Vec Outer·(1,1)");
      M := Mat_Add (I2, I2);
      Check (Approx (M (1, 1), 2.0) and then Approx (M (2, 2), 2.0),
             "Mat_Add I+I");
      M := Mat_Scale (0.5, M);
      Check (Approx (M (1, 1), 1.0) and then Approx (M (1, 2), 0.0),
             "Mat_Scale half");
   end;

   ---------------------------------------------------------------------
   Section ("3. Armijo_Accept predicate");
   ---------------------------------------------------------------------
   begin
      --  Descent Dir_Deriv = -10; α=1, c1=0.1 → RHS = F_Old - 1
      Check (Armijo_Accept (9.0, 10.0, 1.0, 0.1, -10.0),
             "Armijo accept exact boundary interior");
      Check (Armijo_Accept (9.0, 10.0, 1.0, 0.1, -10.0),
             "Armijo F_New = F_Old + c1 α gTp (=9)");
      Check (not Armijo_Accept (9.5, 10.0, 1.0, 0.1, -10.0),
             "Armijo reject insufficient decrease");
      Check (Armijo_Accept (0.0, 10.0, 0.5, 1.0E-4, -100.0),
             "Armijo large decrease accepted");
      Check (Armijo_Accept (10.0, 10.0, 1.0, 0.1, 0.0),
             "Armijo flat direction equality");
   end;

   ---------------------------------------------------------------------
   Section ("4. BFGS_Update identities and curvature skip");
   ---------------------------------------------------------------------
   declare
      H0 : constant Matrix := Identity (2);
      S  : Point (1 .. 2);
      Y  : Point (1 .. 2);
      H1 : Matrix (1 .. 2, 1 .. 2);
      Hs : Point (1 .. 2);
      Ys : Real;
   begin
      --  Exact quadratic f=½ xᵀx → Hessian = I, so for s=y the inverse
      --  Hessian should stay near I after update from I.
      S := [1.0, 0.0];
      Y := [1.0, 0.0];  -- y = B s with B = I
      H1 := BFGS_Update (H0, S, Y);
      Hs := Mat_Vec (H1, S);
      Check (Point_Near (Hs, S, 1.0E-9), "BFGS secant: H+ s ≈ s when y=s");
      Check (Approx (H1 (1, 1), 1.0, 1.0E-9), "BFGS H11≈1 for y=s");
      Check (Approx (H1 (2, 2), 1.0, 1.0E-9), "BFGS H22≈1 for y=s");
      Check (Approx (H1 (1, 2), 0.0, 1.0E-9), "BFGS H12≈0 for y=s");

      --  Curvature skip: yᵀs ≤ 0 → H unchanged
      S := [1.0, 0.0];
      Y := [-1.0, 0.0];
      Ys := Dot (Y, S);
      Check (Ys < 0.0, "curvature yᵀs negative setup");
      H1 := BFGS_Update (H0, S, Y);
      Check (Approx (H1 (1, 1), 1.0) and then Approx (H1 (2, 2), 1.0),
             "curvature skip keeps H=I diag");
      Check (Approx (H1 (1, 2), 0.0) and then Approx (H1 (2, 1), 0.0),
             "curvature skip keeps H=I off");

      --  yᵀs = 0 also skipped
      Y := [0.0, 1.0];
      S := [1.0, 0.0];
      Check (Approx (Dot (Y, S), 0.0), "curvature yᵀs=0 setup");
      H1 := BFGS_Update (H0, S, Y);
      Check (Approx (H1 (1, 1), 1.0) and then Approx (H1 (2, 2), 1.0),
             "curvature skip on yᵀs=0");

      --  General positive-curvature step: H should satisfy H y ≈ s
      --  (secant for inverse Hessian) when starting from I and y≠s.
      S := [2.0, 1.0];
      Y := [1.0, 0.5];  -- y = 0.5 s → consistent with B=0.5 I, H=2 I
      H1 := BFGS_Update (H0, S, Y);
      Hs := Mat_Vec (H1, Y);
      Check (Point_Near (Hs, S, 1.0E-8), "BFGS inverse secant H y ≈ s");
      Check (Dot (Y, S) > 0.0, "positive curvature for general step");

      --  Symmetry of H after update
      Check (Approx (H1 (1, 2), H1 (2, 1), 1.0E-10),
             "BFGS update preserves symmetry");

      --  1-D update: H0=1, s=2, y=1 → H = s/y = 2
      declare
         H1d : constant Matrix (1 .. 1, 1 .. 1) := Identity (1);
         S1  : constant Point (1 .. 1) := [2.0];
         Y1  : constant Point (1 .. 1) := [1.0];
         Hu  : Matrix (1 .. 1, 1 .. 1);
      begin
         Hu := BFGS_Update (H1d, S1, Y1);
         Check (Approx (Hu (1, 1), 2.0, 1.0E-10),
                "1-D BFGS: H ← s/y = 2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Finite_Difference_Gradient vs analytical");
   ---------------------------------------------------------------------
   declare
      X2 : constant Point (1 .. 2) := [0.5, -0.3];
      X3 : constant Point (1 .. 3) := [1.0, -2.0, 0.5];
      Ga, Gf : Point (1 .. 2);
      G3a, G3f : Point (1 .. 3);
   begin
      Ga := Sphere_Grad (X2);
      Gf := Finite_Difference_Gradient (Sphere'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-5), "FD≈analytical Sphere 2D");

      Ga := Rosenbrock_Grad (X2);
      Gf := Finite_Difference_Gradient (Rosenbrock'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-4), "FD≈analytical Rosenbrock");

      Ga := Himmelblau_Grad (X2);
      Gf := Finite_Difference_Gradient (Himmelblau'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-4), "FD≈analytical Himmelblau");

      Ga := Quadratic_Bowl_Grad (X2);
      Gf := Finite_Difference_Gradient (Quadratic_Bowl'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-5), "FD≈analytical Quadratic_Bowl 2D");

      G3a := Quadratic_Bowl_Grad (X3);
      G3f := Finite_Difference_Gradient (Quadratic_Bowl'Access, X3);
      Check (Point_Near (G3a, G3f, 1.0E-5), "FD≈analytical Quadratic_Bowl 3D");

      G3a := Sphere_Grad (X3);
      G3f := Finite_Difference_Gradient (Sphere'Access, X3);
      Check (Point_Near (G3a, G3f, 1.0E-5), "FD≈analytical Sphere 3D");

      Ga := Shifted_Sphere_Grad (X2);
      Gf := Finite_Difference_Gradient (Shifted_Sphere'Access, X2);
      Check (Point_Near (Ga, Gf, 1.0E-5), "FD≈analytical Shifted_Sphere");

      --  At origin Sphere grad is zero
      Ga := Sphere_Grad ([0.0, 0.0]);
      Check (Approx (Real (Norm2 (Ga)), 0.0), "Sphere grad at 0 is 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Demo objective values at known points");
   ---------------------------------------------------------------------
   declare
      Z  : constant Point (1 .. 2) := [0.0, 0.0];
      R1 : constant Point (1 .. 2) := [1.0, 1.0];
      Hb : constant Point (1 .. 2) := [3.0, 2.0];  -- one Himmelblau min
      Ss : constant Point (1 .. 3) := [1.0, 1.0, 1.0];
   begin
      Check (Approx (Sphere (Z), 0.0), "Sphere(0)=0");
      Check (Approx (Sphere ([3.0, 4.0]), 25.0), "Sphere(3,4)=25");
      Check (Approx (Rosenbrock (R1), 0.0), "Rosenbrock(1,1)=0");
      Check (Rosenbrock (Z) > 0.0, "Rosenbrock(0,0)>0");
      Check (Approx (Quadratic_Bowl (Z), 0.0), "Quadratic_Bowl(0)=0");
      Check (Approx (Himmelblau (Hb), 0.0, 1.0E-10), "Himmelblau(3,2)=0");
      Check (Approx (Shifted_Sphere (Ss), 0.0), "Shifted_Sphere(1..)=0");
      Check (Approx (Shifted_Sphere (Z), 2.0), "Shifted_Sphere(0)=2 for n=2");
      Check (Approx (Sphere_Grad (R1) (1), 2.0), "Sphere_Grad(1,1)_x=2");
      Check (Approx (Sphere_Grad (R1) (2), 2.0), "Sphere_Grad(1,1)_y=2");
      Check (Approx (Real (Norm2 (Rosenbrock_Grad (R1))), 0.0, 1.0E-12),
             "Rosenbrock grad at min is 0");
      Check (Approx (Real (Norm2 (Himmelblau_Grad (Hb))), 0.0, 1.0E-10),
             "Himmelblau grad at (3,2) is 0");
   end;

   ---------------------------------------------------------------------
   Section ("7. Line_Search Armijo on Sphere");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [2.0, 0.0];
      G : constant Point (1 .. 2) := Sphere_Grad (X);
      P : constant Point (1 .. 2) := Scale (-1.0, G);  -- steepest descent
      F : constant Real := Sphere (X);
      A : Positive_Real;
   begin
      A := Line_Search
        (Sphere'Access, X, F, G, P, 1.0E-4, 0.5, 30);
      Check (A > 0.0, "Line_Search returns positive α");
      Check (Sphere (Add (X, Scale (A, P))) < F,
             "Line_Search reduces Sphere");
      Check (Armijo_Accept
               (Sphere (Add (X, Scale (A, P))), F, A, 1.0E-4, Dot (G, P)),
             "accepted α satisfies Armijo");
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize Sphere (analytical + FD)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [3.0, -4.0];
      Ra, Rf : Result;
      Cfg : constant Config := Default_Cfg;
   begin
      Ra := Minimize (Sphere'Access, X0, Sphere_Grad'Access, Cfg);
      Check (Ra.Success, "Sphere analytical Success");
      Check (Approx (Ra.Final_Value, 0.0, 1.0E-10), "Sphere analytical f≈0");
      Check (Point_Near
               (Ra.Final_Point (1 .. 2), [0.0, 0.0], 1.0E-5),
             "Sphere analytical x≈0");
      Check (Ra.Final_Grad_Norm <= Cfg.Grad_Tol * 10.0
               or else Ra.Final_Grad_Norm <= 1.0E-6,
             "Sphere analytical ‖g‖ small");
      Check (Ra.Iterations >= 1, "Sphere analytical iters≥1");
      Check (Ra.Dim = 2, "Sphere Dim=2");

      Rf := Minimize (Sphere'Access, X0, null, Cfg);
      Check (Rf.Success, "Sphere FD Success");
      Check (Approx (Rf.Final_Value, 0.0, 1.0E-8), "Sphere FD f≈0");
      Check (Point_Near
               (Rf.Final_Point (1 .. 2), [0.0, 0.0], 1.0E-4),
             "Sphere FD x≈0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Minimize Rosenbrock");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [-1.2, 1.0];
      R  : Result;
      Cfg : Config := Default_Cfg;
   begin
      Cfg.Max_Iterations := 500;
      R := Minimize
        (Rosenbrock'Access, X0, Rosenbrock_Grad'Access, Cfg);
      Check (R.Success, "Rosenbrock Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8), "Rosenbrock f≈0");
      Check (Approx (R.Final_Point (1), 1.0, 1.0E-4), "Rosenbrock x≈1");
      Check (Approx (R.Final_Point (2), 1.0, 1.0E-4), "Rosenbrock y≈1");
      Check (R.Iterations < Cfg.Max_Iterations, "Rosenbrock before max iters");
   end;

   ---------------------------------------------------------------------
   Section ("10. Minimize Quadratic_Bowl / Shifted_Sphere / Himmelblau");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 3) := [2.0, -1.0, 3.0];
      Xs : constant Point (1 .. 2) := [0.0, 0.0];
      Xh : constant Point (1 .. 2) := [1.0, 1.0];  -- toward (3,2) basin
      R  : Result;
      Cfg : Config := Default_Cfg;
   begin
      R := Minimize
        (Quadratic_Bowl'Access, X0, Quadratic_Bowl_Grad'Access, Cfg);
      Check (R.Success, "Quadratic_Bowl Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-10), "Quadratic_Bowl f≈0");
      Check (Point_Near
               (R.Final_Point (1 .. 3), [0.0, 0.0, 0.0], 1.0E-5),
             "Quadratic_Bowl x≈0");
      Check (R.Dim = 3, "Quadratic_Bowl Dim=3");

      R := Minimize
        (Shifted_Sphere'Access, Xs, Shifted_Sphere_Grad'Access, Cfg);
      Check (R.Success, "Shifted_Sphere Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-10), "Shifted_Sphere f≈0");
      Check (Point_Near
               (R.Final_Point (1 .. 2), [1.0, 1.0], 1.0E-5),
             "Shifted_Sphere x≈1");

      Cfg.Max_Iterations := 300;
      R := Minimize
        (Himmelblau'Access, Xh, Himmelblau_Grad'Access, Cfg);
      Check (R.Success, "Himmelblau Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Himmelblau f≈0");
      Check (R.Final_Grad_Norm <= 1.0E-5, "Himmelblau ‖g‖ small");
   end;

   ---------------------------------------------------------------------
   Section ("11. Already at optimum / 1-D / config edges");
   ---------------------------------------------------------------------
   declare
      Z  : constant Point (1 .. 2) := [0.0, 0.0];
      X1 : constant Point (1 .. 1) := [5.0];
      R  : Result;
      Cfg : Config := Default_Cfg;
   begin
      R := Minimize (Sphere'Access, Z, Sphere_Grad'Access, Cfg);
      Check (R.Success, "already optimal Success");
      Check (R.Iterations = 0, "already optimal iters=0");
      Check (Approx (R.Final_Value, 0.0), "already optimal f=0");

      R := Minimize (Sphere'Access, X1, Sphere_Grad'Access, Cfg);
      Check (R.Success, "1-D Sphere Success");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-6), "1-D Sphere x≈0");
      Check (R.Dim = 1, "1-D Dim=1");

      Cfg.Scale_Initial_H := False;
      R := Minimize
        (Sphere'Access, [2.0, 2.0], Sphere_Grad'Access, Cfg);
      Check (R.Success, "no initial H-scale still Success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8), "no H-scale f≈0");

      Cfg := Default_Cfg;
      Cfg.Max_Iterations := 1;
      R := Minimize
        (Rosenbrock'Access, [-1.2, 1.0], Rosenbrock_Grad'Access, Cfg);
      --  May or may not succeed in 1 iter; just ensure it runs
      Check (R.Iterations <= 1, "Max_Iterations=1 respected");
      Check (R.Dim = 2, "short-run Dim=2");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra BFGS / Mat_Vec / objective sanity");
   ---------------------------------------------------------------------
   declare
      H : Matrix (1 .. 2, 1 .. 2);
      S : constant Point (1 .. 2) := [0.5, -0.25];
      Y : constant Point (1 .. 2) := [1.0, -0.5];
      V : Point (1 .. 2);
      A : Matrix (1 .. 2, 1 .. 2);
   begin
      H := Identity (2);
      H := BFGS_Update (H, S, Y);
      V := Mat_Vec (H, Y);
      Check (Point_Near (V, S, 1.0E-8), "second inverse-secant check");
      Check (Approx (H (1, 2), H (2, 1), 1.0E-12), "symmetry again");

      A := Mat_Scale (3.0, Identity (2));
      V := Mat_Vec (A, [1.0, 2.0]);
      Check (Approx (V (1), 3.0) and then Approx (V (2), 6.0),
             "Mat_Vec (3I)·v");

      Check (Quadratic_Bowl ([1.0, 0.0]) > 0.0, "bowl positive off origin");
      Check (Approx (Quadratic_Bowl_Grad ([1.0, 0.0]) (1), 1.0),
             "bowl grad ∂/∂x1 = 1·x1");
      Check (Approx (Quadratic_Bowl_Grad ([0.0, 1.0]) (2), 2.0),
             "bowl grad ∂/∂x2 = 2·x2");
      Check (Approx (Himmelblau ([3.0, 2.0]), 0.0, 1.0E-12),
             "Himmelblau min again");
      Check (Approx (Himmelblau ([-2.805118, 3.131312]), 0.0, 1.0E-4),
             "Himmelblau second min ≈0");
      Check (Sphere ([1.0]) = 1.0, "Sphere 1-D");
      Check (Approx (Shifted_Sphere_Grad ([1.0, 1.0]) (1), 0.0),
             "Shifted grad at min");
      Check (Approx (Rosenbrock ([1.0, 1.0]), 0.0), "Rosenbrock min again");
      Check (not Near (1.0, 2.0, 0.1), "Near reject mid");
      Check (Near (1.0, 1.05, 0.1), "Near accept mid");
      Check (Approx (Real (Norm2 ([0.0, 0.0, 0.0])), 0.0), "Norm2 3-zero");
      Check (Approx (Dot ([1.0, 0.0, 0.0], [0.0, 1.0, 0.0]), 0.0),
             "Dot orthogonal");
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
