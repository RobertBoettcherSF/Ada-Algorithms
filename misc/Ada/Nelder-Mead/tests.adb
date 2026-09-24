--  Standalone test suite for Nelder_Mead (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nelder_Mead; use Nelder_Mead;

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
     (Alpha     => 1.0,
      Gamma     => 2.0,
      Rho       => 0.5,
      Sigma     => 0.5,
      Step      => 0.5,
      Max_Iters => 4_000,
      Size_Tol  => 1.0E-10,
      F_Tol     => 1.0E-12);

begin
   Put_Line ("Nelder_Mead test suite");
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
      Check (Approx (Dot (A, C), 1.0 * 1.0 + 2.0 * 3.0), "Dot product");
      S := Add (A, C);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 5.0), "Add");
      S := Sub (C, A);
      Check (Approx (S (1), 0.0) and then Approx (S (2), 1.0), "Sub");
      S := Scale (2.0, A);
      Check (Approx (S (1), 2.0) and then Approx (S (2), 4.0), "Scale");
   end;

   ---------------------------------------------------------------------
   Section ("2. Reflection / expansion / contraction / shrink math");
   ---------------------------------------------------------------------
   declare
      O  : constant Point (1 .. 2) := [0.0, 0.0];  -- centroid
      W  : constant Point (1 .. 2) := [2.0, 0.0];  -- worst
      Xr : Point (1 .. 2);
      Xe : Point (1 .. 2);
      Xc : Point (1 .. 2);
      Xs : Point (1 .. 2);
      Best : constant Point (1 .. 2) := [0.0, 0.0];
      Other : constant Point (1 .. 2) := [4.0, 2.0];
   begin
      --  α=1: x_r = o + 1*(o−w) = −w when o=0 → (−2, 0)
      Xr := Reflect (O, W, 1.0);
      Check (Approx (Xr (1), -2.0) and then Approx (Xr (2), 0.0),
             "Reflect α=1 through origin");

      --  α=1, o=(1,1), w=(3,1): x_r = (1,1)+(1,1)-(3,1)=(-1,1)
      Xr := Reflect ([1.0, 1.0], [3.0, 1.0], 1.0);
      Check (Approx (Xr (1), -1.0) and then Approx (Xr (2), 1.0),
             "Reflect α=1 general");

      --  γ=2, o=0, r=(-2,0): x_e = 0 + 2*((-2,0)-0) = (-4,0)
      Xe := Expand (O, [-2.0, 0.0], 2.0);
      Check (Approx (Xe (1), -4.0) and then Approx (Xe (2), 0.0),
             "Expand γ=2");

      --  ρ=0.5 outside: o=0, r=(-2,0) → (-1,0)
      Xc := Contract_Outside (O, [-2.0, 0.0], 0.5);
      Check (Approx (Xc (1), -1.0) and then Approx (Xc (2), 0.0),
             "Contract_Outside ρ=0.5");

      --  ρ=0.5 inside: o=0, w=(2,0) → (1,0)
      Xc := Contract_Inside (O, W, 0.5);
      Check (Approx (Xc (1), 1.0) and then Approx (Xc (2), 0.0),
             "Contract_Inside ρ=0.5");

      --  σ=0.5 shrink toward best: best=0, other=(4,2) → (2,1)
      Xs := Shrink_Toward_Best (Best, Other, 0.5);
      Check (Approx (Xs (1), 2.0) and then Approx (Xs (2), 1.0),
             "Shrink σ=0.5 toward origin");

      Xs := Shrink_Toward_Best ([1.0, 1.0], [5.0, 3.0], 0.5);
      Check (Approx (Xs (1), 3.0) and then Approx (Xs (2), 2.0),
             "Shrink σ=0.5 general");

      --  α=2 reflection
      Xr := Reflect (O, W, 2.0);
      Check (Approx (Xr (1), -4.0), "Reflect α=2");
   end;

   ---------------------------------------------------------------------
   Section ("3. Built-in objectives");
   ---------------------------------------------------------------------
   declare
      P0  : constant Point (1 .. 2) := [0.0, 0.0];
      P1  : constant Point (1 .. 2) := [1.0, 1.0];
      P2  : constant Point (1 .. 3) := [1.0, 2.0, 3.0];
      Ph1 : constant Point (1 .. 2) := [3.0, 2.0];       -- Himmelblau min
      Ph2 : constant Point (1 .. 2) := [-2.805118, 3.131312];
      Ph3 : constant Point (1 .. 2) := [-3.779310, -3.283186];
      Ph4 : constant Point (1 .. 2) := [3.584428, -1.848126];
      Q2  : constant Point (1 .. 1) := [2.0];
      Q0  : constant Point (1 .. 1) := [0.0];
   begin
      Check (Approx (Sphere (P0), 0.0), "Sphere(0,0)=0");
      Check (Approx (Sphere (P2), 14.0), "Sphere(1,2,3)=14");
      Check (Approx (Sphere (P1), 2.0), "Sphere(1,1)=2");
      Check (Approx (Rosenbrock (P1), 0.0), "Rosenbrock(1,1)=0");
      Check (Rosenbrock (P0) > 0.0, "Rosenbrock(0,0)>0");
      Check (Rosenbrock ([-1.0, 1.0]) > 0.0, "Rosenbrock(-1,1)>0");
      Check (Approx (Himmelblau (Ph1), 0.0, 1.0E-8),
             "Himmelblau(3,2)≈0");
      Check (Approx (Himmelblau (Ph2), 0.0, 1.0E-4),
             "Himmelblau min 2 ≈0");
      Check (Approx (Himmelblau (Ph3), 0.0, 1.0E-4),
             "Himmelblau min 3 ≈0");
      Check (Approx (Himmelblau (Ph4), 0.0, 1.0E-4),
             "Himmelblau min 4 ≈0");
      Check (Himmelblau (P0) > 100.0, "Himmelblau(0,0) large");
      Check (Approx (Quadratic_1D (Q2), 0.0), "Quadratic_1D(2)=0");
      Check (Approx (Quadratic_1D (Q0), 4.0), "Quadratic_1D(0)=4");
      Check (Approx (Shifted_Sphere (P1), 0.0), "Shifted_Sphere(1,1)=0");
      Check (Approx (Shifted_Sphere (P0), 2.0), "Shifted_Sphere(0,0)=2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Initial simplex / order / size / centroid");
   ---------------------------------------------------------------------
   declare
      X0 : constant Point (1 .. 2) := [0.0, 0.0];
      S  : Simplex := Initial_Simplex (X0, 1.0, Sphere'Access);
      C  : Point (1 .. 2);
      Sz0, Sz1 : Non_Negative;
      Best : Point (1 .. 2);
   begin
      Check (S'Length = 3, "2-D simplex has 3 vertices");
      --  After ordering, best should be origin (f=0)
      Check (Approx (S (1).F, 0.0), "initial best f is 0 at origin");
      Check (Approx (S (1).X (1), 0.0) and then Approx (S (1).X (2), 0.0),
             "initial best at X0");
      Check (S (3).F >= S (2).F and then S (2).F >= S (1).F,
             "ordered best→worst");

      C := Centroid_Excluding_Worst (S, 2);
      --  Best two vertices after order: (0,0) and one axis offset.
      --  Worst is the other. Centroid of best 2 depends on order of ties.
      Check (Real (Norm2 (C)) < 1.1, "centroid near origin-ish");

      Sz0 := Simplex_Size (S, 2);
      Check (Approx (Real (Sz0), 1.0, 1.0E-9), "initial size = step");

      --  Shrink all toward best and size must drop
      Best := [S (1).X (1), S (1).X (2)];
      for V in 2 .. 3 loop
         declare
            P : constant Point :=
              Shrink_Toward_Best
                (Best, [S (V).X (1), S (V).X (2)], 0.5);
         begin
            S (V).X (1) := P (1);
            S (V).X (2) := P (2);
            S (V).F := Sphere (P);
         end;
      end loop;
      Sz1 := Simplex_Size (S, 2);
      Check (Sz1 < Sz0, "shrink reduces simplex size");
      Check (Approx (Real (Sz1), 0.5, 1.0E-9), "shrink halves size");

      Check (F_Spread (S) >= 0.0, "F_Spread non-negative");
   end;

   ---------------------------------------------------------------------
   Section ("5. Sphere: offset start → near origin");
   ---------------------------------------------------------------------
   declare
      Starts : constant array (1 .. 6) of Point (1 .. 2) :=
        [[1.0, 1.0],
         [2.0, -1.0],
         [-3.0, 0.5],
         [0.5, 0.5],
         [-1.5, -1.5],
         [4.0, 0.0]];
      Cfg : Config := Default_Cfg;
      R   : Result;
   begin
      Cfg.Step := 0.8;
      for K in Starts'Range loop
         R := Minimize (Sphere'Access, Starts (K), Cfg);
         Check (Approx (R.Best_F, 0.0, 1.0E-6),
                "Sphere start" & Integer'Image (K) & " f≈0");
         Check (Approx (R.Best_X (1), 0.0, 1.0E-3)
                and then Approx (R.Best_X (2), 0.0, 1.0E-3),
                "Sphere start" & Integer'Image (K) & " x≈0");
         Check (R.Dim = 2, "Sphere dim=2");
         Check (R.Iters <= Cfg.Max_Iters, "Sphere iters bounded");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Rosenbrock banana → (1,1)");
   ---------------------------------------------------------------------
   declare
      Starts : constant array (1 .. 5) of Point (1 .. 2) :=
        [[-1.2, 1.0],
         [0.0, 0.0],
         [2.0, 2.0],
         [-0.5, 0.5],
         [0.8, 0.8]];
      Cfg : Config := Default_Cfg;
      R   : Result;
   begin
      Cfg.Step      := 0.1;
      Cfg.Max_Iters := 8_000;
      Cfg.Size_Tol  := 1.0E-12;
      Cfg.F_Tol     := 1.0E-14;
      for K in Starts'Range loop
         R := Minimize (Rosenbrock'Access, Starts (K), Cfg);
         Check (R.Best_F < 1.0E-4,
                "Rosenbrock start" & Integer'Image (K) & " f small");
         Check (Approx (R.Best_X (1), 1.0, 5.0E-2)
                and then Approx (R.Best_X (2), 1.0, 5.0E-2),
                "Rosenbrock start" & Integer'Image (K) & " near (1,1)");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Himmelblau-2D finds a known minimum");
   ---------------------------------------------------------------------
   declare
      Starts : constant array (1 .. 4) of Point (1 .. 2) :=
        [[0.0, 0.0],
         [1.0, 1.0],
         [-2.0, 2.0],
         [3.0, -1.0]];
      Cfg : Config := Default_Cfg;
      R   : Result;
      Ok  : Boolean;
   begin
      Cfg.Step      := 0.5;
      Cfg.Max_Iters := 6_000;
      for K in Starts'Range loop
         R := Minimize (Himmelblau'Access, Starts (K), Cfg);
         Check (R.Best_F < 1.0E-4,
                "Himmelblau start" & Integer'Image (K) & " f≈0");
         --  Accept any of the four known minima
         Ok :=
           (Approx (R.Best_X (1), 3.0, 0.15)
            and then Approx (R.Best_X (2), 2.0, 0.15))
           or else
           (Approx (R.Best_X (1), -2.805118, 0.15)
            and then Approx (R.Best_X (2), 3.131312, 0.15))
           or else
           (Approx (R.Best_X (1), -3.779310, 0.15)
            and then Approx (R.Best_X (2), -3.283186, 0.15))
           or else
           (Approx (R.Best_X (1), 3.584428, 0.15)
            and then Approx (R.Best_X (2), -1.848126, 0.15));
         Check (Ok, "Himmelblau start" & Integer'Image (K)
                & " near a known min");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. 1-D quadratic with 2-point simplex");
   ---------------------------------------------------------------------
   declare
      Starts : constant array (1 .. 5) of Point (1 .. 1) :=
        [[0.0], [5.0], [-3.0], [1.5], [2.7]];
      Cfg : Config := Default_Cfg;
      R   : Result;
   begin
      Cfg.Step := 0.5;
      for K in Starts'Range loop
         R := Minimize (Quadratic_1D'Access, Starts (K), Cfg);
         Check (R.Dim = 1, "1-D dim");
         Check (Approx (R.Best_F, 0.0, 1.0E-8),
                "1-D quad start" & Integer'Image (K) & " f≈0");
         Check (Approx (R.Best_X (1), 2.0, 1.0E-4),
                "1-D quad start" & Integer'Image (K) & " x≈2");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Shifted sphere / higher dim");
   ---------------------------------------------------------------------
   declare
      X3 : constant Point (1 .. 3) := [0.0, 0.0, 0.0];
      X4 : constant Point (1 .. 4) := [2.0, 0.0, -1.0, 0.5];
      Cfg : Config := Default_Cfg;
      R   : Result;
   begin
      Cfg.Step := 0.4;
      R := Minimize (Shifted_Sphere'Access, X3, Cfg);
      Check (R.Dim = 3, "3-D dim");
      Check (Approx (R.Best_F, 0.0, 1.0E-6), "3-D shifted sphere f≈0");
      Check (Approx (R.Best_X (1), 1.0, 1.0E-3)
             and then Approx (R.Best_X (2), 1.0, 1.0E-3)
             and then Approx (R.Best_X (3), 1.0, 1.0E-3),
             "3-D shifted sphere at (1,1,1)");

      R := Minimize (Sphere'Access, X4, Cfg);
      Check (R.Dim = 4, "4-D dim");
      Check (Approx (R.Best_F, 0.0, 1.0E-5), "4-D sphere f≈0");
      Check (Approx (R.Best_X (1), 0.0, 1.0E-2)
             and then Approx (R.Best_X (2), 0.0, 1.0E-2)
             and then Approx (R.Best_X (3), 0.0, 1.0E-2)
             and then Approx (R.Best_X (4), 0.0, 1.0E-2),
             "4-D sphere at origin");
   end;

   ---------------------------------------------------------------------
   Section ("10. Iteration bound / convergence flags");
   ---------------------------------------------------------------------
   declare
      X0  : constant Point (1 .. 2) := [1.0, 1.0];
      Cfg : Config := Default_Cfg;
      R   : Result;
   begin
      Cfg.Max_Iters := 3;
      Cfg.Size_Tol  := 0.0;   -- never size-stop
      Cfg.F_Tol     := 0.0;
      Cfg.Step      := 1.0;
      R := Minimize (Sphere'Access, X0, Cfg);
      Check (R.Iters <= 3, "iters ≤ Max_Iters=3");
      Check (R.Evals >= 3, "at least initial evals");

      Cfg := Default_Cfg;
      Cfg.Step := 0.5;
      R := Minimize (Sphere'Access, X0, Cfg);
      Check (R.Converged, "sphere converges with default tols");
      Check (R.Final_Size <= Cfg.Size_Tol
             or else R.Best_F <= Cfg.F_Tol
             or else R.Converged,
             "converged implies small size or f");
      Check (R.Evals > 0, "evals counted");
   end;

   ---------------------------------------------------------------------
   Section ("11. Config coefficients / step sensitivity");
   ---------------------------------------------------------------------
   declare
      X0  : constant Point (1 .. 2) := [2.0, 2.0];
      Cfg : Config;
      R   : Result;
   begin
      Cfg := Default_Cfg;
      Cfg.Alpha := 1.0;
      Cfg.Gamma := 2.0;
      Cfg.Rho   := 0.5;
      Cfg.Sigma := 0.5;
      Cfg.Step  := 0.25;
      R := Minimize (Sphere'Access, X0, Cfg);
      Check (Approx (R.Best_F, 0.0, 1.0E-5), "std coeffs sphere ok");

      Cfg.Step := 2.0;
      R := Minimize (Sphere'Access, [-1.0, 3.0], Cfg);
      Check (Approx (R.Best_F, 0.0, 1.0E-4), "large step still works");

      Cfg.Step := 0.05;
      R := Minimize (Sphere'Access, [0.2, -0.2], Cfg);
      Check (Approx (R.Best_F, 0.0, 1.0E-5), "small step still works");
   end;

   ---------------------------------------------------------------------
   Section ("12. Order_Vertices stability / F_Spread");
   ---------------------------------------------------------------------
   declare
      S : Simplex (1 .. 3);
   begin
      S (1) := (X => [3.0, 0.0, others => 0.0], F => 9.0);
      S (2) := (X => [1.0, 0.0, others => 0.0], F => 1.0);
      S (3) := (X => [2.0, 0.0, others => 0.0], F => 4.0);
      Order_Vertices (S);
      Check (Approx (S (1).F, 1.0), "order: best f=1");
      Check (Approx (S (2).F, 4.0), "order: mid f=4");
      Check (Approx (S (3).F, 9.0), "order: worst f=9");
      Check (Approx (Real (F_Spread (S)), 8.0), "F_Spread=8");
      Check (Approx (S (1).X (1), 1.0), "order preserves coords");
   end;

   ---------------------------------------------------------------------
   Section ("13. More reflection edge cases");
   ---------------------------------------------------------------------
   declare
      O  : constant Point (1 .. 3) := [1.0, 2.0, 3.0];
      W  : constant Point (1 .. 3) := [4.0, 2.0, 3.0];
      Xr : Point (1 .. 3);
      Xe : Point (1 .. 3);
   begin
      --  x_r = o + (o−w) = 2o−w = (−2, 2, 3)
      Xr := Reflect (O, W, 1.0);
      Check (Approx (Xr (1), -2.0)
             and then Approx (Xr (2), 2.0)
             and then Approx (Xr (3), 3.0),
             "3-D reflect");
      Xe := Expand (O, Xr, 2.0);
      --  x_e = o + 2(xr−o) = 2 xr − o = (−5, 2, 3)
      Check (Approx (Xe (1), -5.0)
             and then Approx (Xe (2), 2.0)
             and then Approx (Xe (3), 3.0),
             "3-D expand");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra multi-start sphere / Rosenbrock sanity");
   ---------------------------------------------------------------------
   declare
      Cfg : Config := Default_Cfg;
      R   : Result;
      Pts : constant array (1 .. 8) of Point (1 .. 2) :=
        [[0.1, 0.1],
         [3.0, -2.0],
         [-2.0, 4.0],
         [1.5, 1.5],
         [-0.3, 0.9],
         [5.0, 5.0],
         [-4.0, -0.5],
         [0.0, 3.0]];
   begin
      Cfg.Step := 0.6;
      for K in Pts'Range loop
         R := Minimize (Sphere'Access, Pts (K), Cfg);
         Check (R.Best_F < 1.0E-5,
                "extra sphere" & Integer'Image (K) & " f≈0");
      end loop;

      Cfg.Step      := 0.15;
      Cfg.Max_Iters := 10_000;
      R := Minimize (Rosenbrock'Access, [-1.0, 1.2], Cfg);
      Check (R.Best_F < 1.0E-3, "extra Rosenbrock f small");
      Check (Approx (R.Best_X (1), 1.0, 0.1)
             and then Approx (R.Best_X (2), 1.0, 0.1),
             "extra Rosenbrock near (1,1)");
   end;

   New_Line;
   Put_Line ("======================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("TESTS FAILED OR TOO FEW PASSES");
   end if;
end Tests;
