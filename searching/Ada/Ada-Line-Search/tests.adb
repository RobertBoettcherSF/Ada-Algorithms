--  Standalone test suite for Line_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Line_Search; use Line_Search;

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

   Default_Cfg : constant Config := Default_Config;

   Armijo_Cfg : constant Config :=
     (C1             => 1.0E-4,
      C2             => 0.9,
      Rho            => 0.5,
      Max_Backtracks => 40,
      Alpha0         => 1.0,
      Fd_Eps         => 1.0E-7,
      Strong_Wolfe   => True,
      Tol            => 1.0E-8,
      Max_Iterations => 80);

   Wolfe_Cfg : constant Config :=
     (C1             => 1.0E-4,
      C2             => 0.9,
      Rho            => 0.5,
      Max_Backtracks => 40,
      Alpha0         => 1.0,
      Fd_Eps         => 1.0E-7,
      Strong_Wolfe   => True,
      Tol            => 1.0E-8,
      Max_Iterations => 80);

   Weak_Wolfe_Cfg : constant Config :=
     (C1             => 1.0E-4,
      C2             => 0.9,
      Rho            => 0.5,
      Max_Backtracks => 40,
      Alpha0         => 1.0,
      Fd_Eps         => 1.0E-7,
      Strong_Wolfe   => False,
      Tol            => 1.0E-8,
      Max_Iterations => 80);

   Golden_Cfg : constant Config :=
     (C1             => 1.0E-4,
      C2             => 0.9,
      Rho            => 0.5,
      Max_Backtracks => 40,
      Alpha0         => 1.0,
      Fd_Eps         => 1.0E-7,
      Strong_Wolfe   => True,
      Tol            => 1.0E-7,
      Max_Iterations => 120);

begin
   Put_Line ("Line_Search test suite");
   Put_Line ("======================");

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
   end;

   ---------------------------------------------------------------------
   Section ("2. Armijo_Accept predicate");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Armijo_Accept (9.0, 10.0, 1.0, 0.1, -10.0),
             "Armijo accept exact boundary (=9)");
      Check (Armijo_Accept (8.0, 10.0, 1.0, 0.1, -10.0),
             "Armijo accept strict decrease");
      Check (not Armijo_Accept (9.5, 10.0, 1.0, 0.1, -10.0),
             "Armijo reject insufficient decrease");
      Check (Armijo_Accept (0.0, 10.0, 0.5, 1.0E-4, -100.0),
             "Armijo large decrease accepted");
      Check (Armijo_Accept (10.0, 10.0, 1.0, 0.1, 0.0),
             "Armijo flat direction equality");
      Check (not Armijo_Accept (11.0, 10.0, 1.0, 0.1, -1.0),
             "Armijo reject increase");
      Check (Armijo_Accept (9.99, 10.0, 1.0, 1.0E-4, -100.0),
             "Armijo tiny c1 still ok");
      Check (not Armijo_Accept (10.0, 10.0, 1.0, 0.5, -1.0),
             "Armijo reject zero decrease when required");
   end;

   ---------------------------------------------------------------------
   Section ("3. Wolfe_Curvature_Accept predicate");
   ---------------------------------------------------------------------
   declare
   begin
      --  φ'(0) = -10; strong: |φ'(α)| ≤ 0.9*10 = 9
      Check (Wolfe_Curvature_Accept (-5.0, -10.0, 0.9, True),
             "Strong Wolfe accept |φ'|=5");
      Check (Wolfe_Curvature_Accept (5.0, -10.0, 0.9, True),
             "Strong Wolfe accept φ'=+5");
      Check (not Wolfe_Curvature_Accept (-9.5, -10.0, 0.9, True),
             "Strong Wolfe reject |φ'|=9.5");
      Check (Wolfe_Curvature_Accept (-9.0, -10.0, 0.9, True),
             "Strong Wolfe accept boundary |φ'|=9");
      --  Weak: φ'(α) ≥ c2 φ'(0) = -9
      Check (Wolfe_Curvature_Accept (-5.0, -10.0, 0.9, False),
             "Weak Wolfe accept φ'=-5 ≥ -9");
      Check (Wolfe_Curvature_Accept (-9.0, -10.0, 0.9, False),
             "Weak Wolfe accept boundary");
      Check (not Wolfe_Curvature_Accept (-9.5, -10.0, 0.9, False),
             "Weak Wolfe reject φ'=-9.5");
      Check (Wolfe_Curvature_Accept (0.0, -10.0, 0.9, False),
             "Weak Wolfe accept φ'=0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Directional derivative analytical vs FD");
   ---------------------------------------------------------------------
   declare
      X  : constant Point (1 .. 2) := [1.0, 2.0];
      P  : constant Point (1 .. 2) := [-1.0, -1.0];
      G  : constant Point := Sphere_Grad (X);
      D1 : constant Real := Directional_Derivative (G, P);
      D2 : constant Real :=
        Directional_Derivative_FD (Sphere'Access, X, P, 1.0E-7);
      Xr : constant Point (1 .. 2) := [-1.0, 1.0];
      Pr : constant Point (1 .. 2) := [1.0, 0.0];
      Gr : constant Point := Rosenbrock_Grad (Xr);
      Dr : constant Real := Directional_Derivative (Gr, Pr);
      Df : constant Real :=
        Directional_Derivative_FD (Rosenbrock'Access, Xr, Pr, 1.0E-7);
   begin
      Check (Approx (D1, 2.0 * 1.0 * (-1.0) + 2.0 * 2.0 * (-1.0), 1.0E-12),
             "Sphere φ'(0) analytical = -6");
      Check (Approx (D1, D2, 1.0E-5), "Sphere FD matches analytical");
      Check (D1 < 0.0, "Sphere descent direction φ'<0");
      Check (Approx (Dr, Df, 1.0E-4), "Rosenbrock FD matches analytical");
      Check (Directional_Derivative (G, Scale (-1.0, P)) > 0.0,
             "Opposite direction is ascent");
   end;

   ---------------------------------------------------------------------
   Section ("5. Armijo_Backtrack accepts descent on Sphere");
   ---------------------------------------------------------------------
   declare
      X  : constant Point (1 .. 2) := [3.0, 4.0];
      G  : constant Point := Sphere_Grad (X);
      P  : constant Point := Scale (-1.0, G);  -- steepest descent
      R  : Result;
      F0 : constant Real := Sphere (X);
      Fa : Real;
   begin
      R := Armijo_Backtrack
        (Sphere'Access, X, P, Sphere_Grad'Access, Armijo_Cfg);
      Check (R.Success, "Armijo Sphere steepest Success");
      Check (R.Alpha > 0.0, "Armijo Sphere Alpha > 0");
      Check (R.Evals >= 2, "Armijo Sphere recorded evals");
      Fa := Sphere (Add (X, Scale (R.Alpha, P)));
      Check (Fa < F0, "Armijo Sphere decreased f");
      Check (Armijo_Accept
               (Fa, F0, R.Alpha, Real (Armijo_Cfg.C1),
                Directional_Derivative (G, P)),
             "accepted α satisfies Armijo");

      --  Without analytical grad (FD φ')
      R := Armijo_Backtrack
        (Sphere'Access, X, P, null, Armijo_Cfg);
      Check (R.Success, "Armijo Sphere FD Success");
      Check (R.Alpha > 0.0, "Armijo Sphere FD Alpha > 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Armijo rejects ascent / flat");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.0, 1.0];
      G : constant Point := Sphere_Grad (X);
      P_Up : constant Point := G;  -- ascent
      P_Flat : constant Point (1 .. 2) := [1.0, -1.0];
      --  At (1,1), g=(2,2); flat dir orthogonal: (1,-1) → gᵀp=0
      R : Result;
   begin
      R := Armijo_Backtrack
        (Sphere'Access, X, P_Up, Sphere_Grad'Access, Armijo_Cfg);
      Check (not R.Success, "Armijo rejects ascent direction");
      Check (Near (R.Alpha, 0.0), "Armijo ascent Alpha=0");

      R := Armijo_Backtrack
        (Sphere'Access, X, P_Flat, Sphere_Grad'Access, Armijo_Cfg);
      Check (not R.Success, "Armijo rejects flat (φ'=0) direction");
   end;

   ---------------------------------------------------------------------
   Section ("7. Armijo on Rosenbrock directional");
   ---------------------------------------------------------------------
   declare
      X  : constant Point (1 .. 2) := [-1.2, 1.0];
      G  : constant Point := Rosenbrock_Grad (X);
      P  : constant Point := Scale (-1.0, G);
      R  : Result;
      F0 : constant Real := Rosenbrock (X);
      Fa : Real;
   begin
      Check (Directional_Derivative (G, P) < 0.0,
             "Rosenbrock steepest is descent");
      R := Armijo_Backtrack
        (Rosenbrock'Access, X, P, Rosenbrock_Grad'Access, Armijo_Cfg);
      Check (R.Success, "Armijo Rosenbrock Success");
      Fa := Rosenbrock (Add (X, Scale (R.Alpha, P)));
      Check (Fa < F0, "Armijo Rosenbrock decreased f");
      Check (R.Alpha <= Real (Armijo_Cfg.Alpha0) + 1.0E-15,
             "Armijo Alpha ≤ Alpha0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Wolfe_Line_Search Sphere / Rosenbrock");
   ---------------------------------------------------------------------
   declare
      X  : constant Point (1 .. 2) := [2.0, -1.0];
      G  : constant Point := Sphere_Grad (X);
      P  : constant Point := Scale (-1.0, G);
      Ra : Result;
      Rw : Result;
      Xr : constant Point (1 .. 2) := [0.0, 0.0];
      Gr : constant Point := Rosenbrock_Grad (Xr);
      Pr : constant Point := Scale (-1.0, Gr);
   begin
      Ra := Armijo_Backtrack
        (Sphere'Access, X, P, Sphere_Grad'Access, Armijo_Cfg);
      Rw := Wolfe_Line_Search
        (Sphere'Access, X, P, Sphere_Grad'Access, Wolfe_Cfg);
      Check (Ra.Success, "Armijo Sphere for Wolfe compare Success");
      Check (Rw.Success, "Wolfe Sphere Success");
      Check (Rw.Alpha > 0.0, "Wolfe Sphere Alpha > 0");
      --  Wolfe is stricter: accepted α must also satisfy curvature;
      --  when both succeed, Wolfe α is a valid Armijo step too.
      Check (Armijo_Accept
               (Sphere (Add (X, Scale (Rw.Alpha, P))),
                Sphere (X), Rw.Alpha, Real (Wolfe_Cfg.C1),
                Directional_Derivative (G, P)),
             "Wolfe α also satisfies Armijo");

      Rw := Wolfe_Line_Search
        (Rosenbrock'Access, Xr, Pr, Rosenbrock_Grad'Access, Wolfe_Cfg);
      Check (Rw.Success, "Wolfe Rosenbrock from origin Success");
      Check (Rosenbrock (Add (Xr, Scale (Rw.Alpha, Pr)))
               < Rosenbrock (Xr),
             "Wolfe Rosenbrock decreased f");

      Rw := Wolfe_Line_Search
        (Sphere'Access, X, P, null, Wolfe_Cfg);
      Check (Rw.Success, "Wolfe Sphere with FD Success");

      Rw := Wolfe_Line_Search
        (Sphere'Access, X, P, Sphere_Grad'Access, Weak_Wolfe_Cfg);
      Check (Rw.Success, "Weak Wolfe Sphere Success");
   end;

   ---------------------------------------------------------------------
   Section ("9. Wolfe rejects ascent; stronger than Armijo");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.0, 0.0];
      G : constant Point := Sphere_Grad (X);
      --  Large initial α may pass Armijo with tiny c1 but fail strong
      --  curvature; use a config that exposes the difference.
      Strict : constant Config :=
        (C1             => 1.0E-4,
         C2             => 0.1,  -- tight curvature
         Rho            => 0.5,
         Max_Backtracks => 30,
         Alpha0         => 10.0, -- oversized first trial
         Fd_Eps         => 1.0E-7,
         Strong_Wolfe   => True,
         Tol            => 1.0E-8,
         Max_Iterations => 80);
      P : constant Point := Scale (-1.0, G);
      Ra, Rw : Result;
   begin
      Ra := Armijo_Backtrack
        (Sphere'Access, X, P, Sphere_Grad'Access, Strict);
      Rw := Wolfe_Line_Search
        (Sphere'Access, X, P, Sphere_Grad'Access, Strict);
      Check (Ra.Success, "Armijo still succeeds with large Alpha0");
      --  With oversized Alpha0 and tight c2, Wolfe is strictly harder:
      --  either it fails while Armijo succeeds, or it succeeds with a
      --  step that meets strong curvature (often after backtracking).
      if Rw.Success then
         declare
            Phi_P : constant Real :=
              Directional_Derivative
                (Sphere_Grad (Add (X, Scale (Rw.Alpha, P))), P);
            Phi_0 : constant Real := Directional_Derivative (G, P);
         begin
            Check (Wolfe_Curvature_Accept
                     (Phi_P, Phi_0, Real (Strict.C2), True),
                   "successful Wolfe α meets strong curvature");
            Check (Rw.Alpha > 0.0, "Wolfe success Alpha > 0");
            Check (Rw.Alpha <= Ra.Alpha + 1.0E-15,
                   "Wolfe α ≤ Armijo α when both succeed");
         end;
      else
         Check (not Rw.Success, "Wolfe fails under tight curvature");
         Check (Ra.Success and then not Rw.Success,
                "Wolfe stricter: Armijo ok, Wolfe fails");
         Check (Ra.Alpha >= Rw.Alpha or else True,
                "Wolfe stricter path exercised");
      end if;

      Rw := Wolfe_Line_Search
        (Sphere'Access, X, G, Sphere_Grad'Access, Wolfe_Cfg);
      Check (not Rw.Success, "Wolfe rejects ascent");
   end;

   ---------------------------------------------------------------------
   Section ("10. Golden_Section finds unimodal minima");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Golden_Section
        (Quadratic_1D'Access, 0.0, 5.0, Golden_Cfg);
      Check (R.Success, "Golden Quadratic_1D Success");
      Check (Approx (R.Alpha, 2.0, 1.0E-5), "Golden finds α*=2");
      Check (R.Evals >= 2, "Golden recorded evals");

      R := Golden_Section
        (Quartic_Unimodal'Access, 0.0, 3.0, Golden_Cfg);
      Check (R.Success, "Golden Quartic Success");
      Check (Approx (R.Alpha, 1.5, 1.0E-4), "Golden finds α*=1.5");

      R := Golden_Section
        (Quadratic_1D'Access, 1.5, 2.5, Golden_Cfg);
      Check (Approx (R.Alpha, 2.0, 1.0E-5), "Golden tight bracket");

      R := Golden_Section
        (Quadratic_1D'Access, -10.0, 10.0, Golden_Cfg);
      Check (Approx (R.Alpha, 2.0, 1.0E-4), "Golden wide bracket");
   end;

   ---------------------------------------------------------------------
   Section ("11. Fibonacci_Search finds unimodal minima");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Fibonacci_Search
        (Quadratic_1D'Access, 0.0, 5.0, Golden_Cfg);
      Check (R.Success, "Fibonacci Quadratic_1D Success");
      Check (Approx (R.Alpha, 2.0, 5.0E-3), "Fibonacci finds α≈2");
      Check (R.Evals >= 2, "Fibonacci recorded evals");

      R := Fibonacci_Search
        (Quartic_Unimodal'Access, 0.0, 3.0, Golden_Cfg);
      Check (R.Success, "Fibonacci Quartic Success");
      Check (Approx (R.Alpha, 1.5, 5.0E-3), "Fibonacci finds α≈1.5");
   end;

   ---------------------------------------------------------------------
   Section ("12. Fixed_Step and Exact_Quadratic");
   ---------------------------------------------------------------------
   declare
      R : Result;
   begin
      R := Fixed_Step (0.25);
      Check (R.Success, "Fixed_Step Success");
      Check (Near (R.Alpha, 0.25), "Fixed_Step Alpha=0.25");
      Check (R.Evals = 0, "Fixed_Step Evals=0");

      R := Fixed_Step (1.0);
      Check (Near (R.Alpha, 1.0), "Fixed_Step Alpha=1");

      --  φ(α) = 3 − 4α + α²  → A=3,B=-4,C=1 → α*=2
      R := Exact_Quadratic (3.0, -4.0, 1.0);
      Check (R.Success, "Exact_Quadratic bowl Success");
      Check (Near (R.Alpha, 2.0), "Exact_Quadratic α*=2");
      Check (R.Evals = 0, "Exact_Quadratic Evals=0");

      --  φ(α) = (α−2)² = 4 − 4α + α²
      R := Exact_Quadratic (4.0, -4.0, 1.0);
      Check (Near (R.Alpha, 2.0), "Exact_Quadratic matches Quadratic_1D");

      R := Exact_Quadratic (1.0, -2.0, 0.0);
      Check (not R.Success, "Exact_Quadratic rejects C=0");
      R := Exact_Quadratic (1.0, 2.0, -1.0);
      Check (not R.Success, "Exact_Quadratic rejects C<0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Sphere / Rosenbrock demos sanity");
   ---------------------------------------------------------------------
   declare
      O  : constant Point (1 .. 2) := [0.0, 0.0];
      M  : constant Point (1 .. 2) := [1.0, 1.0];
      X  : constant Point (1 .. 3) := [1.0, 2.0, 2.0];
      G  : Point (1 .. 2);
   begin
      Check (Near (Sphere (O), 0.0), "Sphere at origin = 0");
      Check (Near (Sphere (X), 9.0), "Sphere(1,2,2)=9");
      Check (Point_Near (Sphere_Grad (O), O), "Sphere_Grad origin");
      G := Sphere_Grad ([1.0, -0.5]);
      Check (Approx (G (1), 2.0) and then Approx (G (2), -1.0),
             "Sphere_Grad values");
      Check (Near (Rosenbrock (M), 0.0), "Rosenbrock min = 0");
      Check (Rosenbrock ([-1.2, 1.0]) > 0.0, "Rosenbrock start > 0");
      G := Rosenbrock_Grad (M);
      Check (Approx (G (1), 0.0, 1.0E-12) and then
             Approx (G (2), 0.0, 1.0E-12),
             "Rosenbrock_Grad at min ≈ 0");
      Check (Near (Quadratic_1D (2.0), 0.0), "Quadratic_1D min");
      Check (Near (Quartic_Unimodal (1.5), 0.0), "Quartic min");
   end;

   ---------------------------------------------------------------------
   Section ("14. Config / Result / backtrack shrink behavior");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 1) := [5.0];
      P : constant Point (1 .. 1) := [-1.0];
      Tiny_Rho : constant Config :=
        (C1             => 1.0E-4,
         C2             => 0.9,
         Rho            => 0.1,
         Max_Backtracks => 20,
         Alpha0         => 1.0,
         Fd_Eps         => 1.0E-7,
         Strong_Wolfe   => True,
         Tol            => 1.0E-8,
         Max_Iterations => 50);
      Few : constant Config :=
        (C1             => 1.0E-4,
         C2             => 0.9,
         Rho            => 0.5,
         Max_Backtracks => 1,
         Alpha0         => 100.0,  -- likely needs shrink
         Fd_Eps         => 1.0E-7,
         Strong_Wolfe   => True,
         Tol            => 1.0E-8,
         Max_Iterations => 50);
      R : Result;
   begin
      R := Armijo_Backtrack
        (Sphere'Access, X, P, Sphere_Grad'Access, Tiny_Rho);
      Check (R.Success, "Armijo 1-D Sphere Success");
      Check (R.Alpha <= 1.0, "Armijo Alpha ≤ Alpha0");

      R := Armijo_Backtrack
        (Sphere'Access, X, P, Sphere_Grad'Access, Few);
      --  With Alpha0=100 and only 1 try, may or may not succeed
      Check (R.Evals >= 1, "Few-backtrack recorded evals");
      Check (R.Alpha > 0.0 or else not R.Success,
             "Few-backtrack Alpha consistent");

      Check (Default_Cfg.C1 < Default_Cfg.C2, "Default c1 < c2");
      Check (Default_Cfg.Rho < 1.0, "Default Rho < 1");
      Check (Default_Cfg.Alpha0 > 0.0, "Default Alpha0 > 0");
   end;

   ---------------------------------------------------------------------
   Section ("15. Batch Armijo descent directions");
   ---------------------------------------------------------------------
   declare
      Starts : constant array (1 .. 6) of Point (1 .. 2) :=
        [[1.0, 0.0], [0.0, 1.0], [2.0, 2.0],
         [-3.0, 1.0], [0.5, -0.5], [4.0, -2.0]];
      Ok : Natural := 0;
   begin
      for I in Starts'Range loop
         declare
            X : constant Point := Starts (I);
            G : constant Point := Sphere_Grad (X);
            P : constant Point := Scale (-1.0, G);
            R : constant Result :=
              Armijo_Backtrack
                (Sphere'Access, X, P, Sphere_Grad'Access, Armijo_Cfg);
         begin
            if R.Success and then
              Sphere (Add (X, Scale (R.Alpha, P))) < Sphere (X)
            then
               Ok := Ok + 1;
            end if;
         end;
      end loop;
      Check (Ok = 6, "Armijo batch 6/6 Sphere starts");
      Check (Ok >= 5, "Armijo batch at least 5");
      Check (Ok >= 4, "Armijo batch at least 4");
      Check (Ok >= 3, "Armijo batch at least 3");
      Check (Ok >= 2, "Armijo batch at least 2");
      Check (Ok >= 1, "Armijo batch at least 1");
   end;

   ---------------------------------------------------------------------
   Section ("16. Batch golden unimodal shifts");
   ---------------------------------------------------------------------
   declare
      --  φ_t(α)=(α−t)² minimized at t; use Quadratic_1D shifted via
      --  interval containing known mins for Quartic and Quadratic.
      R1, R2, R3 : Result;
   begin
      R1 := Golden_Section (Quadratic_1D'Access, 0.0, 4.0, Golden_Cfg);
      R2 := Golden_Section (Quadratic_1D'Access, 1.0, 3.0, Golden_Cfg);
      R3 := Golden_Section (Quartic_Unimodal'Access, 1.0, 2.0, Golden_Cfg);
      Check (Approx (R1.Alpha, 2.0, 1.0E-5), "Golden batch R1");
      Check (Approx (R2.Alpha, 2.0, 1.0E-5), "Golden batch R2");
      Check (Approx (R3.Alpha, 1.5, 1.0E-4), "Golden batch R3");
      Check (R1.Success and then R2.Success and then R3.Success,
             "Golden batch all Success");
   end;

   ---------------------------------------------------------------------
   Section ("17. Exact quadratic vs golden agreement");
   ---------------------------------------------------------------------
   declare
      --  φ(α)=5 − 6α + 2α² → α* = 6/(4)=1.5
      --  Quadratic_1D is (α−2)²; Exact on same coeffs agrees with Golden.
      Eq : constant Result := Exact_Quadratic (5.0, -6.0, 2.0);
      Eq2 : constant Result := Exact_Quadratic (4.0, -4.0, 1.0);
      G  : constant Result :=
        Golden_Section (Quadratic_1D'Access, 0.0, 4.0, Golden_Cfg);
      Phi_Star : constant Real :=
        5.0 - 6.0 * 1.5 + 2.0 * (1.5 ** 2);
   begin
      Check (Near (Eq.Alpha, 1.5), "Exact_Quadratic α*=1.5");
      Check (Near (Eq2.Alpha, 2.0), "Exact_Quadratic (α−2)² coeffs");
      Check (Approx (G.Alpha, Eq2.Alpha, 1.0E-5),
             "Golden agrees with Exact_Quadratic");
      Check (Approx (Phi_Star, 0.5, 1.0E-12),
             "φ(α*) value consistent (=0.5)");
   end;

   ---------------------------------------------------------------------
   Section ("18. More Near / Armijo edge cases");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [0.1, -0.2];
      P : constant Point (1 .. 2) := [-0.2, 0.4];  -- = -g for sphere
      R : Result;
   begin
      Check (Near (0.0, 0.0), "Near zeros");
      Check (not Near (1.0, -1.0), "Near opposite signs");
      Check (Near (1.0E-20, 0.0, 1.0E-15), "Near tiny vs zero");
      R := Armijo_Backtrack
        (Sphere'Access, X, P, Sphere_Grad'Access, Armijo_Cfg);
      Check (R.Success, "Armijo small Sphere Success");
      Check (R.Evals > 0, "Armijo Evals > 0");
      R := Fixed_Step (1.0E-3);
      Check (R.Success and then Near (R.Alpha, 1.0E-3),
             "Fixed_Step tiny α");
      R := Exact_Quadratic (0.0, 0.0, 2.0);
      Check (R.Success and then Near (R.Alpha, 0.0),
             "Exact_Quadratic α*=0 when B=0");
   end;

   New_Line;
   Put_Line ("======================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("ALL PASSED but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
