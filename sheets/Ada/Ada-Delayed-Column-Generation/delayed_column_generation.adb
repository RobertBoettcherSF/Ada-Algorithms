--  Delayed_Column_Generation body — RMP + knapsack pricing + Bland simplex.

pragma Ada_2022;

package body Delayed_Column_Generation
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
   -- Column-pool helpers
   -------------------------------------------------------------------------

   function Pattern_Width
     (Counts : Pattern_Counts;
      Widths : Vector;
      N      : Item_Count) return Natural
   is
      Total : Natural := 0;
      Wi    : Natural;
      Add   : Natural;
   begin
      for I in 1 .. N loop
         Wi := Natural (Widths (Widths'First + I - 1));
         if Counts (I) > 0 and then Wi > 0 then
            if Counts (I) > Natural'Last / Wi then
               return Natural'Last;
            end if;
            Add := Counts (I) * Wi;
            if Total > Natural'Last - Add then
               return Natural'Last;
            end if;
            Total := Total + Add;
         end if;
      end loop;
      return Total;
   end Pattern_Width;

   function Patterns_Equal
     (A, B : Pattern_Counts; N : Item_Count) return Boolean
   is
   begin
      for I in 1 .. N loop
         if A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Patterns_Equal;

   function Pattern_Exists
     (Pool   : Column_Pool;
      N_Cols : Column_Count;
      Counts : Pattern_Counts;
      N      : Item_Count) return Boolean
   is
   begin
      for J in 1 .. N_Cols loop
         if Pool (J).Valid
           and then Patterns_Equal (Pool (J).Counts, Counts, N)
         then
            return True;
         end if;
      end loop;
      return False;
   end Pattern_Exists;

   procedure Clear_Pool
     (Pool : in out Column_Pool; N_Cols : out Column_Count)
   is
   begin
      for J in Column_Index loop
         Pool (J).Valid := False;
         Pool (J).Cost := 1.0;
         Pool (J).Counts := [others => 0];
      end loop;
      N_Cols := 0;
   end Clear_Pool;

   procedure Add_Column
     (Pool   : in out Column_Pool;
      N_Cols : in out Column_Count;
      Counts : Pattern_Counts;
      Cost   : Real := 1.0)
   is
   begin
      --  Precondition: N_Cols < Max_Columns.
      N_Cols := N_Cols + 1;
      Pool (N_Cols).Counts := Counts;
      Pool (N_Cols).Cost := Cost;
      Pool (N_Cols).Valid := True;
   end Add_Column;

   procedure Init_Trivial_Patterns
     (Pool   : in out Column_Pool;
      N_Cols : out Column_Count;
      Widths : Vector;
      W      : Width_Value;
      N      : Item_Count)
   is
      Counts : Pattern_Counts;
      Wi     : Natural;
      How_Many : Natural;
   begin
      Clear_Pool (Pool, N_Cols);
      for I in 1 .. N loop
         Wi := Natural (Widths (Widths'First + I - 1));
         if Wi = 0 or else Wi > Natural (W) then
            raise Invalid_Argument
              with "Init_Trivial_Patterns: invalid item width";
         end if;
         How_Many := Natural (W) / Wi;
         if How_Many = 0 then
            raise Invalid_Argument
              with "Init_Trivial_Patterns: item wider than rod";
         end if;
         Counts := [others => 0];
         Counts (I) := How_Many;
         Add_Column (Pool, N_Cols, Counts, 1.0);
      end loop;
   end Init_Trivial_Patterns;

   function Reduced_Cost
     (Counts : Pattern_Counts;
      Duals  : Vector;
      N      : Item_Count;
      Cost   : Real := 1.0) return Real
   is
      Dot : Real := 0.0;
   begin
      for I in 1 .. N loop
         Dot := Dot
           + Duals (Duals'First + I - 1) * Real (Counts (I));
      end loop;
      return Cost - Dot;
   end Reduced_Cost;

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
      Cfg : Config := (others => <>)) return RMP_Result
   is
      R            : RMP_Result;
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
   -- Price_Knapsack (unbounded integer knapsack via DP)
   -------------------------------------------------------------------------

   function Price_Knapsack
     (Duals  : Vector;
      Widths : Vector;
      W      : Width_Value;
      N      : Item_Count;
      Cost   : Real := 1.0;
      Tol    : Real := Epsilon_Tol) return Pricing_Result
   is
      Best   : array (0 .. Max_Width) of Real := [others => 0.0];
      Choice : array (0 .. Max_Width) of Natural := [others => 0];
      --  Choice(c) = item index last packed to achieve Best(c), 0 = none.
      R      : Pricing_Result;
      Wi     : Natural;
      Pi     : Real;
      Cand   : Real;
      Cap    : constant Natural := Natural (W);
      Remain : Natural;
      Idx    : Natural;
   begin
      for I in 1 .. N loop
         Wi := Natural (Widths (Widths'First + I - 1));
         Pi := Duals (Duals'First + I - 1);
         if Wi = 0 or else Wi > Cap then
            null;
         elsif Pi > 0.0 then
            for C in Wi .. Cap loop
               Cand := Best (C - Wi) + Pi;
               if Cand > Best (C) + Tol then
                  Best (C) := Cand;
                  Choice (C) := I;
               end if;
            end loop;
         end if;
      end loop;

      --  Reconstruct a maximizer (any capacity ≤ W with best value).
      declare
         Best_C : Natural := 0;
         Best_V : Real := 0.0;
      begin
         for C in 0 .. Cap loop
            if Best (C) > Best_V + Tol then
               Best_V := Best (C);
               Best_C := C;
            end if;
         end loop;

         R.Value := Best_V;
         R.Counts := [others => 0];
         Remain := Best_C;
         while Remain > 0 and then Choice (Remain) > 0 loop
            Idx := Choice (Remain);
            R.Counts (Item_Index (Idx)) :=
              R.Counts (Item_Index (Idx)) + 1;
            Wi := Natural (Widths (Widths'First + Idx - 1));
            if Wi = 0 or else Remain < Wi then
               exit;
            end if;
            Remain := Remain - Wi;
         end loop;
      end;

      R.Feasible := True;
      R.Reduced_Cost := Cost - R.Value;
      R.Improving := R.Value > Cost + Tol;
      return R;
   end Price_Knapsack;

   -------------------------------------------------------------------------
   -- Solve_RMP
   -------------------------------------------------------------------------

   function Solve_RMP
     (Pool   : Column_Pool;
      N_Cols : Column_Count;
      Demand : Vector;
      N      : Item_Count;
      Cfg    : Config := (others => <>)) return RMP_Result
   is
      --  Convert min cost'λ s.t. Aλ ≥ d into max (−cost)'λ s.t. (−A)λ ≤ −d.
      A : Matrix (1 .. Constraint_Index (N), 1 .. Var_Index (N_Cols));
      B : Vector (1 .. Positive (N));
      C : Vector (1 .. Positive (N_Cols));
      Tab : Tableau;
      R   : RMP_Result;
      Slack_Col : Natural;
      Dual_Raw  : Real;
   begin
      if N_Cols = 0 or else N = 0 then
         raise Invalid_Argument with "Solve_RMP: empty";
      end if;

      for J in 1 .. N_Cols loop
         if not Pool (J).Valid then
            raise Invalid_Argument with "Solve_RMP: invalid column";
         end if;
         C (J) := -Pool (J).Cost;  -- maximize −cost
         for I in 1 .. N loop
            A (Constraint_Index (I), Var_Index (J)) :=
              -Real (Pool (J).Counts (I));
         end loop;
      end loop;

      for I in 1 .. N loop
         B (I) := -Demand (Demand'First + I - 1);
      end loop;

      Tab := Build_Tableau (A, B, C);
      R := Solve_Tableau (Tab, Cfg);
      R.N_Items := N;
      R.N_Columns := N_Cols;

      if not R.Success then
         return R;
      end if;

      --  Max objective is −min_cost; recover true minimum.
      R.Objective := -R.Objective;

      --  Duals of original ≥ rows: surplus columns after sign-flip path.
      --  Stored reduced cost of surplus_i equals π_i (see package notes);
      --  take π_i = max(0, T(0, surplus)).
      for I in 1 .. N loop
         Slack_Col := Natural (Tab.N_Decision) + I;
         if Slack_Col <= Natural (Tab.N) then
            Dual_Raw := Tab.T (0, Slack_Col);
            if Dual_Raw < 0.0 then
               Dual_Raw := 0.0;
            end if;
            R.Duals (I) := Dual_Raw;
         else
            R.Duals (I) := 0.0;
         end if;
      end loop;

      return R;
   end Solve_RMP;

   -------------------------------------------------------------------------
   -- Solve_Cutting_Stock
   -------------------------------------------------------------------------

   function Solve_Cutting_Stock
     (Widths : Vector;
      Demand : Vector;
      W      : Width_Value;
      Cfg    : Config := (others => <>)) return Result
   is
      N : constant Item_Count := Item_Count (Widths'Length);
      Pool : Column_Pool;
      N_Cols : Column_Count;
      R : Result;
      RMP : RMP_Result;
      Price : Pricing_Result;
      Cap_Cols : Column_Count;
      Dual_Vec : Vector (1 .. Max_Items) := [others => 0.0];
      Width_Ok : Boolean;
   begin
      if N = 0 then
         raise Invalid_Argument with "Solve_Cutting_Stock: no items";
      end if;
      if Cfg.Max_Columns > Max_Columns then
         Cap_Cols := Max_Columns;
      else
         Cap_Cols := Column_Count (Cfg.Max_Columns);
      end if;

      for I in 1 .. N loop
         if Widths (Widths'First + I - 1) <= 0.0
           or else Widths (Widths'First + I - 1) > Real (W)
         then
            raise Invalid_Argument
              with "Solve_Cutting_Stock: bad width";
         end if;
         if Demand (Demand'First + I - 1) < 0.0 then
            raise Invalid_Argument
              with "Solve_Cutting_Stock: negative demand";
         end if;
      end loop;

      Init_Trivial_Patterns (Pool, N_Cols, Widths, W, N);

      R.N_Items := N;
      R.Pool := Pool;
      R.N_Columns := N_Cols;

      for Iter in 1 .. Cfg.Max_Iters loop
         R.N_Iters := Iter;
         RMP := Solve_RMP (Pool, N_Cols, Demand, N, Cfg);
         R.N_Pivots := R.N_Pivots + RMP.N_Pivots;

         if not RMP.Success then
            R.Stat := RMP.Stat;
            R.Objective := RMP.Objective;
            R.Success := False;
            R.N_Columns := N_Cols;
            R.Pool := Pool;
            return R;
         end if;

         R.Objective := RMP.Objective;
         R.Lambda := RMP.Lambda;
         R.Duals := RMP.Duals;
         R.N_Columns := N_Cols;
         R.Pool := Pool;

         for I in 1 .. N loop
            Dual_Vec (I) := RMP.Duals (I);
         end loop;

         Price := Price_Knapsack
           (Duals  => Dual_Vec (1 .. Positive (N)),
            Widths => Widths,
            W      => W,
            N      => N,
            Cost   => 1.0,
            Tol    => Cfg.Tol);

         Width_Ok :=
           Pattern_Width (Price.Counts, Widths, N) <= Natural (W);

         if not Price.Improving or else not Width_Ok then
            R.Stat := Optimal;
            R.Success := True;
            return R;
         end if;

         if Pattern_Exists (Pool, N_Cols, Price.Counts, N) then
            --  Numerical stall: declare optimal.
            R.Stat := Optimal;
            R.Success := True;
            return R;
         end if;

         if N_Cols >= Cap_Cols then
            R.Stat := Column_Limit;
            R.Success := False;
            return R;
         end if;

         Add_Column (Pool, N_Cols, Price.Counts, 1.0);
         R.Pool := Pool;
         R.N_Columns := N_Cols;
      end loop;

      R.Stat := Iteration_Limit;
      R.Success := False;
      R.N_Columns := N_Cols;
      R.Pool := Pool;
      return R;
   end Solve_Cutting_Stock;

end Delayed_Column_Generation;
