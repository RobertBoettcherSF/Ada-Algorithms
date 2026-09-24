--  Integer_Linear_Programming body — survey implementations.

pragma Ada_2022;

package body Integer_Linear_Programming
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Near / Vec_Near / Frac / Integer / Binary helpers
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
      F : Real;
   begin
      F := X - Real'Truncation (X);
      if F < 0.0 then
         F := F + 1.0;
      end if;
      if F >= 1.0 then
         return 0.0;
      end if;
      return F;
   end Frac;

   function Is_Integer
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return abs (X - Real'Rounding (X)) <= Tol;
   end Is_Integer;

   function Is_Integer_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for V of X loop
         if not Is_Integer (V, Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Integer_Vector;

   function Is_Binary
     (X : Real; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return Near (X, 0.0, Tol) or else Near (X, 1.0, Tol);
   end Is_Binary;

   function Is_Binary_Vector
     (X : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for V of X loop
         if not Is_Binary (V, Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Binary_Vector;

   function Required_Are_Integer
     (X        : Vector;
      Required : Integer_Flags;
      Tol      : Real := Epsilon_Tol) return Boolean
   is
   begin
      for K in 0 .. X'Length - 1 loop
         if Required (Required'First + K)
           and then not Is_Integer (X (X'First + K), Tol)
         then
            return False;
         end if;
      end loop;
      return True;
   end Required_Are_Integer;

   -------------------------------------------------------------------------
   -- Classification
   -------------------------------------------------------------------------

   function Classify
     (Required : Integer_Flags;
      Binary   : Boolean := False) return Problem_Kind
   is
      Any_Int  : Boolean := False;
      All_Int  : Boolean := True;
   begin
      for F of Required loop
         if F then
            Any_Int := True;
         else
            All_Int := False;
         end if;
      end loop;

      if Binary and then All_Int and then Any_Int then
         return Binary_IP;
      elsif All_Int and then Any_Int then
         return Pure_IP;
      else
         return MILP;
      end if;
   end Classify;

   function Classify_Method (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Branch_And_Bound =>
            return (Kind => Branch_And_Bound,
                    Uses_LP => True, Uses_Cuts => False,
                    Exact => True, Special_Case => False);
         when Cutting_Planes =>
            return (Kind => Cutting_Planes,
                    Uses_LP => True, Uses_Cuts => True,
                    Exact => True, Special_Case => False);
         when Branch_And_Cut =>
            return (Kind => Branch_And_Cut,
                    Uses_LP => True, Uses_Cuts => True,
                    Exact => True, Special_Case => False);
         when Dynamic_Programming =>
            return (Kind => Dynamic_Programming,
                    Uses_LP => False, Uses_Cuts => False,
                    Exact => True, Special_Case => True);
      end case;
   end Classify_Method;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Branch_And_Bound     => return "Branch-and-Bound";
         when Cutting_Planes      => return "Cutting planes";
         when Branch_And_Cut      => return "Branch-and-cut";
         when Dynamic_Programming => return "Dynamic programming";
      end case;
   end Method_Name;

   function Problem_Name (Kind : Problem_Kind) return String is
   begin
      case Kind is
         when Pure_IP   => return "Pure IP";
         when Binary_IP => return "Binary IP (0-1)";
         when MILP      => return "MILP";
      end case;
   end Problem_Name;

   function Method_Count return Natural is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   -------------------------------------------------------------------------
   -- Active objective / Bland enter-leave / Pivot
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

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := Default_Config) return Result
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

         if Phase_Stat = Unbounded or else Phase_Stat = Iteration_Limit then
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
      Cfg : Config := Default_Config) return Result
   is
      Tab : Tableau := Build_Tableau (A, B, C);
   begin
      return Solve_Tableau (Tab, Cfg);
   end Maximize_LP;

   -------------------------------------------------------------------------
   -- Integrality gap
   -------------------------------------------------------------------------

   function Integrality_Gap
     (LP_Opt : Real;
      IP_Opt : Real) return Real
   is
   begin
      return LP_Opt - IP_Opt;
   end Integrality_Gap;

   function Relative_Integrality_Gap
     (LP_Opt : Real;
      IP_Opt : Real) return Real
   is
      Den : constant Real := Real'Max (1.0, abs (IP_Opt));
   begin
      return (LP_Opt - IP_Opt) / Den;
   end Relative_Integrality_Gap;

   function Gap_From_Relaxation
     (A        : Matrix;
      B        : Vector;
      C        : Vector;
      IP_Opt   : Real;
      Cfg      : Config := Default_Config) return Real
   is
      LP : constant Result := Maximize_LP (A, B, C, Cfg);
   begin
      if not LP.Success or else LP.Stat /= Optimal then
         raise Invalid_Argument
           with "Gap_From_Relaxation: LP not optimal";
      end if;
      return Integrality_Gap (LP.Objective, IP_Opt);
   end Gap_From_Relaxation;

   -------------------------------------------------------------------------
   -- Feasibility / rounding
   -------------------------------------------------------------------------

   function Feasible_Inequality
     (A   : Matrix;
      B   : Vector;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
   is
      Acc : Real;
   begin
      for J in X'Range loop
         if X (J) < -Tol then
            return False;
         end if;
      end loop;

      for I in 0 .. A'Length (1) - 1 loop
         Acc := 0.0;
         for J in 0 .. A'Length (2) - 1 loop
            Acc := Acc
              + A (A'First (1) + I, A'First (2) + J)
              * X (X'First + J);
         end loop;
         if Acc > B (B'First + I) + Tol then
            return False;
         end if;
      end loop;
      return True;
   end Feasible_Inequality;

   function Round_Binary
     (X : Vector; Tol : Real := Epsilon_Tol) return Binary_Vector
   is
      Bits : Binary_Vector (X'Range);
      pragma Unreferenced (Tol);
   begin
      for J in X'Range loop
         Bits (J) := X (J) >= 0.5;
      end loop;
      return Bits;
   end Round_Binary;

   function Binary_To_Real (Bits : Binary_Vector) return Vector is
      X : Vector (Bits'Range);
   begin
      for J in Bits'Range loop
         if Bits (J) then
            X (J) := 1.0;
         else
            X (J) := 0.0;
         end if;
      end loop;
      return X;
   end Binary_To_Real;

   function Objective_Value (C : Vector; X : Vector) return Real is
      Acc : Real := 0.0;
   begin
      for K in 0 .. C'Length - 1 loop
         Acc := Acc + C (C'First + K) * X (X'First + K);
      end loop;
      return Acc;
   end Objective_Value;

   function Round_And_Check
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Result
   is
      Bits : constant Binary_Vector := Round_Binary (X, Tol);
      XR   : constant Vector := Binary_To_Real (Bits);
      R    : Result;
   begin
      R.N_Vars := Var_Count (X'Length);
      for J in 1 .. X'Length loop
         R.X (J) := XR (XR'First + J - 1);
      end loop;
      if Feasible_Inequality (A, B, XR, Tol) then
         R.Stat := Optimal;
         R.Objective := Objective_Value (C, XR);
         R.Success := True;
      else
         R.Stat := Infeasible;
         R.Success := False;
      end if;
      return R;
   end Round_And_Check;

   -------------------------------------------------------------------------
   -- 0–1 knapsack DP
   -------------------------------------------------------------------------

   function Solve_Knapsack_01
     (Items    : Knapsack_Items;
      Capacity : Natural) return Knapsack_Result
   is
      N : constant Natural := Items'Length;
      --  DP[w] = best value using capacity exactly/at most w
      type DP_Array is array (0 .. Max_Knapsack_Capacity) of Real;
      type Take_Array is
        array (1 .. Max_Knapsack_Items, 0 .. Max_Knapsack_Capacity)
        of Boolean;
      DP   : DP_Array := [others => 0.0];
      Prev : DP_Array;
      Take : Take_Array := [others => [others => False]];
      W_I  : Natural;
      V_I  : Real;
      Remain  : Natural;
      R    : Knapsack_Result;
      Best_W : Natural := 0;
   begin
      for Idx in 1 .. N loop
         declare
            It : constant Knapsack_Item :=
              Items (Items'First + Idx - 1);
         begin
            if It.Weight > Max_Knapsack_Capacity then
               raise Invalid_Argument
                 with "Solve_Knapsack_01: item weight too large";
            end if;
         end;
      end loop;

      for Idx in 1 .. N loop
         Prev := DP;
         W_I := Items (Items'First + Idx - 1).Weight;
         V_I := Items (Items'First + Idx - 1).Value;
         for W in reverse 0 .. Capacity loop
            if W_I <= W
              and then Prev (W - W_I) + V_I > Prev (W)
            then
               DP (W) := Prev (W - W_I) + V_I;
               Take (Idx, W) := True;
            else
               DP (W) := Prev (W);
               Take (Idx, W) := False;
            end if;
         end loop;
      end loop;

      for W in 0 .. Capacity loop
         if DP (W) > DP (Best_W) then
            Best_W := W;
         end if;
      end loop;

      R.Objective := DP (Best_W);
      R.N_Items := N;
      R.Capacity := Capacity;
      R.Success := True;

      Remain := Best_W;
      for Idx in reverse 1 .. N loop
         if Take (Idx, Remain) then
            R.Selected (Idx) := True;
            Remain := Remain - Items (Items'First + Idx - 1).Weight;
         else
            R.Selected (Idx) := False;
         end if;
      end loop;

      return R;
   end Solve_Knapsack_01;

   -------------------------------------------------------------------------
   -- Binary branch-and-bound (no cuts)
   -------------------------------------------------------------------------

   function Branch_Variable_Binary
     (X   : Vector;
      Tol : Real := Epsilon_Tol) return Natural
   is
      Best_J    : Natural := 0;
      Best_Dist : Real := Real'Last;
      F, Dist   : Real;
   begin
      for J in X'Range loop
         if not Is_Binary (X (J), Tol) then
            F := Frac (X (J));
            Dist := abs (F - 0.5);
            if Dist < Best_Dist then
               Best_Dist := Dist;
               Best_J := Natural (J - X'First + 1);
            end if;
         end if;
      end loop;
      return Best_J;
   end Branch_Variable_Binary;

   --  Append fixed binary bounds as inequalities to (A,B).
   --  Fix(j)=0 → free; Fix(j)=1 → x_j ≤ 0; Fix(j)=2 → x_j ≥ 1 i.e. −x ≤ −1;
   --  Also always add x_j ≤ 1 for each free/unfixed binary.
   procedure Build_Bounded_System
     (A_In  : Matrix;
      B_In  : Vector;
      Fix   : Vector;  -- 0=free, 1=fixed0, 2=fixed1  (as Real codes)
      N_Dec : Var_Count;
      M_In  : Constraint_Count;
      A_Out : in out Matrix;
      B_Out : in out Vector;
      M_Out : out Constraint_Count)
   is
      M : Constraint_Count := 0;
      Code : Real;
   begin
      for I in 1 .. M_In loop
         M := M + 1;
         for J in 1 .. N_Dec loop
            A_Out (M, J) :=
              A_In (A_In'First (1) + I - 1, A_In'First (2) + J - 1);
         end loop;
         B_Out (M) := B_In (B_In'First + I - 1);
      end loop;

      for J in 1 .. N_Dec loop
         Code := Fix (J);
         --  Always x_j ≤ 1
         M := M + 1;
         for K in 1 .. N_Dec loop
            A_Out (M, K) := 0.0;
         end loop;
         A_Out (M, J) := 1.0;
         B_Out (M) := 1.0;

         if Near (Code, 1.0) then
            --  x_j ≤ 0
            M := M + 1;
            for K in 1 .. N_Dec loop
               A_Out (M, K) := 0.0;
            end loop;
            A_Out (M, J) := 1.0;
            B_Out (M) := 0.0;
         elsif Near (Code, 2.0) then
            --  −x_j ≤ −1  (x_j ≥ 1)
            M := M + 1;
            for K in 1 .. N_Dec loop
               A_Out (M, K) := 0.0;
            end loop;
            A_Out (M, J) := -1.0;
            B_Out (M) := -1.0;
         end if;
      end loop;

      M_Out := M;
   end Build_Bounded_System;

   function Solve_Binary_BB
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := Default_Config) return Result
   is
      N_Dec  : constant Var_Count := A'Length (2);
      M_Orig : constant Constraint_Count := A'Length (1);

      Max_Queue : constant := 4096;
      type Node_Rec is record
         Fix  : Vector (1 .. Max_Problem_Vars) := [others => 0.0];
         Used : Boolean := False;
      end record;
      type Queue_Arr is array (1 .. Max_Queue) of Node_Rec;
      Queue   : Queue_Arr;
      Q_Count : Natural := 0;

      Incumbent      : Real := -Real'Last / 4.0;
      Have_Incumbent : Boolean := False;
      Best_X         : Vector (1 .. Max_Vars) := [others => 0.0];
      Nodes_Done     : Natural := 0;
      Hit_Limit      : Boolean := False;

      A_Work : Matrix (1 .. Max_Constraints, 1 .. Max_Problem_Vars) :=
        [others => [others => 0.0]];
      B_Work : Vector (1 .. Max_Constraints) := [others => 0.0];
      M_Work : Constraint_Count;

      procedure Enqueue (N : Node_Rec) is
      begin
         if Q_Count >= Max_Queue then
            Hit_Limit := True;
            return;
         end if;
         Q_Count := Q_Count + 1;
         Queue (Q_Count) := N;
         Queue (Q_Count).Used := True;
      end Enqueue;

      function Dequeue return Node_Rec is
         N : Node_Rec;
      begin
         if Q_Count = 0 then
            raise Invalid_Argument with "Dequeue: empty";
         end if;
         N := Queue (1);
         for I in 1 .. Q_Count - 1 loop
            Queue (I) := Queue (I + 1);
         end loop;
         Queue (Q_Count).Used := False;
         Q_Count := Q_Count - 1;
         return N;
      end Dequeue;

      procedure Process_Node (N : Node_Rec) is
         Tab : Tableau;
         LP  : Result;
         Br  : Natural;
         Child : Node_Rec;
         Dec : Vector (1 .. Max_Vars);
      begin
         Nodes_Done := Nodes_Done + 1;
         if Nodes_Done > Cfg.Max_Nodes then
            Hit_Limit := True;
            return;
         end if;

         Build_Bounded_System
           (A, B, N.Fix (1 .. N_Dec), N_Dec, M_Orig,
            A_Work, B_Work, M_Work);

         if M_Work = 0 then
            return;
         end if;
         --  N_Dec ≤ 12 and M_Work ≤ Max_Constraints keep tableau in range.

         declare
            A_Slice : Matrix (1 .. M_Work, 1 .. N_Dec);
            B_Slice : Vector (1 .. M_Work);
         begin
            for I in 1 .. M_Work loop
               for J in 1 .. N_Dec loop
                  A_Slice (I, J) := A_Work (I, J);
               end loop;
               B_Slice (I) := B_Work (I);
            end loop;
            Tab := Build_Tableau (A_Slice, B_Slice, C);
         end;

         LP := Solve_Tableau (Tab, Cfg);
         if not LP.Success then
            return;
         end if;

         if Have_Incumbent and then LP.Objective <= Incumbent + Cfg.Tol then
            return;
         end if;

         declare
            X_Dec : constant Vector :=
              Extract_Primal (Tab, Tab.N_Decision);
         begin
            for J in 1 .. N_Dec loop
               Dec (J) := X_Dec (J);
               LP.X (J) := X_Dec (J);
            end loop;
         end;

         if Is_Binary_Vector (Dec (1 .. N_Dec), Cfg.Integer_Tol) then
            if (not Have_Incumbent)
              or else LP.Objective > Incumbent + Cfg.Tol
            then
               Have_Incumbent := True;
               Incumbent := LP.Objective;
               for J in 1 .. N_Dec loop
                  --  Snap to exact 0/1
                  if Near (Dec (J), 1.0, Cfg.Integer_Tol) then
                     Best_X (J) := 1.0;
                  else
                     Best_X (J) := 0.0;
                  end if;
               end loop;
            end if;
            return;
         end if;

         Br := Branch_Variable_Binary (Dec (1 .. N_Dec), Cfg.Integer_Tol);
         if Br = 0 then
            return;
         end if;

         --  Child: fix x_Br = 0
         Child := N;
         Child.Fix (Br) := 1.0;
         Enqueue (Child);

         --  Child: fix x_Br = 1
         Child := N;
         Child.Fix (Br) := 2.0;
         Enqueue (Child);
      end Process_Node;

      Root : Node_Rec;
      R    : Result;
   begin
      Root.Used := True;
      Enqueue (Root);

      while Q_Count > 0 and then not Hit_Limit loop
         declare
            N : constant Node_Rec := Dequeue;
         begin
            Process_Node (N);
         end;
      end loop;

      R.Nodes := Nodes_Done;
      R.N_Vars := N_Dec;

      if Have_Incumbent then
         R.Stat := Optimal;
         R.Objective := Incumbent;
         for J in 1 .. N_Dec loop
            R.X (J) := Best_X (J);
         end loop;
         R.Success := True;
         --  If Hit_Limit also, incumbent is feasible but may be unproven.
      elsif Hit_Limit then
         R.Stat := Node_Limit;
         R.Success := False;
      else
         R.Stat := Infeasible;
         R.Success := False;
      end if;

      return R;
   end Solve_Binary_BB;

end Integer_Linear_Programming;
