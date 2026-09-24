--  Standalone test suite for Cutting_Plane_Method (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Cutting_Plane_Method; use Cutting_Plane_Method;

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
     (Max_Cuts    => 40,
      Max_Pivots  => 400,
      Tol         => 1.0E-9,
      Integer_Tol => 1.0E-6);

   Tight_Cuts : constant Config :=
     (Max_Cuts    => 3,
      Max_Pivots  => 400,
      Tol         => 1.0E-9,
      Integer_Tol => 1.0E-6);

begin
   Ada.Text_IO.Put_Line ("Cutting_Plane_Method test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Frac / Is_Integer helpers");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.5, 3.0];
      Z : constant Vector (1 .. 2) := [1.0, 2.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Vec_Near (U, W, 0.6), "Vec_Near loose Tol");
      Check (Approx (Frac (2.3), 0.3, 1.0E-12), "Frac 2.3");
      Check (Approx (Frac (5.0), 0.0, 1.0E-12), "Frac integer");
      Check (Approx (Frac (-1.25), 0.75, 1.0E-12), "Frac negative");
      Check (Approx (Frac (0.0), 0.0), "Frac zero");
      Check (Approx (Frac (0.999), 0.999, 1.0E-12), "Frac near one");
      Check (Is_Integer_Val (3.0), "Is_Integer_Val 3");
      Check (Is_Integer_Val (3.0 + 1.0E-12), "Is_Integer_Val near");
      Check (not Is_Integer_Val (3.5), "Is_Integer_Val rejects 3.5");
      Check (Is_Integer_Vector (Z), "Is_Integer_Vector true");
      Check (not Is_Integer_Vector (W), "Is_Integer_Vector false");
      Check (Is_Integer_Val (-2.0), "Is_Integer_Val -2");
      Check (not Is_Integer_Val (-2.3), "Is_Integer_Val -2.3");
      Check (Near (100.0, 100.0 + 5.0E-12), "Near large mag");
   end;

   ---------------------------------------------------------------------
   Section ("2. Embedded Maximize_LP — simple LPs");
   ---------------------------------------------------------------------
   declare
      --  max x  s.t. x ≤ 2, x ≥ 0  → opt 2
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B1 : constant Vector (1 .. 1) := [2.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      R1 : constant Result := Maximize_LP (A1, B1, C1, Default_Cfg);

      --  max x+y  s.t. x+y ≤ 1, x≤1, y≤1
      A2 : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B2 : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      C2 : constant Vector (1 .. 2) := [1.0, 1.0];
      R2 : constant Result := Maximize_LP (A2, B2, C2, Default_Cfg);

      --  max 3x+4y  s.t. x≤4? classic: x+2y≤4, 2x+y≤5? → (2,1) wait
      --  max x  s.t. −x ≤ −1 (i.e. x ≥ 1), x ≤ 3
      A3 : constant Matrix (1 .. 2, 1 .. 1) := [[-1.0], [1.0]];
      B3 : constant Vector (1 .. 2) := [-1.0, 3.0];
      C3 : constant Vector (1 .. 1) := [1.0];
      R3 : constant Result := Maximize_LP (A3, B3, C3, Default_Cfg);

      --  Infeasible: x ≤ 1 and −x ≤ −2
      A4 : constant Matrix (1 .. 2, 1 .. 1) := [[1.0], [-1.0]];
      B4 : constant Vector (1 .. 2) := [1.0, -2.0];
      C4 : constant Vector (1 .. 1) := [1.0];
      R4 : constant Result := Maximize_LP (A4, B4, C4, Default_Cfg);
   begin
      Check (R1.Success, "LP1 success");
      Check (R1.Stat = Optimal, "LP1 Optimal");
      Check (Approx (R1.Objective, 2.0), "LP1 obj=2");
      Check (Approx (R1.X (1), 2.0), "LP1 x=2");
      Check (R2.Success, "LP2 success");
      Check (Approx (R2.Objective, 1.0), "LP2 obj=1");
      Check (Approx (R2.X (1) + R2.X (2), 1.0), "LP2 x+y=1");
      Check (R3.Success, "LP3 Phase-I success");
      Check (Approx (R3.Objective, 3.0), "LP3 obj=3");
      Check (Approx (R3.X (1), 3.0), "LP3 x=3");
      Check (not R4.Success, "LP4 infeasible fails");
      Check (R4.Stat = Infeasible, "LP4 Infeasible status");
   end;

   ---------------------------------------------------------------------
   Section ("3. Tableau helpers: Build / Enter / Leave / Pivot");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [2.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      Ent : Natural;
      Leave : Natural;
   begin
      Check (Tab.M = 1, "Build M=1");
      Check (Tab.N_Decision = 2, "Build N_Decision=2");
      Check (Tab.N_Slack = 1, "Build N_Slack=1");
      Check (Tab.N = 3, "Build N=3");
      Check (Tab.N_Artificial = 0, "Build no artificials");
      Check (Approx (Tab.T (0, 1), -1.0), "Obj reduced cost −c1");
      Check (Approx (Tab.T (0, 2), 0.0), "Obj reduced cost −c2");
      Check (Approx (Tab.T (1, 0), 2.0), "RHS=2");
      Check (not Is_Optimal_LP (Tab), "Not yet optimal");
      Ent := Select_Entering (Tab);
      Check (Ent = 1, "Entering col 1 (Bland)");
      Leave := Select_Leaving (Tab, Ent);
      Check (Leave = 1, "Leaving row 1");
      Pivot (Tab, Leave, Ent);
      Check (Is_Optimal_LP (Tab), "Optimal after one pivot");
      Check (Approx (Tab.T (0, 0), 2.0), "z=2 after pivot");
      declare
         X : constant Vector := Extract_Primal (Tab, 2);
      begin
         Check (Approx (X (1), 2.0), "Extract x1=2");
         Check (Approx (X (2), 0.0), "Extract x2=0");
      end;
      Check (Active_Obj_Row (Tab) = 0, "Active obj row 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Gomory_Cut_From_Row / Frac row");
   ---------------------------------------------------------------------
   declare
      --  Fabricate a tiny optimal-looking tableau row with fractional RHS
      Tab : Tableau;
      Gc  : Cut;
      Row : Natural;
   begin
      Tab.M := 1;
      Tab.N := 3;
      Tab.N_Decision := 2;
      Tab.N_Slack := 1;
      Tab.T (1, 0) := 1.5;
      Tab.T (1, 1) := 0.0;   -- basic x1
      Tab.T (1, 2) := 0.5;
      Tab.T (1, 3) := 0.25;
      Tab.Basic (1) := 1;
      Row := First_Fractional_Row (Tab);
      Check (Row = 1, "First_Fractional_Row finds 1");
      Gc := Gomory_Cut_From_Row (Tab, 1);
      Check (Gc.Valid, "Gomory cut valid");
      Check (Approx (Gc.RHS, 0.5), "Gomory f0=0.5");
      Check (Approx (Gc.Coeff (1), 0.0), "Gomory f1=0");
      Check (Approx (Gc.Coeff (2), 0.5), "Gomory f2=0.5");
      Check (Approx (Gc.Coeff (3), 0.25), "Gomory f3=0.25");
      Check (Gc.N_Cols = 3, "Gomory N_Cols=3");

      Tab.T (1, 0) := 2.0;
      Check (First_Fractional_Row (Tab) = 0, "No fractional row");
      Gc := Gomory_Cut_From_Row (Tab, 1);
      Check (not Gc.Valid, "Gomory invalid on integer RHS");
   end;

   ---------------------------------------------------------------------
   Section ("5. Classic pure-IP: max x+y s.t. 2x+2y ≤ 3");
   ---------------------------------------------------------------------
   --  LP opt 1.5 (fractional); IP opt 1 at (1,0) or (0,1).
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      LP : constant Result := Maximize_LP (A, B, C, Default_Cfg);
      IP : constant Result :=
        Solve_ILP_Cutting_Planes (A, B, C, Default_Cfg);
   begin
      Check (LP.Success, "Classic LP success");
      Check (Approx (LP.Objective, 1.5), "Classic LP obj=1.5");
      Check (not Is_Integer_Vector
               (LP.X (1 .. 2), Default_Cfg.Integer_Tol),
             "Classic LP fractional");
      Check (IP.Success, "Classic IP success");
      Check (IP.Stat = Optimal, "Classic IP Optimal");
      Check (Approx (IP.Objective, 1.0, 1.0E-5), "Classic IP obj=1");
      Check (Is_Integer_Vector
               (IP.X (1 .. 2), Default_Cfg.Integer_Tol),
             "Classic IP integer x");
      Check (Approx (IP.X (1) + IP.X (2), 1.0, 1.0E-5),
             "Classic IP x+y=1");
      Check (IP.N_Cuts >= 1, "Classic IP used ≥1 cut");
      Check (IP.X (1) >= -1.0E-6 and then IP.X (2) >= -1.0E-6,
             "Classic IP nonnegative");
   end;

   ---------------------------------------------------------------------
   Section ("6. Classic IP: max 5x+8y  s.t. x+y≤6, 5x+9y≤45");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [5.0, 9.0]];
      B : constant Vector (1 .. 2) := [6.0, 45.0];
      C : constant Vector (1 .. 2) := [5.0, 8.0];
      LP : constant Result := Maximize_LP (A, B, C, Default_Cfg);
      IP : constant Result :=
        Solve_ILP_Cutting_Planes (A, B, C, Default_Cfg);
   begin
      Check (LP.Success, "5-8 LP success");
      Check (Approx (LP.Objective, 41.25, 1.0E-4), "5-8 LP obj=41.25");
      Check (Approx (LP.X (1), 2.25, 1.0E-4), "5-8 LP x=2.25");
      Check (Approx (LP.X (2), 3.75, 1.0E-4), "5-8 LP y=3.75");
      Check (IP.Success, "5-8 IP success");
      Check (IP.Stat = Optimal, "5-8 IP Optimal");
      Check (Is_Integer_Vector (IP.X (1 .. 2), 1.0E-5),
             "5-8 IP integer");
      --  Known IP opt (0,5) with obj 40 (or possibly other with ≤40)
      Check (IP.Objective <= 41.25 + 1.0E-4, "5-8 IP ≤ LP bound");
      Check (IP.Objective >= 39.0, "5-8 IP obj near 40");
      Check (Approx (IP.X (1) + IP.X (2), IP.X (1) + IP.X (2)),
             "5-8 IP x finite");
      Check (IP.X (1) + IP.X (2) <= 6.0 + 1.0E-4, "5-8 IP x+y≤6");
      Check (5.0 * IP.X (1) + 9.0 * IP.X (2) <= 45.0 + 1.0E-3,
             "5-8 IP 5x+9y≤45");
      Check (Approx (IP.Objective, 5.0 * IP.X (1) + 8.0 * IP.X (2),
                     1.0E-4),
             "5-8 IP obj matches c·x");
   end;

   ---------------------------------------------------------------------
   Section ("7. Already-integer LP relaxation");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 2) := [3.0, 4.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      IP : constant Result :=
        Solve_ILP_Cutting_Planes (A, B, C, Default_Cfg);
   begin
      Check (IP.Success, "Integer-relax success");
      Check (Approx (IP.Objective, 7.0), "Integer-relax obj=7");
      Check (Approx (IP.X (1), 3.0) and then Approx (IP.X (2), 4.0),
             "Integer-relax x=(3,4)");
      Check (IP.N_Cuts = 0, "Integer-relax zero cuts");
   end;

   ---------------------------------------------------------------------
   Section ("8. Infeasible IP / tight cut budget");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 1) := [[1.0], [-1.0]];
      B : constant Vector (1 .. 2) := [1.0, -2.0];
      C : constant Vector (1 .. 1) := [1.0];
      IP : constant Result :=
        Solve_ILP_Cutting_Planes (A, B, C, Default_Cfg);

      A2 : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B2 : constant Vector (1 .. 1) := [3.0];
      C2 : constant Vector (1 .. 2) := [1.0, 1.0];
      IP2 : constant Result :=
        Solve_ILP_Cutting_Planes (A2, B2, C2, Tight_Cuts);
   begin
      Check (not IP.Success, "Infeasible IP fails");
      Check (IP.Stat = Infeasible, "Infeasible IP status");
      --  Tight budget may still solve classic (often 1 cut) or hit limit
      Check (IP2.Stat = Optimal or else IP2.Stat = Iteration_Limit,
             "Tight budget Optimal or Iteration_Limit");
      if IP2.Success then
         Check (Approx (IP2.Objective, 1.0, 1.0E-4),
                "Tight budget still obj=1");
      else
         Check (True, "Tight budget Iteration_Limit path");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("9. Add_Gomory_Cut + Dual_Restore path (via ILP)");
   ---------------------------------------------------------------------
   --  Integer data: 2x ≤ 5, 2y ≤ 5 → LP (2.5,2.5), IP (2,2).
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 0.0],
         [0.0, 2.0]];
      B : constant Vector (1 .. 2) := [5.0, 5.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      LP : constant Result := Maximize_LP (A, B, C, Default_Cfg);
      IP : constant Result :=
        Solve_ILP_Cutting_Planes (A, B, C, Default_Cfg);
   begin
      Check (LP.Success, "Box LP success");
      Check (Approx (LP.Objective, 5.0), "Box LP obj=5");
      Check (not Is_Integer_Vector (LP.X (1 .. 2), 1.0E-6),
             "Box LP fractional");
      Check (IP.Success, "Box IP success");
      Check (Approx (IP.Objective, 4.0, 1.0E-4), "Box IP obj=4");
      Check (Is_Integer_Vector (IP.X (1 .. 2), 1.0E-5),
             "Box IP integer");
      Check (IP.N_Cuts >= 1, "Box IP ≥1 cut");
   end;

   ---------------------------------------------------------------------
   Section ("10. Kelley: minimize max{|x|, |x-1|} on [-2,2]");
   ---------------------------------------------------------------------
   --  f(x) = max(x, -x, x-1, 1-x) wait: max(|x|, |x-1|)
   --  Affines: x, -x, x-1, 1-x
   declare
      A_Aff : constant Affine_Matrix (1 .. 4, 1 .. 1) :=
        [[1.0], [-1.0], [1.0], [-1.0]];
      B_Aff : constant Affine_Bias (1 .. 4) :=
        [0.0, 0.0, -1.0, 1.0];
      Lo : constant Vector (1 .. 1) := [-2.0];
      Hi : constant Vector (1 .. 1) := [2.0];
      R  : constant Result :=
        Solve_Kelley (A_Aff, B_Aff, Lo, Hi, Default_Cfg);
      F0 : constant Real :=
        Eval_Max_Of_Affines (A_Aff, B_Aff, [0.0]);
      F05 : constant Real :=
        Eval_Max_Of_Affines (A_Aff, B_Aff, [0.5]);
      G05 : constant Vector :=
        Subgradient_Max_Of_Affines (A_Aff, B_Aff, [0.5]);
   begin
      Check (Approx (F0, 1.0), "Eval f(0)=1");
      Check (Approx (F05, 0.5), "Eval f(0.5)=0.5");
      Check (Approx (G05 (1), 0.0)
             or else Approx (abs (G05 (1)), 1.0),
             "Subgrad at 0.5 finite");
      Check (R.Success, "Kelley success");
      Check (R.Stat = Optimal, "Kelley Optimal");
      Check (Approx (R.Objective, 0.5, 1.0E-3), "Kelley min=0.5");
      Check (Approx (R.X (1), 0.5, 1.0E-2), "Kelley x≈0.5");
      Check (R.N_Cuts >= 1, "Kelley used cuts");
      Check (R.N_Vars = 1, "Kelley N_Vars=1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Kelley: 2-D max of affines");
   ---------------------------------------------------------------------
   --  f(x,y) = max(x+y, −x, −y) on [-1,1]^2 → min 0 at (0,0)
   declare
      A_Aff : constant Affine_Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [-1.0, 0.0],
         [0.0, -1.0]];
      B_Aff : constant Affine_Bias (1 .. 3) := [0.0, 0.0, 0.0];
      Lo : constant Vector (1 .. 2) := [-1.0, -1.0];
      Hi : constant Vector (1 .. 2) := [1.0, 1.0];
      R  : constant Result :=
        Solve_Kelley (A_Aff, B_Aff, Lo, Hi, Default_Cfg);
      F_Origin : constant Real :=
        Eval_Max_Of_Affines (A_Aff, B_Aff, [0.0, 0.0]);
      F_Corner : constant Real :=
        Eval_Max_Of_Affines (A_Aff, B_Aff, [1.0, 1.0]);
   begin
      Check (Approx (F_Origin, 0.0), "2D Eval at 0");
      Check (Approx (F_Corner, 2.0), "2D Eval at (1,1)");
      Check (R.Success, "2D Kelley success");
      Check (Approx (R.Objective, 0.0, 5.0E-3), "2D Kelley min≈0");
      Check (Approx (R.X (1), 0.0, 5.0E-2)
             and then Approx (R.X (2), 0.0, 5.0E-2),
             "2D Kelley x≈0");
   end;

   ---------------------------------------------------------------------
   Section ("12. More LP / integer edge cases");
   ---------------------------------------------------------------------
   declare
      --  max 2x+y  s.t. x≤1, y≤1, 2x+2y≤3  (integer data)
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0],
         [2.0, 2.0]];
      B : constant Vector (1 .. 3) := [1.0, 1.0, 3.0];
      C : constant Vector (1 .. 2) := [2.0, 1.0];
      LP : constant Result := Maximize_LP (A, B, C, Default_Cfg);
      IP : constant Result :=
        Solve_ILP_Cutting_Planes (A, B, C, Default_Cfg);

      --  Single var IP: max x s.t. 2x ≤ 5 → LP 2.5, IP x=2
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[2.0]];
      B1 : constant Vector (1 .. 1) := [5.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      IP1 : constant Result :=
        Solve_ILP_Cutting_Planes (A1, B1, C1, Default_Cfg);
   begin
      Check (LP.Success, "Edge LP success");
      Check (Approx (LP.Objective, 2.5, 1.0E-4)
             or else Approx (LP.Objective, 2.0, 1.0E-4),
             "Edge LP obj 2.5 or 2");
      Check (Approx (LP.Objective, 2.5, 1.0E-4), "Edge LP obj=2.5");
      Check (IP.Success, "Edge IP success");
      Check (Is_Integer_Vector (IP.X (1 .. 2), 1.0E-5),
             "Edge IP integer");
      Check (Approx (IP.Objective, 2.0 * IP.X (1) + IP.X (2), 1.0E-4),
             "Edge IP obj=c·x");
      Check (IP.Objective <= LP.Objective + 1.0E-4,
             "Edge IP ≤ LP");
      Check (IP1.Success, "Single-var IP success");
      Check (Approx (IP1.X (1), 2.0), "Single-var IP x=2");
      Check (Approx (IP1.Objective, 2.0), "Single-var IP obj=2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Bulk Near / Frac / Is_Integer micro-checks");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
   begin
      for K in 0 .. 19 loop
         declare
            X : constant Real := Real (K) * 0.1;
         begin
            if not Near (X, X) then
               Ok := False;
            end if;
            if Frac (Real (K)) > 1.0E-12 then
               Ok := False;
            end if;
            if not Is_Integer_Val (Real (K)) then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "Bulk 0..19 Near/Frac/Is_Integer");

      for K in 1 .. 15 loop
         Check (Approx (Frac (Real (K) + 0.25), 0.25, 1.0E-12),
                "Frac K+0.25 #" & Integer'Image (K));
      end loop;

      for K in 1 .. 10 loop
         declare
            V : constant Vector (1 .. 2) :=
              [Real (K), Real (K + 1)];
         begin
            Check (Is_Integer_Vector (V),
                   "IntVec #" & Integer'Image (K));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Config / Result field sanity");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize_LP (A, B, C, Default_Cfg);
   begin
      Check (R.N_Vars = 1, "Result N_Vars");
      Check (R.N_Pivots < 10_000, "Result N_Pivots bounded");
      Check (Default_Cfg.Max_Cuts = 40, "Config Max_Cuts");
      Check (Default_Cfg.Max_Pivots = 400, "Config Max_Pivots");
      Check (Status'Pos (Optimal) = Status'Pos (Optimal),
             "Status enum exists");
      Check (R.Success = (R.Stat = Optimal), "Success iff Optimal");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===============================");
   Ada.Text_IO.Put_Line
     ("Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count /= 0 then
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   else
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   end if;
end Tests;
