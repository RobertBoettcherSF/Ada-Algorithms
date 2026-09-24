--  Cutting_Plane_Method body — Gomory ILP cuts + Kelley sketch;
--  embedded Bland two-phase tableau (sibling ideas, no with-clause).

pragma Ada_2022;


package body Cutting_Plane_Method
  with SPARK_Mode => Off
is


   -------------------------------------------------------------------------
   -- Near / Vec_Near / Frac / Is_Integer
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

   function Frac (X : Real) return Real is
      F : constant Real := Real'Floor (X);
   begin
      return X - F;
   end Frac;

   function Is_Integer_Val
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return abs (X - Real'Rounding (X)) <= Tol;
   end Is_Integer_Val;

   function Is_Integer_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in X'Range loop
         if not Is_Integer_Val (X (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Integer_Vector;

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
   -- Drop artificials / Run_Phase / Solve_Tableau / Maximize_LP
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

   --  Dual simplex: restore primal feasibility after a Gomory cut.
   function Dual_Restore
     (Tab          : in out Tableau;
      Cfg          : Config;
      Pivot_Budget : in out Natural) return Status
   is
      Leave, Enter : Natural;
      Best_Ratio   : Real;
      Ratio        : Real;
      Tol          : constant Real := Cfg.Tol;
      Obj_R        : constant Natural := 0;
   begin
      loop
         Leave := 0;
         for I in 1 .. Tab.M loop
            if Tab.T (I, 0) < -Tol then
               if Leave = 0 or else Tab.T (I, 0) < Tab.T (Leave, 0) then
                  Leave := I;
               end if;
            end if;
         end loop;
         if Leave = 0 then
            return Optimal;
         end if;

         --  Dual Bland: among cols with T(Leave,j) < −Tol, minimize
         --  |reduced_cost / a_lj| then smallest j.
         Enter := 0;
         Best_Ratio := Real'Last;
         for J in 1 .. Tab.N loop
            if Tab.T (Leave, J) < -Tol then
               Ratio := abs (Tab.T (Obj_R, J) / Tab.T (Leave, J));
               if Ratio + Tol < Best_Ratio then
                  Best_Ratio := Ratio;
                  Enter := J;
               elsif abs (Ratio - Best_Ratio) <= Tol
                 and then (Enter = 0 or else J < Enter)
               then
                  Enter := J;
               end if;
            end if;
         end loop;
         if Enter = 0 then
            return Infeasible;
         end if;
         if Pivot_Budget = 0 then
            return Iteration_Limit;
         end if;
         Pivot (Tab, Leave, Enter);
         Pivot_Budget := Pivot_Budget - 1;
      end loop;
   end Dual_Restore;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := (others => <>)) return Result
   is
      R            : Result;
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

         if Phase_Stat = Unbounded or else Phase_Stat = Iteration_Limit
           or else Phase_Stat = Infeasible
         then
            R.Stat := (if Phase_Stat = Iteration_Limit then Iteration_Limit
                       else Infeasible);
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
         when Infeasible | Iteration_Limit =>
            R.Stat := Phase_Stat;
            R.Success := False;
      end case;

      return R;
   end Solve_Tableau;

   function Maximize_LP
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return Result
   is
      Tab : Tableau := Build_Tableau (A, B, C);
   begin
      return Solve_Tableau (Tab, Cfg);
   end Maximize_LP;

   -------------------------------------------------------------------------
   -- Gomory cut generation / addition
   -------------------------------------------------------------------------

   function First_Fractional_Row
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
   is
   begin
      for I in 1 .. Tab.M loop
         if not Is_Integer_Val (Tab.T (I, 0), Tol) then
            return I;
         end if;
      end loop;
      return 0;
   end First_Fractional_Row;

   function Gomory_Cut_From_Row
     (Tab : Tableau;
      Row : Positive;
      Tol : Real := Epsilon_Tol) return Cut
   is
      C      : Cut;
      F0     : Real;
      Fj     : Real;
      Any_Fj : Boolean := False;
   begin
      C.Valid := False;
      C.N_Cols := Tab.N;
      if Row > Tab.M then
         return C;
      end if;
      F0 := Frac (Tab.T (Row, 0));
      if F0 <= Tol or else F0 >= 1.0 - Tol then
         return C;
      end if;
      C.RHS := F0;
      for J in 1 .. Tab.N loop
         Fj := Frac (Tab.T (Row, J));
         if Fj <= Tol or else Fj >= 1.0 - Tol then
            Fj := 0.0;
         else
            Any_Fj := True;
         end if;
         C.Coeff (J) := Fj;
      end loop;
      --  Need at least one fractional nonbasic coeff (integer A,b data).
      C.Valid := Any_Fj;
      return C;
   end Gomory_Cut_From_Row;

   procedure Add_Gomory_Cut
     (Tab : in out Tableau;
      C   : Cut)
   is
      New_Row : Constraint_Index;
      New_Col : Var_Index;
   begin
      if not C.Valid then
         raise Invalid_Argument with "Add_Gomory_Cut: invalid cut";
      end if;
      if Tab.M = Max_Constraints then
         raise Invalid_Argument with "Add_Gomory_Cut: row overflow";
      end if;
      if Tab.N = Max_Vars then
         raise Invalid_Argument with "Add_Gomory_Cut: column overflow";
      end if;

      --  Cut sum f_j x_j ≥ f0  →  −sum f_j x_j + s = −f0, s basic.
      New_Row := Constraint_Index (Tab.M + 1);
      New_Col := Var_Index (Tab.N + 1);

      for J in 0 .. Max_Vars loop
         Tab.T (New_Row, J) := 0.0;
      end loop;

      Tab.T (New_Row, 0) := -C.RHS;
      for J in 1 .. C.N_Cols loop
         if J <= Tab.N then
            Tab.T (New_Row, J) := -C.Coeff (J);
         end if;
      end loop;
      Tab.T (New_Row, New_Col) := 1.0;
      Tab.Basic (New_Row) := New_Col;

      --  Objective reduced cost for new slack is 0.
      Tab.T (0, New_Col) := 0.0;
      if Tab.Obj_Phase1 > 0 then
         Tab.T (Tab.Obj_Phase1, New_Col) := 0.0;
      end if;

      Tab.M := Tab.M + 1;
      Tab.N := Tab.N + 1;
      Tab.N_Slack := Tab.N_Slack + 1;
   end Add_Gomory_Cut;

   -------------------------------------------------------------------------
   -- Solve_ILP_Cutting_Planes
   -------------------------------------------------------------------------

   function Solve_ILP_Cutting_Planes
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := (others => <>)) return Result
   is
      Tab    : Tableau := Build_Tableau (A, B, C);
      R      : Result;
      Budget : Natural := Cfg.Max_Pivots;
      Used   : Natural;
      Row    : Natural;
      Gc     : Cut;
      Dual_S : Status;
      Dec    : Vector (1 .. Max_Vars);
   begin
      R := Solve_Tableau (Tab, Cfg);
      Used := R.N_Pivots;
      if Budget > Used then
         Budget := Budget - Used;
      else
         Budget := 0;
      end if;

      if not R.Success then
         return R;
      end if;

      for Cut_Iter in 1 .. Cfg.Max_Cuts loop
         Dec := Extract_Primal (Tab, Tab.N_Decision);
         if Is_Integer_Vector
              (Dec (1 .. Tab.N_Decision), Cfg.Integer_Tol)
         then
            R.Stat := Optimal;
            R.Objective := Tab.T (0, 0);
            for J in 1 .. Tab.N_Decision loop
               R.X (J) := Real'Rounding (Dec (J));
            end loop;
            R.N_Vars := Tab.N_Decision;
            R.N_Cuts := Cut_Iter - 1;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := True;
            return R;
         end if;

         Gc.Valid := False;
         Row := 0;
         for I in 1 .. Tab.M loop
            if not Is_Integer_Val (Tab.T (I, 0), Cfg.Integer_Tol) then
               Gc := Gomory_Cut_From_Row (Tab, I, Cfg.Integer_Tol);
               if Gc.Valid then
                  Row := I;
                  exit;
               end if;
            end if;
         end loop;
         if not Gc.Valid or else Row = 0 then
            R.Stat := Iteration_Limit;
            R.N_Cuts := Cut_Iter - 1;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := False;
            return R;
         end if;

         if Tab.M = Max_Constraints or else Tab.N = Max_Vars then
            R.Stat := Iteration_Limit;
            R.N_Cuts := Cut_Iter - 1;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := False;
            return R;
         end if;

         Add_Gomory_Cut (Tab, Gc);

         Dual_S := Dual_Restore (Tab, Cfg, Budget);
         if Dual_S = Infeasible then
            R.Stat := Infeasible;
            R.N_Cuts := Cut_Iter;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := False;
            return R;
         end if;
         if Dual_S = Iteration_Limit then
            R.Stat := Iteration_Limit;
            R.N_Cuts := Cut_Iter;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := False;
            return R;
         end if;

         --  Re-optimize primal (dual restore leaves dual-feasible; polish).
         Dual_S := Run_Phase (Tab, Cfg, Budget);
         if Dual_S = Unbounded then
            R.Stat := Unbounded;
            R.N_Cuts := Cut_Iter;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := False;
            return R;
         end if;
         if Dual_S = Iteration_Limit then
            R.Stat := Iteration_Limit;
            R.N_Cuts := Cut_Iter;
            R.N_Pivots := Cfg.Max_Pivots - Budget;
            R.Success := False;
            return R;
         end if;

         R.N_Cuts := Cut_Iter;
         R.Objective := Tab.T (0, 0);
         Dec := Extract_Primal (Tab, Tab.N_Decision);
         for J in 1 .. Tab.N_Decision loop
            R.X (J) := Dec (J);
         end loop;
         R.N_Vars := Tab.N_Decision;
      end loop;

      R.Stat := Iteration_Limit;
      R.N_Pivots := Cfg.Max_Pivots - Budget;
      R.Success := False;
      return R;
   end Solve_ILP_Cutting_Planes;

   -------------------------------------------------------------------------
   -- Kelley sketch
   -------------------------------------------------------------------------

   function Eval_Max_Of_Affines
     (A_Aff : Affine_Matrix;
      B_Aff : Affine_Bias;
      X     : Vector) return Real
   is
      K     : constant Natural := A_Aff'Length (1);
      N     : constant Natural := X'Length;
      Best  : Real := Real'First;
      Val   : Real;
   begin
      for I in 0 .. K - 1 loop
         Val := B_Aff (B_Aff'First + I);
         for J in 0 .. N - 1 loop
            Val := Val
              + A_Aff (A_Aff'First (1) + I, A_Aff'First (2) + J)
                * X (X'First + J);
         end loop;
         if I = 0 or else Val > Best then
            Best := Val;
         end if;
      end loop;
      return Best;
   end Eval_Max_Of_Affines;

   function Subgradient_Max_Of_Affines
     (A_Aff : Affine_Matrix;
      B_Aff : Affine_Bias;
      X     : Vector) return Vector
   is
      K     : constant Natural := A_Aff'Length (1);
      N     : constant Natural := X'Length;
      Best  : Real := Real'First;
      Best_I : Natural := 0;
      Val   : Real;
      G     : Vector (1 .. Max_Vars) := [others => 0.0];
   begin
      for I in 0 .. K - 1 loop
         Val := B_Aff (B_Aff'First + I);
         for J in 0 .. N - 1 loop
            Val := Val
              + A_Aff (A_Aff'First (1) + I, A_Aff'First (2) + J)
                * X (X'First + J);
         end loop;
         if I = 0 or else Val > Best + Epsilon_Tol then
            Best := Val;
            Best_I := I;
         end if;
      end loop;
      for J in 0 .. N - 1 loop
         G (J + 1) :=
           A_Aff (A_Aff'First (1) + Best_I, A_Aff'First (2) + J);
      end loop;
      return G (1 .. N);
   end Subgradient_Max_Of_Affines;

   function Solve_Kelley
     (A_Aff : Affine_Matrix;
      B_Aff : Affine_Bias;
      X_Lo  : Vector;
      X_Hi  : Vector;
      Cfg   : Config := (others => <>)) return Result
   is
      N     : constant Var_Count := Var_Count (X_Lo'Length);
      --  Master: vars = (x_1..x_n, t). Constraints grow with cuts + box.
      --  We rebuild A,b each outer iteration for clarity.
      R     : Result;
      X_Cur : Vector (1 .. Max_Vars) := [others => 0.0];
      G     : Vector (1 .. Max_Vars);
      F_Val : Real;
      T_Val : Real;
      --  Stored supporting cuts: t ≥ g·x + beta  ⇒  g·x − t ≤ −beta
      Max_Stored : constant := Max_Constraints;
      N_Stored   : Natural := 0;
      Cut_G      : array (1 .. Max_Stored, 1 .. Max_Vars) of Real :=
        [others => [others => 0.0]];
      Cut_Beta   : array (1 .. Max_Stored) of Real := [others => 0.0];
      M_Master   : Constraint_Count;
      N_Master   : constant Var_Count := N + 1;  -- x and t
   begin
      if N = 0 then
         raise Invalid_Argument with "Solve_Kelley: empty x";
      end if;

      --  Start at box midpoint.
      for J in 1 .. N loop
         X_Cur (J) :=
           0.5 * (X_Lo (X_Lo'First + J - 1) + X_Hi (X_Hi'First + J - 1));
      end loop;

      for Iter in 1 .. Cfg.Max_Cuts loop
         F_Val := Eval_Max_Of_Affines
           (A_Aff, B_Aff, X_Cur (1 .. N));
         G (1 .. N) := Subgradient_Max_Of_Affines
           (A_Aff, B_Aff, X_Cur (1 .. N));

         --  Supporting cut: t ≥ g·x + (f − g·x_cur) = g·x + beta
         --  with beta = f − g·x_cur.
         declare
            Beta : Real := F_Val;
            Dot  : Real := 0.0;
         begin
            for J in 1 .. N loop
               Dot := Dot + G (J) * X_Cur (J);
            end loop;
            Beta := F_Val - Dot;
            if N_Stored < Max_Stored then
               N_Stored := N_Stored + 1;
               for J in 1 .. N loop
                  Cut_G (N_Stored, J) := G (J);
               end loop;
               Cut_Beta (N_Stored) := Beta;
            end if;
         end;

         --  Master LP: min t  ≡ max −t
         --  s.t. for each cut k: g_k·x − t ≤ −beta_k
         --       x_j ≤ X_Hi,  −x_j ≤ −X_Lo
         declare
            Need_M : constant Natural := N_Stored + 2 * Natural (N);
         begin
            if Need_M > Max_Constraints
              or else Natural (N_Master) + Need_M > Max_Vars
            then
               R.Stat := Iteration_Limit;
               R.N_Cuts := Iter;
               R.Success := False;
               return R;
            end if;
            M_Master := Constraint_Count (Need_M);
         end;

         declare
            A_M : Matrix (1 .. M_Master, 1 .. N_Master);
            B_M : Vector (1 .. M_Master);
            C_M : Vector (1 .. N_Master) := [others => 0.0];
            Row : Natural := 0;
            LP  : Result;
         begin
            for I in 1 .. M_Master loop
               for J in 1 .. N_Master loop
                  A_M (I, J) := 0.0;
               end loop;
            end loop;

            for K in 1 .. N_Stored loop
               Row := Row + 1;
               for J in 1 .. N loop
                  A_M (Constraint_Index (Row), Var_Index (J)) :=
                    Cut_G (K, J);
               end loop;
               A_M (Constraint_Index (Row), Var_Index (N + 1)) := -1.0;
               B_M (Row) := -Cut_Beta (K);
            end loop;

            for J in 1 .. N loop
               Row := Row + 1;
               A_M (Constraint_Index (Row), Var_Index (J)) := 1.0;
               B_M (Row) := X_Hi (X_Hi'First + J - 1);
               Row := Row + 1;
               A_M (Constraint_Index (Row), Var_Index (J)) := -1.0;
               B_M (Row) := -X_Lo (X_Lo'First + J - 1);
            end loop;

            C_M (N + 1) := -1.0;  -- maximize −t ⇒ minimize t

            LP := Maximize_LP (A_M, B_M, C_M, Cfg);
            R.N_Pivots := R.N_Pivots + LP.N_Pivots;
            R.N_Cuts := Iter;

            if not LP.Success then
               R.Stat := LP.Stat;
               R.Success := False;
               return R;
            end if;

            for J in 1 .. N loop
               X_Cur (J) := LP.X (J);
            end loop;
            T_Val := LP.X (N + 1);
            F_Val := Eval_Max_Of_Affines
              (A_Aff, B_Aff, X_Cur (1 .. N));

            --  Converged when master t matches f(x) within Tol.
            if abs (T_Val - F_Val) <= Cfg.Tol
              or else abs (T_Val - F_Val) <= Cfg.Integer_Tol
            then
               R.Stat := Optimal;
               R.Objective := F_Val;
               for J in 1 .. N loop
                  R.X (J) := X_Cur (J);
               end loop;
               R.N_Vars := N;
               R.Success := True;
               return R;
            end if;
         end;
      end loop;

      F_Val := Eval_Max_Of_Affines (A_Aff, B_Aff, X_Cur (1 .. N));
      R.Stat := Iteration_Limit;
      R.Objective := F_Val;
      for J in 1 .. N loop
         R.X (J) := X_Cur (J);
      end loop;
      R.N_Vars := N;
      R.Success := False;
      return R;
   end Solve_Kelley;

end Cutting_Plane_Method;
