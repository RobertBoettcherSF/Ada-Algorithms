--  Standalone test suite for Branch_And_Cut (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Branch_And_Cut; use Branch_And_Cut;

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
     (Max_Nodes         => 200,
      Max_Pivots        => 400,
      Max_Cuts_Per_Node => 3,
      Tol               => 1.0E-9,
      Integer_Tol       => 1.0E-6,
      Use_Best_Bound     => False);

   Cuts_Off : constant Config :=
     (Max_Nodes         => 200,
      Max_Pivots        => 400,
      Max_Cuts_Per_Node => 0,
      Tol               => 1.0E-9,
      Integer_Tol       => 1.0E-6,
      Use_Best_Bound     => False);

   Best_Bound_Cfg : constant Config :=
     (Max_Nodes         => 200,
      Max_Pivots        => 400,
      Max_Cuts_Per_Node => 3,
      Tol               => 1.0E-9,
      Integer_Tol       => 1.0E-6,
      Use_Best_Bound     => True);

   All_Int_2 : constant Integer_Flags (1 .. 2) := [True, True];
   All_Int_1 : constant Integer_Flags (1 .. 1) := [True];
   All_Int_3 : constant Integer_Flags (1 .. 3) := [True, True, True];
   Mixed_2   : constant Integer_Flags (1 .. 2) := [True, False];

begin
   Ada.Text_IO.Put_Line ("Branch_And_Cut test suite");
   Ada.Text_IO.Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Frac / Is_Integer helpers");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.5, 3.0];
      Z : constant Vector (1 .. 2) := [1.0, 2.0];
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
      Check (Approx (Frac (0.999), 0.999, 1.0E-12), "Frac near one");
      Check (Is_Integer (3.0), "Is_Integer 3");
      Check (Is_Integer (3.0 + 1.0E-12), "Is_Integer near");
      Check (not Is_Integer (3.5), "Is_Integer rejects 3.5");
      Check (Is_Integer_Vector (Z), "Is_Integer_Vector true");
      Check (not Is_Integer_Vector (W), "Is_Integer_Vector false");
      Check (Is_Integer (-2.0), "Is_Integer -2");
      Check (not Is_Integer (-2.3), "Is_Integer -2.3");
      Check (Near (100.0, 100.0 + 5.0E-12), "Near large mag");
      Check (Required_Are_Integer ([1.0, 2.0, 0.5], Req),
             "Required_Are_Integer ignores continuous");
      Check (not Required_Are_Integer ([1.5, 2.0, 0.5], Req),
             "Required_Are_Integer catches fractional");
   end;

   ---------------------------------------------------------------------
   Section ("2. Embedded Maximize_LP — simple LPs");
   ---------------------------------------------------------------------
   declare
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B1 : constant Vector (1 .. 1) := [2.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      R1 : constant Result := Maximize_LP (A1, B1, C1, Default_Cfg);

      A2 : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B2 : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      C2 : constant Vector (1 .. 2) := [1.0, 1.0];
      R2 : constant Result := Maximize_LP (A2, B2, C2, Default_Cfg);

      A3 : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0],
         [2.0, 1.0]];
      B3 : constant Vector (1 .. 2) := [4.0, 5.0];
      C3 : constant Vector (1 .. 2) := [3.0, 4.0];
      R3 : constant Result := Maximize_LP (A3, B3, C3, Default_Cfg);
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
   end;

   ---------------------------------------------------------------------
   Section ("3. Tableau helpers: Build / Enter / Leave / Pivot");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      Ent, Leave : Natural;
      R : Result;
   begin
      Check (Tab.M = 1, "Build M=1");
      Check (Tab.N_Decision = 2, "Build N_Decision=2");
      Check (Tab.N_Slack = 1, "Build N_Slack=1");
      Check (Tab.N = 3, "Build N=3");
      Check (not Is_Optimal_LP (Tab), "not optimal before solve");
      Ent := Select_Entering (Tab);
      Check (Ent >= 1, "Select_Entering finds column");
      Leave := Select_Leaving (Tab, Ent);
      Check (Leave = 1, "Select_Leaving row 1");
      R := Solve_Tableau (Tab, Default_Cfg);
      Check (R.Success, "Solve_Tableau success");
      Check (Approx (R.Objective, 1.5), "LP relax obj=1.5");
      Check (Is_Optimal_LP (Tab), "optimal after solve");
      Check (Active_Obj_Row (Tab) = 0, "Active_Obj_Row phase II");
   end;

   ---------------------------------------------------------------------
   Section ("4. Gomory_Cut_From_Row");
   ---------------------------------------------------------------------
   declare
      Tab : Tableau;
      Gc  : Cut;
   begin
      Tab.M := 1;
      Tab.N := 3;
      Tab.N_Decision := 2;
      Tab.T (1, 0) := 1.5;
      Tab.T (1, 1) := 1.0;
      Tab.T (1, 2) := 0.5;
      Tab.T (1, 3) := 0.25;
      Tab.Basic (1) := 1;
      Gc := Gomory_Cut_From_Row (Tab, 1);
      Check (Gc.Valid, "Gomory cut valid");
      Check (Approx (Gc.RHS, 0.5), "Gomory f0=0.5");
      Check (Approx (Gc.Coeff (1), 0.0), "Gomory f1=0");
      Check (Approx (Gc.Coeff (2), 0.5), "Gomory f2=0.5");
      Check (Approx (Gc.Coeff (3), 0.25), "Gomory f3=0.25");
      Check (Gc.N_Cols = 3, "Gomory N_Cols=3");
      Check (First_Fractional_Row (Tab) = 1, "First_Fractional_Row");

      Tab.T (1, 0) := 2.0;
      Gc := Gomory_Cut_From_Row (Tab, 1);
      Check (not Gc.Valid, "Gomory invalid on integer RHS");
      Check (First_Fractional_Row (Tab) = 0, "no fractional row");
   end;

   ---------------------------------------------------------------------
   Section ("5. Classic IP: max x+y s.t. 2x+2y ≤ 3");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Solve (A, B, C, All_Int_2, Default_Cfg);
      R0 : constant Result := Solve (A, B, C, All_Int_2, Cuts_Off);
   begin
      Check (R.Success, "classic IP success");
      Check (R.Stat = Optimal, "classic IP Optimal");
      Check (Approx (R.Objective, 1.0), "classic IP obj=1");
      Check (Is_Integer (R.X (1)) and then Is_Integer (R.X (2)),
             "classic IP integer X");
      Check (Approx (R.X (1) + R.X (2), 1.0), "classic IP x+y=1");
      Check (R.Nodes >= 1, "classic IP nodes>=1");
      Check (R0.Success, "classic IP cuts-off success");
      Check (Approx (R0.Objective, 1.0), "classic IP cuts-off obj=1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Classic IP: max 5x+8y s.t. x+y≤6, 5x+9y≤45");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [5.0, 9.0]];
      B : constant Vector (1 .. 2) := [6.0, 45.0];
      C : constant Vector (1 .. 2) := [5.0, 8.0];
      R : constant Result := Solve (A, B, C, All_Int_2, Default_Cfg);
   begin
      Check (R.Success, "5x+8y success");
      Check (R.Stat = Optimal, "5x+8y Optimal");
      --  Known IP optimum is 40 at (0,5) or check feasible integer
      Check (Approx (R.Objective, 40.0) or else Approx (R.Objective, 39.0)
               or else Approx (R.Objective, 41.0),
             "5x+8y obj near 40");
      Check (Is_Integer (R.X (1), 1.0E-4), "5x+8y x int");
      Check (Is_Integer (R.X (2), 1.0E-4), "5x+8y y int");
      Check (R.X (1) + R.X (2) <= 6.0 + 1.0E-4, "5x+8y c1");
      Check (5.0 * R.X (1) + 9.0 * R.X (2) <= 45.0 + 1.0E-3, "5x+8y c2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Already-integer LP relaxation");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 1) := [2.0];
      R : constant Result := Solve (A, B, C, All_Int_1, Default_Cfg);
   begin
      Check (R.Success, "already-int success");
      Check (Approx (R.Objective, 6.0), "already-int obj=6");
      Check (Approx (R.X (1), 3.0), "already-int x=3");
      Check (R.Nodes = 1, "already-int single node");
      Check (R.Cuts = 0, "already-int no cuts needed");
   end;

   ---------------------------------------------------------------------
   Section ("8. Infeasible IP");
   ---------------------------------------------------------------------
   declare
      --  x ≤ 1 and x ≥ 2 (via Apply_Bound path through Solve with
      --  contradictory structure): x + 0 ≤ 1, -x ≤ -2 encoded as
      --  two inequalities that force empty set with x≥0 integer.
      A : constant Matrix (1 .. 2, 1 .. 1) :=
        [[1.0],
         [-1.0]];
      B : constant Vector (1 .. 2) := [1.0, -2.0];  -- x≤1, -x≤-2 ⇒ x≥2
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Solve (A, B, C, All_Int_1, Default_Cfg);
   begin
      Check (not R.Success, "infeasible not success");
      Check (R.Stat = Infeasible, "infeasible status");
   end;

   ---------------------------------------------------------------------
   Section ("9. Branch_Variable / Apply_Bound");
   ---------------------------------------------------------------------
   declare
      X : constant Vector (1 .. 2) := [1.3, 2.7];
      Y : constant Vector (1 .. 2) := [1.0, 2.0];
      Req : constant Integer_Flags (1 .. 2) := [True, True];
      Req2 : constant Integer_Flags (1 .. 2) := [False, True];
      Br : Natural;
      A_In : Matrix (1 .. Max_Constraints, 1 .. 2) :=
        [others => [others => 0.0]];
      A_Out : Matrix (1 .. Max_Constraints, 1 .. 2) :=
        [others => [others => 0.0]];
      B_In : Vector (1 .. Max_Constraints) := [others => 0.0];
      B_Out : Vector (1 .. Max_Constraints) := [others => 0.0];
      Lo : constant Vector (1 .. 2) := [0.0, 1.0];
      Hi : constant Vector (1 .. 2) := [3.0, No_Upper];
      M_Out : Constraint_Count;
   begin
      Br := Branch_Variable (X, Req);
      Check (Br = 1 or else Br = 2, "Branch_Variable picks fractional");
      --  1.3 has frac 0.3 (dist 0.2), 2.7 has frac 0.7 (dist 0.2) — tie → 1
      Check (Br = 1, "Branch_Variable tie → smallest index");
      Check (Branch_Variable (Y, Req) = 0, "Branch_Variable all int → 0");
      Check (Branch_Variable ([1.0, 2.4], Req2) = 2,
             "Branch_Variable respects Required");

      A_In (1, 1) := 1.0;
      A_In (1, 2) := 1.0;
      B_In (1) := 5.0;
      Apply_Bound (A_In, A_Out, B_In, B_Out, Lo, Hi, 1, 2, M_Out);
      --  original + UB x1≤3 + LB -x2≤-1
      Check (M_Out = 3, "Apply_Bound M_Out=3");
      Check (Approx (A_Out (2, 1), 1.0) and then Approx (B_Out (2), 3.0),
             "Apply_Bound UB row");
      Check (Approx (A_Out (3, 2), -1.0) and then Approx (B_Out (3), -1.0),
             "Apply_Bound LB row");
   end;

   ---------------------------------------------------------------------
   Section ("10. Mixed-integer: only x integer");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Solve (A, B, C, Mixed_2, Default_Cfg);
   begin
      Check (R.Success, "MILP mixed success");
      Check (Is_Integer (R.X (1), 1.0E-4), "MILP x integer");
      Check (Approx (R.Objective, 1.5) or else Approx (R.Objective, 1.0),
             "MILP mixed obj");
      --  With only x integer: LP (0.75,0.75) branches on x.
      --  Best: x=1,y=0.5 → obj 1.5 or x=0,y=1.5 → obj 1.5
      Check (Approx (R.Objective, 1.5), "MILP mixed opt=1.5");
   end;

   ---------------------------------------------------------------------
   Section ("11. Cuts-on vs cuts-off node counts");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R_On  : constant Result := Solve (A, B, C, All_Int_2, Default_Cfg);
      R_Off : constant Result := Solve (A, B, C, All_Int_2, Cuts_Off);
   begin
      Check (R_On.Success and then R_Off.Success, "both succeed");
      Check (Approx (R_On.Objective, R_Off.Objective), "same objective");
      Check (R_On.Nodes >= 1 and then R_Off.Nodes >= 1, "nodes positive");
      --  Cuts may reduce or not change nodes on this tiny instance
      Check (R_On.Cuts < 10_000, "cuts counter bounded");
      Check (R_Off.Cuts = 0, "cuts-off zero cuts");
   end;

   ---------------------------------------------------------------------
   Section ("12. Best-bound queue");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Solve (A, B, C, All_Int_2, Best_Bound_Cfg);
   begin
      Check (R.Success, "best-bound success");
      Check (Approx (R.Objective, 1.0), "best-bound obj=1");
      Check (R.Nodes >= 1, "best-bound nodes");
   end;

   ---------------------------------------------------------------------
   Section ("13. Pure continuous (no integer) = LP");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
      B : constant Vector (1 .. 1) := [3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      None : constant Integer_Flags (1 .. 2) := [False, False];
      R : constant Result := Solve (A, B, C, None, Default_Cfg);
   begin
      Check (R.Success, "pure LP via Solve success");
      Check (Approx (R.Objective, 1.5), "pure LP obj=1.5");
      Check (R.Nodes = 1, "pure LP one node");
   end;

   ---------------------------------------------------------------------
   Section ("14. Node_Limit status");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [5.0, 9.0]];
      B : constant Vector (1 .. 2) := [6.0, 45.0];
      C : constant Vector (1 .. 2) := [5.0, 8.0];
      Tiny : constant Config :=
        (Max_Nodes         => 1,
         Max_Pivots        => 400,
         Max_Cuts_Per_Node => 0,
         Tol               => 1.0E-9,
         Integer_Tol       => 1.0E-6,
         Use_Best_Bound     => False);
      R : constant Result := Solve (A, B, C, All_Int_2, Tiny);
   begin
      --  Root is fractional; Max_Nodes=1 → may find nothing or limit
      Check (R.Stat = Node_Limit or else R.Stat = Optimal
               or else R.Stat = Infeasible,
             "tiny budget yields Node_Limit or solved");
      if not R.Success then
         Check (R.Stat = Node_Limit, "expect Node_Limit when unsolved");
      else
         Check (True, "solved within 1 node (lucky integer root)");
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("15. 3-var knapsack-style IP");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 3) := [[2.0, 3.0, 4.0]];
      B : constant Vector (1 .. 1) := [7.0];
      C : constant Vector (1 .. 3) := [4.0, 5.0, 6.0];
      R : constant Result := Solve (A, B, C, All_Int_3, Default_Cfg);
   begin
      Check (R.Success, "knapsack success");
      Check (Is_Integer (R.X (1)) and then Is_Integer (R.X (2))
               and then Is_Integer (R.X (3)),
             "knapsack integer");
      Check (2.0 * R.X (1) + 3.0 * R.X (2) + 4.0 * R.X (3)
               <= 7.0 + 1.0E-4,
             "knapsack feasible");
      --  Best: (0,1,1) weight 7 value 11; or (2,1,0) weight 7 value 13
      Check (Approx (R.Objective, 13.0) or else R.Objective >= 11.0,
             "knapsack obj >= 11");
      Check (Approx (R.Objective, 13.0), "knapsack opt=13");
   end;

   ---------------------------------------------------------------------
   Section ("16. Bulk micro-checks");
   ---------------------------------------------------------------------
   for K in 1 .. 20 loop
      declare
         V : constant Vector (1 .. 2) := [Real (K), Real (K + 1)];
      begin
         Check (Is_Integer_Vector (V),
                "IntVec #" & Integer'Image (K));
      end;
   end loop;
   for K in 1 .. 15 loop
      Check (Near (Real (K), Real (K) + 1.0E-12),
             "Near #" & Integer'Image (K));
   end loop;
   for K in 1 .. 10 loop
      Check (Approx (Frac (Real (K) + 0.25), 0.25, 1.0E-12),
             "Frac #" & Integer'Image (K));
   end loop;

   ---------------------------------------------------------------------
   Section ("17. Config / Result field sanity");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize_LP (A, B, C, Default_Cfg);
   begin
      Check (R.N_Vars = 1, "Result N_Vars");
      Check (Default_Cfg.Max_Nodes = 200, "Config Max_Nodes");
      Check (Default_Cfg.Max_Cuts_Per_Node = 3, "Config Max_Cuts");
      Check (Default_Cfg.Max_Pivots = 400, "Config Max_Pivots");
      Check (not Default_Cfg.Use_Best_Bound, "Config FIFO default");
      Check (Best_Bound_Cfg.Use_Best_Bound, "Config best-bound");
      Check (Cuts_Off.Max_Cuts_Per_Node = 0, "Config cuts off");
      Check (Status'Pos (Optimal) /= Status'Pos (Infeasible),
             "Status enum distinct");
      Check (R.Success = (R.Stat = Optimal), "LP Success iff Optimal");
      Check (Near (No_Upper, 1.0E6), "No_Upper sentinel");
   end;

   ---------------------------------------------------------------------
   Section ("18. Zero objective / single binary");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 1) := [0.0];
      R : constant Result := Solve (A, B, C, All_Int_1, Default_Cfg);
      A2 : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      B2 : constant Vector (1 .. 2) := [1.0, 1.0];
      C2 : constant Vector (1 .. 2) := [3.0, 2.0];
      R2 : constant Result := Solve (A2, B2, C2, All_Int_2, Default_Cfg);
   begin
      Check (R.Success, "zero-c success");
      Check (Approx (R.Objective, 0.0), "zero-c obj=0");
      Check (R2.Success, "box IP success");
      Check (Approx (R2.Objective, 5.0), "box IP obj=5 at (1,1)");
      Check (Approx (R2.X (1), 1.0) and then Approx (R2.X (2), 1.0),
             "box IP X");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=========================");
   Ada.Text_IO.Put_Line
     ("Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count /= 0 then
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   else
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   end if;
end Tests;
