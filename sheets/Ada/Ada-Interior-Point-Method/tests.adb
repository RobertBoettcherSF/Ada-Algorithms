--  Standalone test suite for Interior_Point_Method (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Interior_Point_Method; use Interior_Point_Method;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Default_Cfg : constant Config :=
     (Max_Iterations  => 200,
      Tol             => 1.0E-8,
      Step_Fraction   => 0.9,
      Min_Step        => 1.0E-14,
      Method          => Affine_Scaling,
      Mu_Init         => 1.0,
      Mu_Min          => 1.0E-10,
      Mu_Factor       => 0.1,
      Centering_Iters => 8);

   Loose_Cfg : constant Config :=
     (Max_Iterations  => 400,
      Tol             => 1.0E-6,
      Step_Fraction   => 0.95,
      Min_Step        => 1.0E-14,
      Method          => Affine_Scaling,
      Mu_Init         => 1.0,
      Mu_Min          => 1.0E-10,
      Mu_Factor       => 0.1,
      Centering_Iters => 8);

   Barrier_Cfg : constant Config :=
     (Max_Iterations  => 500,
      Tol             => 1.0E-6,
      Step_Fraction   => 0.9,
      Min_Step        => 1.0E-14,
      Method          => Logarithmic_Barrier,
      Mu_Init         => 10.0,
      Mu_Min          => 1.0E-8,
      Mu_Factor       => 0.2,
      Centering_Iters => 10);

begin
   Ada.Text_IO.Put_Line ("Interior_Point_Method test suite");
   Ada.Text_IO.Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Dot / Norms");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Vec_Near (U, W, 1.5), "Vec_Near loose Tol");
      Check (not Near (1.0, 2.0, 0.1), "Near reject mid");
      Check (Near (1.0, 1.05, 0.1), "Near accept mid");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (Near (-1.0E-12, 1.0E-12, 1.0E-10), "Near both tiny");
      Check (not Near (-1.0, 1.0), "Near opposite signs");
      Check (Approx (Dot (U, V), 14.0), "Dot U·V=14");
      Check (Approx (Dot (U, W), 17.0), "Dot U·W=17");
      Check (Approx (Norm_Inf (U), 3.0), "Norm_Inf U=3");
      Check (Approx (Norm2 (U) * Norm2 (U), 14.0, 1.0E-12), "Norm2 U squared");
      Check (Approx (Norm_Inf ([-2.0, 0.5]), 2.0), "Norm_Inf abs");
   end;

   ---------------------------------------------------------------------
   Section ("2. Scale / Add / Sub / All_Positive");
   ---------------------------------------------------------------------
   declare
      A : constant Vector (1 .. 2) := [1.0, -2.0];
      B : constant Vector (1 .. 2) := [3.0, 4.0];
      S : constant Vector := Scale (2.0, A);
      P : constant Vector := Add (A, B);
      D : constant Vector := Sub (A => B, B => A);
      Pos : constant Vector (1 .. 3) := [0.1, 0.2, 0.3];
      Mix : constant Vector (1 .. 3) := [0.1, 0.0, 0.3];
   begin
      Check (Approx (S (1), 2.0) and then Approx (S (2), -4.0), "Scale");
      Check (Approx (P (1), 4.0) and then Approx (P (2), 2.0), "Add");
      Check (Approx (D (1), 2.0) and then Approx (D (2), 6.0), "Sub");
      Check (All_Positive (Pos, 0.0), "All_Positive true");
      Check (not All_Positive (Mix, 0.0), "All_Positive rejects zero");
      Check (not All_Positive ([-1.0, 2.0], 0.0), "All_Positive rejects neg");
      Check (All_Positive (Pos, 0.05), "All_Positive with Tol");
      Check (not All_Positive (Pos, 0.25), "All_Positive Tol reject");
   end;

   ---------------------------------------------------------------------
   Section ("3. Mat_Vec / Mat_Vec_T / Solve_GE / Solve_SPD");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 0.0],
         [0.0, 1.0, 3.0]];
      X : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      Y : constant Vector := Mat_Vec (A, X);
      Z : constant Vector := Mat_Vec_T (A, [1.0, 1.0]);
      I2 : constant Square_Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      SPD : constant Square_Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0],
         [1.0, 3.0]];
      Rhs : constant Vector (1 .. 2) := [1.0, 2.0];
      Sol : Vector (1 .. 2);
      Sing_Raised : Boolean := False;
   begin
      Check (Approx (Y (1), 3.0) and then Approx (Y (2), 4.0),
             "Mat_Vec A x");
      Check (Approx (Z (1), 1.0) and then Approx (Z (2), 3.0)
             and then Approx (Z (3), 3.0),
             "Mat_Vec_T Aᵀ y");
      Sol := Mat_Vec (I2, [5.0, -3.0]);
      Check (Approx (Sol (1), 5.0) and then Approx (Sol (2), -3.0),
             "Square Mat_Vec identity");
      Sol := Solve_SPD (I2, [5.0, -3.0]);
      Check (Approx (Sol (1), 5.0) and then Approx (Sol (2), -3.0),
             "Solve_SPD identity");
      Sol := Solve_GE (SPD, Rhs);
      Check (Approx (Sol (1), 1.0 / 11.0, 1.0E-12), "Solve_GE x=1/11");
      Check (Approx (Sol (2), 7.0 / 11.0, 1.0E-12), "Solve_GE y=7/11");
      Sol := Solve_SPD (SPD, Rhs);
      Check (Approx (Sol (1), 1.0 / 11.0, 1.0E-12), "Solve_SPD x=1/11");
      Check (Approx (Sol (2), 7.0 / 11.0, 1.0E-12), "Solve_SPD y=7/11");
      declare
         Recover : constant Vector := Mat_Vec (SPD, Sol);
      begin
         Check (Approx (Recover (1), 1.0, 1.0E-10), "SPD recover b1");
         Check (Approx (Recover (2), 2.0, 1.0E-10), "SPD recover b2");
      end;
      declare
         Sing : constant Square_Matrix (1 .. 2, 1 .. 2) :=
           [[1.0, 2.0],
            [2.0, 4.0]];
      begin
         begin
            Sol := Solve_GE (Sing, [1.0, 2.0]);
         exception
            when Singular_System =>
               Sing_Raised := True;
         end;
         Check (Sing_Raised, "Solve_GE raises Singular_System");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Project_Nullspace / Feasible_Residual");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      V : constant Vector (1 .. 2) := [1.0, -1.0];
      P : constant Vector := Project_Nullspace (A, V);
      --  V already in nullspace → projection ≈ V
      W : constant Vector (1 .. 2) := [3.0, 1.0];
      Q : constant Vector := Project_Nullspace (A, W);
      --  A Q = 0, Q = W − mean*(1,1)
   begin
      Check (Approx (P (1), 1.0, 1.0E-10) and then Approx (P (2), -1.0, 1.0E-10),
             "Project null vector");
      Check (Approx (Q (1) + Q (2), 0.0, 1.0E-10), "Projected sum zero");
      Check (Approx (Feasible_Residual (A, [2.0], [1.0, 1.0]), 0.0, 1.0E-12),
             "Feasible residual zero");
      Check (Approx (Feasible_Residual (A, [2.0], [1.0, 0.5]), 0.5, 1.0E-12),
             "Feasible residual 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("5. Taxonomy Method_Name / Classify_Method");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      Check (Method_Name (Affine_Scaling) = "affine-scaling",
             "Name affine-scaling");
      Check (Method_Name (Logarithmic_Barrier) = "logarithmic-barrier",
             "Name logarithmic-barrier");
      Check (Method_Name (Primal_Dual) = "primal-dual",
             "Name primal-dual");
      Check (Classify_Method ("affine") = Affine_Scaling, "Classify affine");
      Check (Classify_Method ("AFFINE-SCALING") = Affine_Scaling,
             "Classify AFFINE-SCALING");
      Check (Classify_Method ("barrier") = Logarithmic_Barrier,
             "Classify barrier");
      Check (Classify_Method ("log-barrier") = Logarithmic_Barrier,
             "Classify log-barrier");
      Check (Classify_Method ("primal-dual") = Primal_Dual,
             "Classify primal-dual");
      Check (Classify_Method ("PD") = Primal_Dual, "Classify PD");
      Check (Classify_Method ("mehrotra") = Primal_Dual, "Classify mehrotra");
      begin
         declare
            Unused : Method_Kind := Classify_Method ("simplex");
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Classify rejects simplex");
   end;

   ---------------------------------------------------------------------
   Section ("6. Max_Feasible_Step / Interior_Step");
   ---------------------------------------------------------------------
   declare
      X : constant Vector (1 .. 2) := [2.0, 4.0];
      DX : constant Vector (1 .. 2) := [-1.0, -2.0];
      Alpha : constant Real := Max_Feasible_Step (X, DX);
      Y : Vector (1 .. 2);
      Unb : Boolean := False;
   begin
      Check (Approx (Alpha, 2.0), "Max_Feasible_Step=2");
      Check (Approx (Max_Feasible_Step (X, [1.0, 1.0]), Real'Last),
             "Max_Feasible_Step unbounded ray");
      Y := Interior_Step (X, DX, 0.5);
      Check (Approx (Y (1), 1.0) and then Approx (Y (2), 2.0),
             "Interior_Step half to boundary");
      --  Alpha_Max=2/10=0.2 → γ·α=0.18 < Min_Step=1 → unchanged X
      Y := Interior_Step (X, [-10.0, 0.0], 0.9, 1.0);
      Check (Approx (Y (1), 2.0) and then Approx (Y (2), 4.0),
             "Interior_Step Min_Step stall");
      begin
         Y := Interior_Step (X, [1.0, 0.5], 0.9, 1.0E-14);
      exception
         when Invalid_Argument =>
            Unb := True;
      end;
      Check (Unb, "Interior_Step raises on unbounded");
   end;

   ---------------------------------------------------------------------
   Section ("7. Affine_Direction basic");
   ---------------------------------------------------------------------
   declare
      --  min x1 s.t. x1+x2=1, x>0. At (0.5,0.5) direction should decrease x1.
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      X : constant Vector (1 .. 2) := [0.5, 0.5];
      DX : Vector (1 .. 2);
      Rsc : Non_Negative;
   begin
      Affine_Direction (A, C, X, Minimize_Sense, DX, Rsc);
      Check (DX (1) < 0.0, "Affine min decreases x1");
      Check (DX (2) > 0.0, "Affine min increases x2");
      Check (Approx (DX (1) + DX (2), 0.0, 1.0E-10), "Affine DX in nullspace");
      Check (Rsc > 0.0, "Affine stationarity positive mid");
   end;

   ---------------------------------------------------------------------
   Section ("8. Equality min x1 (affine)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      X0 : constant Vector (1 .. 2) := [0.5, 0.5];
      R : Result;
   begin
      Check (Approx (Feasible_Residual (A, B, X0), 0.0), "eq start feasible");
      R := Minimize (A, B, C, X0, Loose_Cfg);
      Check (R.Success, "eq min Success");
      Check (R.Stat = Optimal, "eq min Optimal");
      Check (R.X (1) < 0.05, "eq min x1→0+");
      Check (Approx (R.X (1) + R.X (2), 1.0, 1.0E-4), "eq min stays on plane");
      Check (All_Positive (R.X (1 .. 2), 0.0), "eq min stays positive");
      Check (R.Objective < 0.05, "eq min obj small");
   end;

   ---------------------------------------------------------------------
   Section ("9. Equality max x1 (affine)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      X0 : constant Vector (1 .. 2) := [0.3, 0.7];
      R : Result;
   begin
      R := Maximize (A, B, C, X0, Loose_Cfg);
      Check (R.Success, "eq max Success");
      Check (R.X (1) > 0.95, "eq max x1→1-");
      Check (Approx (R.X (1) + R.X (2), 1.0, 1.0E-4), "eq max feasible");
      Check (R.Objective > 0.95, "eq max obj");
   end;

   ---------------------------------------------------------------------
   Section ("10. Classic inequality max 3x+5y (simplex twin)");
   ---------------------------------------------------------------------
   --  max 3x+5y s.t. x≤4, 2y≤12, 3x+2y≤18, x,y>0 → (2,6), z=36
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      X0 : constant Vector (1 .. 2) := [1.0, 1.0];
      R : Result;
   begin
      R := Maximize_Inequalities (A, B, C, X0, Loose_Cfg);
      Check (R.Success or else R.Stat = Optimal or else R.Stat = Iteration_Limit,
             "classic finished");
      Check (Approx (R.X (1), 2.0, 0.15), "classic x≈2");
      Check (Approx (R.X (2), 6.0, 0.15), "classic y≈6");
      Check (Approx (R.Objective, 36.0, 1.0), "classic z≈36");
      Check (R.X (1) > 0.0 and then R.X (2) > 0.0, "classic positive");
      Check (1.0 * R.X (1) <= 4.0 + 0.05, "classic x≤4");
      Check (2.0 * R.X (2) <= 12.0 + 0.1, "classic 2y≤12");
      Check (3.0 * R.X (1) + 2.0 * R.X (2) <= 18.0 + 0.2, "classic 3x+2y≤18");
   end;

   ---------------------------------------------------------------------
   Section ("11. Ill_Started / Unbounded");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, -1.0]];
      B : constant Vector (1 .. 1) := [0.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      R : Result;
   begin
      R := Maximize (A, B, C, [1.0, 1.0], Default_Cfg);
      --  x1-x2=0, max x1 is unbounded along (t,t)
      Check (R.Stat = Unbounded or else R.Stat = Iteration_Limit
             or else (R.Success and then R.X (1) > 10.0),
             "unbounded or large");
      R := Minimize (A, B, C, [0.0, 0.0], Default_Cfg);
      Check (R.Stat = Ill_Started, "non-positive start");
      Check (not R.Success, "ill not Success");
      R := Minimize ([[1.0, 1.0]], [1.0], [1.0, 0.0], [0.2, 0.2], Default_Cfg);
      Check (R.Stat = Ill_Started, "infeasible start Ax≠b");
   end;

   ---------------------------------------------------------------------
   Section ("12. Expand_Inequalities");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 2) := [3.0, 4.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      X0 : constant Vector (1 .. 2) := [1.0, 1.0];
      Aeq : Matrix (1 .. 2, 1 .. 4);
      Ceq : Vector (1 .. 4);
      Xeq : Vector (1 .. 4);
      N_Out : Var_Count;
      Bad : Boolean := False;
   begin
      Expand_Inequalities (A, B, C, X0, Aeq, Ceq, Xeq, N_Out);
      Check (N_Out = 4, "expand n=4");
      Check (Approx (Xeq (3), 2.0) and then Approx (Xeq (4), 3.0),
             "expand slacks");
      Check (Approx (Ceq (3), 0.0) and then Approx (Ceq (4), 0.0),
             "expand c slack 0");
      Check (Approx (Aeq (1, 3), 1.0) and then Approx (Aeq (2, 4), 1.0),
             "expand identity slacks");
      begin
         Expand_Inequalities (A, B, C, [5.0, 1.0], Aeq, Ceq, Xeq, N_Out);
      exception
         when Invalid_Argument =>
            Bad := True;
      end;
      Check (Bad, "expand rejects bad slack");
   end;

   ---------------------------------------------------------------------
   Section ("13. Barrier_Value / Barrier_Direction");
   ---------------------------------------------------------------------
   declare
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      X : constant Vector (1 .. 2) := [0.5, 0.5];
      Phi : constant Real := Barrier_Value (C, X, 1.0);
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      DX : Vector (1 .. 2);
      Gsc : Non_Negative;
   begin
      --  φ = 0.5 − 1·(log 0.5 + log 0.5) = 0.5 − 2 log 0.5 > 0
      Check (Phi > 0.5, "Barrier_Value > cTx");
      Barrier_Direction (A, C, X, 1.0, Minimize_Sense, DX, Gsc);
      Check (Approx (DX (1) + DX (2), 0.0, 1.0E-8), "Barrier DX nullspace");
      Check (Gsc >= 0.0, "Barrier Grad_Scaled nonnegative");
   end;

   ---------------------------------------------------------------------
   Section ("14. Equality min via barrier");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      X0 : constant Vector (1 .. 2) := [0.5, 0.5];
      R : Result;
   begin
      R := Minimize (A, B, C, X0, Barrier_Cfg);
      Check (R.Success or else R.Stat = Optimal, "barrier min Success");
      Check (R.X (1) < 0.15, "barrier min x1 small");
      Check (Approx (R.X (1) + R.X (2), 1.0, 1.0E-3), "barrier feasible");
      Check (All_Positive (R.X (1 .. 2), 0.0), "barrier positive");
      Check (R.Mu_Final <= Barrier_Cfg.Mu_Init, "barrier μ reduced");
   end;

   ---------------------------------------------------------------------
   Section ("15. Classic via barrier");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      X0 : constant Vector (1 .. 2) := [1.0, 1.0];
      R : Result;
   begin
      R := Maximize_Inequalities (A, B, C, X0, Barrier_Cfg);
      Check (R.Stat /= Ill_Started, "barrier classic not ill");
      Check (Approx (R.Objective, 36.0, 3.0), "barrier classic z≈36");
      Check (Approx (R.X (1), 2.0, 0.4), "barrier classic x≈2");
      Check (Approx (R.X (2), 6.0, 0.4), "barrier classic y≈6");
   end;

   ---------------------------------------------------------------------
   Section ("16. Solve dispatch / Solve_Affine / Solve_Barrier");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [0.0, 1.0];
      X0 : constant Vector (1 .. 2) := [0.4, 0.6];
      Ra, Rb, Rc : Result;
      Cfg_A : Config := Default_Cfg;
      Cfg_B : Config := Barrier_Cfg;
      Cfg_PD : Config := Barrier_Cfg;
   begin
      Cfg_A.Method := Affine_Scaling;
      Cfg_B.Method := Logarithmic_Barrier;
      Cfg_PD.Method := Primal_Dual;
      Ra := Solve_Affine (A, B, C, X0, Minimize_Sense, Loose_Cfg);
      Rb := Solve (A, B, C, X0, Minimize_Sense, Cfg_B);
      Rc := Solve (A, B, C, X0, Minimize_Sense, Cfg_PD);
      Check (Ra.Success, "Solve_Affine success");
      Check (Ra.X (2) < 0.1, "Solve_Affine drives x2→0");
      Check (Rb.Success or else Rb.Stat = Optimal, "Solve Barrier dispatch");
      Check (Rc.Stat /= Ill_Started, "Primal_Dual maps to barrier");
      Check (Solve (A, B, C, X0, Minimize_Sense, Cfg_A).Success,
             "Solve Affine_Scaling dispatch");
      Check (Solve_Barrier (A, B, C, X0, Minimize_Sense, Barrier_Cfg).Stat
              /= Ill_Started,
             "Solve_Barrier direct");
   end;

   ---------------------------------------------------------------------
   Section ("17. Minimize_Inequalities small");
   ---------------------------------------------------------------------
   --  min x+y s.t. x≥1 → rewrite as −x ≤ −1 with start x=2,y=1? Better:
   --  min x s.t. x + s = 2, use equalities. Inequality: min x+2y s.t. x+y≤3
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 2.0];
      X0 : constant Vector (1 .. 2) := [1.0, 1.0];
      R : Result;
   begin
      R := Minimize_Inequalities (A, B, C, X0, Loose_Cfg);
      Check (R.Stat /= Ill_Started, "min-ineq not ill");
      Check (R.X (1) > 0.0 and then R.X (2) > 0.0, "min-ineq positive");
      --  Optimum on boundary toward reducing y first → y→0, x→0-ish but
      --  interior; objective should improve vs start 3.
      Check (R.Objective < 2.9, "min-ineq improved");
   end;

   ---------------------------------------------------------------------
   Section ("18. Config defaults / Result fields");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R : Result;
   begin
      Check (Cfg.Max_Iterations = 200, "default Max_Iterations");
      Check (Cfg.Method = Affine_Scaling, "default Method affine");
      Check (Cfg.Step_Fraction = 0.9, "default Step_Fraction");
      Check (Cfg.Mu_Init = 1.0, "default Mu_Init");
      Check (R.Stat = Ill_Started, "default Result Ill_Started");
      Check (not R.Success, "default Success False");
      Check (R.N_Vars = 0, "default N_Vars 0");
   end;

   ---------------------------------------------------------------------
   Section ("19. More GE / projection checks");
   ---------------------------------------------------------------------
   declare
      A3 : constant Square_Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 1.0, 0.0],
         [1.0, 2.0, 1.0],
         [0.0, 1.0, 2.0]];
      B3 : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      S3 : constant Vector := Solve_GE (A3, B3);
      Rec : constant Vector := Mat_Vec (A3, S3);
      A2 : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 0.0, 1.0],
         [0.0, 1.0, 1.0]];
      Pv : constant Vector := Project_Nullspace (A2, [1.0, 1.0, -1.0]);
   begin
      Check (Approx (Rec (1), 1.0, 1.0E-9), "3x3 recover 1");
      Check (Approx (Rec (2), 2.0, 1.0E-9), "3x3 recover 2");
      Check (Approx (Rec (3), 3.0, 1.0E-9), "3x3 recover 3");
      Check (Approx (Pv (1) + Pv (3), 0.0, 1.0E-9)
             and then Approx (Pv (2) + Pv (3), 0.0, 1.0E-9),
             "2-row project A P=0");
      Check (Norm2 (Pv) <= Norm2 ([1.0, 1.0, -1.0]) + 1.0E-9,
             "projection shortens or equal");
   end;

   ---------------------------------------------------------------------
   Section ("20. Two-constraint equality LP");
   ---------------------------------------------------------------------
   --  min 2x+y  s.t. x+y+z=3, x+2y=2, all >0. Start feasible.
   declare
      A : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 1.0, 1.0],
         [1.0, 2.0, 0.0]];
      B : constant Vector (1 .. 2) := [3.0, 2.0];
      C : constant Vector (1 .. 3) := [2.0, 1.0, 0.0];
      --  x=1,y=0.5,z=1.5 → Ax=[3,2]
      X0 : constant Vector (1 .. 3) := [1.0, 0.5, 1.5];
      R : Result;
   begin
      Check (Approx (Feasible_Residual (A, B, X0), 0.0, 1.0E-12),
             "2-eq start feasible");
      R := Minimize (A, B, C, X0, Loose_Cfg);
      Check (R.Stat = Optimal or else R.Success, "2-eq finished");
      Check (All_Positive (R.X (1 .. 3), 0.0), "2-eq positive");
      Check (Feasible_Residual (A, B, R.X (1 .. 3)) < 1.0E-3,
             "2-eq stays feasible");
      Check (R.Objective <= Dot (C, X0) + 1.0E-6, "2-eq improved/eq");
   end;

   ---------------------------------------------------------------------
   Section ("21. Affine vs barrier agreement (loose)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      X0 : constant Vector (1 .. 2) := [0.5, 0.5];
      Ra : constant Result :=
        Minimize (A, B, C, X0, Loose_Cfg);
      Rb : constant Result :=
        Minimize (A, B, C, X0, Barrier_Cfg);
   begin
      --  Objective is constant (=1) on the plane → both Optimal near start
      Check (Approx (Ra.Objective, 1.0, 0.05), "affine flat obj≈1");
      Check (Approx (Rb.Objective, 1.0, 0.15), "barrier flat obj≈1");
      Check (Approx (Ra.X (1) + Ra.X (2), 1.0, 1.0E-3), "affine flat feas");
      Check (Approx (Rb.X (1) + Rb.X (2), 1.0, 1.0E-3), "barrier flat feas");
   end;

   ---------------------------------------------------------------------
   Section ("22. Step_Fraction invalid");
   ---------------------------------------------------------------------
   declare
      Bad : Config := Default_Cfg;
      Raised : Boolean := False;
   begin
      Bad.Step_Fraction := 1.0;
      begin
         declare
            R : constant Result :=
              Minimize ([[1.0, 1.0]], [1.0], [1.0, 0.0], [0.5, 0.5], Bad);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "invalid Step_Fraction raises");
   end;

   ---------------------------------------------------------------------
   Section ("23. Dot / Scale edge cases");
   ---------------------------------------------------------------------
   declare
      Z : constant Vector (1 .. 1) := [0.0];
      E : constant Vector (1 .. 4) := [1.0, -1.0, 2.0, -2.0];
   begin
      Check (Approx (Dot (Z, Z), 0.0), "Dot zero");
      Check (Approx (Norm_Inf (E), 2.0), "Norm_Inf E");
      Check (Approx (Norm2 (E) * Norm2 (E), 10.0, 1.0E-12), "Norm2 E^2");
      Check (Approx (Scale (0.0, E) (1), 0.0), "Scale by zero");
      Check (Approx (Add (E, Scale (-1.0, E)) (2), 0.0), "Add cancel");
   end;

   ---------------------------------------------------------------------
   Section ("24. Maximize_Inequalities ill slack");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      R : Result;
   begin
      R := Maximize_Inequalities (A, [1.0], [1.0], [2.0], Default_Cfg);
      Check (R.Stat = Ill_Started, "ineq ill when x0 outside");
   end;

   ---------------------------------------------------------------------
   Section ("25. Tiny maximize equality pair");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 3) := [[1.0, 1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      X0 : constant Vector (1 .. 3) := [0.2, 0.3, 0.5];
      R : Result;
   begin
      R := Maximize (A, B, C, X0, Loose_Cfg);
      Check (R.Success, "3-var max success");
      Check (R.X (3) > R.X (1), "3-var prefers largest c");
      Check (Approx (R.X (1) + R.X (2) + R.X (3), 1.0, 1.0E-3),
             "3-var feasible");
      Check (R.Objective > Dot (C, X0) - 1.0E-6, "3-var improved");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===============================");
   Ada.Text_IO.Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Ada.Text_IO.Put_Line
        ("WARNING: Fail_Count=0 but Pass_Count < 100");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
