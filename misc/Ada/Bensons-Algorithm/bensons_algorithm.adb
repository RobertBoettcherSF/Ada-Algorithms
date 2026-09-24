--  Bensons_Algorithm body — bi-objective dichotomic / Benson-style front
--  recovery; embedded Bland two-phase tableau (sibling ideas, no with).

pragma Ada_2022;

package body Bensons_Algorithm
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Near / Vec_Near / Outcome helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for K in 0 .. A'Length - 1 loop
         if abs (A (A'First + K) - B (B'First + K)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Outcome_Near
     (A, B : Outcome; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return Near (A.Y1, B.Y1, Tol) and then Near (A.Y2, B.Y2, Tol);
   end Outcome_Near;

   function Is_Dominated
     (Cand, Other : Outcome; Tol : Real := Epsilon_Tol) return Boolean
   is
      Le1 : constant Boolean := Other.Y1 <= Cand.Y1 + Tol;
      Le2 : constant Boolean := Other.Y2 <= Cand.Y2 + Tol;
      St1 : constant Boolean := Other.Y1 < Cand.Y1 - Tol;
      St2 : constant Boolean := Other.Y2 < Cand.Y2 - Tol;
   begin
      return Le1 and then Le2 and then (St1 or else St2);
   end Is_Dominated;

   function Is_Weakly_Dominated
     (Cand, Other : Outcome; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return Other.Y1 <= Cand.Y1 + Tol
        and then Other.Y2 <= Cand.Y2 + Tol;
   end Is_Weakly_Dominated;

   function Eval_Objectives
     (C1, C2 : Vector; X : Vector) return Outcome
   is
      Y : Outcome := (0.0, 0.0);
   begin
      for K in 0 .. C1'Length - 1 loop
         Y.Y1 := Y.Y1 + C1 (C1'First + K) * X (X'First + K);
         Y.Y2 := Y.Y2 + C2 (C2'First + K) * X (X'First + K);
      end loop;
      return Y;
   end Eval_Objectives;

   -------------------------------------------------------------------------
   -- Active objective / entering / leaving / optimal
   -------------------------------------------------------------------------

   function Active_Obj_Row (Tab : Tableau) return Natural is
   begin
      if Tab.Obj_Phase1 > 0 then
         return Tab.Obj_Phase1;
      end if;
      return 0;
   end Active_Obj_Row;

   function Select_Entering
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
   is
      R : constant Natural := Active_Obj_Row (Tab);
   begin
      for J in 1 .. Tab.N loop
         if Tab.T (R, J) < -Tol then
            return J;
         end if;
      end loop;
      return 0;
   end Select_Entering;

   function Is_Optimal_LP
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return Select_Entering (Tab, Tol) = 0;
   end Is_Optimal_LP;

   function Select_Leaving
     (Tab       : Tableau;
      Enter_Col : Positive;
      Tol       : Real := Epsilon_Tol) return Natural
   is
      Best_Ratio : Real := Real'Last;
      Best_Row   : Natural := 0;
      Best_Basic : Natural := Natural'Last;
      Ratio      : Real;
      Aij        : Real;
   begin
      for I in 1 .. Tab.M loop
         Aij := Tab.T (I, Enter_Col);
         if Aij > Tol then
            Ratio := Tab.T (I, 0) / Aij;
            if Ratio + Tol < Best_Ratio then
               Best_Ratio := Ratio;
               Best_Row   := I;
               Best_Basic := Tab.Basic (I);
            elsif abs (Ratio - Best_Ratio) <= Tol
              and then Tab.Basic (I) < Best_Basic
            then
               Best_Row   := I;
               Best_Basic := Tab.Basic (I);
            end if;
         end if;
      end loop;
      return Best_Row;
   end Select_Leaving;

   -------------------------------------------------------------------------
   -- Pivot
   -------------------------------------------------------------------------

   procedure Pivot
     (Tab                  : in out Tableau;
      Leave_Row, Enter_Col : Positive)
   is
      Pivot_Val : constant Real := Tab.T (Leave_Row, Enter_Col);
      Factor    : Real;
      Last_Row  : Natural;
   begin
      if abs (Pivot_Val) < Real'Model_Small then
         raise Invalid_Argument with "Pivot: near-zero pivot element";
      end if;

      for J in 0 .. Tab.N loop
         Tab.T (Leave_Row, J) := Tab.T (Leave_Row, J) / Pivot_Val;
      end loop;

      Last_Row := Tab.M;
      if Tab.Obj_Phase1 > Last_Row then
         Last_Row := Tab.Obj_Phase1;
      end if;

      for I in 0 .. Last_Row loop
         if I /= Leave_Row then
            Factor := Tab.T (I, Enter_Col);
            if Factor /= 0.0 then
               for J in 0 .. Tab.N loop
                  Tab.T (I, J) :=
                    Tab.T (I, J) - Factor * Tab.T (Leave_Row, J);
               end loop;
            end if;
         end if;
      end loop;

      Tab.Basic (Leave_Row) := Enter_Col;
   end Pivot;

   -------------------------------------------------------------------------
   -- Extract_Primal
   -------------------------------------------------------------------------

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
   is
      X : Vector (1 .. Max_Vars) := [others => 0.0];
   begin
      for I in 1 .. Tab.M loop
         declare
            Bv : constant Natural := Tab.Basic (I);
         begin
            if Bv >= 1 and then Bv <= Natural (N_Decision) then
               X (Bv) := Tab.T (I, 0);
            end if;
         end;
      end loop;
      return X;
   end Extract_Primal;

   -------------------------------------------------------------------------
   -- Build_Tableau
   -------------------------------------------------------------------------

   function Build_Tableau
     (A : Matrix; B, C : Vector) return Tableau
   is
      M_Cons       : constant Constraint_Count := A'Length (1);
      N_Dec        : constant Var_Count := A'Length (2);
      Tab          : Tableau;
      Art_Count    : Var_Count := 0;
      Row_Sign     : array (1 .. Max_Constraints) of Real :=
        [others => 1.0];
      Art_Col_Base : Var_Count;
      Art_Used     : Var_Count;
      Slack_Col    : Var_Index;
      Art_Col      : Var_Index;
      Bi           : Real;
   begin
      if M_Cons = 0 or else N_Dec = 0 then
         raise Invalid_Argument with "Build_Tableau: empty problem";
      end if;
      if N_Dec + M_Cons > Max_Vars then
         raise Invalid_Argument with "Build_Tableau: too many columns";
      end if;

      for I in 1 .. M_Cons loop
         if B (B'First + I - 1) < 0.0 then
            Row_Sign (I) := -1.0;
            Art_Count := Art_Count + 1;
         end if;
      end loop;

      if N_Dec + M_Cons + Art_Count > Max_Vars then
         raise Invalid_Argument with "Build_Tableau: artificial overflow";
      end if;

      Tab.M            := M_Cons;
      Tab.N_Decision   := N_Dec;
      Tab.N_Slack      := M_Cons;
      Tab.N_Artificial := Art_Count;
      Tab.N            := N_Dec + M_Cons + Art_Count;
      Tab.Obj_Phase1   := 0;

      for I in 0 .. Max_Constraints loop
         for J in 0 .. Max_Vars loop
            Tab.T (I, J) := 0.0;
         end loop;
      end loop;
      for I in 1 .. Max_Constraints loop
         Tab.Basic (I) := 0;
      end loop;

      Tab.T (0, 0) := 0.0;
      for J in 1 .. N_Dec loop
         Tab.T (0, J) := -C (C'First + J - 1);
      end loop;

      Art_Col_Base := N_Dec + M_Cons;
      Art_Used := 0;

      for I in 1 .. M_Cons loop
         Bi := Row_Sign (I) * B (B'First + I - 1);
         Tab.T (I, 0) := Bi;
         for J in 1 .. N_Dec loop
            Tab.T (I, J) :=
              Row_Sign (I)
              * A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;

         Slack_Col := Var_Index (N_Dec + I);
         if Row_Sign (I) > 0.0 then
            Tab.T (I, Slack_Col) := 1.0;
            Tab.Basic (I) := Slack_Col;
         else
            Tab.T (I, Slack_Col) := -1.0;
            Art_Used := Art_Used + 1;
            Art_Col := Var_Index (Art_Col_Base + Art_Used);
            Tab.T (I, Art_Col) := 1.0;
            Tab.Basic (I) := Art_Col;
         end if;
      end loop;

      if Art_Count > 0 then
         Tab.Obj_Phase1 := Natural (M_Cons) + 1;
         if Tab.Obj_Phase1 > Max_Constraints then
            raise Invalid_Argument
              with "Build_Tableau: no room for Phase-I row";
         end if;
         for J in 0 .. Tab.N loop
            Tab.T (Tab.Obj_Phase1, J) := 0.0;
         end loop;
         for K in 1 .. Art_Count loop
            Art_Col := Var_Index (Art_Col_Base + K);
            Tab.T (Tab.Obj_Phase1, Art_Col) := -1.0;
         end loop;
         for I in 1 .. M_Cons loop
            if Tab.Basic (I) > Natural (N_Dec + M_Cons) then
               for J in 0 .. Tab.N loop
                  Tab.T (Tab.Obj_Phase1, J) :=
                    Tab.T (Tab.Obj_Phase1, J) + Tab.T (I, J);
               end loop;
            end if;
         end loop;
         for J in 0 .. Tab.N loop
            Tab.T (Tab.Obj_Phase1, J) := -Tab.T (Tab.Obj_Phase1, J);
         end loop;
      end if;

      return Tab;
   end Build_Tableau;

   -------------------------------------------------------------------------
   -- Drop artificials / Run_Phase / Solve_Tableau
   -------------------------------------------------------------------------

   procedure Drop_Artificials (Tab : in out Tableau) is
      First_Art : constant Var_Count := Tab.N_Decision + Tab.N_Slack + 1;
      New_N     : constant Var_Count := Tab.N_Decision + Tab.N_Slack;
      Enter     : Natural;
   begin
      if Tab.N_Artificial = 0 then
         Tab.Obj_Phase1 := 0;
         return;
      end if;

      for I in 1 .. Tab.M loop
         if Tab.Basic (I) >= Natural (First_Art) then
            Enter := 0;
            for J in 1 .. New_N loop
               if abs (Tab.T (I, J)) > Epsilon_Tol then
                  Enter := J;
                  exit;
               end if;
            end loop;
            if Enter > 0 then
               Pivot (Tab, I, Enter);
            end if;
         end if;
      end loop;

      Tab.N := New_N;
      Tab.N_Artificial := 0;
      if Tab.Obj_Phase1 > 0 then
         for J in 0 .. Max_Vars loop
            Tab.T (Tab.Obj_Phase1, J) := 0.0;
         end loop;
      end if;
      Tab.Obj_Phase1 := 0;
   end Drop_Artificials;

   function Run_Phase
     (Tab          : in out Tableau;
      Cfg          : Config;
      Pivot_Budget : in out Natural) return Status
   is
      Enter, Leave : Natural;
   begin
      loop
         Enter := Select_Entering (Tab, Cfg.Tol);
         if Enter = 0 then
            return Optimal;
         end if;
         Leave := Select_Leaving (Tab, Enter, Cfg.Tol);
         if Leave = 0 then
            return Unbounded;
         end if;
         if Pivot_Budget = 0 then
            return Iteration_Limit;
         end if;
         Pivot (Tab, Leave, Enter);
         Pivot_Budget := Pivot_Budget - 1;
      end loop;
   end Run_Phase;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := (others => <>)) return LP_Result
   is
      R            : LP_Result;
      Phase_Stat   : Status;
      Budget       : Natural := Cfg.Max_Pivots;
      Pivots_Start : constant Natural := Budget;
      Phase1_Obj   : Real;
   begin
      if Tab.M = 0 or else Tab.N = 0 then
         raise Invalid_Argument with "Solve_Tableau: empty tableau";
      end if;

      R.N_Vars := Tab.N_Decision;

      if Tab.N_Artificial > 0 and then Tab.Obj_Phase1 > 0 then
         Phase_Stat := Run_Phase (Tab, Cfg, Budget);
         R.N_Pivots := Pivots_Start - Budget;

         if Phase_Stat = Unbounded
           or else Phase_Stat = Iteration_Limit
           or else Phase_Stat = Infeasible
         then
            R.Stat := Infeasible;
            R.Success := False;
            return R;
         end if;

         Phase1_Obj := Tab.T (Tab.Obj_Phase1, 0);
         if Phase1_Obj < -Cfg.Tol then
            R.Stat := Infeasible;
            R.Objective := Phase1_Obj;
            R.Success := False;
            return R;
         end if;

         Drop_Artificials (Tab);
      end if;

      Phase_Stat := Run_Phase (Tab, Cfg, Budget);
      R.N_Pivots := Pivots_Start - Budget;

      case Phase_Stat is
         when Optimal =>
            R.Stat := Optimal;
            R.Objective := Tab.T (0, 0);
            declare
               X_Dec : constant Vector :=
                 Extract_Primal (Tab, Tab.N_Decision);
            begin
               for J in 1 .. Tab.N_Decision loop
                  R.X (J) := X_Dec (J);
               end loop;
            end;
            R.Success := True;
         when Unbounded =>
            R.Stat := Unbounded;
            R.Objective := Tab.T (0, 0);
            declare
               X_Dec : constant Vector :=
                 Extract_Primal (Tab, Tab.N_Decision);
            begin
               for J in 1 .. Tab.N_Decision loop
                  R.X (J) := X_Dec (J);
               end loop;
            end;
            R.Success := False;
         when Iteration_Limit =>
            R.Stat := Iteration_Limit;
            R.Success := False;
         when others =>
            R.Stat := Infeasible;
            R.Success := False;
      end case;

      return R;
   end Solve_Tableau;

   function Maximize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return LP_Result
   is
      Tab : Tableau := Build_Tableau (A, B, C);
   begin
      return Solve_Tableau (Tab, Cfg);
   end Maximize_LP;

   function Minimize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return LP_Result
   is
      Neg_C : Vector (C'Range);
      R     : LP_Result;
   begin
      for I in C'Range loop
         Neg_C (I) := -C (I);
      end loop;
      R := Maximize_LP (A, B, Neg_C, Cfg);
      if R.Success then
         R.Objective := -R.Objective;
      end if;
      return R;
   end Minimize_LP;

   -------------------------------------------------------------------------
   -- Weighted_Sum_Solve
   -------------------------------------------------------------------------

   function Weighted_Sum_Solve
     (A      : Matrix;
      B      : Vector;
      C1, C2 : Vector;
      Lambda : Real;
      Cfg    : Config := (others => <>)) return Front_Point
   is
      Comb  : Vector (C1'Range);
      R     : LP_Result;
      P     : Front_Point;
      N_Dec : constant Decision_Count := Decision_Count (C1'Length);
   begin
      for I in C1'Range loop
         Comb (I) := Lambda * C1 (I) + (1.0 - Lambda) * C2 (I);
      end loop;

      R := Minimize_LP (A, B, Comb, Cfg);
      if not R.Success then
         P.Valid := False;
         return P;
      end if;

      P.N_Vars := N_Dec;
      for J in 1 .. N_Dec loop
         P.X (J) := R.X (J);
      end loop;
      P.Y := Eval_Objectives (C1, C2, R.X (1 .. Natural (N_Dec)));
      P.Valid := True;
      return P;
   end Weighted_Sum_Solve;

   -------------------------------------------------------------------------
   -- Front bookkeeping
   -------------------------------------------------------------------------

   procedure Try_Insert
     (R   : in out Result;
      P   : Front_Point;
      Tol : Real)
   is
      Dup : Boolean;
   begin
      if not P.Valid or else R.N_Points = Max_Front then
         return;
      end if;

      Dup := False;
      for I in 1 .. R.N_Points loop
         if Outcome_Near (R.Points (I).Y, P.Y, Tol) then
            Dup := True;
            exit;
         end if;
      end loop;
      if Dup then
         return;
      end if;

      R.N_Points := R.N_Points + 1;
      R.Points (R.N_Points) := P;
   end Try_Insert;

   procedure Filter_Nondominated (R : in out Result; Tol : Real) is
      Keep : Front_Array (1 .. Max_Front);
      K    : Front_Count := 0;
      Dom  : Boolean;
   begin
      for I in 1 .. R.N_Points loop
         Dom := False;
         for J in 1 .. R.N_Points loop
            if I /= J
              and then Is_Dominated
                (R.Points (I).Y, R.Points (J).Y, Tol)
            then
               Dom := True;
               exit;
            end if;
         end loop;
         if not Dom then
            K := K + 1;
            Keep (K) := R.Points (I);
         end if;
      end loop;
      R.N_Points := K;
      for I in 1 .. Max_Front loop
         if I <= K then
            R.Points (I) := Keep (I);
         else
            R.Points (I).Valid := False;
         end if;
      end loop;
   end Filter_Nondominated;

   procedure Sort_Front (R : in out Result) is
      Tmp  : Front_Point;
      Done : Boolean;
   begin
      if R.N_Points <= 1 then
         return;
      end if;
      for Pass in 1 .. R.N_Points - 1 loop
         Done := True;
         for I in 1 .. R.N_Points - Pass loop
            if R.Points (I).Y.Y1 > R.Points (I + 1).Y.Y1 + Epsilon_Tol
              or else
                (abs (R.Points (I).Y.Y1 - R.Points (I + 1).Y.Y1)
                   <= Epsilon_Tol
                 and then R.Points (I).Y.Y2
                            > R.Points (I + 1).Y.Y2 + Epsilon_Tol)
            then
               Tmp := R.Points (I);
               R.Points (I) := R.Points (I + 1);
               R.Points (I + 1) := Tmp;
               Done := False;
            end if;
         end loop;
         exit when Done;
      end loop;
   end Sort_Front;

   -------------------------------------------------------------------------
   -- Solve_Biobjective (dichotomic + weight grid)
   -------------------------------------------------------------------------

   function Solve_Biobjective
     (A      : Matrix;
      B      : Vector;
      C1, C2 : Vector;
      Cfg    : Config := (others => <>)) return Result
   is
      R           : Result;
      LP_Count    : Natural := 0;
      Pivot_Count : Natural := 0;
      Tol         : constant Real := Cfg.Tol;
      Left, Right : Front_Point;
      Splits_Left : Natural := Cfg.Max_Dichotomy;
      Tiny        : constant Real := 1.0E-3;

      procedure Dichotomy (YA, YB : Outcome; Depth : Natural) is
         W1, W2                         : Real;
         Lam                            : Real;
         Comb                           : Vector (C1'Range);
         LP                             : LP_Result;
         P                              : Front_Point;
         N_Dec : constant Decision_Count := Decision_Count (C1'Length);
         Mid_Val_A, Mid_Val_B, Mid_Val_P : Real;
      begin
         if Depth = 0 or else Splits_Left = 0 then
            return;
         end if;
         if Outcome_Near (YA, YB, Tol) then
            return;
         end if;

         W1 := YB.Y2 - YA.Y2;
         W2 := YA.Y1 - YB.Y1;
         if W1 < 0.0 then
            W1 := -W1;
            W2 := -W2;
         end if;
         if W1 + W2 <= Tol then
            return;
         end if;
         Lam := W1 / (W1 + W2);
         if Lam < 0.0 then
            Lam := 0.0;
         elsif Lam > 1.0 then
            Lam := 1.0;
         end if;

         for I in C1'Range loop
            Comb (I) := Lam * C1 (I) + (1.0 - Lam) * C2 (I);
         end loop;

         LP := Minimize_LP (A, B, Comb, Cfg);
         LP_Count := LP_Count + 1;
         Pivot_Count := Pivot_Count + LP.N_Pivots;
         Splits_Left := Splits_Left - 1;

         if not LP.Success then
            return;
         end if;

         P.N_Vars := N_Dec;
         for J in 1 .. N_Dec loop
            P.X (J) := LP.X (J);
         end loop;
         P.Y := Eval_Objectives (C1, C2, LP.X (1 .. Natural (N_Dec)));
         P.Valid := True;

         if Outcome_Near (P.Y, YA, Tol)
           or else Outcome_Near (P.Y, YB, Tol)
         then
            return;
         end if;

         Mid_Val_A := Lam * YA.Y1 + (1.0 - Lam) * YA.Y2;
         Mid_Val_B := Lam * YB.Y1 + (1.0 - Lam) * YB.Y2;
         Mid_Val_P := Lam * P.Y.Y1 + (1.0 - Lam) * P.Y.Y2;
         if Mid_Val_P < Mid_Val_A - Tol
           and then Mid_Val_P < Mid_Val_B - Tol
         then
            Try_Insert (R, P, Tol);
            Dichotomy (YA, P.Y, Depth - 1);
            Dichotomy (P.Y, YB, Depth - 1);
         end if;
      end Dichotomy;

      procedure Collect_Weighted (Lam : Real) is
         P  : Front_Point;
         LP : LP_Result;
         Comb : Vector (C1'Range);
         N_Dec : constant Decision_Count := Decision_Count (C1'Length);
      begin
         for I in C1'Range loop
            Comb (I) := Lam * C1 (I) + (1.0 - Lam) * C2 (I);
         end loop;
         LP := Minimize_LP (A, B, Comb, Cfg);
         LP_Count := LP_Count + 1;
         Pivot_Count := Pivot_Count + LP.N_Pivots;
         if not LP.Success then
            return;
         end if;
         P.N_Vars := N_Dec;
         for J in 1 .. N_Dec loop
            P.X (J) := LP.X (J);
         end loop;
         P.Y := Eval_Objectives (C1, C2, LP.X (1 .. Natural (N_Dec)));
         P.Valid := True;
         Try_Insert (R, P, Tol);
      end Collect_Weighted;

   begin
      Left := Weighted_Sum_Solve (A, B, C1, C2, 1.0, Cfg);
      Collect_Weighted (1.0);
      Right := Weighted_Sum_Solve (A, B, C1, C2, 0.0, Cfg);
      Collect_Weighted (0.0);

      --  Left/Right used only to detect total infeasibility early.
      if not Left.Valid and then not Right.Valid then
         --  Collect_Weighted already attempted; if still empty → infeasible.
         if R.N_Points = 0 then
            R.Stat := Infeasible;
            R.Success := False;
            R.N_LP_Solves := LP_Count;
            R.N_Pivots := Pivot_Count;
            return R;
         end if;
      end if;

      Collect_Weighted (1.0 - Tiny);
      Collect_Weighted (Tiny);

      if Cfg.Weight_Grid >= 2 then
         declare
            G   : constant Positive := Cfg.Weight_Grid;
            Lam : Real;
         begin
            for K in 0 .. G - 1 loop
               Lam := Real (K) / Real (G - 1);
               Collect_Weighted (Lam);
            end loop;
         end;
      end if;

      Filter_Nondominated (R, Tol);
      Sort_Front (R);

      declare
         Snapshot_N : constant Front_Count := R.N_Points;
         I          : Front_Index;
      begin
         I := 1;
         while I < Snapshot_N loop
            Dichotomy
              (R.Points (I).Y, R.Points (I + 1).Y, Cfg.Max_Dichotomy);
            I := I + 1;
         end loop;
      end;

      Filter_Nondominated (R, Tol);
      Sort_Front (R);

      R.N_LP_Solves := LP_Count;
      R.N_Pivots := Pivot_Count;
      if R.N_Points = 0 then
         R.Stat := Empty_Front;
         R.Success := False;
      else
         R.Stat := Optimal;
         R.Success := True;
      end if;
      return R;
   end Solve_Biobjective;

end Bensons_Algorithm;
