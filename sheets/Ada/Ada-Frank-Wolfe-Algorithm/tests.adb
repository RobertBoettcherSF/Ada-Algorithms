--  Standalone test suite for Frank_Wolfe_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO;            use Ada.Text_IO;
with Frank_Wolfe_Algorithm;  use Frank_Wolfe_Algorithm;

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

   Open_Cfg : constant Config :=
     (Max_Iterations  => 500,
      Gap_Tol         => 1.0E-6,
      Step_Tol        => 1.0E-12,
      Step_Mode       => Open_Loop,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 40,
      Exact_Tol       => 1.0E-10,
      Fd_Eps          => 1.0E-7);

   Exact_Cfg : constant Config :=
     (Max_Iterations  => 200,
      Gap_Tol         => 1.0E-7,
      Step_Tol        => 1.0E-12,
      Step_Mode       => Exact_Line_Search,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 80,
      Exact_Tol       => 1.0E-10,
      Fd_Eps          => 1.0E-7);

   Armijo_Cfg : constant Config :=
     (Max_Iterations  => 200,
      Gap_Tol         => 1.0E-6,
      Step_Tol        => 1.0E-12,
      Step_Mode       => Armijo,
      Armijo_C        => 1.0E-4,
      Line_Search_Rho => 0.5,
      Max_Line_Search => 40,
      Exact_Tol       => 1.0E-10,
      Fd_Eps          => 1.0E-7);

begin
   Put_Line ("Frank_Wolfe_Algorithm test suite");
   Put_Line ("================================");

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
      CC : Point (1 .. 2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (Point_Near (A, B), "Point_Near equal");
      Check (not Point_Near (A, C), "Point_Near rejects");
      Check (Approx (Norm2 (D), 5.0), "Norm2 3-4-5");
      Check (Approx (Norm2 (Z), 0.0), "Norm2 zero");
      Check (Approx (Dot (A, C), 1.0 + 6.0), "Dot product");
      S := Add (A, C);
      Check (Point_Near (S, Point'(1 => 2.0, 2 => 5.0)), "Add");
      S := Sub (C, A);
      Check (Point_Near (S, Point'(1 => 0.0, 2 => 1.0)), "Sub");
      S := Scale (2.0, A);
      Check (Point_Near (S, Point'(1 => 2.0, 2 => 4.0)), "Scale");
      CC := Convex_Combination (0.5, A, C);
      Check (Point_Near (CC, Point'(1 => 1.0, 2 => 2.5)),
             "Convex_Combination mid");
      CC := Convex_Combination (0.0, A, C);
      Check (Point_Near (CC, A), "Convex_Combination gamma=0");
      CC := Convex_Combination (1.0, A, C);
      Check (Point_Near (CC, C), "Convex_Combination gamma=1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Open_Loop_Step schedule");
   ---------------------------------------------------------------------
   Check (Near (Open_Loop_Step (0), 1.0), "gamma_0 = 1");
   Check (Near (Open_Loop_Step (1), 2.0 / 3.0), "gamma_1 = 2/3");
   Check (Near (Open_Loop_Step (2), 0.5), "gamma_2 = 1/2");
   Check (Near (Open_Loop_Step (8), 0.2), "gamma_8 = 2/10");
   Check (Open_Loop_Step (100) > 0.0, "gamma_100 positive");
   Check (Open_Loop_Step (100) <= 1.0, "gamma_100 <= 1");

   ---------------------------------------------------------------------
   Section ("3. LMO_Simplex");
   ---------------------------------------------------------------------
   declare
      G1 : constant Point (1 .. 3) := [0.5, -1.0, 2.0];
      S1 : constant Point := LMO_Simplex (G1);
      G2 : constant Point (1 .. 4) := [3.0, 1.0, 1.0, 2.0];
      S2 : constant Point := LMO_Simplex (G2);
      G3 : constant Point (1 .. 2) := [-0.1, -0.1];
      S3 : constant Point := LMO_Simplex (G3);
      Sum : Real;
   begin
      Check (Point_Near (S1, Point'(1 => 0.0, 2 => 1.0, 3 => 0.0)),
             "Simplex LMO picks argmin index 2");
      Check (Point_Near (S2, Point'(1 => 0.0, 2 => 1.0, 3 => 0.0, 4 => 0.0)),
             "Simplex LMO first of tied argmin");
      Sum := S3 (1) + S3 (2);
      Check (Near (Sum, 1.0), "Simplex vertex sums to 1");
      Check (S3 (1) = 1.0 or else S3 (2) = 1.0, "Simplex one-hot");
   end;

   ---------------------------------------------------------------------
   Section ("4. LMO_Box");
   ---------------------------------------------------------------------
   declare
      G  : constant Point (1 .. 3) := [1.0, -2.0, 0.0];
      L  : constant Point (1 .. 3) := [-1.0, -1.0, -1.0];
      U  : constant Point (1 .. 3) := [2.0, 2.0, 2.0];
      S  : constant Point := LMO_Box (G, L, U);
   begin
      Check (Near (S (1), -1.0), "Box LMO g>0 -> Lower");
      Check (Near (S (2), 2.0), "Box LMO g<0 -> Upper");
      Check (Near (S (3), 2.0), "Box LMO g=0 -> Upper");
   end;

   declare
      G : constant Point (1 .. 2) := [-0.5, 0.5];
      L : constant Point (1 .. 2) := [0.0, 0.0];
      U : constant Point (1 .. 2) := [1.0, 1.0];
      S : constant Point := LMO_Box (G, L, U);
   begin
      Check (Point_Near (S, Point'(1 => 1.0, 2 => 0.0)),
             "Box unit LMO");
   end;

   ---------------------------------------------------------------------
   Section ("5. LMO_L1_Ball");
   ---------------------------------------------------------------------
   declare
      G1 : constant Point (1 .. 3) := [0.1, -0.9, 0.2];
      S1 : constant Point := LMO_L1_Ball (G1, 1.0);
      G0 : constant Point (1 .. 2) := [0.0, 0.0];
      S0 : constant Point := LMO_L1_Ball (G0, 1.0);
      G2 : constant Point (1 .. 2) := [3.0, 1.0];
      S2 : constant Point := LMO_L1_Ball (G2, 2.0);
   begin
      Check (Point_Near (S1, Point'(1 => 0.0, 2 => 1.0, 3 => 0.0)),
             "L1 LMO opposite largest |g|");
      Check (Point_Near (S0, Point'(1 => 0.0, 2 => 0.0)),
             "L1 LMO zero grad -> origin");
      Check (Point_Near (S2, Point'(1 => -2.0, 2 => 0.0)),
             "L1 LMO radius 2");
      Check (Approx (abs (S1 (1)) + abs (S1 (2)) + abs (S1 (3)), 1.0),
             "L1 vertex has l1-norm = R");
   end;

   ---------------------------------------------------------------------
   Section ("6. Duality_Gap");
   ---------------------------------------------------------------------
   declare
      Grad : constant Point (1 .. 2) := [1.0, -1.0];
      X    : constant Point (1 .. 2) := [0.5, 0.5];
      S    : constant Point (1 .. 2) := [0.0, 1.0];
      Gap  : Non_Negative;
   begin
      --  <g, x-s> = 1*(0.5-0) + (-1)*(0.5-1) = 0.5 + 0.5 = 1
      Gap := Duality_Gap (Grad, X, S);
      Check (Near (Gap, 1.0), "Duality_Gap explicit S");
      Gap := Duality_Gap (Grad, X, LMO_Simplex'Access);
      Check (Near (Gap, 1.0), "Duality_Gap via LMO");
   end;

   ---------------------------------------------------------------------
   Section ("7. Demo objectives / analytical gradients vs FD");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 3) := [0.2, 0.3, 0.5];
      Ga, Gn : Point (1 .. 3);
   begin
      Check (Approx (Sphere (X), 0.04 + 0.09 + 0.25), "Sphere value");
      Ga := Sphere_Grad (X);
      Gn := Finite_Difference_Gradient (Sphere'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-5), "Sphere Grad vs FD");

      Ga := Shifted_Quadratic_Grad (X);
      Gn := Finite_Difference_Gradient (Shifted_Quadratic'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-5), "Shifted_Quadratic Grad vs FD");
      Check (Approx (Shifted_Quadratic (X),
                     0.5 * ((0.2 - 1.0 / 3.0)**2
                            + (0.3 - 1.0 / 3.0)**2
                            + (0.5 - 1.0 / 3.0)**2)),
             "Shifted_Quadratic value");

      Ga := Weighted_Quadratic_Grad (X);
      Gn := Finite_Difference_Gradient (Weighted_Quadratic'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-5), "Weighted_Quadratic Grad vs FD");

      Check (Approx (Linear_Ones (X), 1.0), "Linear_Ones value");
      Ga := Linear_Ones_Grad (X);
      Check (Point_Near (Ga, Point'(1 => 1.0, 2 => 1.0, 3 => 1.0)),
             "Linear_Ones Grad");
      Gn := Finite_Difference_Gradient (Linear_Ones'Access, X);
      Check (Point_Near (Ga, Gn, 1.0E-5), "Linear_Ones Grad vs FD");
   end;

   ---------------------------------------------------------------------
   Section ("8. Armijo_Accept");
   ---------------------------------------------------------------------
   Check (Armijo_Accept (0.5, 1.0, 0.5, 1.0E-4, -1.0),
          "Armijo accepts sufficient decrease");
   Check (not Armijo_Accept (1.5, 1.0, 0.5, 1.0E-4, -1.0),
          "Armijo rejects increase");

   ---------------------------------------------------------------------
   Section ("9. Exact / Armijo line search on segment");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 2) := [1.0, 0.0];
      S : constant Point (1 .. 2) := [0.0, 0.0];
      --  Sphere: f((1-g)x)= (1-g)^2; exact min on [0,1] at g=1
      Gex : Unit_Interval;
      Gar : Unit_Interval;
      F0  : constant Real := Sphere (X);
      Dir : constant Real :=
        Dot (Sphere_Grad (X), Sub (S, X));  -- 2x · (-x) = -2
   begin
      Gex := Exact_Line_Search
        (Sphere'Access, X, S, 1.0E-10, 80);
      Check (Near (Gex, 1.0, 1.0E-4), "Exact LS Sphere toward 0");
      Gar := Armijo_Line_Search
        (Sphere'Access, X, S, F0, Dir, 1.0E-4, 0.5, 40);
      Check (Gar > 0.0, "Armijo LS positive step");
      Check (Sphere (Convex_Combination (Gar, X, S)) <= F0,
             "Armijo LS decreases Sphere");
   end;

   ---------------------------------------------------------------------
   Section ("10. FW Shifted_Quadratic over simplex (open-loop)");
   ---------------------------------------------------------------------
   declare
      --  Uniform start on Δ²; unconstrained min is uniform → already optimal
      X0 : constant Point (1 .. 3) :=
        [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0];
      R  : Result;
   begin
      R := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, Open_Cfg);
      Check (R.Success, "Uniform start succeeds immediately");
      Check (R.Final_Gap <= Open_Cfg.Gap_Tol, "Gap small at uniform");
      Check (Approx (R.Final_Value, 0.0, 1.0E-8), "Value ~ 0 at uniform");
      Check (R.Dim = 3, "Dim = 3");
   end;

   declare
      X0 : constant Point (1 .. 3) := [1.0, 0.0, 0.0];
      R  : Result;
      Sum : Real;
      Cfg : Config := Exact_Cfg;
   begin
      Cfg.Max_Iterations := 200;
      Cfg.Gap_Tol := 1.0E-4;
      R := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, Cfg);
      Check (R.Success, "Simplex Shifted_Quadratic succeeds");
      Sum := R.Final_Point (1) + R.Final_Point (2) + R.Final_Point (3);
      Check (Near (Sum, 1.0, 1.0E-5), "Stays on simplex (sum=1)");
      Check (R.Final_Point (1) >= -1.0E-8, "x1 >= 0");
      Check (R.Final_Point (2) >= -1.0E-8, "x2 >= 0");
      Check (R.Final_Point (3) >= -1.0E-8, "x3 >= 0");
      Check (Point_Near
               (R.Final_Point (1 .. 3),
                Point'(1 => 1.0 / 3.0, 2 => 1.0 / 3.0, 3 => 1.0 / 3.0),
                5.0E-2),
             "Approaches uniform barycenter");
      Check (R.Final_Gap <= 1.0E-3, "Final gap small");
   end;

   ---------------------------------------------------------------------
   Section ("11. FW Weighted_Quadratic over simplex");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 4) := [0.25, 0.25, 0.25, 0.25];
      R  : Result;
      Cfg : Config := Exact_Cfg;
   begin
      Cfg.Max_Iterations := 300;
      R := Minimize
        (Weighted_Quadratic'Access, X0, LMO_Simplex'Access,
         Weighted_Quadratic_Grad'Access, Cfg);
      Check (R.Success, "Weighted_Quadratic simplex Exact LS succeeds");
      --  Optimum puts mass on smallest weight index → e_1
      Check (R.Final_Point (1) > R.Final_Point (2)
             and then R.Final_Point (1) > R.Final_Point (4),
             "Mass concentrates on smallest weight");
      Check (R.Final_Value < Weighted_Quadratic (X0),
             "Objective decreased from uniform");
   end;

   ---------------------------------------------------------------------
   Section ("12. FW Sphere over box (sphere-like)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [0.8, -0.6];
      R  : Result;
      Cfg : Config := Exact_Cfg;
   begin
      Set_Box_Bounds
        (Point'(1 => -1.0, 2 => -1.0), Point'(1 => 1.0, 2 => 1.0));
      Cfg.Max_Iterations := 100;
      Cfg.Gap_Tol := 1.0E-5;
      R := Minimize
        (Sphere'Access, X0, Active_Box_LMO'Access, Sphere_Grad'Access, Cfg);
      Check (R.Success, "Sphere over box succeeds");
      Check (Point_Near
               (R.Final_Point (1 .. 2), Point'(1 => 0.0, 2 => 0.0),
                5.0E-3),
             "Sphere over box -> origin");
      Check (Approx (R.Final_Value, 0.0, 1.0E-4), "Sphere value ~ 0");
   end;

   declare
      X0 : constant Point (1 .. 3) := [0.5, 0.5, 0.5];
      R  : Result;
   begin
      Set_Box_Bounds
        (Point'(1 => 0.0, 2 => 0.0, 3 => 0.0),
         Point'(1 => 1.0, 2 => 1.0, 3 => 1.0));
      R := Minimize
        (Sphere'Access, X0, Active_Box_LMO'Access, Sphere_Grad'Access, Exact_Cfg);
      Check (R.Success, "Sphere over [0,1]^3 Exact succeeds");
      Check (Point_Near
               (R.Final_Point (1 .. 3),
                Point'(1 => 0.0, 2 => 0.0, 3 => 0.0),
                1.0E-3),
             "Sphere over unit box -> 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Linear objective over box");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [0.0, 0.0];
      R  : Result;
      Cfg : Config := Open_Cfg;
   begin
      Set_Box_Bounds
        (Point'(1 => -2.0, 2 => -3.0), Point'(1 => 4.0, 2 => 5.0));
      Cfg.Max_Iterations := 50;
      Cfg.Gap_Tol := 1.0E-8;
      R := Minimize
        (Linear_Ones'Access, X0, Active_Box_LMO'Access,
         Linear_Ones_Grad'Access, Cfg);
      Check (R.Success, "Linear over box succeeds");
      Check (Point_Near
               (R.Final_Point (1 .. 2), Point'(1 => -2.0, 2 => -3.0),
                1.0E-6),
             "Linear over box -> lower corner");
      Check (Approx (R.Final_Value, -5.0), "Linear value = -5");
   end;

   ---------------------------------------------------------------------
   Section ("14. Linear / Sphere over ℓ₁ ball");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 3) := [0.1, 0.1, 0.1];
      R  : Result;
   begin
      Set_L1_Radius (1.0);
      R := Minimize
        (Linear_Ones'Access, X0, Active_L1_LMO'Access,
         Linear_Ones_Grad'Access, Exact_Cfg);
      Check (R.Success, "Linear over L1 succeeds");
      --  min Σ x_i on ||x||_1 ≤ 1 → put -1 on one coordinate
      Check (Approx (R.Final_Value, -1.0, 1.0E-4),
             "Linear L1 optimum value -1");
      Check (Approx
               (abs (R.Final_Point (1))
                + abs (R.Final_Point (2))
                + abs (R.Final_Point (3)),
                1.0, 1.0E-3),
             "L1 solution on boundary");
   end;

   declare
      X0 : constant Point (1 .. 2) := [0.5, -0.3];
      R  : Result;
      Cfg : Config := Exact_Cfg;
   begin
      Set_L1_Radius (1.0);
      Cfg.Max_Iterations := 150;
      Cfg.Gap_Tol := 1.0E-4;
      R := Minimize
        (Sphere'Access, X0, Active_L1_LMO'Access, Sphere_Grad'Access, Cfg);
      Check (R.Success, "Sphere over L1 succeeds");
      Check (Point_Near
               (R.Final_Point (1 .. 2), Point'(1 => 0.0, 2 => 0.0),
                5.0E-2),
             "Sphere over L1 -> origin");
   end;

   ---------------------------------------------------------------------
   Section ("15. Armijo step mode");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 3) := [1.0, 0.0, 0.0];
      R  : Result;
      Cfg : Config := Armijo_Cfg;
   begin
      Cfg.Max_Iterations := 400;
      R := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, Cfg);
      Check (R.Success, "Armijo mode Shifted_Quadratic succeeds");
      Check (Point_Near
               (R.Final_Point (1 .. 3),
                Point'(1 => 1.0 / 3.0, 2 => 1.0 / 3.0, 3 => 1.0 / 3.0),
                8.0E-2),
             "Armijo approaches uniform");
   end;

   ---------------------------------------------------------------------
   Section ("16. FD gradient path (Grad null)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [1.0, 0.0];
      R  : Result;
      Cfg : Config := Exact_Cfg;
   begin
      Cfg.Max_Iterations := 200;
      Cfg.Gap_Tol := 1.0E-4;
      R := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         null, Cfg);
      Check (R.Success, "FD-only Minimize succeeds");
      Check (Point_Near
               (R.Final_Point (1 .. 2),
                Point'(1 => 0.5, 2 => 0.5),
                8.0E-2),
             "FD path approaches uniform on Δ¹");
   end;

   ---------------------------------------------------------------------
   Section ("17. Gap decreases / monotonic open-loop values");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 3) := [1.0, 0.0, 0.0];
      R_Few, R_Many : Result;
      C_Few, C_Many : Config := Open_Cfg;
   begin
      C_Few.Max_Iterations := 5;
      C_Few.Gap_Tol := 0.0;  -- force full budget
      C_Many.Max_Iterations := 100;
      C_Many.Gap_Tol := 0.0;
      R_Few := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, C_Few);
      R_Many := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, C_Many);
      Check (R_Many.Final_Gap <= R_Few.Final_Gap + 1.0E-9,
             "More iters => gap not worse");
      Check (R_Many.Final_Value <= R_Few.Final_Value + 1.0E-6,
             "More iters => value not worse (approx)");
   end;

   ---------------------------------------------------------------------
   Section ("18. Feasibility preserved (simplex / box)");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 5) :=
        [0.2, 0.2, 0.2, 0.2, 0.2];
      R  : Result;
      Sum : Real := 0.0;
      Cfg : Config := Open_Cfg;
   begin
      Cfg.Max_Iterations := 50;
      R := Minimize
        (Weighted_Quadratic'Access, X0, LMO_Simplex'Access,
         Weighted_Quadratic_Grad'Access, Cfg);
      for I in 1 .. 5 loop
         Sum := Sum + R.Final_Point (I);
         Check (R.Final_Point (I) >= -1.0E-8,
                "Simplex coord nonneg #" & I'Image);
      end loop;
      Check (Near (Sum, 1.0, 1.0E-6), "Simplex sum preserved");
   end;

   declare
      X0 : constant Point (1 .. 2) := [0.5, 0.5];
      R  : Result;
      Cfg : Config := Open_Cfg;
   begin
      Set_Box_Bounds
        (Point'(1 => 0.0, 2 => 0.0), Point'(1 => 1.0, 2 => 1.0));
      Cfg.Max_Iterations := 30;
      R := Minimize
        (Sphere'Access, X0, Active_Box_LMO'Access, Sphere_Grad'Access, Cfg);
      Check (R.Final_Point (1) >= -1.0E-9
             and then R.Final_Point (1) <= 1.0 + 1.0E-9,
             "Box x1 in bounds");
      Check (R.Final_Point (2) >= -1.0E-9
             and then R.Final_Point (2) <= 1.0 + 1.0E-9,
             "Box x2 in bounds");
   end;

   ---------------------------------------------------------------------
   Section ("19. Default_Config / Result fields");
   ---------------------------------------------------------------------
   declare
      C : constant Config := Default_Config;
      X0 : constant Point (1 .. 2) := [1.0, 0.0];
      R  : Result;
   begin
      Check (C.Step_Mode = Open_Loop, "Default Step_Mode Open_Loop");
      Check (C.Max_Iterations = 500, "Default Max_Iterations");
      Check (C.Gap_Tol > 0.0, "Default Gap_Tol positive");
      R := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, C);
      Check (R.Iterations >= 1, "Iterations >= 1");
      Check (R.Dim = 2, "Result.Dim");
      Check (R.Final_Gap >= 0.0, "Final_Gap nonnegative");
   end;

   ---------------------------------------------------------------------
   Section ("20. High dimension n=16 simplex");
   ---------------------------------------------------------------------
   declare
      X0 : Point (1 .. 16) := [others => 0.0];
      R  : Result;
      Sum : Real := 0.0;
      Cfg : Config := Exact_Cfg;
   begin
      X0 (1) := 1.0;
      Cfg.Max_Iterations := 400;
      Cfg.Gap_Tol := 1.0E-3;
      R := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, Cfg);
      Check (R.Success, "n=16 Shifted_Quadratic succeeds");
      for I in 1 .. 16 loop
         Sum := Sum + R.Final_Point (I);
      end loop;
      Check (Near (Sum, 1.0, 1.0E-4), "n=16 simplex sum");
      Check (R.Dim = 16, "n=16 Dim");
   end;

   ---------------------------------------------------------------------
   Section ("21. Exact LS vs open-loop both reach optimum");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 3) := [1.0, 0.0, 0.0];
      Ro, Re : Result;
      Co : Config := Open_Cfg;
      Ce : Config := Exact_Cfg;
   begin
      Co.Max_Iterations := 2000;
      Co.Gap_Tol := 1.0E-3;
      Ce.Max_Iterations := 200;
      Ce.Gap_Tol := 1.0E-3;
      Ro := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, Co);
      Re := Minimize
        (Shifted_Quadratic'Access, X0, LMO_Simplex'Access,
         Shifted_Quadratic_Grad'Access, Ce);
      Check (Ro.Success and then Re.Success,
             "Both step modes succeed");
      Check (Point_Near
               (Ro.Final_Point (1 .. 3), Re.Final_Point (1 .. 3),
                5.0E-2),
             "Open-loop and Exact same limit");
      Check (Re.Iterations <= Ro.Iterations + 5
             or else Re.Final_Gap <= Ro.Final_Gap,
             "Exact not obviously worse");
   end;

   ---------------------------------------------------------------------
   Section ("22. Gap formula identity");
   ---------------------------------------------------------------------
   declare
      X : constant Point (1 .. 4) := [0.4, 0.3, 0.2, 0.1];
      G : constant Point := Shifted_Quadratic_Grad (X);
      S : constant Point := LMO_Simplex (G);
      Gap1 : constant Non_Negative := Duality_Gap (G, X, S);
      Gap2 : constant Real := Dot (G, X) - Dot (G, S);
   begin
      Check (Near (Gap1, Gap2, 1.0E-12),
             "Gap = <g,x> - <g,s>");
      Check (Gap1 >= 0.0, "Gap nonnegative on simplex");
   end;

   ---------------------------------------------------------------------
   Section ("23. Box LMO respects bounds componentwise");
   ---------------------------------------------------------------------
   declare
      G : constant Point (1 .. 4) := [1.0, -1.0, 0.5, -0.5];
      L : constant Point (1 .. 4) := [-2.0, -3.0, 0.0, 1.0];
      U : constant Point (1 .. 4) := [2.0, 3.0, 4.0, 5.0];
      S : constant Point := LMO_Box (G, L, U);
   begin
      Check (Near (S (1), L (1)), "Box #1 Lower");
      Check (Near (S (2), U (2)), "Box #2 Upper");
      Check (Near (S (3), L (3)), "Box #3 Lower");
      Check (Near (S (4), U (4)), "Box #4 Upper");
   end;

   ---------------------------------------------------------------------
   Section ("24. Simplex LMO is a vertex");
   ---------------------------------------------------------------------
   declare
      G : constant Point (1 .. 6) :=
        [0.9, 0.8, 0.7, 0.1, 0.5, 0.6];
      S : constant Point := LMO_Simplex (G);
      Ones : Natural := 0;
      Sum  : Real := 0.0;
   begin
      for I in S'Range loop
         Sum := Sum + S (I);
         if Near (S (I), 1.0) then
            Ones := Ones + 1;
         else
            Check (Near (S (I), 0.0), "Non-support coord zero");
         end if;
      end loop;
      Check (Ones = 1, "Exactly one ones-hot");
      Check (Near (Sum, 1.0), "Vertex sum 1");
      Check (Near (S (4), 1.0), "Picked argmin index 4");
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
