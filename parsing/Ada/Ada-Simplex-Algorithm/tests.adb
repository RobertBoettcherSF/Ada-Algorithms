--  Standalone test suite for Simplex_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Simplex_Algorithm; use Simplex_Algorithm;

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
     (Max_Pivots => 500, Tol => 1.0E-10);

begin
   Ada.Text_IO.Put_Line ("Simplex_Algorithm test suite");
   Ada.Text_IO.Put_Line ("============================");

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
   Section ("2. Build_Tableau slack basis (b ≥ 0)");
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
      Check (T.M = 3, "M=3 constraints");
      Check (T.N_Decision = 2, "N_Decision=2");
      Check (T.N_Slack = 3, "N_Slack=3");
      Check (T.N_Artificial = 0, "no artificials when b≥0");
      Check (T.N = 5, "N=2+3 columns");
      Check (T.Obj_Phase1 = 0, "no Phase-I row");
      Check (Approx (T.T (0, 1), -3.0), "obj reduced cost −c1");
      Check (Approx (T.T (0, 2), -5.0), "obj reduced cost −c2");
      Check (Approx (T.T (0, 3), 0.0), "slack1 reduced cost 0");
      Check (Approx (T.T (1, 0), 4.0), "RHS row1");
      Check (Approx (T.T (2, 0), 12.0), "RHS row2");
      Check (Approx (T.T (3, 0), 18.0), "RHS row3");
      Check (Approx (T.T (1, 3), 1.0), "slack1 identity");
      Check (Approx (T.T (2, 4), 1.0), "slack2 identity");
      Check (Approx (T.T (3, 5), 1.0), "slack3 identity");
      Check (T.Basic (1) = 3, "basic1 = slack1");
      Check (T.Basic (2) = 4, "basic2 = slack2");
      Check (T.Basic (3) = 5, "basic3 = slack3");
      Check (not Is_Optimal (T), "initial not optimal");
      Check (Select_Entering (T) = 1, "Bland enters smallest index (x)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Pivot / Is_Optimal / Select_Leaving");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      C : constant Vector (1 .. 2) := [3.0, 2.0];
      T : Tableau := Build_Tableau (A, B, C);
      Enter, Leave : Natural;
      X : Vector (1 .. 2);
   begin
      Check (not Is_Optimal (T), "pre-pivot not optimal");
      Enter := Select_Entering (T);
      Check (Enter = 1, "enter col 1 (Bland)");
      Leave := Select_Leaving (T, Enter);
      Check (Leave > 0, "leaving row exists");
      --  Ratios: row1 4/1=4, row2 6/2=3 → leave row 2
      Check (Leave = 2, "min-ratio leaves row 2");
      Pivot (T, Leave, Enter);
      Check (T.Basic (2) = 1, "after pivot basic2 = x1");
      Check (Approx (T.T (2, 1), 1.0), "pivot column cleared to 1");
      Check (Approx (T.T (1, 1), 0.0, 1.0E-9), "pivot col row1 cleared");
      Check (Approx (T.T (0, 1), 0.0, 1.0E-9), "pivot col obj cleared");
      X := Extract_Primal (T, 2);
      Check (Approx (X (1), 3.0), "x1=3 after first pivot");
      Check (Approx (X (2), 0.0), "x2 still nonbasic 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Classic textbook: max 3x+5y → (2,6) z=36");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      R : constant Result := Maximize (A, B, C, Default_Cfg);
   begin
      Check (R.Stat = Optimal, "classic Optimal");
      Check (R.Success, "classic Success");
      Check (Approx (R.Objective, 36.0, 1.0E-6), "classic z=36");
      Check (Approx (R.X (1), 2.0, 1.0E-6), "classic x=2");
      Check (Approx (R.X (2), 6.0, 1.0E-6), "classic y=6");
      Check (R.N_Vars = 2, "classic N_Vars=2");
      Check (R.N_Pivots >= 1, "classic used pivots");
      Check (R.N_Pivots <= 10, "classic few pivots");
   end;

   ---------------------------------------------------------------------
   Section ("5. Unbounded ray");
   ---------------------------------------------------------------------
   declare
      --  max x  s.t.  x − y ≤ 1,  x,y ≥ 0  → unbounded
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, -1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      R : constant Result := Maximize (A, B, C, Default_Cfg);
   begin
      Check (R.Stat = Unbounded, "unbounded status");
      Check (not R.Success, "unbounded not Success");
   end;

   declare
      --  max x+y s.t. −x + y ≤ 1  (only one constraint) → unbounded
      A : constant Matrix (1 .. 1, 1 .. 2) := [[-1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Maximize (A, B, C, Default_Cfg);
   begin
      Check (R.Stat = Unbounded, "unbounded 2 status");
      Check (not R.Success, "unbounded 2 not Success");
   end;

   ---------------------------------------------------------------------
   Section ("6. Infeasible (two-phase / artificials)");
   ---------------------------------------------------------------------
   declare
      --  max x  s.t. x ≤ 1 and −x ≤ −2 (i.e. x ≥ 2) → infeasible
      A : constant Matrix (1 .. 2, 1 .. 1) :=
        [[1.0],
         [-1.0]];
      B : constant Vector (1 .. 2) := [1.0, -2.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize (A, B, C, Default_Cfg);
      T : constant Tableau := Build_Tableau (A, B, C);
   begin
      Check (T.N_Artificial >= 1, "infeas build has artificial");
      Check (T.Obj_Phase1 > 0, "infeas has Phase-I row");
      Check (R.Stat = Infeasible, "infeasible status");
      Check (not R.Success, "infeasible not Success");
   end;

   declare
      --  max x+y s.t. x+y ≤ 1, −x−y ≤ −3 → infeasible
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [-1.0, -1.0]];
      B : constant Vector (1 .. 2) := [1.0, -3.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Maximize (A, B, C, Default_Cfg);
   begin
      Check (R.Stat = Infeasible, "infeasible sum status");
      Check (not R.Success, "infeasible sum not Success");
   end;

   ---------------------------------------------------------------------
   Section ("7. Tiny 1-var LPs");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[2.0]];
      B : constant Vector (1 .. 1) := [10.0];
      C : constant Vector (1 .. 1) := [3.0];
      R : constant Result := Maximize (A, B, C);
   begin
      --  max 3x s.t. 2x ≤ 10 → x=5, z=15
      Check (R.Stat = Optimal, "1var Optimal");
      Check (Approx (R.Objective, 15.0), "1var z=15");
      Check (Approx (R.X (1), 5.0), "1var x=5");
   end;

   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [0.0];
      C : constant Vector (1 .. 1) := [5.0];
      R : constant Result := Maximize (A, B, C);
   begin
      --  max 5x s.t. x ≤ 0 → x=0, z=0
      Check (R.Stat = Optimal, "bound0 Optimal");
      Check (Approx (R.Objective, 0.0), "bound0 z=0");
      Check (Approx (R.X (1), 0.0), "bound0 x=0");
   end;

   declare
      A : constant Matrix (1 .. 2, 1 .. 1) := [[1.0], [1.0]];
      B : constant Vector (1 .. 2) := [3.0, 5.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize (A, B, C);
   begin
      --  max x s.t. x≤3, x≤5 → x=3
      Check (R.Stat = Optimal, "two-upper Optimal");
      Check (Approx (R.X (1), 3.0), "two-upper x=3");
      Check (Approx (R.Objective, 3.0), "two-upper z=3");
   end;

   ---------------------------------------------------------------------
   Section ("8. Two-variable diet / production variants");
   ---------------------------------------------------------------------
   declare
      --  max 4x+3y s.t. x≤4, y≤6, x+y≤8 → (4,4) or check z=28? 
      --  At (4,4): z=28; at (2,6): z=26; at (4,4) on x+y=8. Optimal (4,4) z=28
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0],
         [1.0, 1.0]];
      B : constant Vector (1 .. 3) := [4.0, 6.0, 8.0];
      C : constant Vector (1 .. 2) := [4.0, 3.0];
      R : constant Result := Maximize (A, B, C);
   begin
      Check (R.Stat = Optimal, "prod Optimal");
      Check (Approx (R.Objective, 28.0, 1.0E-5), "prod z=28");
      Check (Approx (R.X (1), 4.0, 1.0E-5), "prod x=4");
      Check (Approx (R.X (2), 4.0, 1.0E-5), "prod y=4");
   end;

   declare
      --  max x+2y s.t. x+y≤4, x≤3, y≤3 → (1,3) z=7
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [4.0, 3.0, 3.0];
      C : constant Vector (1 .. 2) := [1.0, 2.0];
      R : constant Result := Maximize (A, B, C);
   begin
      Check (R.Stat = Optimal, "diet Optimal");
      Check (Approx (R.Objective, 7.0, 1.0E-5), "diet z=7");
      Check (Approx (R.X (1), 1.0, 1.0E-5), "diet x=1");
      Check (Approx (R.X (2), 3.0, 1.0E-5), "diet y=3");
   end;

   declare
      --  max 2x+y s.t. x+y≤3, x≤2 → (2,1) z=5
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0]];
      B : constant Vector (1 .. 2) := [3.0, 2.0];
      C : constant Vector (1 .. 2) := [2.0, 1.0];
      R : constant Result := Maximize (A, B, C);
   begin
      Check (R.Stat = Optimal, "mix Optimal");
      Check (Approx (R.Objective, 5.0, 1.0E-5), "mix z=5");
      Check (Approx (R.X (1), 2.0, 1.0E-5), "mix x=2");
      Check (Approx (R.X (2), 1.0, 1.0E-5), "mix y=1");
   end;

   ---------------------------------------------------------------------
   Section ("9. Already optimal at origin");
   ---------------------------------------------------------------------
   declare
      --  max −x−y s.t. x+y≤1 → optimum at (0,0), z=0
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [-1.0, -1.0];
      R : constant Result := Maximize (A, B, C);
      T : constant Tableau := Build_Tableau (A, B, C);
   begin
      Check (Is_Optimal (T), "neg obj already optimal");
      Check (Select_Entering (T) = 0, "neg obj no entering");
      Check (R.Stat = Optimal, "neg obj Optimal");
      Check (Approx (R.Objective, 0.0), "neg obj z=0");
      Check (Approx (R.X (1), 0.0), "neg obj x=0");
      Check (Approx (R.X (2), 0.0), "neg obj y=0");
   end;

   ---------------------------------------------------------------------
   Section ("10. Solve on built tableau matches Maximize");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [5.0, 8.0];
      C : constant Vector (1 .. 2) := [3.0, 2.0];
      T : Tableau := Build_Tableau (A, B, C);
      R1 : constant Result := Maximize (A, B, C);
      R2 : Result;
   begin
      R2 := Solve (T, Default_Cfg);
      Check (R1.Stat = R2.Stat, "Solve/Maximize same status");
      Check (Approx (R1.Objective, R2.Objective, 1.0E-8),
             "Solve/Maximize same z");
      Check (Approx (R1.X (1), R2.X (1), 1.0E-8), "Solve/Maximize x");
      Check (Approx (R1.X (2), R2.X (2), 1.0E-8), "Solve/Maximize y");
      --  max 3x+2y s.t. x+y≤5, 2x+y≤8 → (3,2)? 3+2=5, 6+2=8 → z=13
      --  or (4,0): z=12; (0,5): z=10. Vertex (3,2) from 2x+y=8 & x+y=5 →
      --  x=3,y=2,z=13. Or (0,5),(4,0),(0,0).
      Check (Approx (R1.Objective, 13.0, 1.0E-5), "pair z=13");
      Check (Approx (R1.X (1), 3.0, 1.0E-5), "pair x=3");
      Check (Approx (R1.X (2), 2.0, 1.0E-5), "pair y=2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Bland entering prefers lowest index");
   ---------------------------------------------------------------------
   declare
      --  Both x and y improve; Bland must pick column 1 first.
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [10.0];
      C : constant Vector (1 .. 2) := [5.0, 5.0];
      T : constant Tableau := Build_Tableau (A, B, C);
   begin
      Check (Select_Entering (T) = 1, "Bland picks col 1 not 2");
      Check (Approx (T.T (0, 1), -5.0), "both reduced costs −5");
      Check (Approx (T.T (0, 2), -5.0), "both reduced costs −5 b");
   end;

   ---------------------------------------------------------------------
   Section ("12. Active_Obj_Row / Phase-I bookkeeping");
   ---------------------------------------------------------------------
   declare
      A0 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B0 : constant Vector (1 .. 1) := [2.0];
      C0 : constant Vector (1 .. 1) := [1.0];
      T0 : constant Tableau := Build_Tableau (A0, B0, C0);
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[-1.0]];
      B1 : constant Vector (1 .. 1) := [-3.0];  -- −x ≤ −3 → x ≥ 3
      C1 : constant Vector (1 .. 1) := [1.0];
      T1 : constant Tableau := Build_Tableau (A1, B1, C1);
   begin
      Check (Active_Obj_Row (T0) = 0, "no Phase I → row 0");
      Check (T1.N_Artificial = 1, "neg RHS → 1 artificial");
      Check (Active_Obj_Row (T1) = T1.Obj_Phase1, "Phase I active");
      Check (T1.Obj_Phase1 = 2, "Phase-I row index M+1");
      --  After negation, Phase-I value = −Σa = −3 initially
      Check (Approx (T1.T (T1.Obj_Phase1, 0), -3.0, 1.0E-9),
             "Phase-I value −Σa = −3");
   end;

   ---------------------------------------------------------------------
   Section ("13. Feasible problem needing Phase I then Phase II");
   ---------------------------------------------------------------------
   declare
      --  max x  s.t. −x ≤ −1 (x≥1), x ≤ 4  → x=4, z=4
      A : constant Matrix (1 .. 2, 1 .. 1) :=
        [[-1.0],
         [1.0]];
      B : constant Vector (1 .. 2) := [-1.0, 4.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant Result := Maximize (A, B, C);
      T : constant Tableau := Build_Tableau (A, B, C);
   begin
      Check (T.N_Artificial = 1, "lower-bound needs artificial");
      Check (R.Stat = Optimal, "PhaseI+II Optimal");
      Check (Approx (R.Objective, 4.0, 1.0E-5), "PhaseI+II z=4");
      Check (Approx (R.X (1), 4.0, 1.0E-5), "PhaseI+II x=4");
      Check (R.Success, "PhaseI+II Success");
   end;

   ---------------------------------------------------------------------
   Section ("14. Zero objective / degenerate RHS");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 2) := [0.0, 0.0];
      C : constant Vector (1 .. 2) := [1.0, 1.0];
      R : constant Result := Maximize (A, B, C);
   begin
      Check (R.Stat = Optimal, "degen Optimal");
      Check (Approx (R.Objective, 0.0), "degen z=0");
      Check (Approx (R.X (1), 0.0), "degen x=0");
      Check (Approx (R.X (2), 0.0), "degen y=0");
   end;

   ---------------------------------------------------------------------
   Section ("15. Three variables");
   ---------------------------------------------------------------------
   declare
      --  max x+y+z s.t. x≤1, y≤1, z≤1 → (1,1,1) z=3
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 1.0]];
      B : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      C : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      R : constant Result := Maximize (A, B, C);
   begin
      Check (R.Stat = Optimal, "3var Optimal");
      Check (Approx (R.Objective, 3.0, 1.0E-5), "3var z=3");
      Check (Approx (R.X (1), 1.0, 1.0E-5), "3var x=1");
      Check (Approx (R.X (2), 1.0, 1.0E-5), "3var y=1");
      Check (Approx (R.X (3), 1.0, 1.0E-5), "3var z=1");
   end;

   declare
      --  max 5x+4y+3z s.t. 2x+3y+z≤5, 4x+y+2z≤11, 3x+4y+2z≤8
      --  (Wikipedia-style). Known optimum z=13 at (0,0,4)? Check:
      --  Actually classic solution is x=2,y=0,z=1? Let's verify by solver
      --  and check consistency: feasibility + objective match.
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[2.0, 3.0, 1.0],
         [4.0, 1.0, 2.0],
         [3.0, 4.0, 2.0]];
      B : constant Vector (1 .. 3) := [5.0, 11.0, 8.0];
      C : constant Vector (1 .. 3) := [5.0, 4.0, 3.0];
      R : constant Result := Maximize (A, B, C);
      Z_Check : Real;
   begin
      Check (R.Stat = Optimal, "wiki3 Optimal");
      Check (R.Success, "wiki3 Success");
      --  Feasibility
      Check (2.0 * R.X (1) + 3.0 * R.X (2) + R.X (3) <= 5.0 + 1.0E-5,
             "wiki3 c1 feasible");
      Check (4.0 * R.X (1) + R.X (2) + 2.0 * R.X (3) <= 11.0 + 1.0E-5,
             "wiki3 c2 feasible");
      Check (3.0 * R.X (1) + 4.0 * R.X (2) + 2.0 * R.X (3) <= 8.0 + 1.0E-5,
             "wiki3 c3 feasible");
      Check (R.X (1) >= -1.0E-8 and then R.X (2) >= -1.0E-8
             and then R.X (3) >= -1.0E-8,
             "wiki3 nonneg");
      Z_Check := 5.0 * R.X (1) + 4.0 * R.X (2) + 3.0 * R.X (3);
      Check (Approx (R.Objective, Z_Check, 1.0E-5), "wiki3 z matches x");
      --  Known optimum is 13 at (2, 0, 1): 5*2+3*1=13
      Check (Approx (R.Objective, 13.0, 1.0E-4), "wiki3 z=13");
   end;

   ---------------------------------------------------------------------
   Section ("16. Select_Leaving unbounded column");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, -1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C : constant Vector (1 .. 2) := [0.0, 1.0];  -- improve y
      T : constant Tableau := Build_Tableau (A, B, C);
      Enter : Natural;
   begin
      --  y has reduced cost −1; column 2 of constraint is −1 (no positive)
      Enter := Select_Entering (T);
      Check (Enter = 2, "unbounded enter y");
      Check (Select_Leaving (T, Enter) = 0, "unbounded leaving=0");
      Check (not Is_Optimal (T), "unbounded not optimal");
   end;

   ---------------------------------------------------------------------
   Section ("17. Extract_Primal zeros nonbasics");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 2) := [[1.0, 1.0]];
      B : constant Vector (1 .. 1) := [5.0];
      C : constant Vector (1 .. 2) := [1.0, 0.0];
      T : Tableau := Build_Tableau (A, B, C);
      X : Vector (1 .. 2);
   begin
      X := Extract_Primal (T, 2);
      Check (Approx (X (1), 0.0) and then Approx (X (2), 0.0),
             "initial primal all zero");
      Pivot (T, 1, 1);
      X := Extract_Primal (T, 2);
      Check (Approx (X (1), 5.0), "after pivot x1=5");
      Check (Approx (X (2), 0.0), "after pivot x2=0");
   end;

   ---------------------------------------------------------------------
   Section ("18. Config Tol / Max_Pivots smoke");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [2.0];
      C : constant Vector (1 .. 1) := [1.0];
      Cfg : Config := Default_Cfg;
      R : Result;
   begin
      Cfg.Tol := 1.0E-8;
      R := Maximize (A, B, C, Cfg);
      Check (R.Stat = Optimal, "Tol config Optimal");
      Check (Approx (R.X (1), 2.0), "Tol config x=2");
      Cfg.Max_Pivots := 1;
      R := Maximize (A, B, C, Cfg);
      --  One pivot suffices for this tiny LP
      Check (R.Stat = Optimal, "Max_Pivots=1 still Optimal");
   end;

   ---------------------------------------------------------------------
   Section ("19. More Near / helper regression");
   ---------------------------------------------------------------------
   begin
      Check (Near (3.1415926535, 3.1415926535), "Near pi");
      Check (not Near (1.0, 1.0 + 1.0E-5, 1.0E-9), "Near tight reject");
      Check (Near (1.0, 1.0 + 1.0E-5, 1.0E-4), "Near loose accept");
      Check (Near (-100.0, -100.0), "Near −100");
      Check (Approx (Real (0.0), 0.0), "Approx zero");
   end;

   declare
      A : constant Vector (1 .. 4) := [0.0, 0.0, 0.0, 0.0];
      B : constant Vector (1 .. 4) := [0.0, 0.0, 0.0, 1.0E-12];
   begin
      Check (Vec_Near (A, B, 1.0E-9), "Vec_Near near-zero vec");
      Check (not Vec_Near (A, B, 1.0E-15), "Vec_Near strict reject");
   end;

   ---------------------------------------------------------------------
   Section ("20. Extra LP sanity battery");
   ---------------------------------------------------------------------
   declare
      --  max 10x s.t. x≤1 → z=10
      R1 : constant Result :=
        Maximize ([[1.0]], [1.0], [10.0]);
      --  max y s.t. y≤7 → z=7
      R2 : constant Result :=
        Maximize ([[1.0]], [7.0], [1.0]);
      --  max x+y s.t. x≤2, y≤3 → (2,3) z=5
      R3 : constant Result :=
        Maximize ([[1.0, 0.0], [0.0, 1.0]], [2.0, 3.0], [1.0, 1.0]);
      --  max 2x s.t. 4x≤8 → x=2 z=4
      R4 : constant Result :=
        Maximize ([[4.0]], [8.0], [2.0]);
   begin
      Check (R1.Stat = Optimal and then Approx (R1.Objective, 10.0),
             "battery R1");
      Check (R2.Stat = Optimal and then Approx (R2.Objective, 7.0),
             "battery R2");
      Check (R3.Stat = Optimal and then Approx (R3.Objective, 5.0),
             "battery R3 z");
      Check (Approx (R3.X (1), 2.0) and then Approx (R3.X (2), 3.0),
             "battery R3 x");
      Check (R4.Stat = Optimal and then Approx (R4.Objective, 4.0),
             "battery R4");
      Check (Approx (R4.X (1), 2.0), "battery R4 x");
   end;

   declare
      --  Unbounded: max x+y no constraining upper on both
      R : constant Result :=
        Maximize ([[1.0, -2.0]], [0.0], [1.0, 1.0]);
   begin
      Check (R.Stat = Unbounded, "battery unbounded");
   end;

   declare
      --  Infeasible: x≤1 and x≥5
      R : constant Result :=
        Maximize ([[1.0], [-1.0]], [1.0, -5.0], [1.0]);
   begin
      Check (R.Stat = Infeasible, "battery infeasible");
   end;

   declare
      --  max 3x+4y s.t. x+y≤5, x≤3, y≤4 → (1,4) z=19? 3+16=19;
      --  (3,2): 9+8=17. Yes (1,4).
      R : constant Result :=
        Maximize
          ([[1.0, 1.0], [1.0, 0.0], [0.0, 1.0]],
           [5.0, 3.0, 4.0],
           [3.0, 4.0]);
   begin
      Check (R.Stat = Optimal, "3x4y Optimal");
      Check (Approx (R.Objective, 19.0, 1.0E-5), "3x4y z=19");
      Check (Approx (R.X (1), 1.0, 1.0E-5), "3x4y x=1");
      Check (Approx (R.X (2), 4.0, 1.0E-5), "3x4y y=4");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("======================================");
   Ada.Text_IO.Put_Line ("Pass_Count =" & Pass_Count'Image);
   Ada.Text_IO.Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
