--  Standalone test suite for Integer_Linear_Programming (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Integer_Linear_Programming; use Integer_Linear_Programming;

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
   Ada.Text_IO.Put_Line ("Integer_Linear_Programming test suite");
   Ada.Text_IO.Put_Line ("=====================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Frac / Is_Integer / Is_Binary helpers");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.5, 3.0];
      Z : constant Vector (1 .. 2) := [0.0, 1.0];
      Req : constant Integer_Flags (1 .. 3) := [True, True, False];
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
      Check (Is_Integer (3.0), "Is_Integer 3");
      Check (Is_Integer (3.0 + 1.0E-12), "Is_Integer near");
      Check (not Is_Integer (3.5), "Is_Integer rejects 3.5");
      Check (Is_Integer_Vector (Z), "Is_Integer_Vector true");
      Check (not Is_Integer_Vector (W), "Is_Integer_Vector false");
      Check (Is_Integer (-2.0), "Is_Integer -2");
      Check (Is_Binary (0.0), "Is_Binary 0");
      Check (Is_Binary (1.0), "Is_Binary 1");
      Check (not Is_Binary (0.5), "Is_Binary rejects 0.5");
      Check (Is_Binary_Vector (Z), "Is_Binary_Vector true");
      Check (not Is_Binary_Vector (W), "Is_Binary_Vector false");
      Check (Required_Are_Integer ([1.0, 2.0, 0.5], Req),
             "Required_Are_Integer ignores continuous");
      Check (not Required_Are_Integer ([1.5, 2.0, 0.5], Req),
             "Required_Are_Integer catches fractional");
   end;

   ---------------------------------------------------------------------
   Section ("2. Taxonomy: Classify / Method_Kind");
   ---------------------------------------------------------------------
   declare
      All_Int : constant Integer_Flags (1 .. 3) := [True, True, True];
      Mixed   : constant Integer_Flags (1 .. 3) := [True, False, True];
      None    : constant Integer_Flags (1 .. 2) := [False, False];
      Info_BB : constant Method_Info := Classify_Method (Branch_And_Bound);
      Info_CP : constant Method_Info := Classify_Method (Cutting_Planes);
      Info_BC : constant Method_Info := Classify_Method (Branch_And_Cut);
      Info_DP : constant Method_Info := Classify_Method (Dynamic_Programming);
   begin
      Check (Classify (All_Int) = Pure_IP, "Classify Pure_IP");
      Check (Classify (All_Int, Binary => True) = Binary_IP,
             "Classify Binary_IP");
      Check (Classify (Mixed) = MILP, "Classify MILP");
      Check (Classify (None) = MILP, "Classify no-int as MILP");
      Check (Problem_Name (Pure_IP) = "Pure IP", "Problem_Name Pure");
      Check (Problem_Name (Binary_IP) = "Binary IP (0-1)",
             "Problem_Name Binary");
      Check (Problem_Name (MILP) = "MILP", "Problem_Name MILP");
      Check (Method_Count = 4, "Method_Count=4");
      Check (Method_Name (Branch_And_Bound) = "Branch-and-Bound",
             "Method_Name BB");
      Check (Method_Name (Cutting_Planes) = "Cutting planes",
             "Method_Name CP");
      Check (Method_Name (Branch_And_Cut) = "Branch-and-cut",
             "Method_Name BC");
      Check (Method_Name (Dynamic_Programming) = "Dynamic programming",
             "Method_Name DP");
      Check (Info_BB.Uses_LP and then not Info_BB.Uses_Cuts,
             "BB uses LP no cuts");
      Check (Info_CP.Uses_Cuts and then Info_CP.Exact, "CP cuts exact");
      Check (Info_BC.Uses_LP and then Info_BC.Uses_Cuts, "BC LP+cuts");
      Check (Info_DP.Special_Case and then not Info_DP.Uses_LP,
             "DP special no LP");
      Check (Info_BB.Exact and then Info_DP.Exact, "BB and DP exact");
   end;

   ---------------------------------------------------------------------
   Section ("3. Embedded Maximize_LP — simple LPs");
   ---------------------------------------------------------------------
   declare
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B1 : constant Vector (1 .. 1) := [2.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      R1 : constant Result := Maximize_LP (A1, B1, C1, Cfg);

      A2 : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B2 : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      C2 : constant Vector (1 .. 2) := [1.0, 1.0];
      R2 : constant Result := Maximize_LP (A2, B2, C2, Cfg);

      A3 : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0],
         [2.0, 1.0]];
      B3 : constant Vector (1 .. 2) := [4.0, 5.0];
      C3 : constant Vector (1 .. 2) := [3.0, 4.0];
      R3 : constant Result := Maximize_LP (A3, B3, C3, Cfg);

      --  Infeasible: x ≥ 0 and x ≤ −1
      A4 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B4 : constant Vector (1 .. 1) := [-1.0];
      C4 : constant Vector (1 .. 1) := [1.0];
      R4 : constant Result := Maximize_LP (A4, B4, C4, Cfg);
   begin
      Check (R1.Success, "LP1 success");
      Check (R1.Stat = Optimal, "LP1 Optimal");
      Check (Approx (R1.Objective, 2.0), "LP1 obj=2");
      Check (Approx (R1.X (1), 2.0), "LP1 x=2");
      Check (R2.Success, "LP2 success");
      Check (Approx (R2.Objective, 1.0), "LP2 obj=1");
      Check (R3.Success, "LP3 success");
      Check (Approx (R3.Objective, 10.0, 1.0E-4), "LP3 obj=10");
      Check (Approx (R3.X (1), 2.0) and then Approx (R3.X (2), 1.0),
             "LP3 x=(2,1)");
      Check (not R4.Success, "LP4 infeasible");
      Check (R4.Stat = Infeasible, "LP4 Infeasible status");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tableau helpers: Build / Enter / Leave / Pivot");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      Enter : Natural;
      Leave : Natural;
   begin
      Check (Tab.M = 1, "Tab M=1");
      Check (Tab.N_Decision = 2, "Tab N_Decision=2");
      Check (Tab.N_Slack = 1, "Tab N_Slack=1");
      Check (Tab.N_Artificial = 0, "Tab no artificial");
      Check (not Is_Optimal_LP (Tab), "not optimal initially");
      Enter := Select_Entering (Tab);
      Check (Enter = 1, "Bland enter col 1");
      Leave := Select_Leaving (Tab, Enter);
      Check (Leave = 1, "Leave row 1");
      Pivot (Tab, Leave, Enter);
      Check (Tab.Basic (1) = 1, "Basic after pivot");
      declare
         R : constant Result := Solve_Tableau (Tab, Cfg);
      begin
         Check (R.Success, "Solve after partial pivot");
         Check (Approx (R.Objective, 1.5, 1.0E-4), "obj=1.5");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Integrality gap helpers");
   ---------------------------------------------------------------------
   declare
      --  Classic: max x1+x2 s.t. 2x1+2x2 ≤ 3, x≥0 → LP=1.5; IP binary=1
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      LP : constant Result := Maximize_LP (A, B, C, Cfg);
      Gap : Real;
      Rel : Real;
   begin
      Check (LP.Success, "Gap LP success");
      Check (Approx (LP.Objective, 1.5), "Gap LP=1.5");
      Gap := Integrality_Gap (LP.Objective, 1.0);
      Check (Approx (Gap, 0.5), "Abs gap=0.5");
      Rel := Relative_Integrality_Gap (LP.Objective, 1.0);
      Check (Approx (Rel, 0.5), "Rel gap=0.5");
      Check (Approx (Integrality_Gap (5.0, 5.0), 0.0), "Zero gap");
      Check (Approx (Relative_Integrality_Gap (0.0, 0.0), 0.0),
             "Rel gap zero/zero");
      Gap := Gap_From_Relaxation (A, B, C, 1.0, Cfg);
      Check (Approx (Gap, 0.5), "Gap_From_Relaxation=0.5");
      Check (Approx (Relative_Integrality_Gap (10.0, 8.0), 0.25),
             "Rel gap 10/8");
   end;

   ---------------------------------------------------------------------
   Section ("6. Feasibility / Round_And_Check");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [2.0, 3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      X_Good : constant Vector (1 .. 2) := [1.0, 1.0];
      X_Bad  : constant Vector (1 .. 2) := [2.0, 2.0];
      X_Frac : constant Vector (1 .. 2) := [0.6, 0.4];
      Bits   : Binary_Vector (1 .. 2);
      Rnd    : Result;
   begin
      Check (Feasible_Inequality (A, B, X_Good), "Feasible (1,1)");
      Check (not Feasible_Inequality (A, B, X_Bad), "Infeasible (2,2)");
      Check (Approx (Objective_Value (C, X_Good), 2.0), "Obj=2");
      Bits := Round_Binary (X_Frac);
      Check (Bits (1) and then not Bits (2), "Round 0.6/0.4 → 1,0");
      declare
         XR : constant Vector := Binary_To_Real (Bits);
      begin
         Check (Approx (XR (1), 1.0) and then Approx (XR (2), 0.0),
                "Binary_To_Real");
         Check (Feasible_Inequality (A, B, XR), "Rounded feasible");
      end;
      Rnd := Round_And_Check (A, B, C, X_Frac);
      Check (Rnd.Success, "Round_And_Check success");
      Check (Approx (Rnd.Objective, 1.0), "Round obj=1");
      Rnd := Round_And_Check (A, B, C, [0.9, 0.9]);
      Check (Rnd.Success, "Round (0.9,0.9)→(1,1) feasible");
      Rnd := Round_And_Check (A, B, C, [1.0, 1.0]);
      Check (Rnd.Success and then Approx (Rnd.Objective, 2.0),
             "Already integer feasible");
   end;

   ---------------------------------------------------------------------
   Section ("7. 0-1 knapsack DP");
   ---------------------------------------------------------------------
   declare
      Items1 : constant Knapsack_Items (1 .. 3) :=
        [(Weight => 2, Value => 3.0),
         (Weight => 3, Value => 4.0),
         (Weight => 4, Value => 5.0)];
      R1 : constant Knapsack_Result := Solve_Knapsack_01 (Items1, 5);
      --  Best: items 1+2 = weight 5, value 7

      Items2 : constant Knapsack_Items (1 .. 4) :=
        [(1, 1.0), (2, 6.0), (3, 10.0), (5, 12.0)];
      R2 : constant Knapsack_Result := Solve_Knapsack_01 (Items2, 5);
      --  Best: 2+3 = weight 5, value 16? Wait 2+3=5 weight, 6+10=16
      --  Or item 3 alone=10, or 1+2=7. Best=16.

      Items3 : constant Knapsack_Items (1 .. 1) := [(5, 10.0)];
      R3 : constant Knapsack_Result := Solve_Knapsack_01 (Items3, 4);
      --  Cannot take → 0

      Items4 : constant Knapsack_Items (1 .. 2) :=
        [(0, 5.0), (3, 4.0)];
      R4 : constant Knapsack_Result := Solve_Knapsack_01 (Items4, 3);
      --  Zero-weight + item2 = 9

      Items5 : constant Knapsack_Items (1 .. 5) :=
        [(2, 3.0), (2, 3.0), (2, 3.0), (2, 3.0), (2, 3.0)];
      R5 : constant Knapsack_Result := Solve_Knapsack_01 (Items5, 6);
   begin
      Check (R1.Success, "Knapsack1 success");
      Check (Approx (R1.Objective, 7.0), "Knapsack1 obj=7");
      Check (R1.Selected (1) and then R1.Selected (2)
             and then not R1.Selected (3), "Knapsack1 select 1,2");
      Check (R2.Success, "Knapsack2 success");
      Check (Approx (R2.Objective, 16.0), "Knapsack2 obj=16");
      Check (not R2.Selected (1) and then R2.Selected (2)
             and then R2.Selected (3) and then not R2.Selected (4),
             "Knapsack2 select 2,3");
      Check (R3.Success, "Knapsack3 success");
      Check (Approx (R3.Objective, 0.0), "Knapsack3 empty");
      Check (not R3.Selected (1), "Knapsack3 none selected");
      Check (R4.Success, "Knapsack4 success");
      Check (Approx (R4.Objective, 9.0), "Knapsack4 zero-weight");
      Check (R4.Selected (1) and then R4.Selected (2),
             "Knapsack4 both");
      Check (R5.Success, "Knapsack5 success");
      Check (Approx (R5.Objective, 9.0), "Knapsack5 three items");
   end;

   ---------------------------------------------------------------------
   Section ("8. Branch_Variable_Binary");
   ---------------------------------------------------------------------
   declare
      X1 : constant Vector (1 .. 3) := [0.0, 1.0, 0.0];
      X2 : constant Vector (1 .. 3) := [0.2, 0.7, 0.4];
      X3 : constant Vector (1 .. 2) := [0.51, 0.49];
   begin
      Check (Branch_Variable_Binary (X1) = 0, "All binary → 0");
      Check (Branch_Variable_Binary (X2) = 3, "Most frac is 0.4→idx3");
      --  0.2 dist=0.3, 0.7 dist=0.2, 0.4 dist=0.1 → closest to 0.5 is 0.4
      Check (Branch_Variable_Binary (X3) = 1
             or else Branch_Variable_Binary (X3) = 2,
             "Near-half either");
   end;

   ---------------------------------------------------------------------
   Section ("9. Solve_Binary_BB — tiny binary IPs");
   ---------------------------------------------------------------------
   declare
      --  max x1+x2 s.t. 2x1+2x2 ≤ 3, x in {0,1} → opt=1
      A1 : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B1 : constant Vector (1 .. 1) := [3.0];
      C1 : constant Vector (1 .. 2) := [1.0, 1.0];
      R1 : constant Result := Solve_Binary_BB (A1, B1, C1, Cfg);

      --  max 3x1+4x2 s.t. 2x1+x2 ≤ 2, x1+2x2 ≤ 2 → LP may be fractional
      A2 : constant Matrix (1 .. 2, 1 .. 2) :=
        [[2.0, 1.0],
         [1.0, 2.0]];
      B2 : constant Vector (1 .. 2) := [2.0, 2.0];
      C2 : constant Vector (1 .. 2) := [3.0, 4.0];
      R2 : constant Result := Solve_Binary_BB (A2, B2, C2, Cfg);
      --  Feasible binaries: (0,0)=0, (1,0)=3, (0,1)=4, (1,1)=7 but
      --  2+1=3>2 infeas. So opt=4 at (0,1)

      --  Single var max x s.t. x ≤ 1 → 1
      A3 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B3 : constant Vector (1 .. 1) := [1.0];
      C3 : constant Vector (1 .. 1) := [5.0];
      R3 : constant Result := Solve_Binary_BB (A3, B3, C3, Cfg);

      --  Infeasible: x1+x2 ≤ −1 impossible for x≥0 binary
      A4 : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B4 : constant Vector (1 .. 1) := [-1.0];
      C4 : constant Vector (1 .. 2) := [1.0, 1.0];
      R4 : constant Result := Solve_Binary_BB (A4, B4, C4, Cfg);

      --  All-zero objective still feasible
      A5 : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B5 : constant Vector (1 .. 1) := [1.0];
      C5 : constant Vector (1 .. 2) := [0.0, 0.0];
      R5 : constant Result := Solve_Binary_BB (A5, B5, C5, Cfg);
   begin
      Check (R1.Success, "BB1 success");
      Check (R1.Stat = Optimal, "BB1 Optimal");
      Check (Approx (R1.Objective, 1.0), "BB1 obj=1");
      Check (Is_Binary_Vector (R1.X (1 .. 2)), "BB1 binary sol");
      Check (R2.Success, "BB2 success");
      Check (Approx (R2.Objective, 4.0), "BB2 obj=4");
      Check (Approx (R2.X (1), 0.0) and then Approx (R2.X (2), 1.0),
             "BB2 x=(0,1)");
      Check (R3.Success, "BB3 success");
      Check (Approx (R3.Objective, 5.0), "BB3 obj=5");
      Check (Approx (R3.X (1), 1.0), "BB3 x=1");
      Check (not R4.Success, "BB4 infeasible");
      Check (R4.Stat = Infeasible, "BB4 status");
      Check (R5.Success, "BB5 zero-obj success");
      Check (Approx (R5.Objective, 0.0), "BB5 obj=0");
      Check (R1.Nodes >= 1, "BB1 visited nodes");
   end;

   ---------------------------------------------------------------------
   Section ("10. LP relaxation vs binary BB gap demo");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      LP : constant Result := Maximize_LP (A, B, C, Cfg);
      IP : constant Result := Solve_Binary_BB (A, B, C, Cfg);
      G  : Real;
   begin
      Check (LP.Success and then IP.Success, "Both succeed");
      Check (LP.Objective >= IP.Objective - 1.0E-6, "LP ≥ IP");
      G := Integrality_Gap (LP.Objective, IP.Objective);
      Check (Approx (G, 0.5), "Classic gap 0.5");
      Check (not Is_Binary_Vector (LP.X (1 .. 2)), "LP fractional");
      Check (Is_Binary_Vector (IP.X (1 .. 2)), "IP binary");
   end;

   ---------------------------------------------------------------------
   Section ("11. Knapsack as binary IP via BB (small)");
   ---------------------------------------------------------------------
   declare
      --  max 3x1+4x2+5x3 s.t. 2x1+3x2+4x3 ≤ 5, binary
      A : constant Matrix (1 .. 1, 1 .. 3) := [[2.0, 3.0, 4.0]];
      B : constant Vector (1 .. 1) := [5.0];
      C : constant Vector (1 .. 3) := [3.0, 4.0, 5.0];
      Items : constant Knapsack_Items (1 .. 3) :=
        [(2, 3.0), (3, 4.0), (4, 5.0)];
      DP : constant Knapsack_Result := Solve_Knapsack_01 (Items, 5);
      BB : constant Result := Solve_Binary_BB (A, B, C, Cfg);
   begin
      Check (DP.Success and then BB.Success, "DP and BB succeed");
      Check (Approx (DP.Objective, BB.Objective), "DP matches BB");
      Check (Approx (DP.Objective, 7.0), "Known opt=7");
   end;

   ---------------------------------------------------------------------
   Section ("12. More LP / Phase-I / bounds");
   ---------------------------------------------------------------------
   declare
      --  max x+y s.t. x+y ≤ 2, x ≤ 1.5, y ≤ 1.5
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [2.0, 1.5, 1.5];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Maximize_LP (A, B, C, Cfg);

      A0 : constant Matrix (1 .. 1, 1 .. 2) := [[0.0, 0.0]];
      B0 : constant Vector (1 .. 1) := [0.0];
      C0 : constant Vector (1 .. 2) := [0.0, 0.0];
      R0 : constant Result := Maximize_LP (A0, B0, C0, Cfg);
   begin
      Check (R.Success, "LP bounds success");
      Check (Approx (R.Objective, 2.0), "LP bounds obj=2");
      Check (R0.Success, "Zero LP success");
      Check (Approx (R0.Objective, 0.0), "Zero LP obj=0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Extra knapsack / binary edge cases");
   ---------------------------------------------------------------------
   declare
      Items : constant Knapsack_Items (1 .. 3) :=
        [(10, 100.0), (1, 1.0), (1, 1.0)];
      R : constant Knapsack_Result := Solve_Knapsack_01 (Items, 2);
      --  Only two unit items

      A : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 1.0, 1.0],
         [1.0, 0.0, 0.0]];
      B : constant Vector (1 .. 2) := [2.0, 1.0];
      C : constant Vector (1 .. 3) := [5.0, 3.0, 3.0];
      BB : constant Result := Solve_Binary_BB (A, B, C, Cfg);
      --  Opt: x1=1, and one of x2/x3 → obj=8
   begin
      Check (Approx (R.Objective, 2.0), "Heavy item excluded");
      Check (not R.Selected (1) and then R.Selected (2)
             and then R.Selected (3), "Select two light");
      Check (BB.Success, "3-var BB success");
      Check (Approx (BB.Objective, 8.0), "3-var BB obj=8");
      Check (Approx (BB.X (1), 1.0), "3-var x1=1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Config / Active_Obj_Row / Extract");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 1) := [1.0];
      Tab : constant Tableau := Build_Tableau (A, B, C);
      X : Vector (1 .. 1);
      Cfg2 : constant Config :=
        (Max_Pivots => 10, Max_Nodes => 50,
         Tol => 1.0E-8, Integer_Tol => 1.0E-5);
   begin
      Check (Active_Obj_Row (Tab) = 0, "Active row 0 Phase II");
      Check (Cfg2.Max_Nodes = 50, "Config Max_Nodes");
      Check (Default_Config.Max_Pivots = 500, "Default Max_Pivots");
      declare
         Tab2 : Tableau := Tab;
         R : constant Result := Solve_Tableau (Tab2, Cfg2);
      begin
         Check (R.Success, "Cfg2 solve");
         X := Extract_Primal (Tab2, 1);
         Check (Approx (X (1), 1.0), "Extract primal");
      end;
      Check (Method_Count = 4, "Method_Count again");
      Check (Classify ([True, True], True) = Binary_IP,
             "Classify 2-bin");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=====================================");
   Ada.Text_IO.Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   Ada.Text_IO.Put_Line ("=====================================");

   pragma Assert (Fail_Count = 0);
   pragma Assert (Pass_Count >= 100);

end Tests;
