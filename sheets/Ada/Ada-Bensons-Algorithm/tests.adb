--  Standalone test suite for Bensons_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Bensons_Algorithm; use Bensons_Algorithm;

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

   function Has_Outcome
     (R : Result; Y1, Y2 : Real; Tol : Real := 1.0E-5) return Boolean
   is
   begin
      for I in 1 .. R.N_Points loop
         if Approx (R.Points (I).Y.Y1, Y1, Tol)
           and then Approx (R.Points (I).Y.Y2, Y2, Tol)
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Outcome;

   Default_Cfg : constant Config :=
     (Max_Pivots    => 400,
      Max_Dichotomy => 32,
      Weight_Grid   => 11,
      Tol           => 1.0E-9);

   Sparse_Cfg : constant Config :=
     (Max_Pivots    => 400,
      Max_Dichotomy => 16,
      Weight_Grid   => 5,
      Tol           => 1.0E-9);

begin
   Ada.Text_IO.Put_Line ("Bensons_Algorithm test suite");
   Ada.Text_IO.Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Outcome / dominance helpers");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
      A : constant Outcome := (1.0, 2.0);
      B : constant Outcome := (1.0, 2.0);
      C : constant Outcome := (0.5, 1.5);
      D : constant Outcome := (0.5, 3.0);
      E : constant Outcome := (2.0, 1.0);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Vec_Near (U, W, 1.5), "Vec_Near loose Tol");
      Check (Outcome_Near (A, B), "Outcome_Near equal");
      Check (not Outcome_Near (A, C), "Outcome_Near rejects");
      Check (Is_Dominated (A, C), "C dominates A");
      Check (not Is_Dominated (C, A), "A does not dominate C");
      Check (not Is_Dominated (A, D), "D not dominate A (Y2 worse)");
      Check (not Is_Dominated (A, E), "E not dominate A (Y1 worse)");
      Check (Is_Weakly_Dominated (A, B), "weak equal");
      Check (Is_Weakly_Dominated (A, C), "weak C vs A");
      Check (not Is_Weakly_Dominated (C, A), "not weak A vs C");
      Check (not Is_Dominated (A, A), "point not dominate self");
      Check (Near (100.0, 100.0 + 5.0E-12), "Near large mag");
   end;

   ---------------------------------------------------------------------
   Section ("2. Eval_Objectives");
   ---------------------------------------------------------------------
   declare
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      X  : constant Vector (1 .. 2) := [3.0, 4.0];
      Y  : constant Outcome := Eval_Objectives (C1, C2, X);
      C3 : constant Vector (1 .. 2) := [2.0, 1.0];
      C4 : constant Vector (1 .. 2) := [1.0, 3.0];
      Y2 : constant Outcome := Eval_Objectives (C3, C4, X);
   begin
      Check (Approx (Y.Y1, 3.0), "Eval Y1=3");
      Check (Approx (Y.Y2, 4.0), "Eval Y2=4");
      Check (Approx (Y2.Y1, 10.0), "Eval 2x+y=10");
      Check (Approx (Y2.Y2, 15.0), "Eval x+3y=15");
      Check (Approx (Eval_Objectives (C1, C2, [0.0, 0.0]).Y1, 0.0),
             "Eval zero x Y1");
      Check (Approx (Eval_Objectives (C1, C2, [0.0, 0.0]).Y2, 0.0),
             "Eval zero x Y2");
   end;

   ---------------------------------------------------------------------
   Section ("3. Embedded Maximize_LP / Minimize_LP");
   ---------------------------------------------------------------------
   declare
      A1 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B1 : constant Vector (1 .. 1) := [2.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      R1 : constant LP_Result := Maximize_LP (A1, B1, C1, Default_Cfg);

      A2 : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B2 : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C2 : constant Vector (1 .. 2) := [3.0, 5.0];
      R2 : constant LP_Result := Maximize_LP (A2, B2, C2, Default_Cfg);

      A3 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B3 : constant Vector (1 .. 1) := [5.0];
      C3 : constant Vector (1 .. 1) := [1.0];
      R3 : constant LP_Result := Minimize_LP (A3, B3, C3, Default_Cfg);

      --  Infeasible: x ≤ -1, x ≥ 0 impossible via x ≤ -1 alone with x≥0
      A4 : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B4 : constant Vector (1 .. 1) := [-1.0];
      C4 : constant Vector (1 .. 1) := [1.0];
      R4 : constant LP_Result := Maximize_LP (A4, B4, C4, Default_Cfg);
   begin
      Check (R1.Success, "max x≤2 Success");
      Check (R1.Stat = Optimal, "max x≤2 Optimal");
      Check (Approx (R1.Objective, 2.0), "max x≤2 z=2");
      Check (Approx (R1.X (1), 2.0), "max x≤2 x=2");

      Check (R2.Success, "classic Success");
      Check (Approx (R2.Objective, 36.0, 1.0E-5), "classic z=36");
      Check (Approx (R2.X (1), 2.0, 1.0E-5), "classic x=2");
      Check (Approx (R2.X (2), 6.0, 1.0E-5), "classic y=6");

      Check (R3.Success, "min x≤5 Success");
      Check (Approx (R3.Objective, 0.0, 1.0E-6), "min x≥0 → 0");
      Check (Approx (R3.X (1), 0.0, 1.0E-6), "min x=0");

      Check (not R4.Success, "infeasible not Success");
      Check (R4.Stat = Infeasible, "infeasible Stat");
   end;

   ---------------------------------------------------------------------
   Section ("4. Build_Tableau / Bland helpers");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0]];
      B : constant Vector (1 .. 2) := [4.0, 6.0];
      C : constant Vector (1 .. 2) := [3.0, 2.0];
      T : Tableau := Build_Tableau (A, B, C);
      Enter, Leave : Natural;
      X : Vector (1 .. Max_Vars);
   begin
      Check (T.M = 2, "M=2");
      Check (T.N_Decision = 2, "N_Decision=2");
      Check (T.N_Slack = 2, "N_Slack=2");
      Check (T.N_Artificial = 0, "no artificials");
      Check (T.N = 4, "N=4");
      Check (T.Obj_Phase1 = 0, "no Phase-I");
      Check (Approx (T.T (0, 1), -3.0), "reduced −c1");
      Check (Approx (T.T (0, 2), -2.0), "reduced −c2");
      Check (Approx (T.T (1, 0), 4.0), "RHS1");
      Check (Approx (T.T (2, 0), 6.0), "RHS2");
      Check (not Is_Optimal_LP (T), "initial not optimal");
      Check (Select_Entering (T) = 1, "Bland enters col 1");
      Enter := Select_Entering (T);
      Leave := Select_Leaving (T, Enter);
      Check (Leave = 2, "min-ratio leave row 2");
      Pivot (T, Leave, Enter);
      Check (T.Basic (2) = 1, "basic2=x1");
      Check (Approx (T.T (2, 1), 1.0), "pivot=1");
      X := Extract_Primal (T, 2);
      Check (Approx (X (1), 3.0), "x1=3 after pivot");
      Check (Active_Obj_Row (T) = 0, "active obj row 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Weighted_Sum_Solve");
   ---------------------------------------------------------------------
   declare
      --  min (x, y) s.t. x+y ≥ 1 → −x−y ≤ −1; x≤2; y≤2
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-1.0, 2.0, 2.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      P0 : constant Front_Point :=
        Weighted_Sum_Solve (A, B, C1, C2, 0.0, Default_Cfg);
      P1 : constant Front_Point :=
        Weighted_Sum_Solve (A, B, C1, C2, 1.0, Default_Cfg);
      P5 : constant Front_Point :=
        Weighted_Sum_Solve (A, B, C1, C2, 0.5, Default_Cfg);
   begin
      Check (P0.Valid, "λ=0 Valid");
      Check (Approx (P0.Y.Y2, 0.0, 1.0E-5)
             or else Approx (P0.Y.Y1 + P0.Y.Y2, 1.0, 1.0E-4),
             "λ=0 favors f2");
      Check (Approx (P0.Y.Y2, 0.0, 1.0E-4), "λ=0 → min y → y=0,x=1");
      Check (Approx (P0.Y.Y1, 1.0, 1.0E-4), "λ=0 → x=1");

      Check (P1.Valid, "λ=1 Valid");
      Check (Approx (P1.Y.Y1, 0.0, 1.0E-4), "λ=1 → min x → x=0");
      Check (Approx (P1.Y.Y2, 1.0, 1.0E-4), "λ=1 → y=1");

      Check (P5.Valid, "λ=0.5 Valid");
      Check (Approx (P5.Y.Y1 + P5.Y.Y2, 1.0, 1.0E-4),
             "λ=0.5 on front x+y=1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Demo triangle front (two extremes)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-1.0, 2.0, 2.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Default_Cfg);
   begin
      Check (R.Success, "triangle Success");
      Check (R.Stat = Optimal, "triangle Optimal");
      Check (R.N_Points >= 2, "triangle ≥2 points");
      Check (Has_Outcome (R, 0.0, 1.0), "has (0,1)");
      Check (Has_Outcome (R, 1.0, 0.0), "has (1,0)");
      Check (R.N_LP_Solves > 0, "triangle LP solves >0");
      --  All points on front should satisfy y1+y2 ≈ 1 and be nondominated.
      declare
         Ok : Boolean := True;
      begin
         for I in 1 .. R.N_Points loop
            if R.Points (I).Y.Y1 + R.Points (I).Y.Y2 < 1.0 - 1.0E-4 then
               Ok := False;
            end if;
            if R.Points (I).Y.Y1 < -1.0E-6
              or else R.Points (I).Y.Y2 < -1.0E-6
            then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "triangle points feasible outcomes");
      end;
      --  Sorted by Y1.
      Check (R.Points (1).Y.Y1 <= R.Points (R.N_Points).Y.Y1 + 1.0E-9,
             "sorted Y1 nondecreasing ends");
   end;

   ---------------------------------------------------------------------
   Section ("7. Box tradeoff front");
   ---------------------------------------------------------------------
   declare
      --  min (x+2y, 2x+y) s.t. x+y≤3, x≤2, y≤2, x,y≥0
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [3.0, 2.0, 2.0];
      C1 : constant Vector (1 .. 2) := [1.0, 2.0];
      C2 : constant Vector (1 .. 2) := [2.0, 1.0];
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Default_Cfg);
      --  Individual min f1: prefer small x+2y → (0,0) y=(0,0)
      --  Actually (0,0) is feasible! Both objectives 0. Single point.
   begin
      Check (R.Success, "box Success");
      Check (R.N_Points >= 1, "box ≥1 point");
      Check (Has_Outcome (R, 0.0, 0.0), "utopia (0,0) feasible");
      Check (R.N_Points = 1, "only utopia nondominated extreme");
   end;

   ---------------------------------------------------------------------
   Section ("8. Conflicting box (no zero utopia)");
   ---------------------------------------------------------------------
   declare
      --  min (x, y) s.t. x+y ≥ 2, x≤3, y≤3  → extremes (0,2),(2,0)
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-2.0, 3.0, 3.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Sparse_Cfg);
   begin
      Check (R.Success, "conflict Success");
      Check (Has_Outcome (R, 0.0, 2.0), "has (0,2)");
      Check (Has_Outcome (R, 2.0, 0.0), "has (2,0)");
      Check (R.N_Points >= 2, "conflict ≥2");
      --  No interior dominated point should remain after filter.
      declare
         Ok : Boolean := True;
      begin
         for I in 1 .. R.N_Points loop
            for J in 1 .. R.N_Points loop
               if I /= J
                 and then Is_Dominated
                   (R.Points (I).Y, R.Points (J).Y, 1.0E-8)
               then
                  Ok := False;
               end if;
            end loop;
         end loop;
         Check (Ok, "no dominated survivors");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Three-variable bi-objective");
   ---------------------------------------------------------------------
   declare
      --  min (x+y+z, 3x+y+2z) s.t. x+y+z ≥ 1, x,y,z ≤ 2
      A : constant Matrix (1 .. 4, 1 .. 3) :=
        [[-1.0, -1.0, -1.0],
         [1.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 1.0]];
      B : constant Vector (1 .. 4) := [-1.0, 2.0, 2.0, 2.0];
      C1 : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
      C2 : constant Vector (1 .. 3) := [3.0, 1.0, 2.0];
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Default_Cfg);
   begin
      Check (R.Success, "3var Success");
      Check (R.N_Points >= 1, "3var ≥1");
      --  Min f1 with x+y+z=1: f1=1 always on that face.
      Check (Has_Outcome (R, 1.0, 1.0)
             or else Has_Outcome (R, 1.0, 2.0)
             or else Has_Outcome (R, 1.0, 3.0),
             "f1-min face represented");
      declare
         Ok : Boolean := True;
      begin
         for I in 1 .. R.N_Points loop
            if R.Points (I).Y.Y1 < 1.0 - 1.0E-4 then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "3var Y1≥1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Infeasible MOLP");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [-1.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      C2 : constant Vector (1 .. 1) := [2.0];
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Sparse_Cfg);
   begin
      Check (not R.Success, "infeas MOLP not Success");
      Check (R.Stat = Infeasible or else R.Stat = Empty_Front,
             "infeas Stat");
      Check (R.N_Points = 0, "infeas zero points");
   end;

   ---------------------------------------------------------------------
   Section ("11. Single-objective-like (aligned costs)");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [1.0, 0.0]];
      B : constant Vector (1 .. 2) := [4.0, 3.0];
      C1 : constant Vector (1 .. 2) := [1.0, 1.0];
      C2 : constant Vector (1 .. 2) := [2.0, 2.0];  -- parallel
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Sparse_Cfg);
   begin
      Check (R.Success, "aligned Success");
      Check (R.N_Points >= 1, "aligned ≥1");
      Check (Has_Outcome (R, 0.0, 0.0), "aligned utopia at 0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Preimages match objectives");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-1.0, 2.0, 2.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      R : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Sparse_Cfg);
      Ok : Boolean := True;
      Y  : Outcome;
   begin
      for I in 1 .. R.N_Points loop
         Y := Eval_Objectives
           (C1, C2,
            R.Points (I).X (1 .. Natural (R.Points (I).N_Vars)));
         if not Outcome_Near (Y, R.Points (I).Y, 1.0E-5) then
            Ok := False;
         end if;
         if R.Points (I).N_Vars /= 2 then
            Ok := False;
         end if;
         if not R.Points (I).Valid then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "preimages reproduce outcomes");
      Check (R.N_Points >= 2, "preimage demo ≥2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Config / caps smoke");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [1.0];
      C1 : constant Vector (1 .. 1) := [1.0];
      C2 : constant Vector (1 .. 1) := [1.0];
      Cfg : constant Config :=
        (Max_Pivots => 50, Max_Dichotomy => 2, Weight_Grid => 2,
         Tol => 1.0E-8);
      R : constant Result := Solve_Biobjective (A, B, C1, C2, Cfg);
   begin
      Check (R.Success, "tiny cfg Success");
      Check (Has_Outcome (R, 0.0, 0.0), "tiny → (0,0)");
      Check (Cfg.Weight_Grid = 2, "cfg Weight_Grid");
      Check (Cfg.Max_Dichotomy = 2, "cfg Max_Dichotomy");
      Check (R.N_Points >= 1, "tiny ≥1 point");
      Check (R.N_LP_Solves >= 1, "tiny LP solves");
      Check (R.Points (1).Valid, "tiny point Valid");
      Check (R.Points (1).N_Vars = 1, "tiny N_Vars=1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Dominance edge cases batch");
   ---------------------------------------------------------------------
   declare
      O1 : constant Outcome := (1.0, 1.0);
      O2 : constant Outcome := (1.0, 0.5);
      O3 : constant Outcome := (0.5, 1.0);
      O4 : constant Outcome := (0.5, 0.5);
      O5 : constant Outcome := (1.0 + 1.0E-12, 1.0);
   begin
      Check (Is_Dominated (O1, O2), "O2 dom O1");
      Check (Is_Dominated (O1, O3), "O3 dom O1");
      Check (Is_Dominated (O1, O4), "O4 dom O1");
      Check (not Is_Dominated (O4, O1), "O1 not dom O4");
      Check (not Is_Dominated (O2, O3), "incomparable O2/O3");
      Check (not Is_Dominated (O3, O2), "incomparable O3/O2");
      Check (Is_Weakly_Dominated (O1, O5, 1.0E-9), "weak near");
      Check (Outcome_Near (O1, O5, 1.0E-9), "Outcome_Near tol");
      Check (not Is_Dominated (O2, O2), "self");
      Check (Is_Weakly_Dominated (O2, O2), "self weak");
   end;

   ---------------------------------------------------------------------
   Section ("15. More LP smoke (unbounded / phase I)");
   ---------------------------------------------------------------------
   declare
      --  max x s.t. -x ≤ -1  → x ≥ 1, no upper bound → unbounded
      A : constant Matrix (1 .. 1, 1 .. 1) := [[-1.0]];
      B : constant Vector (1 .. 1) := [-1.0];
      C : constant Vector (1 .. 1) := [1.0];
      R : constant LP_Result := Maximize_LP (A, B, C, Default_Cfg);
   begin
      Check (R.Stat = Unbounded or else R.Success = False,
             "unbounded detected");
      Check (not R.Success, "unbounded not Success");
   end;

   declare
      --  max -x s.t. x ≤ 5 → opt at x=0, z=0
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [5.0];
      C : constant Vector (1 .. 1) := [-1.0];
      R : constant LP_Result := Maximize_LP (A, B, C, Default_Cfg);
   begin
      Check (R.Success, "max -x Success");
      Check (Approx (R.Objective, 0.0), "max -x z=0");
      Check (Approx (R.X (1), 0.0), "max -x x=0");
   end;

   ---------------------------------------------------------------------
   Section ("16. Grid vs sparse consistency");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-1.5, 4.0, 4.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      R1 : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Default_Cfg);
      R2 : constant Result :=
        Solve_Biobjective (A, B, C1, C2, Sparse_Cfg);
   begin
      Check (R1.Success and then R2.Success, "both grids Success");
      Check (Has_Outcome (R1, 0.0, 1.5), "dense (0,1.5)");
      Check (Has_Outcome (R1, 1.5, 0.0), "dense (1.5,0)");
      Check (Has_Outcome (R2, 0.0, 1.5), "sparse (0,1.5)");
      Check (Has_Outcome (R2, 1.5, 0.0), "sparse (1.5,0)");
   end;

   ---------------------------------------------------------------------
   Section ("17. Weighted sum λ sweep batch");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[-1.0, -1.0],
         [1.0, 0.0],
         [0.0, 1.0]];
      B : constant Vector (1 .. 3) := [-1.0, 2.0, 2.0];
      C1 : constant Vector (1 .. 2) := [1.0, 0.0];
      C2 : constant Vector (1 .. 2) := [0.0, 1.0];
      P : Front_Point;
      Ok_All : Boolean := True;
   begin
      for K in 0 .. 10 loop
         P := Weighted_Sum_Solve
           (A, B, C1, C2, Real (K) / 10.0, Default_Cfg);
         if not P.Valid then
            Ok_All := False;
         elsif abs (P.Y.Y1 + P.Y.Y2 - 1.0) > 1.0E-3 then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "λ sweep all on x+y=1");
      P := Weighted_Sum_Solve (A, B, C1, C2, 0.25, Default_Cfg);
      Check (P.Valid, "λ=0.25 Valid");
      Check (Approx (P.Y.Y1 + P.Y.Y2, 1.0, 1.0E-4), "λ=0.25 sum");
      P := Weighted_Sum_Solve (A, B, C1, C2, 0.75, Default_Cfg);
      Check (P.Valid, "λ=0.75 Valid");
      Check (Approx (P.Y.Y1 + P.Y.Y2, 1.0, 1.0E-4), "λ=0.75 sum");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count /= 0 then
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   else
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   end if;
end Tests;
