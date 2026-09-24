--  Standalone test suite for Gradient_Descent (main program).

pragma Ada_2022;

with Ada.Text_IO;        use Ada.Text_IO;
with Gradient_Descent;   use Gradient_Descent;

procedure Tests
  with SPARK_Mode => Off
is

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

   Fixed_Cfg : constant Config :=
     (Max_Iterations  => 500,
      Step            => 0.1,
      Grad_Tol        => 1.0E-8,
      Step_Tol        => 1.0E-12,
      Use_Line_Search => False,
      Momentum_Beta   => 0.0,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 40,
      Fd_Eps          => 1.0E-7);

   Armijo_Cfg : constant Config :=
     (Max_Iterations  => 300,
      Step            => 1.0,
      Grad_Tol        => 1.0E-8,
      Step_Tol        => 1.0E-12,
      Use_Line_Search => True,
      Momentum_Beta   => 0.0,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 40,
      Fd_Eps          => 1.0E-7);

begin
   Put_Line ("Gradient_Descent test suite");
   Put_Line ("===========================");

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
      Check (Approx (Real (Norm2 (Scale (0.0, A))), 0.0), "Scale zero");
      Check (Approx (Dot (Z, A), 0.0), "Dot with zero");
   end;

   ---------------------------------------------------------------------
   Section ("2. Descent_Step / Ascent_Step / Momentum_Step");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.0, 1.0];
      G : constant Point (1 .. 2) := [2.0, 4.0];
      Y : Point (1 .. 2);
      V : Point (1 .. 2) := [0.5, -0.5];
   begin
      Y := Descent_Step (X, G, 0.5);
      Check (Approx (Y (1), 0.0) and then Approx (Y (2), -1.0),
             "Descent_Step x-0.5g");
      Y := Ascent_Step (X, G, 0.25);
      Check (Approx (Y (1), 1.5) and then Approx (Y (2), 2.0),
             "Ascent_Step x+0.25g");
      Y := Descent_Step (X, G, 0.0);
      Check (Point_Near (Y, X, 1.0E-15), "Descent_Step eta=0");
      Y := Momentum_Step (X, V, G, 0.1, 0.9);
      --  v' = 0.9*[0.5,-0.5] - 0.1*[2,4] = [0.45,-0.45] - [0.2,0.4]
      --      = [0.25, -0.85]
      --  x' = [1,1] + [0.25,-0.85] = [1.25, 0.15]
      Check (Approx (V (1), 0.25, 1.0E-12) and then
             Approx (V (2), -0.85, 1.0E-12),
             "Momentum_Step updates v");
      Check (Approx (Y (1), 1.25, 1.0E-12) and then
             Approx (Y (2), 0.15, 1.0E-12),
             "Momentum_Step updates x");
      V := [0.0, 0.0];
      Y := Momentum_Step (X, V, G, 0.1, 0.0);
      Check (Point_Near (Y, Descent_Step (X, G, 0.1), 1.0E-12),
             "Momentum beta=0 equals Descent_Step");
   end;

   ---------------------------------------------------------------------
   Section ("3. Armijo_Accept predicate");
   ---------------------------------------------------------------------
   begin
      Check (Armijo_Accept (9.0, 10.0, 1.0, 0.1, -10.0),
             "Armijo accept at boundary RHS=9");
      Check (not Armijo_Accept (9.5, 10.0, 1.0, 0.1, -10.0),
             "Armijo reject insufficient decrease");
      Check (Armijo_Accept (0.0, 10.0, 0.5, 1.0E-4, -100.0),
             "Armijo large decrease accepted");
      Check (Armijo_Accept (10.0, 10.0, 1.0, 0.1, 0.0),
             "Armijo flat direction equality");
      Check (not Armijo_Accept (11.0, 10.0, 1.0, 0.1, -1.0),
             "Armijo reject increase");
      Check (Armijo_Accept (9.7, 10.0, 1.0, 0.01, -20.0),
             "Armijo small c1 still ok");
      --  RHS = 10 + 0.01*(-20) = 9.8; 9.7 ≤ 9.8
   end;

   ---------------------------------------------------------------------
   Section ("4. Demo objectives and analytical gradients");
   ---------------------------------------------------------------------
   declare
      Z2 : constant Point (1 .. 2) := [0.0, 0.0];
      P1 : constant Point (1 .. 2) := [1.0, 1.0];
      P3 : constant Point (1 .. 3) := [1.0, 2.0, 3.0];
      G  : Point (1 .. 2);
      Gd : Point (1 .. 3);
   begin
      Check (Approx (Sphere (Z2), 0.0), "Sphere at origin");
      Check (Approx (Sphere (P1), 2.0), "Sphere(1,1)=2");
      Check (Approx (Sphere (P3), 14.0), "Sphere(1,2,3)=14");
      G := Sphere_Grad (P1);
      Check (Approx (G (1), 2.0) and then Approx (G (2), 2.0),
             "Sphere_Grad(1,1)");
      Check (Approx (Quadratic_Bowl (Z2), 0.0), "Bowl at origin");
      --  0.5*(1*1 + 2*4) = 0.5*(1+8)=4.5 for (1,2) wait P3:
      --  0.5*(1*1 + 2*4 + 3*9) = 0.5*(1+8+27)=18
      Check (Approx (Quadratic_Bowl (P3), 18.0), "Bowl(1,2,3)=18");
      Gd := Quadratic_Bowl_Grad (P3);
      Check (Approx (Gd (1), 1.0) and then Approx (Gd (2), 4.0)
             and then Approx (Gd (3), 9.0),
             "Bowl_Grad(1,2,3)=(1,4,9)");
      Check (Approx (Rosenbrock (P1), 0.0), "Rosenbrock at (1,1)");
      G := Rosenbrock_Grad (P1);
      Check (Approx (G (1), 0.0, 1.0E-12) and then
             Approx (G (2), 0.0, 1.0E-12),
             "Rosenbrock_Grad at min");
      Check (Approx (Himmelblau ([3.0, 2.0]), 0.0, 1.0E-10),
             "Himmelblau at (3,2)");
      G := Himmelblau_Grad ([3.0, 2.0]);
      Check (Approx (G (1), 0.0, 1.0E-8) and then
             Approx (G (2), 0.0, 1.0E-8),
             "Himmelblau_Grad at (3,2)");
      Check (Approx (Himmelblau ([-2.805118, 3.131312]), 0.0, 1.0E-4),
             "Himmelblau near second min");
   end;

   ---------------------------------------------------------------------
   Section ("5. Finite_Difference_Gradient vs analytical");
   ---------------------------------------------------------------------
   declare
      X  : constant Point (1 .. 2) := [0.3, -0.7];
      X3 : constant Point (1 .. 3) := [0.5, -0.2, 0.8];
      Ga, Gn : Point (1 .. 2);
      Ga3, Gn3 : Point (1 .. 3);
   begin
      Ga := Sphere_Grad (X);
      Gn := Finite_Difference_Gradient (Sphere'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-5), "FD Sphere matches analytical");
      Ga := Quadratic_Bowl_Grad (X);
      Gn := Finite_Difference_Gradient (Quadratic_Bowl'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-5), "FD Bowl matches");
      Ga := Rosenbrock_Grad (X);
      Gn := Finite_Difference_Gradient (Rosenbrock'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-4), "FD Rosenbrock matches");
      Ga := Himmelblau_Grad (X);
      Gn := Finite_Difference_Gradient (Himmelblau'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-4), "FD Himmelblau matches");
      Ga3 := Sphere_Grad (X3);
      Gn3 := Finite_Difference_Gradient (Sphere'Access, X3);
      Check (Point_Near (Ga3, Gn3, 1.0E-5), "FD Sphere 3-D");
      Ga3 := Quadratic_Bowl_Grad (X3);
      Gn3 := Finite_Difference_Gradient (Quadratic_Bowl'Access, X3);
      Check (Point_Near (Ga3, Gn3, 1.0E-5), "FD Bowl 3-D");
      declare
         Z : constant Point (1 .. 1) := [2.5];
         G1a : constant Point := Sphere_Grad (Z);
         G1n : constant Point :=
           Finite_Difference_Gradient (Sphere'Access, Z);
      begin
         Check (Point_Near (G1a, G1n, 1.0E-5), "FD Sphere 1-D");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Line_Search Armijo on Sphere");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.0, 1.0];
      G : constant Point := Sphere_Grad (X);
      P : constant Point := Scale (-1.0, G);
      F : constant Real := Sphere (X);
      A : Positive_Real;
   begin
      A := Line_Search
        (Sphere'Access, X, F, G, P,
         1.0, 1.0E-4, 0.5, 40);
      Check (A > 0.0, "Line_Search returns positive alpha");
      Check (Sphere (Add (X, Scale (Real (A), P))) < F,
             "Line_Search decreases Sphere");
      Check (Armijo_Accept
               (Sphere (Add (X, Scale (Real (A), P))),
                F, Real (A), 1.0E-4, Dot (G, P)),
             "Accepted alpha satisfies Armijo");
      --  Exact line min of Sphere along −g: φ(α)=‖x−α·2x‖² = (1−2α)²‖x‖²
      --  min at α=0.5. Starting Alpha0=1 should backtrack to 0.5.
      A := Line_Search
        (Sphere'Access, X, F, G, P,
         1.0, 1.0E-4, 0.5, 40);
      Check (Approx (Real (A), 0.5, 1.0E-12),
             "Sphere Armijo finds alpha=0.5");
   end;

   ---------------------------------------------------------------------
   Section ("7. Minimize Sphere fixed step");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [3.0, -2.0];
      R  : Result;
      C  : Config := Fixed_Cfg;
   begin
      C.Step := 0.2;  --  for f=‖x‖², η<0.5 for stability with g=2x
      R := Minimize (Sphere'Access, X0, Sphere_Grad'Access, C);
      Check (R.Success, "Minimize Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Sphere value ~0");
      Check (Point_Near
               (R.Final_Point (1 .. 2), [0.0, 0.0], 1.0E-4),
             "Sphere point ~origin");
      Check (R.Final_Grad_Norm <= C.Grad_Tol * 10.0
             or else Approx (Real (R.Final_Grad_Norm), 0.0, 1.0E-5),
             "Sphere grad small");
      Check (R.Dim = 2, "Sphere Dim=2");
      Check (R.Iterations > 0, "Sphere iterations >0");
      Check (R.Iterations < C.Max_Iterations, "Sphere before max iters");
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize Sphere with Armijo / FD");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 3) := [2.0, -1.5, 0.5];
      R  : Result;
   begin
      R := Minimize (Sphere'Access, X0, null, Armijo_Cfg);
      Check (R.Success, "Armijo+FD Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6), "Armijo Sphere value");
      Check (Point_Near
               (R.Final_Point (1 .. 3), [0.0, 0.0, 0.0], 1.0E-3),
             "Armijo Sphere origin");
      R := Minimize
        (Sphere'Access, X0, Sphere_Grad'Access, Armijo_Cfg);
      Check (R.Success, "Armijo+analytic Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8),
             "Armijo analytic Sphere value");
   end;

   ---------------------------------------------------------------------
   Section ("9. Minimize Quadratic_Bowl");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 4) := [1.0, -2.0, 0.5, 3.0];
      R  : Result;
      C  : Config := Fixed_Cfg;
   begin
      C.Step := 0.15;
      C.Max_Iterations := 800;
      R := Minimize
        (Quadratic_Bowl'Access, X0, Quadratic_Bowl_Grad'Access, C);
      Check (R.Success, "Bowl fixed success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-5), "Bowl value ~0");
      Check (Point_Near
               (R.Final_Point (1 .. 4),
                [0.0, 0.0, 0.0, 0.0], 1.0E-3),
             "Bowl at origin");
      R := Minimize (Quadratic_Bowl'Access, X0, null, Armijo_Cfg);
      Check (R.Success, "Bowl Armijo+FD success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-5), "Bowl Armijo value");
   end;

   ---------------------------------------------------------------------
   Section ("10. Minimize Rosenbrock");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [-1.2, 1.0];
      R  : Result;
      C  : Config := Armijo_Cfg;
   begin
      --  Classic GD is slow on the banana; use enough iters + milder tol.
      C.Max_Iterations := 20000;
      C.Step := 0.5;
      C.Grad_Tol := 1.0E-6;
      R := Minimize
        (Rosenbrock'Access, X0, Rosenbrock_Grad'Access, C);
      Check (R.Success or else R.Final_Value < 1.0E-6,
             "Rosenbrock Armijo success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4), "Rosenbrock value ~0");
      Check (Point_Near
               (R.Final_Point (1 .. 2), [1.0, 1.0], 1.0E-2),
             "Rosenbrock near (1,1)");
      --  Fixed small step also converges (slowly)
      C := Fixed_Cfg;
      C.Step := 0.001;
      C.Max_Iterations := 20000;
      C.Grad_Tol := 1.0E-5;
      R := Minimize
        (Rosenbrock'Access, X0, Rosenbrock_Grad'Access, C);
      Check (R.Success or else R.Final_Value < 0.01,
             "Rosenbrock fixed-step progress");
      Check (R.Final_Value < Rosenbrock (X0),
             "Rosenbrock decreased from start");
   end;

   ---------------------------------------------------------------------
   Section ("11. Minimize Himmelblau");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [0.0, 0.0];
      R  : Result;
      C  : Config := Armijo_Cfg;
      Hit : Boolean;
   begin
      C.Max_Iterations := 2000;
      R := Minimize
        (Himmelblau'Access, X0, Himmelblau_Grad'Access, C);
      Check (R.Success, "Himmelblau Armijo success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4), "Himmelblau value ~0");
      Hit :=
        Point_Near (R.Final_Point (1 .. 2), [3.0, 2.0], 0.05)
        or else Point_Near
          (R.Final_Point (1 .. 2), [-2.805118, 3.131312], 0.05)
        or else Point_Near
          (R.Final_Point (1 .. 2), [-3.779310, -3.283186], 0.05)
        or else Point_Near
          (R.Final_Point (1 .. 2), [3.584428, -1.848126], 0.05);
      Check (Hit, "Himmelblau near one of four minima");
   end;

   ---------------------------------------------------------------------
   Section ("12. Maximize Negated_Sphere (ascent to origin)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [2.0, -1.0];
      R  : Result;
      C  : Config := Fixed_Cfg;
   begin
      C.Step := 0.2;
      R := Maximize
        (Negated_Sphere'Access, X0, Negated_Sphere_Grad'Access, C);
      Check (R.Success, "Maximize Negated_Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-5),
             "Maximize reaches ~0");
      Check (Point_Near
               (R.Final_Point (1 .. 2), [0.0, 0.0], 1.0E-3),
             "Maximize at origin");
      C.Use_Line_Search := True;
      C.Step := 1.0;
      R := Maximize
        (Negated_Sphere'Access, X0, Negated_Sphere_Grad'Access, C);
      Check (R.Success, "Maximize Armijo Negated_Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-6),
             "Maximize Armijo value");
      R := Maximize (Negated_Sphere'Access, X0, null, C);
      Check (R.Success, "Maximize FD Negated_Sphere success");
   end;

   ---------------------------------------------------------------------
   Section ("13. Minimize_Momentum heavy-ball");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [4.0, -3.0];
      R  : Result;
      C  : Config := Fixed_Cfg;
   begin
      C.Step := 0.15;
      C.Momentum_Beta := 0.0;
      R := Minimize_Momentum
        (Sphere'Access, X0, Sphere_Grad'Access, C);
      Check (R.Success, "Momentum beta=0 Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-5),
             "Momentum beta=0 value");

      C.Momentum_Beta := 0.5;
      C.Step := 0.1;
      R := Minimize_Momentum
        (Sphere'Access, X0, Sphere_Grad'Access, C);
      Check (R.Success, "Momentum beta=0.5 Sphere success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4),
             "Momentum beta=0.5 value");
      Check (Point_Near
               (R.Final_Point (1 .. 2), [0.0, 0.0], 1.0E-2),
             "Momentum near origin");

      C.Momentum_Beta := 0.8;
      C.Step := 0.05;
      C.Max_Iterations := 1000;
      R := Minimize_Momentum
        (Quadratic_Bowl'Access, [1.0, -1.0, 0.5],
         Quadratic_Bowl_Grad'Access, C);
      Check (R.Success, "Momentum Bowl success");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4), "Momentum Bowl value");

      R := Minimize_Momentum (Sphere'Access, X0, null, C);
      Check (R.Success, "Momentum FD Sphere success");
   end;

   ---------------------------------------------------------------------
   Section ("14. Already at optimum / early stop");
   ---------------------------------------------------------------------
   declare
      Z : constant Point (1 .. 2) := [0.0, 0.0];
      R : Result;
   begin
      R := Minimize (Sphere'Access, Z, Sphere_Grad'Access, Fixed_Cfg);
      Check (R.Success, "Start at min Success");
      Check (R.Iterations = 0, "Start at min zero iters");
      Check (Approx (R.Final_Value, 0.0), "Start at min value 0");
      R := Maximize
        (Negated_Sphere'Access, Z, Negated_Sphere_Grad'Access, Fixed_Cfg);
      Check (R.Success and then R.Iterations = 0,
             "Start at max zero iters");
      R := Minimize_Momentum
        (Sphere'Access, Z, Sphere_Grad'Access, Fixed_Cfg);
      Check (R.Success and then R.Iterations = 0,
             "Momentum start at min");
   end;

   ---------------------------------------------------------------------
   Section ("15. Config / Result field sanity");
   ---------------------------------------------------------------------
   declare
      C : Config := Default_Config;
      R : Result;
      X0 : constant Point (1 .. 1) := [5.0];
   begin
      Check (C.Max_Iterations = 500, "Default Max_Iterations");
      Check (Approx (C.Step, 0.1), "Default Step");
      Check (not C.Use_Line_Search, "Default no line search");
      Check (Approx (C.Momentum_Beta, 0.0), "Default beta 0");
      C.Step := 0.25;
      C.Max_Iterations := 200;
      R := Minimize (Sphere'Access, X0, Sphere_Grad'Access, C);
      Check (R.Dim = 1, "1-D Dim");
      Check (R.Success, "1-D Sphere success");
      Check (Approx (R.Final_Point (1), 0.0, 1.0E-4), "1-D at 0");
      Check (R.Final_Grad_Norm >= 0.0, "Grad norm non-neg");
   end;

   ---------------------------------------------------------------------
   Section ("16. Exceptions");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      X1 : constant Point (1 .. 1) := [1.0];
   begin
      Raised := False;
      begin
         declare
            Dummy : constant Real := Rosenbrock (X1);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock rejects dim<2");

      Raised := False;
      begin
         declare
            Dummy : constant Real := Himmelblau (X1);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Himmelblau rejects dim<2");

      Raised := False;
      begin
         declare
            Dummy : constant Point := Rosenbrock_Grad (X1);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock_Grad rejects dim<2");
   end;

   ---------------------------------------------------------------------
   Section ("17. High dimension n=8 Sphere");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 8) :=
        [1.0, -1.0, 0.5, -0.5, 2.0, -2.0, 0.25, -0.25];
      R  : Result;
      C  : constant Config := Armijo_Cfg;
   begin
      R := Minimize (Sphere'Access, X0, Sphere_Grad'Access, C);
      Check (R.Success, "n=8 Sphere success");
      Check (R.Dim = 8, "n=8 Dim");
      Check (Approx (R.Final_Value, 0.0, 1.0E-5), "n=8 value");
      Check (Point_Near
               (R.Final_Point (1 .. 8),
                [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                1.0E-2),
             "n=8 at origin");
   end;

   ---------------------------------------------------------------------
   Section ("18. Fixed vs Armijo consistency on Bowl");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [2.0, -1.0];
      Rf, Ra : Result;
      Cf : Config := Fixed_Cfg;
   begin
      Cf.Step := 0.2;
      Rf := Minimize
        (Quadratic_Bowl'Access, X0, Quadratic_Bowl_Grad'Access, Cf);
      Ra := Minimize
        (Quadratic_Bowl'Access, X0, Quadratic_Bowl_Grad'Access,
         Armijo_Cfg);
      Check (Rf.Success and then Ra.Success,
             "Both modes succeed on Bowl");
      Check (Approx (Rf.Final_Value, 0.0, 1.0E-5)
             and then Approx (Ra.Final_Value, 0.0, 1.0E-5),
             "Both reach ~0");
      Check (Point_Near
               (Rf.Final_Point (1 .. 2), Ra.Final_Point (1 .. 2),
                1.0E-2),
             "Fixed and Armijo same basin");
   end;

   ---------------------------------------------------------------------
   Section ("19. Value decreases each successful Minimize");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [1.5, -0.5];
      R  : Result;
      F0 : constant Real := Sphere (X0);
   begin
      R := Minimize
        (Sphere'Access, X0, Sphere_Grad'Access, Fixed_Cfg);
      Check (R.Final_Value < F0, "Final < initial Sphere");
      Check (R.Final_Value >= 0.0, "Sphere value non-negative");
      R := Minimize
        (Quadratic_Bowl'Access, X0, Quadratic_Bowl_Grad'Access,
         Armijo_Cfg);
      Check (R.Final_Value < Quadratic_Bowl (X0),
             "Final < initial Bowl");
   end;

   ---------------------------------------------------------------------
   Section ("20. Extra Near / Scale / Dot edge cases");
   ---------------------------------------------------------------------
   declare
      U : constant Point (1 .. 4) := [1.0, 0.0, -1.0, 2.0];
      V : constant Point (1 .. 4) := [0.0, 1.0, 1.0, 0.5];
      W : Point (1 .. 4);
   begin
      Check (Approx (Dot (U, V), -1.0 + 1.0), "Dot mixed signs");
      --  0 + 0 + (-1)*1 + 2*0.5 = -1 + 1 = 0
      Check (Approx (Dot (U, V), 0.0), "Dot U·V = 0");
      W := Scale (-1.0, U);
      Check (Approx (W (1), -1.0) and then Approx (W (3), 1.0),
             "Scale -1");
      Check (Near (1.0E-20, 0.0, 1.0E-15), "Near tiny vs zero");
      Check (not Near (1.0, -1.0), "Near opposite signs");
      Check (Point_Near (U, U), "Point_Near reflexive");
      Check (Approx (Real (Norm2 (Scale (3.0, [0.0, 1.0]))), 3.0),
             "Norm2 Scale");
      Check (Approx (Sphere ([0.0]), 0.0), "Sphere 1-D zero");
      Check (Approx (Sphere ([3.0]), 9.0), "Sphere 1-D 9");
      Check (Approx (Sphere_Grad ([3.0]) (1), 6.0),
             "Sphere_Grad 1-D");
   end;

   ---------------------------------------------------------------------
   Section ("21. Himmelblau other starts / Maximize progress");
   ---------------------------------------------------------------------
   declare
      R : Result;
      C : Config := Armijo_Cfg;
      X0 : constant Point (1 .. 2) := [1.0, 1.0];
      F0 : Real;
   begin
      C.Max_Iterations := 3000;
      R := Minimize
        (Himmelblau'Access, [-1.0, 1.0], Himmelblau_Grad'Access, C);
      Check (R.Success or else R.Final_Value < 1.0,
             "Himmelblau alt start progress");
      F0 := Negated_Sphere (X0);
      R := Maximize
        (Negated_Sphere'Access, X0, Negated_Sphere_Grad'Access, Fixed_Cfg);
      Check (R.Final_Value > F0 or else R.Success,
             "Maximize increased objective");
      Check (R.Final_Value <= 0.0 + 1.0E-8,
             "Negated_Sphere upper bound 0");
   end;

   ---------------------------------------------------------------------
   Section ("22. Momentum vs plain GD same limit");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [1.0, 2.0];
      Rm, Rf : Result;
      Cm : Config := Fixed_Cfg;
   begin
      Cm.Step := 0.1;
      Cm.Momentum_Beta := 0.3;
      Cm.Max_Iterations := 800;
      Rm := Minimize_Momentum
        (Sphere'Access, X0, Sphere_Grad'Access, Cm);
      Rf := Minimize (Sphere'Access, X0, Sphere_Grad'Access, Fixed_Cfg);
      Check (Rm.Success and then Rf.Success,
             "Momentum and GD both succeed");
      Check (Point_Near
               (Rm.Final_Point (1 .. 2), Rf.Final_Point (1 .. 2),
                1.0E-2),
             "Momentum and GD same limit");
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("WARNING: all passed but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
