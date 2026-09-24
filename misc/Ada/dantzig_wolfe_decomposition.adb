--  Dantzig_Wolfe_Decomposition body — master + block pricing + Bland simplex.

pragma Ada_2022;

package body Dantzig_Wolfe_Decomposition
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Near / Vec_Near
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

   -------------------------------------------------------------------------
   -- Proposal / column helpers
   -------------------------------------------------------------------------

   function Proposals_Equal
     (A, B : Proposal_X; N : Block_Var_Count; Tol : Real := Epsilon_Tol)
      return Boolean
   is
   begin
      for J in 1 .. N loop
         if abs (A (J) - B (J)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Proposals_Equal;

   function Column_Exists
     (Pool     : Column_Pool;
      N_Cols   : Column_Count;
      Block_Id : Block_Index;
      X        : Proposal_X;
      N_Vars   : Block_Var_Count;
      Tol      : Real := Epsilon_Tol) return Boolean
   is
   begin
      for J in 1 .. N_Cols loop
         if Pool (J).Valid
           and then Pool (J).Block_Id = Block_Id
           and then Proposals_Equal (Pool (J).X, X, N_Vars, Tol)
         then
            return True;
         end if;
      end loop;
      return False;
   end Column_Exists;

   procedure Clear_Pool
     (Pool : in out Column_Pool; N_Cols : out Column_Count)
   is
   begin
      for J in Column_Index loop
         Pool (J).Valid := False;
         Pool (J).Cost := 0.0;
         Pool (J).X := [others => 0.0];
         Pool (J).Coup := [others => 0.0];
         Pool (J).Block_Id := 1;
      end loop;
      N_Cols := 0;
   end Clear_Pool;

   function Proposal_Cost
     (Blk : Block_Data; X : Proposal_X) return Real
   is
      S : Real := 0.0;
   begin
      for J in 1 .. Blk.N_Vars loop
         S := S + Blk.Cost (J) * X (J);
      end loop;
      return S;
   end Proposal_Cost;

   function Proposal_Coupling
     (Blk : Block_Data; X : Proposal_X; N_Coup : Coupling_Count)
      return Coupling_RHS_Array
   is
      Coup : Coupling_RHS_Array := [others => 0.0];
   begin
      for R in 1 .. N_Coup loop
         for J in 1 .. Blk.N_Vars loop
            Coup (R) := Coup (R) + Blk.A_Coup (R, J) * X (J);
         end loop;
      end loop;
      return Coup;
   end Proposal_Coupling;

   function Make_Column
     (Prob     : Problem;
      Block_Id : Block_Index;
      X        : Proposal_X) return Column
   is
      Blk : Block_Data renames Prob.Blocks (Block_Id);
      Col : Column;
   begin
      Col.Block_Id := Block_Id;
      Col.X := X;
      Col.Cost := Proposal_Cost (Blk, X);
      Col.Coup := Proposal_Coupling (Blk, X, Prob.N_Coupling);
      Col.Valid := True;
      return Col;
   end Make_Column;

   procedure Add_Column
     (Pool : in out Column_Pool;
      N_Cols : in out Column_Count;
      Col  : Column)
   is
   begin
      N_Cols := N_Cols + 1;
      Pool (N_Cols) := Col;
      Pool (N_Cols).Valid := True;
   end Add_Column;

   function Reduced_Cost
     (Col      : Column;
      Pi       : Vector;
      Sigma    : Real;
      N_Coup   : Coupling_Count) return Real
   is
      Dot : Real := 0.0;
   begin
      for R in 1 .. N_Coup loop
         Dot := Dot + Pi (Pi'First + R - 1) * Col.Coup (R);
      end loop;
      return Col.Cost + Dot - Sigma;
   end Reduced_Cost;

   procedure Init_Zero_Columns
     (Prob   : Problem;
      Pool   : in out Column_Pool;
      N_Cols : out Column_Count)
   is
      X : Proposal_X;
   begin
      Clear_Pool (Pool, N_Cols);
      for K in 1 .. Prob.N_Blocks loop
         if Prob.Blocks (K).N_Vars = 0 then
            raise Invalid_Argument with "Init_Zero_Columns: empty block";
         end if;
         X := [others => 0.0];
         Add_Column (Pool, N_Cols, Make_Column (Prob, K, X));
      end loop;
   end Init_Zero_Columns;

   function Total_Vars (Prob : Problem) return Total_Var_Count is
      N : Natural := 0;
   begin
      for K in 1 .. Prob.N_Blocks loop
         N := N + Natural (Prob.Blocks (K).N_Vars);
      end loop;
      if N > Max_Total_Vars then
         return Max_Total_Vars;
      end if;
      return Total_Var_Count (N);
   end Total_Vars;

   function Reconstruct_X
     (Prob   : Problem;
      Pool   : Column_Pool;
      N_Cols : Column_Count;
      Lambda : Vector) return Vector
   is
      X : Vector (1 .. Max_Total_Vars) := [others => 0.0];
      Offset : Natural := 0;
      Nv : Block_Var_Count;
      Lam : Real;
   begin
      for K in 1 .. Prob.N_Blocks loop
         Nv := Prob.Blocks (K).N_Vars;
         for J in 1 .. N_Cols loop
            if Pool (J).Valid and then Pool (J).Block_Id = K then
               Lam := Lambda (Lambda'First + J - 1);
               if abs (Lam) > Epsilon_Tol then
                  for V in 1 .. Nv loop
                     X (Offset + V) :=
                       X (Offset + V) + Lam * Pool (J).X (V);
                  end loop;
               end if;
            end if;
         end loop;
         Offset := Offset + Natural (Nv);
      end loop;
      return X;
   end Reconstruct_X;

   -------------------------------------------------------------------------
   -- Toy problem
   -------------------------------------------------------------------------

   function Toy_Optimum return Real is
   begin
      return -26.0;
   end Toy_Optimum;

   function Make_Toy_Problem return Problem is
      P : Problem;
   begin
      --  Block 1: x1,x2 with box  x1≤3, x2≤2
      --  Block 2: y1,y2 with box  y1≤2, y2≤3
      --  Coupling: x1+y1≤4, x2+y2≤3
      --  Costs: (−3,−4) and (−2,−5)
      P.N_Blocks := 2;
      P.N_Coupling := 2;
      P.Coupling_RHS := [1 => 4.0, 2 => 3.0, others => 0.0];

      P.Blocks (1).N_Vars := 2;
      P.Blocks (1).N_Cons := 2;
      P.Blocks (1).Cost := [1 => -3.0, 2 => -4.0];
      P.Blocks (1).B_Mat :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0],
         others => [others => 0.0]];
      P.Blocks (1).B_RHS := [1 => 3.0, 2 => 2.0, others => 0.0];
      P.Blocks (1).A_Coup :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0],
         others => [others => 0.0]];

      P.Blocks (2).N_Vars := 2;
      P.Blocks (2).N_Cons := 2;
      P.Blocks (2).Cost := [1 => -2.0, 2 => -5.0];
      P.Blocks (2).B_Mat :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0],
         others => [others => 0.0]];
      P.Blocks (2).B_RHS := [1 => 2.0, 2 => 3.0, others => 0.0];
      P.Blocks (2).A_Coup :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0],
         others => [others => 0.0]];

      return P;
   end Make_Toy_Problem;

   -------------------------------------------------------------------------
   -- Active objective row / entering / leaving / pivot
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
      if N_Decision = 0 then
         declare
            Empty : Vector (1 .. 0);
         begin
            return Empty;
         end;
      end if;
      return X (1 .. N_Decision);
   end Extract_Primal;

   -------------------------------------------------------------------------
   -- Build_Tableau  (max cᵀx s.t. Ax ≤ b, x ≥ 0)
   -------------------------------------------------------------------------

   function Build_Tableau
     (A : Matrix; B, C : Vector) return Tableau
   is
      M_Cons : constant Constraint_Count := A'Length (1);
      N_Dec  : constant Var_Count := A'Length (2);
      Tab    : Tableau;
      Art_Count : Var_Count := 0;
      Row_Sign  : array (1 .. Max_Constraints) of Real := [others => 1.0];
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
      Cfg : Config := (others => <>)) return Master_Result
   is
      R            : Master_Result;
      Phase_Stat   : Status;
      Budget       : Natural := Cfg.Max_Pivots;
      Pivots_Start : constant Natural := Budget;
      Phase1_Obj   : Real;
   begin
      if Tab.M = 0 or else Tab.N = 0 then
         raise Invalid_Argument with "Solve_Tableau: empty tableau";
      end if;

      R.N_Columns := Column_Count (Tab.N_Decision);

      if Tab.N_Artificial > 0 and then Tab.Obj_Phase1 > 0 then
         Phase_Stat := Run_Phase (Tab, Cfg, Budget);
         R.N_Pivots := Pivots_Start - Budget;

         if Phase_Stat = Unbounded or else Phase_Stat = Iteration_Limit
           or else Phase_Stat = Infeasible or else Phase_Stat = Column_Limit
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
                  if J <= Max_Columns then
                     R.Lambda (J) := X_Dec (J);
                  end if;
               end loop;
            end;
            R.Success := True;
         when Unbounded =>
            R.Stat := Unbounded;
            R.Objective := Tab.T (0, 0);
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

   -------------------------------------------------------------------------
   -- Price_Block
   -------------------------------------------------------------------------

   function Price_Block
     (Prob     : Problem;
      Block_Id : Block_Index;
      Pi       : Vector;
      Sigma    : Real;
      Cfg      : Config := (others => <>)) return Pricing_Result
   is
      Blk : Block_Data renames Prob.Blocks (Block_Id);
      Nv  : constant Block_Var_Count := Blk.N_Vars;
      Nc  : constant Block_Cons_Count := Blk.N_Cons;
      R   : Pricing_Result;
      --  Pricing obj coeffs: reduced = c_j − Σ_r π_r A_{r j}
      Red : Block_Cost_Array := [others => 0.0];
      Dot : Real;
   begin
      R.Block_Id := Block_Id;

      if Nv = 0 or else Nc = 0 then
         R.Feasible := False;
         return R;
      end if;

      for J in 1 .. Nv loop
         Dot := 0.0;
         for Rr in 1 .. Prob.N_Coupling loop
            Dot := Dot
              + Pi (Pi'First + Rr - 1) * Blk.A_Coup (Rr, J);
         end loop;
         Red (J) := Blk.Cost (J) + Dot;
      end loop;

      --  min Redᵀx s.t. Bx≤b, x≥0  ≡  max (−Red)ᵀx s.t. Bx≤b
      declare
         A : Matrix
           (1 .. Constraint_Index (Nc), 1 .. Var_Index (Nv));
         B : Vector (1 .. Positive (Nc));
         C : Vector (1 .. Positive (Nv));
         Tab : Tableau;
         MR  : Master_Result;
      begin
         for I in 1 .. Nc loop
            B (I) := Blk.B_RHS (I);
            for J in 1 .. Nv loop
               A (Constraint_Index (I), Var_Index (J)) :=
                 Blk.B_Mat (I, J);
            end loop;
         end loop;
         for J in 1 .. Nv loop
            C (J) := -Red (J);
         end loop;

         Tab := Build_Tableau (A, B, C);
         MR := Solve_Tableau (Tab, Cfg);

         if not MR.Success then
            R.Feasible := False;
            return R;
         end if;

         R.X := [others => 0.0];
         for J in 1 .. Nv loop
            R.X (J) := MR.Lambda (J);
         end loop;

         --  MR.Objective is max (−Red)ᵀx = − min Redᵀx
         R.Value := -MR.Objective;
         R.Reduced_Cost := R.Value - Sigma;
         R.Feasible := True;
         R.Improving := R.Reduced_Cost < -Cfg.Tol;
         return R;
      end;
   end Price_Block;

   -------------------------------------------------------------------------
   -- Solve_Master
   -------------------------------------------------------------------------

   function Solve_Master
     (Prob   : Problem;
      Pool   : Column_Pool;
      N_Cols : Column_Count;
      Cfg    : Config := (others => <>)) return Master_Result
   is
      --  Rows: N_Coup coupling (≤) + K convexity-upper (≤1)
      --        + K convexity-lower (≥1 encoded as −sum ≤ −1).
      Nb : constant Block_Count := Prob.N_Blocks;
      Nc : constant Coupling_Count := Prob.N_Coupling;
      M_Rows : constant Natural :=
        Natural (Nc) + 2 * Natural (Nb);
      A : Matrix
        (1 .. Constraint_Index (M_Rows), 1 .. Var_Index (N_Cols));
      B : Vector (1 .. Positive (M_Rows));
      C : Vector (1 .. Positive (N_Cols));
      Tab : Tableau;
      R   : Master_Result;
      Row : Natural;
      Slack_Col : Natural;
      Dual_Raw  : Real;
      Pi_U, Pi_L : Real;
   begin
      if N_Cols = 0 or else Nb = 0 then
         raise Invalid_Argument with "Solve_Master: empty";
      end if;

      for I in 1 .. M_Rows loop
         for J in 1 .. Natural (N_Cols) loop
            A (Constraint_Index (I), Var_Index (J)) := 0.0;
         end loop;
         B (I) := 0.0;
      end loop;

      for J in 1 .. N_Cols loop
         if not Pool (J).Valid then
            raise Invalid_Argument with "Solve_Master: invalid column";
         end if;
         --  Maximize −cost ⇔ minimize cost
         C (J) := -Pool (J).Cost;
         for R_Coup in 1 .. Nc loop
            A (Constraint_Index (Natural (R_Coup)), Var_Index (J)) :=
              Pool (J).Coup (R_Coup);
         end loop;
         --  Convexity upper: sum_{j in block k} λ_j ≤ 1
         Row := Natural (Nc) + Natural (Pool (J).Block_Id);
         A (Constraint_Index (Row), Var_Index (J)) := 1.0;
         --  Convexity lower: −sum λ_j ≤ −1
         Row := Natural (Nc) + Natural (Nb) + Natural (Pool (J).Block_Id);
         A (Constraint_Index (Row), Var_Index (J)) := -1.0;
      end loop;

      for R_Coup in 1 .. Nc loop
         B (Natural (R_Coup)) := Prob.Coupling_RHS (R_Coup);
      end loop;
      for K in 1 .. Nb loop
         B (Natural (Nc) + Natural (K)) := 1.0;
         B (Natural (Nc) + Natural (Nb) + Natural (K)) := -1.0;
      end loop;

      Tab := Build_Tableau (A, B, C);
      R := Solve_Tableau (Tab, Cfg);
      R.N_Blocks := Nb;
      R.N_Coupling := Nc;
      R.N_Columns := N_Cols;

      if not R.Success then
         return R;
      end if;

      --  Max objective is −min_cost; recover true minimum.
      R.Objective := -R.Objective;

      --  Duals of coupling ≤ rows: π = T(0, slack) for max tableau
      --  (equals min-problem dual for Ax≤a; see package notes).
      for R_Coup in 1 .. Nc loop
         Slack_Col := Natural (Tab.N_Decision) + Natural (R_Coup);
         if Slack_Col <= Natural (Tab.N) then
            Dual_Raw := Tab.T (0, Slack_Col);
            if Dual_Raw < 0.0 then
               Dual_Raw := 0.0;
            end if;
            R.Coupling_Dual (R_Coup) := Dual_Raw;
         else
            R.Coupling_Dual (R_Coup) := 0.0;
         end if;
      end loop;

      --  Convexity dual σ_k = π_lower − π_upper for equality sum λ = 1.
      --  Lower row (≥1) was sign-flipped; its slack dual matches sibling
      --  ≥-row extraction. Upper row is ordinary ≤.
      for K in 1 .. Nb loop
         Slack_Col :=
           Natural (Tab.N_Decision) + Natural (Nc) + Natural (K);
         if Slack_Col <= Natural (Tab.N) then
            Pi_U := Tab.T (0, Slack_Col);
         else
            Pi_U := 0.0;
         end if;
         if Pi_U < 0.0 then
            Pi_U := 0.0;
         end if;

         Slack_Col :=
           Natural (Tab.N_Decision) + Natural (Nc) + Natural (Nb)
           + Natural (K);
         if Slack_Col <= Natural (Tab.N) then
            Pi_L := Tab.T (0, Slack_Col);
         else
            Pi_L := 0.0;
         end if;
         if Pi_L < 0.0 then
            Pi_L := 0.0;
         end if;

         R.Convexity_Dual (K) := Pi_L - Pi_U;
      end loop;

      return R;
   end Solve_Master;

   -------------------------------------------------------------------------
   -- Solve (full Dantzig–Wolfe)
   -------------------------------------------------------------------------

   function Solve
     (Prob : Problem;
      Cfg  : Config := (others => <>)) return Result
   is
      Pool : Column_Pool;
      N_Cols : Column_Count;
      R : Result;
      MR : Master_Result;
      Price : Pricing_Result;
      Cap_Cols : Column_Count;
      Pi : Vector (1 .. Max_Coupling_Rows) := [others => 0.0];
      Added : Boolean;
      Col : Column;
      Any_Improve : Boolean;
   begin
      if Prob.N_Blocks = 0 then
         raise Invalid_Argument with "Solve: no blocks";
      end if;
      for K in 1 .. Prob.N_Blocks loop
         if Prob.Blocks (K).N_Vars = 0 or else Prob.Blocks (K).N_Cons = 0
         then
            raise Invalid_Argument with "Solve: empty block data";
         end if;
      end loop;

      if Cfg.Max_Columns > Max_Columns then
         Cap_Cols := Max_Columns;
      else
         Cap_Cols := Column_Count (Cfg.Max_Columns);
      end if;

      Init_Zero_Columns (Prob, Pool, N_Cols);

      R.N_Blocks := Prob.N_Blocks;
      R.N_Coupling := Prob.N_Coupling;
      R.N_Total_Vars := Total_Vars (Prob);
      R.Pool := Pool;
      R.N_Columns := N_Cols;

      for Iter in 1 .. Cfg.Max_Iters loop
         R.N_Iters := Iter;
         MR := Solve_Master (Prob, Pool, N_Cols, Cfg);
         R.N_Pivots := R.N_Pivots + MR.N_Pivots;

         if not MR.Success then
            R.Stat := MR.Stat;
            R.Objective := MR.Objective;
            R.Success := False;
            R.N_Columns := N_Cols;
            R.Pool := Pool;
            return R;
         end if;

         R.Objective := MR.Objective;
         R.Lambda := MR.Lambda;
         R.Coupling_Dual := MR.Coupling_Dual;
         R.Convexity_Dual := MR.Convexity_Dual;
         R.N_Columns := N_Cols;
         R.Pool := Pool;

         for Rr in 1 .. Prob.N_Coupling loop
            Pi (Rr) := MR.Coupling_Dual (Rr);
         end loop;

         Any_Improve := False;
         Added := False;

         for K in 1 .. Prob.N_Blocks loop
            if Prob.N_Coupling = 0 then
               declare
                  Empty_Pi : Vector (1 .. 0);
               begin
                  Price := Price_Block
                    (Prob, K, Empty_Pi, MR.Convexity_Dual (K), Cfg);
               end;
            else
               Price := Price_Block
                 (Prob, K,
                  Pi (1 .. Positive (Prob.N_Coupling)),
                  MR.Convexity_Dual (K),
                  Cfg);
            end if;

            if Price.Feasible and then Price.Improving then
               Any_Improve := True;
               if not Column_Exists
                 (Pool, N_Cols, K, Price.X,
                  Prob.Blocks (K).N_Vars, Cfg.Tol)
               then
                  if N_Cols >= Cap_Cols then
                     R.Stat := Column_Limit;
                     R.Success := False;
                     R.X := Reconstruct_X
                       (Prob, Pool, N_Cols, MR.Lambda);
                     return R;
                  end if;
                  Col := Make_Column (Prob, K, Price.X);
                  Add_Column (Pool, N_Cols, Col);
                  Added := True;
               end if;
            end if;
         end loop;

         if not Any_Improve or else not Added then
            R.Stat := Optimal;
            R.Success := True;
            R.N_Columns := N_Cols;
            R.Pool := Pool;
            R.X := Reconstruct_X (Prob, Pool, N_Cols, MR.Lambda);
            return R;
         end if;

         R.Pool := Pool;
         R.N_Columns := N_Cols;
      end loop;

      R.Stat := Iteration_Limit;
      R.Success := False;
      R.N_Columns := N_Cols;
      R.Pool := Pool;
      R.X := Reconstruct_X (Prob, Pool, N_Cols, R.Lambda);
      return R;
   end Solve;

end Dantzig_Wolfe_Decomposition;
