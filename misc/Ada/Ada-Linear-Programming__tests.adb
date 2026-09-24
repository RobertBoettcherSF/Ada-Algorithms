--  Standalone test suite for Linear_Programming (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Linear_Programming; use Linear_Programming;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Cfg : constant Config := Default_Config;

begin
   Ada.Text_IO.Put_Line ("Linear_Programming test suite");
   Ada.Text_IO.Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near / Dot / Objective_Value");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      X : constant Vector (1 .. 2) := [2.0, 1.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Vec_Near (U, W, 1.5), "Vec_Near loose Tol");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (not Near (-1.0, 1.0), "Near opposite signs");
      Check (Approx (Dot (U, V), 14.0), "Dot 1+4+9=14");
      Check (Approx (Objective_Value (C, X), 11.0), "Objective 3*2+5*1");
      Check (Approx (Dot ([2.0], [4.0]), 8.0), "Dot singleton");
   end;

   ---------------------------------------------------------------------
   Section ("2. Taxonomy Method_Kind / Form_Kind");
   ---------------------------------------------------------------------
   declare
      ISX : constant Method_Info := Classify_Method (Simplex);
      IIP : constant Method_Info := Classify_Method (Interior_Point);
      IEL : constant Method_Info := Classify_Method (Ellipsoid);
      IDS : constant Method_Info := Classify_Method (Dual_Simplex);
   begin
      Check (Method_Count = 4, "Method_Count=4");
      Check (Form_Count = 3, "Form_Count=3");
      Check (ISX.Fully_Implemented, "Simplex implemented");
      Check (ISX.Uses_Basis_Exchange, "Simplex uses basis");
      Check (not ISX.Polynomial_Worst_Case, "Simplex not poly worst");
      Check (not IIP.Fully_Implemented, "IP flag only");
      Check (IIP.Polynomial_Worst_Case, "IP poly worst-case");
      Check (not IIP.Uses_Basis_Exchange, "IP no basis exchange");
      Check (IEL.Polynomial_Worst_Case, "Ellipsoid poly");
      Check (not IEL.Fully_Implemented, "Ellipsoid flag only");
      Check (IDS.Uses_Basis_Exchange, "Dual simplex basis");
      Check (not IDS.Fully_Implemented, "Dual simplex flag only");
      Check (Method_Name (Simplex) = "Simplex", "Method_Name Simplex");
      Check (Method_Name (Interior_Point) = "Interior_Point",
             "Method_Name Interior_Point");
      Check (Method_Name (Ellipsoid) = "Ellipsoid", "Method_Name Ellipsoid");
      Check (Method_Name (Dual_Simplex) = "Dual_Simplex",
             "Method_Name Dual_Simplex");
      Check (Form_Name (Canonical) = "Canonical", "Form_Name Canonical");
      Check (Form_Name (Standard_Equality) = "Standard_Equality", "Form_Name Standard_Equality");
      Check (Form_Name (Slack) = "Slack", "Form_Name Slack");
   end;

   ---------------------------------------------------------------------
   Section ("3. Slack form / Mat_Vec / feasibility helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      X_Ok : constant Vector (1 .. 2) := [1.0, 1.0];
      X_Bad : constant Vector (1 .. 2) := [5.0, 0.0];
      Out_A : Matrix (1 .. 2, 1 .. 4);
      W : Vector (1 .. 2);
      Ax : Vector (1 .. 2);
   begin
      Check (Slack_Column_Count (2) = 2, "Slack_Column_Count 2");
      Check (Slack_Column_Count (0) = 0, "Slack_Column_Count 0");
      Append_Slacks (A, Out_A);
      Check (Approx (Out_A (1, 1), 1.0), "Append A11");
      Check (Approx (Out_A (1, 2), 1.0), "Append A12");
      Check (Approx (Out_A (1, 3), 1.0), "Append slack1");
      Check (Approx (Out_A (1, 4), 0.0), "Append off-diag slack");
      Check (Approx (Out_A (2, 1), 2.0), "Append A21");
      Check (Approx (Out_A (2, 4), 1.0), "Append slack2");
      Ax := Mat_Vec (A, X_Ok);
      Check (Approx (Ax (1), 2.0), "Mat_Vec row1");
      Check (Approx (Ax (2), 3.0), "Mat_Vec row2");
      W := Primal_Slack (A, B, X_Ok);
      Check (Approx (W (1), 2.0), "Primal slack1");
      Check (Approx (W (2), 3.0), "Primal slack2");
      Check (Feasible_Inequality (A, B, X_Ok), "feasible point");
      Check (not Feasible_Inequality (A, B, X_Bad), "infeasible point");
      Check (Is_Nonnegative ([0.0, 1.0, 2.0]), "Is_Nonnegative ok");
      Check (not Is_Nonnegative ([0.0, -1.0]), "Is_Nonnegative reject");
   end;

   ---------------------------------------------------------------------
   Section ("4. Build_Tableau slack basis (b ≥ 0)");
   ---------------------------------------------------------------------
   declare
      --  max 3x+5y s.t. x≤4, 2y≤12, 3x+2y≤18
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      T : constant Tableau := Build_Tableau (A, B, C);
   begin
      Check (T.M = 3, "M=3");
      Check (T.N_Decision = 2, "N_Decision=2");
      Check (T.N_Slack = 3, "N_Slack=3");
      Check (T.N_Artificial = 0, "no artificials");
      Check (T.N = 5, "N=5 columns");
      Check (T.Obj_Phase1 = 0, "no Phase-I");
      Check (Approx (T.T (0, 1), -3.0), "reduced cost −c1");
      Check (Approx (T.T (0, 2), -5.0), "reduced cost −c2");
      Check (Approx (T.T (1, 0), 4.0), "RHS1");
      Check (Approx (T.T (2, 0), 12.0), "RHS2");
      Check (Approx (T.T (3, 0), 18.0), "RHS3");
      Check (T.Basic (1) = 3, "basic1 slack");
      Check (T.Basic (2) = 4, "basic2 slack");
      Check (T.Basic (3) = 5, "basic3 slack");
      Check (not Is_Optimal_LP (T), "initial not optimal");
      Check (Select_Entering (T) = 1, "Bland enters col 1");
      Check (Active_Obj_Row (T) = 0, "Active_Obj_Row phase II");
   end;

   ---------------------------------------------------------------------
   Section ("5. Maximize classic diet / production LP");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      R : constant Result := Maximize (A, B, C, Cfg);
   begin
      Check (R.Success, "Maximize success");
      Check (R.Stat = Optimal, "Maximize Optimal");
      Check (Approx (R.Objective, 36.0), "opt z=36");
      Check (Approx (R.X (1), 2.0), "x*=2");
      Check (Approx (R.X (2), 6.0), "y*=6");
      Check (R.N_Vars = 2, "N_Vars=2");
      Check (R.N_Pivots >= 1, "pivots >= 1");
      Check (Feasible_Inequality (A, B, R.X (1 .. 2)), "opt feasible");
   end;

   ---------------------------------------------------------------------
   Section ("6. Minimize via Maximize (−c)");
   ---------------------------------------------------------------------
   declare
      --  min x+y s.t. x+y ≥ 2 rewritten as −x−y ≤ −2, x≤3, y≤3
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-2.0, 3.0, 3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Minimize (A, B, C, Cfg);
   begin
      Check (R.Success, "Minimize success");
      Check (R.Stat = Optimal, "Minimize Optimal");
      Check (Approx (R.Objective, 2.0), "min z=2");
      Check (Approx (R.X (1) + R.X (2), 2.0), "x+y=2");
      Check (R.X (1) >= -1.0E-6, "x>=0");
      Check (R.X (2) >= -1.0E-6, "y>=0");
   end;

   ---------------------------------------------------------------------
   Section ("7. Infeasible detection");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 1) :=
        [[1.0],
         [-1.0]];
      B : constant Vector (1 .. 2) := [1.0, -2.0];  -- x≤1 and −x≤−2 ⇒ x≥2
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize (A, B, C, Cfg);
   begin
      Check (not R.Success, "infeasible Success=False");
      Check (R.Stat = Infeasible, "Stat=Infeasible");
   end;

   ---------------------------------------------------------------------
   Section ("8. Unbounded detection");
   ---------------------------------------------------------------------
   declare
      --  max x s.t. −x ≤ 0  (i.e. x ≥ 0 only) → unbounded
      A : constant Matrix (1 .. 1, 1 .. 1) := [[-1.0]];
      B : constant Vector (1 .. 1) := [0.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize (A, B, C, Cfg);
   begin
      Check (not R.Success, "unbounded Success=False");
      Check (R.Stat = Unbounded, "Stat=Unbounded");
   end;

   ---------------------------------------------------------------------
   Section ("9. Weak duality");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      C : constant Vector (1 .. 2) := [3.0, 2.0];
      --  Primal opt: solve max 3x+2y s.t. x+y≤4, 2x+y≤6, x,y≥0
      --  Opt at (2,2) z=10 or (0,4) z=8 or (3,0) z=9 → (2,2)=10
      Rp : constant Result := Maximize (A, B, C, Cfg);
      --  Dual: min 4y1+6y2 s.t. y1+2y2≥3, y1+y2≥2, y≥0
      --  Opt y=(1,1): 4+6=10; Aᵀy=(1+2,1+1)=(3,2)=c
      Y_Opt : constant Vector (1 .. 2) := [1.0, 1.0];
      X_Sub : constant Vector (1 .. 2) := [1.0, 1.0];
      Gap : Real;
   begin
      Check (Rp.Success, "primal solved");
      Check (Approx (Rp.Objective, 10.0), "primal z=10");
      Check (Dual_Feasible (A, C, Y_Opt), "Y_Opt dual feasible");
      Check (Weak_Duality_Holds
               (A, B, C, Rp.X (1 .. 2), Y_Opt),
             "weak duality at optima");
      Check (Approx (Duality_Gap (C, Rp.X (1 .. 2), B, Y_Opt), 0.0),
             "gap=0 at optima");
      Check (Weak_Duality_Holds (A, B, C, X_Sub, Y_Opt),
             "weak duality suboptimal primal");
      Gap := Duality_Gap (C, X_Sub, B, Y_Opt);
      Check (Gap >= -1.0E-9, "gap nonnegative");
      Check (Approx (Gap, 5.0), "gap at (1,1): 10-5=5");
      --  Infeasible Y should fail weak-duality helper
      Check (not Weak_Duality_Holds
               (A, B, C, Rp.X (1 .. 2), [-1.0, 0.0]),
             "rejects negative dual");
      Check (Dual_Feasible (A, C, [0.0, 2.0]),
             "alt dual (0,2) feasible for ATy>=c");
      declare
         Z : constant Vector := Dual_Slack (A, C, Y_Opt);
      begin
         Check (Approx (Z (1), 0.0), "dual slack1=0 at opt");
         Check (Approx (Z (2), 0.0), "dual slack2=0 at opt");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Complementary slackness smoke");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      C : constant Vector (1 .. 2) := [3.0, 2.0];
      X : constant Vector (1 .. 2) := [2.0, 2.0];
      Y : constant Vector (1 .. 2) := [1.0, 1.0];
      X_Bad : constant Vector (1 .. 2) := [1.0, 1.0];
   begin
      Check (Complementary_Slackness_Holds (A, B, C, X, Y),
             "CS at optima");
      Check (not Complementary_Slackness_Holds (A, B, C, X_Bad, Y),
             "CS fails suboptimal with positive dual");
      Check (Feasible_Inequality (A, B, X), "CS primal feasible");
      Check (Dual_Feasible (A, C, Y), "CS dual feasible");
   end;

   ---------------------------------------------------------------------
   Section ("11. Graphical 2-D vertices");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      V : constant Vertex_List := Feasible_Vertices_2D (A, B);
      Best : Point2;
      Found_Opt : Boolean := False;
   begin
      Check (V.Count >= 3, "at least 3 vertices");
      Check (V.Count >= 4, "box+diagonal yields >=4 vertices");
      Best := Best_Vertex (V, C, 'M');
      Check (Approx (Evaluate_At (Best, C), 36.0), "graphical max=36");
      Check (Approx (Best.X, 2.0) and then Approx (Best.Y, 6.0),
             "graphical vertex (2,6)");
      for K in 1 .. V.Count loop
         if Approx (V.Points (K).X, 0.0) and then Approx (V.Points (K).Y, 0.0)
         then
            Found_Opt := True;
         end if;
      end loop;
      Check (Found_Opt, "includes origin");
      declare
         Best_Min : constant Point2 := Best_Vertex (V, C, 'm');
      begin
         Check (Approx (Evaluate_At (Best_Min, C), 0.0), "graphical min at 0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Pivot / Extract_Primal / Solve_Tableau smoke");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      C : constant Vector (1 .. 2) := [3.0, 2.0];
      T : Tableau := Build_Tableau (A, B, C);
      Enter, Leave : Natural;
      R : Result;
      Xp : Vector (1 .. 2);
   begin
      Enter := Select_Entering (T);
      Check (Enter > 0, "entering exists");
      Leave := Select_Leaving (T, Enter);
      Check (Leave > 0, "leaving exists");
      Pivot (T, Leave, Enter);
      Check (T.Basic (Leave) = Enter, "basic updated");
      --  Rebuild for a clean full solve after the smoke pivot.
      T := Build_Tableau (A, B, C);
      R := Solve_Tableau (T, Cfg);
      Check (R.Success, "Solve_Tableau success");
      Check (Approx (R.Objective, 10.0), "Solve_Tableau z=10");
      Xp := Extract_Primal (T, 2);
      Check (Approx (Xp (1), R.X (1)), "Extract matches X1");
      Check (Approx (Xp (2), R.X (2)), "Extract matches X2");
      Check (Is_Optimal_LP (T), "tableau optimal after solve");
   end;

   ---------------------------------------------------------------------
   Section ("13. More Maximize / Minimize cases");
   ---------------------------------------------------------------------
   declare
      --  Single var: max 5x s.t. x ≤ 3
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B1 : constant Vector (1 .. 1) := [3.0];
      C1 : constant Vector (1 .. 1) := [5.0];
      R1 : constant Result := Maximize (A1, B1, C1);
      --  Zero objective
      R0 : constant Result := Maximize (A1, B1, [0.0]);
      --  Two constraints binding
      A2 : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      B2 : constant Vector (1 .. 2) := [2.0, 3.0];
      C2 : constant Vector (1 .. 2) := [1.0, 1.0];
      R2 : constant Result := Maximize (A2, B2, C2);
      Rm : constant Result := Minimize (A2, B2, C2);
   begin
      Check (R1.Success and then Approx (R1.Objective, 15.0), "max 5*3=15");
      Check (Approx (R1.X (1), 3.0), "x=3");
      Check (R0.Success and then Approx (R0.Objective, 0.0), "zero obj");
      Check (R2.Success and then Approx (R2.Objective, 5.0), "box max=5");
      Check (Approx (R2.X (1), 2.0) and then Approx (R2.X (2), 3.0),
             "box corner");
      Check (Rm.Success and then Approx (Rm.Objective, 0.0), "box min=0");
   end;

   ---------------------------------------------------------------------
   Section ("14. Dual slack / Mat_T_Vec");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 0.0],
         [0.0, 1.0, 1.0]];
      Y : constant Vector (1 .. 2) := [1.0, 2.0];
      C : constant Vector (1 .. 3) := [1.0, 3.0, 1.0];
      ATy : constant Vector := Mat_T_Vec (A, Y);
      Z : constant Vector := Dual_Slack (A, C, Y);
   begin
      Check (Approx (ATy (1), 1.0), "ATy1");
      Check (Approx (ATy (2), 4.0), "ATy2");
      Check (Approx (ATy (3), 2.0), "ATy3");
      Check (Approx (Z (1), 0.0), "Z1=0");
      Check (Approx (Z (2), 1.0), "Z2=1");
      Check (Approx (Z (3), 1.0), "Z3=1");
      Check (Dual_Feasible (A, C, Y), "dual feasible Y");
      Check (not Dual_Feasible (A, [2.0, 3.0, 1.0], Y),
             "dual infeasible when c too large");
   end;

   ---------------------------------------------------------------------
   Section ("15. Phase-I path (negative RHS)");
   ---------------------------------------------------------------------
   declare
      --  max x s.t. x ≥ 1, x ≤ 2  →  −x ≤ −1, x ≤ 2
      A : constant Matrix (1 .. 2, 1 .. 1) :=
        [[-1.0],
         [1.0]];
      B : constant Vector (1 .. 2) := [-1.0, 2.0];
      C : constant Vector (1 .. 1) := [1.0];
      T : constant Tableau := Build_Tableau (A, B, C);
      R : constant Result := Maximize (A, B, C);
   begin
      Check (T.N_Artificial >= 1, "artificials for b<0");
      Check (T.Obj_Phase1 > 0, "Phase-I row present");
      Check (R.Success, "Phase-I then Phase-II success");
      Check (Approx (R.Objective, 2.0), "max at upper bound");
      Check (Approx (R.X (1), 2.0), "x=2");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Pass_Count=" & Natural'Image (Pass_Count)
     & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("TEST SUITE FAILED");
   else
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
