--  Standalone test suite for Dantzig_Wolfe_Decomposition (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Dantzig_Wolfe_Decomposition; use Dantzig_Wolfe_Decomposition;

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

   Default_Cfg : constant Config :=
     (Max_Iters => 64, Max_Columns => 48, Max_Pivots => 800, Tol => 1.0E-9);

begin
   Ada.Text_IO.Put_Line ("Dantzig_Wolfe_Decomposition test suite");
   Ada.Text_IO.Put_Line ("======================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near");
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
   end;

   ---------------------------------------------------------------------
   Section ("2. Proposal / column helpers");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      Pool : Column_Pool;
      N_Cols : Column_Count;
      X0, X1, X2 : Proposal_X;
      Col : Column;
      Pi : constant Vector (1 .. 2) := [1.0, 1.0];
   begin
      Check (Prob.N_Blocks = 2, "toy N_Blocks=2");
      Check (Prob.N_Coupling = 2, "toy N_Coupling=2");
      Check (Prob.Blocks (1).N_Vars = 2, "block1 vars");
      Check (Prob.Blocks (2).N_Vars = 2, "block2 vars");
      Check (Approx (Toy_Optimum, -26.0), "Toy_Optimum=-26");
      Check (Total_Vars (Prob) = 4, "Total_Vars=4");

      Clear_Pool (Pool, N_Cols);
      Check (N_Cols = 0, "Clear_Pool empty");
      Check (not Pool (1).Valid, "Clear invalidates");

      Init_Zero_Columns (Prob, Pool, N_Cols);
      Check (N_Cols = 2, "zero columns: 1 per block");
      Check (Pool (1).Block_Id = 1, "col1 block1");
      Check (Pool (2).Block_Id = 2, "col2 block2");
      Check (Approx (Pool (1).Cost, 0.0), "zero cost1");
      Check (Approx (Pool (2).Cost, 0.0), "zero cost2");

      X0 := [others => 0.0];
      X1 := [1 => 3.0, 2 => 0.0];
      X2 := [1 => 3.0, 2 => 2.0];
      Check (Proposals_Equal (X0, X0, 2), "Proposals_Equal yes");
      Check (not Proposals_Equal (X1, X2, 2), "Proposals_Equal no");
      Check (Column_Exists (Pool, N_Cols, 1, X0, 2), "zero exists");
      Check (not Column_Exists (Pool, N_Cols, 1, X1, 2), "X1 absent");

      Col := Make_Column (Prob, 1, X1);
      Check (Approx (Col.Cost, -9.0), "Make_Column cost -3*3");
      Check (Approx (Col.Coup (1), 3.0), "coup row1 = x1");
      Check (Approx (Col.Coup (2), 0.0), "coup row2 = x2");
      Add_Column (Pool, N_Cols, Col);
      Check (N_Cols = 3, "Add_Column grows");
      Check (Column_Exists (Pool, N_Cols, 1, X1, 2), "X1 present");

      Check (Approx (Proposal_Cost (Prob.Blocks (1), X2), -17.0),
             "cost (3,2)=−17");
      Check (Approx
               (Reduced_Cost (Col, Pi, 0.0, 2), -9.0 + 3.0),
             "rc = −9 + π·(3,0)");
      Check (Approx
               (Reduced_Cost (Col, Pi, -2.0, 2), -9.0 + 3.0 - (-2.0)),
             "rc with sigma");
   end;

   ---------------------------------------------------------------------
   Section ("3. Embedded simplex smoke");
   ---------------------------------------------------------------------
   declare
      --  max 3x+5y s.t. x≤4, 2y≤12, 3x+2y≤18 → opt 36 at (2,6)
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      R : Master_Result;
      Cfg : constant Config := Default_Cfg;
   begin
      Check (Tab.M = 3, "tableau M=3");
      Check (Tab.N_Decision = 2, "N_Decision=2");
      Check (Tab.N_Artificial = 0, "no arts when b≥0");
      Check (Is_Optimal_LP (Tab) = False, "not optimal at start");
      Check (Select_Entering (Tab) = 1, "Bland enters col 1");
      R := Solve_Tableau (Tab, Cfg);
      Check (R.Success, "simplex smoke success");
      Check (Approx (R.Objective, 36.0), "obj=36");
      Check (Approx (R.Lambda (1), 2.0), "x=2");
      Check (Approx (R.Lambda (2), 6.0), "y=6");
      Check (Active_Obj_Row (Tab) = 0, "phase-II obj row");
   end;

   ---------------------------------------------------------------------
   Section ("4. Simplex Phase-I / equality via ≥");
   ---------------------------------------------------------------------
   declare
      --  max x s.t. x ≥ 2, x ≤ 5  → encode as −x ≤ −2, x ≤ 5 → opt 5
      A : constant Matrix (1 .. 2, 1 .. 1) :=
        [[-1.0],
         [1.0]];
      B : constant Vector (1 .. 2) := [-2.0, 5.0];
      C : constant Vector (1 .. 1) := [1.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      R : Master_Result;
   begin
      Check (Tab.N_Artificial = 1, "one artificial for ≥");
      R := Solve_Tableau (Tab, Default_Cfg);
      Check (R.Success, "phase-I success");
      Check (Approx (R.Objective, 5.0), "max x=5");
      Check (Approx (R.Lambda (1), 5.0), "x=5");
   end;

   ---------------------------------------------------------------------
   Section ("5. Price_Block on toy");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      Pi0 : constant Vector (1 .. 2) := [0.0, 0.0];
      Pi1 : constant Vector (1 .. 2) := [3.0, 4.0];
      P : Pricing_Result;
   begin
      --  With π=0, σ=0: min cᵀx over boxes → pick most negative costs
      --  Block1: min −3x1−4x2 over [0,3]×[0,2] → (−3,−4) at (3,2), value −17
      P := Price_Block (Prob, 1, Pi0, 0.0, Default_Cfg);
      Check (P.Feasible, "price1 feasible");
      Check (Approx (P.Value, -17.0), "price1 value −17 at (3,2)");
      Check (Approx (P.X (1), 3.0) and then Approx (P.X (2), 2.0),
             "price1 x=(3,2)");
      Check (P.Improving, "price1 improving vs σ=0");

      P := Price_Block (Prob, 2, Pi0, 0.0, Default_Cfg);
      Check (P.Feasible, "price2 feasible");
      Check (Approx (P.Value, -19.0), "price2 value −19 at (2,3)");
      Check (Approx (P.X (1), 2.0) and then Approx (P.X (2), 3.0),
             "price2 y=(2,3)");

      --  Large π: Red = c+Aᵀπ = (−3+3,−4+4)=(0,0) → value 0
      P := Price_Block (Prob, 1, Pi1, 0.0, Default_Cfg);
      Check (P.Feasible, "price1 with π");
      Check (Approx (P.Value, 0.0), "price1 value with π");

      P := Price_Block (Prob, 1, Pi0, -100.0, Default_Cfg);
      Check (not P.Improving, "large negative σ not improving");
      Check (Approx (P.Reduced_Cost, -17.0 - (-100.0)), "rc = V−σ");
   end;

   ---------------------------------------------------------------------
   Section ("6. Solve_Master with known columns");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      Pool : Column_Pool;
      N_Cols : Column_Count := 0;
      MR : Master_Result;
      --  All corners of both boxes (exact DW master)
      C1 : constant Proposal_X := [0.0, 0.0];
      C2 : constant Proposal_X := [3.0, 0.0];
      C3 : constant Proposal_X := [0.0, 2.0];
      C4 : constant Proposal_X := [3.0, 2.0];
      D1 : constant Proposal_X := [0.0, 0.0];
      D2 : constant Proposal_X := [2.0, 0.0];
      D3 : constant Proposal_X := [0.0, 3.0];
      D4 : constant Proposal_X := [2.0, 3.0];
   begin
      Clear_Pool (Pool, N_Cols);
      Add_Column (Pool, N_Cols, Make_Column (Prob, 1, C1));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 1, C2));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 1, C3));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 1, C4));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 2, D1));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 2, D2));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 2, D3));
      Add_Column (Pool, N_Cols, Make_Column (Prob, 2, D4));
      Check (N_Cols = 8, "8 corner columns");

      MR := Solve_Master (Prob, Pool, N_Cols, Default_Cfg);
      Check (MR.Success, "full-corner master success");
      Check (Approx (MR.Objective, -26.0, 1.0E-4), "master obj=-26");
      Check (MR.Stat = Optimal, "master Optimal");
   end;

   ---------------------------------------------------------------------
   Section ("7. Solve toy DW end-to-end");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      R : Result;
      X : Vector (1 .. 4);
   begin
      R := Solve (Prob, Default_Cfg);
      Check (R.Success, "Solve success");
      Check (R.Stat = Optimal, "Solve Optimal");
      Check (Approx (R.Objective, -26.0, 1.0E-3), "Solve obj=-26");
      Check (R.N_Blocks = 2, "result blocks");
      Check (R.N_Coupling = 2, "result coupling");
      Check (R.N_Total_Vars = 4, "result total vars");
      Check (R.N_Iters >= 1, "at least one iter");
      Check (R.N_Columns >= 2, "at least zero columns");

      for I in 1 .. 4 loop
         X (I) := R.X (I);
      end loop;
      --  Expected (3,0,1,3)
      Check (Approx (X (1), 3.0, 1.0E-3), "x1=3");
      Check (Approx (X (2), 0.0, 1.0E-3), "x2=0");
      Check (Approx (X (3), 1.0, 1.0E-3), "y1=1");
      Check (Approx (X (4), 3.0, 1.0E-3), "y2=3");

      --  Coupling feasibility
      Check (X (1) + X (3) <= 4.0 + 1.0E-3, "coup1 feasible");
      Check (X (2) + X (4) <= 3.0 + 1.0E-3, "coup2 feasible");

      --  Box feasibility
      Check (X (1) <= 3.0 + 1.0E-3 and then X (1) >= -1.0E-3, "x1 box");
      Check (X (2) <= 2.0 + 1.0E-3 and then X (2) >= -1.0E-3, "x2 box");
      Check (X (3) <= 2.0 + 1.0E-3 and then X (3) >= -1.0E-3, "y1 box");
      Check (X (4) <= 3.0 + 1.0E-3 and then X (4) >= -1.0E-3, "y2 box");

      --  Objective from reconstructed x
      declare
         Obj : constant Real :=
           -3.0 * X (1) - 4.0 * X (2) - 2.0 * X (3) - 5.0 * X (4);
      begin
         Check (Approx (Obj, R.Objective, 1.0E-3), "obj matches x");
         Check (Approx (Obj, -26.0, 1.0E-3), "obj from x = -26");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Reconstruct_X / convex combination");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      Pool : Column_Pool;
      N_Cols : Column_Count := 0;
      Lam : Vector (1 .. 4) := [others => 0.0];
      X : Vector (1 .. Max_Total_Vars);
   begin
      Clear_Pool (Pool, N_Cols);
      Add_Column (Pool, N_Cols,
                  Make_Column (Prob, 1, [1 => 3.0, 2 => 0.0]));
      Add_Column (Pool, N_Cols,
                  Make_Column (Prob, 1, [1 => 0.0, 2 => 0.0]));
      Add_Column (Pool, N_Cols,
                  Make_Column (Prob, 2, [1 => 0.0, 2 => 3.0]));
      Add_Column (Pool, N_Cols,
                  Make_Column (Prob, 2, [1 => 2.0, 2 => 0.0]));
      --  Block1: λ1=1 → (3,0); Block2: 0.5*(0,3)+0.5*(2,0)=(1,1.5)
      Lam := [1.0, 0.0, 0.5, 0.5];
      X := Reconstruct_X (Prob, Pool, N_Cols, Lam);
      Check (Approx (X (1), 3.0), "recon x1");
      Check (Approx (X (2), 0.0), "recon x2");
      Check (Approx (X (3), 1.0), "recon y1");
      Check (Approx (X (4), 1.5), "recon y2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Single-block / no coupling");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Result;
   begin
      --  Single block: min −x s.t. x ≤ 5, x ≥ 0  → opt −5 at x=5
      P.N_Blocks := 1;
      P.N_Coupling := 0;
      P.Blocks (1).N_Vars := 1;
      P.Blocks (1).N_Cons := 1;
      P.Blocks (1).Cost := [1 => -1.0, 2 => 0.0];
      P.Blocks (1).B_Mat :=
        [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];
      P.Blocks (1).B_RHS := [1 => 5.0, others => 0.0];

      R := Solve (P, Default_Cfg);
      Check (R.Success, "1-block success");
      Check (Approx (R.Objective, -5.0, 1.0E-4), "1-block obj=-5");
      Check (Approx (R.X (1), 5.0, 1.0E-4), "1-block x=5");
   end;

   ---------------------------------------------------------------------
   Section ("10. Dual signs / no improving at opt");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      R : Result;
      P1, P2 : Pricing_Result;
      Pi : Vector (1 .. 2);
   begin
      R := Solve (Prob, Default_Cfg);
      Check (R.Success, "dual-check solve ok");
      Pi :=
        [R.Coupling_Dual (1), R.Coupling_Dual (2)];
      Check (R.Coupling_Dual (1) >= -1.0E-8, "π1 ≥ 0");
      Check (R.Coupling_Dual (2) >= -1.0E-8, "π2 ≥ 0");

      P1 := Price_Block
        (Prob, 1, Pi, R.Convexity_Dual (1), Default_Cfg);
      P2 := Price_Block
        (Prob, 2, Pi, R.Convexity_Dual (2), Default_Cfg);
      Check (P1.Feasible and then P2.Feasible, "final price feasible");
      Check (not P1.Improving, "block1 no improve at opt");
      Check (not P2.Improving, "block2 no improve at opt");
      Check (P1.Reduced_Cost >= -1.0E-5, "block1 rc ≥ 0");
      Check (P2.Reduced_Cost >= -1.0E-5, "block2 rc ≥ 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Pivot / leaving / Bland helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0]];
      B : constant Vector (1 .. 2) := [2.0, 1.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      Enter, Leave : Natural;
   begin
      Enter := Select_Entering (Tab);
      Check (Enter >= 1, "entering exists");
      Leave := Select_Leaving (Tab, Enter);
      Check (Leave >= 1, "leaving exists");
      Pivot (Tab, Leave, Enter);
      Check (Tab.Basic (Leave) = Enter, "basic updated");
      Check (Approx (Tab.T (Leave, Enter), 1.0), "pivot col unit");
   end;

   ---------------------------------------------------------------------
   Section ("12. Caps / config / status paths");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      R : Result;
      Tight : Config := Default_Cfg;
   begin
      Tight.Max_Iters := 1;
      Tight.Max_Columns := 48;
      R := Solve (Prob, Tight);
      --  May or may not finish in 1 iter; just ensure no crash
      Check (R.N_Iters = 1, "Max_Iters respected");
      Check (R.Stat = Optimal or else R.Stat = Iteration_Limit
             or else R.Stat = Column_Limit
             or else R.Stat = Infeasible
             or else R.Stat = Unbounded,
             "status in enum");

      Tight := Default_Cfg;
      R := Solve (Prob, Tight);
      Check (R.Success, "default solve again");
      Check (R.N_Columns >= 2, "at least seed columns");
      Check (R.N_Pivots > 0, "pivots recorded");
   end;

   ---------------------------------------------------------------------
   Section ("13. Three-block tiny");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Result;
   begin
      --  min −x −y −z
      --  coupling: x+y+z ≤ 3
      --  boxes: x≤2, y≤2, z≤2
      P.N_Blocks := 3;
      P.N_Coupling := 1;
      P.Coupling_RHS := [1 => 3.0, others => 0.0];
      for K in 1 .. 3 loop
         P.Blocks (K).N_Vars := 1;
         P.Blocks (K).N_Cons := 1;
         P.Blocks (K).Cost := [1 => -1.0, 2 => 0.0];
         P.Blocks (K).B_Mat :=
           [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];
         P.Blocks (K).B_RHS := [1 => 2.0, others => 0.0];
         P.Blocks (K).A_Coup :=
           [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];
      end loop;

      R := Solve (P, Default_Cfg);
      Check (R.Success, "3-block success");
      Check (Approx (R.Objective, -3.0, 1.0E-3), "3-block obj=-3");
      Check (Approx (R.X (1) + R.X (2) + R.X (3), 3.0, 1.0E-3),
             "3-block sum=3");
      Check (R.X (1) <= 2.0 + 1.0E-3, "x≤2");
      Check (R.X (2) <= 2.0 + 1.0E-3, "y≤2");
      Check (R.X (3) <= 2.0 + 1.0E-3, "z≤2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Master with only zeros");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      Pool : Column_Pool;
      N_Cols : Column_Count;
      MR : Master_Result;
   begin
      Init_Zero_Columns (Prob, Pool, N_Cols);
      MR := Solve_Master (Prob, Pool, N_Cols, Default_Cfg);
      Check (MR.Success, "zero-pool master feasible");
      Check (Approx (MR.Objective, 0.0, 1.0E-6), "zero-pool obj=0");
      Check (Approx (MR.Lambda (1), 1.0), "λ1=1");
      Check (Approx (MR.Lambda (2), 1.0), "λ2=1");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extract_Primal / Is_Optimal edge");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [0.0];
      C : constant Vector (1 .. 1) := [0.0];
      Tab : constant Tableau := Build_Tableau (A, B, C);
   begin
      Check (Is_Optimal_LP (Tab), "already optimal c=0");
      declare
         Xp : constant Vector := Extract_Primal (Tab, 1);
      begin
         Check (Xp'Length = 1, "primal length 1");
         Check (Approx (Xp (1), 0.0), "primal zero");
      end;
      Check (Select_Entering (Tab) = 0, "no entering");
   end;

   ---------------------------------------------------------------------
   Section ("16. Coupling dual sensitivity smoke");
   ---------------------------------------------------------------------
   declare
      Prob : Problem := Make_Toy_Problem;
      R_Loose, R_Tight : Result;
   begin
      R_Loose := Solve (Prob, Default_Cfg);
      Prob.Coupling_RHS (1) := 10.0;  -- relax first coupling
      R_Tight := Solve (Prob, Default_Cfg);
      Check (R_Loose.Success and then R_Tight.Success, "both succeed");
      --  Relaxing can only improve (decrease) min objective
      Check (R_Tight.Objective <= R_Loose.Objective + 1.0E-3,
             "relax coupling improves or equal");
   end;

   ---------------------------------------------------------------------
   Section ("17. Make_Column coupling consistency");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      X : constant Proposal_X := [1 => 1.5, 2 => 1.0];
      Col : constant Column := Make_Column (Prob, 1, X);
      Coup : constant Coupling_RHS_Array :=
        Proposal_Coupling (Prob.Blocks (1), X, 2);
   begin
      Check (Approx (Col.Coup (1), Coup (1)), "coup1 match");
      Check (Approx (Col.Coup (2), Coup (2)), "coup2 match");
      Check (Approx (Col.Coup (1), 1.5), "A x row1");
      Check (Approx (Col.Coup (2), 1.0), "A x row2");
      Check (Approx (Col.Cost, Proposal_Cost (Prob.Blocks (1), X)),
             "cost match");
   end;

   ---------------------------------------------------------------------
   Section ("18. Iteration growth finds columns");
   ---------------------------------------------------------------------
   declare
      Prob : constant Problem := Make_Toy_Problem;
      R : Result;
   begin
      R := Solve (Prob, Default_Cfg);
      Check (R.N_Columns > 2, "generated columns beyond zeros");
      Check (R.N_Iters >= 2, "multiple CG rounds");
      for J in 1 .. R.N_Columns loop
         Check (R.Pool (J).Valid, "pool entry valid");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("19. Positive-cost minimization");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Result;
   begin
      --  min 2x + 3y
      --  coupling: x + y ≥ 4  →  −x−y ≤ −4
      --  boxes: x≤5, y≤5
      --  Opt: (4,0) or mix with cost 8 if only x; actually min at (4,0)=8
      --  Wait: use coupling x+y ≤ 4 with positive costs → opt at 0.
      P.N_Blocks := 2;
      P.N_Coupling := 1;
      P.Coupling_RHS := [1 => 4.0, others => 0.0];
      P.Blocks (1).N_Vars := 1;
      P.Blocks (1).N_Cons := 1;
      P.Blocks (1).Cost := [1 => 2.0, 2 => 0.0];
      P.Blocks (1).B_Mat :=
        [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];
      P.Blocks (1).B_RHS := [1 => 5.0, others => 0.0];
      P.Blocks (1).A_Coup :=
        [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];

      P.Blocks (2).N_Vars := 1;
      P.Blocks (2).N_Cons := 1;
      P.Blocks (2).Cost := [1 => 3.0, 2 => 0.0];
      P.Blocks (2).B_Mat :=
        [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];
      P.Blocks (2).B_RHS := [1 => 5.0, others => 0.0];
      P.Blocks (2).A_Coup :=
        [1 => [1 => 1.0, 2 => 0.0], others => [others => 0.0]];

      R := Solve (P, Default_Cfg);
      Check (R.Success, "pos-cost success");
      Check (Approx (R.Objective, 0.0, 1.0E-4), "pos-cost stays at 0");
      Check (Approx (R.X (1), 0.0, 1.0E-4), "x=0");
      Check (Approx (R.X (2), 0.0, 1.0E-4), "y=0");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("RESULT: FAIL");
   elsif Pass_Count < 100 then
      Ada.Text_IO.Put_Line ("RESULT: FAIL (need Pass_Count >= 100)");
   else
      Ada.Text_IO.Put_Line ("RESULT: PASS");
   end if;
end Tests;
