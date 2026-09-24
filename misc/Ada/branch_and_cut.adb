--  Branch_And_Cut body — B&B + optional Gomory cuts;
--  embedded Bland two-phase tableau (sibling ideas, no with-clause).

pragma Ada_2022;

package body Branch_And_Cut
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
      for I in X'Range loop
         if not Is_Integer (X (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Integer_Vector;

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
   -- Drop artificials / Run_Phase / Dual_Restore / Solve_Tableau
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
            --  Treat unbounded ray as infeasible for bounded MILP nodes.
            return Infeasible;
         end if;
         if Pivot_Budget = 0 then
            return Node_Limit;
         end if;
         Pivot (Tab, Leave, Enter);
         Pivot_Budget := Pivot_Budget - 1;
      end loop;
   end Run_Phase;

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
            return Node_Limit;
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

         if Phase_Stat /= Optimal then
            R.Stat := Phase_Stat;
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
      R.Nodes := 0;
      R.Cuts := 0;

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
         when Infeasible | Node_Limit =>
            R.Stat := Phase_Stat;
            R.Objective := Tab.T (0, 0);
            R.Success := False;
      end case;

      --  N_Vars already set; Nodes/Cuts unused for pure LP.
      pragma Unreferenced (Pivots_Start);
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
         if not Is_Integer (Tab.T (I, 0), Tol) then
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

      Tab.T (0, New_Col) := 0.0;
      if Tab.Obj_Phase1 > 0 then
         Tab.T (Tab.Obj_Phase1, New_Col) := 0.0;
      end if;

      Tab.M := Tab.M + 1;
      Tab.N := Tab.N + 1;
      Tab.N_Slack := Tab.N_Slack + 1;
   end Add_Gomory_Cut;

   -------------------------------------------------------------------------
   -- Branch_Variable / Apply_Bound
   -------------------------------------------------------------------------

   function Branch_Variable
     (X        : Vector;
      Required : Integer_Flags;
      Tol      : Real := Epsilon_Tol) return Natural
   is
      Best_J    : Natural := 0;
      Best_Dist : Real := Real'Last;
      F         : Real;
      Dist      : Real;
   begin
      for K in 0 .. X'Length - 1 loop
         if Required (Required'First + K)
           and then not Is_Integer (X (X'First + K), Tol)
         then
            F := Frac (X (X'First + K));
            Dist := abs (F - 0.5);
            if Dist < Best_Dist then
               Best_Dist := Dist;
               Best_J := K + 1;  -- 1-based among decision vars
            end if;
         end if;
      end loop;
      return Best_J;
   end Branch_Variable;

   procedure Apply_Bound
     (A_In        : Matrix;
      A_Out       : in out Matrix;
      B_In        : Vector;
      B_Out       : in out Vector;
      Lo, Hi      : Vector;
      M_In        : Constraint_Count;
      N_Dec       : Var_Count;
      M_Out       : out Constraint_Count)
   is
      Row : Natural := 0;
   begin
      for I in 1 .. M_In loop
         Row := Row + 1;
         if Row > Max_Constraints then
            raise Invalid_Argument with "Apply_Bound: row overflow";
         end if;
         for J in 1 .. N_Dec loop
            A_Out (Row, J) := A_In (A_In'First (1) + I - 1,
                                    A_In'First (2) + J - 1);
         end loop;
         B_Out (Row) := B_In (B_In'First + I - 1);
      end loop;

      for J in 1 .. N_Dec loop
         --  Upper bound x_j ≤ Hi_j
         if Hi (Hi'First + J - 1) < No_Upper - 1.0 then
            Row := Row + 1;
            if Row > Max_Constraints then
               raise Invalid_Argument with "Apply_Bound: UB overflow";
            end if;
            for K in 1 .. N_Dec loop
               A_Out (Row, K) := 0.0;
            end loop;
            A_Out (Row, J) := 1.0;
            B_Out (Row) := Hi (Hi'First + J - 1);
         end if;

         --  Lower bound x_j ≥ Lo_j  ⇒  −x_j ≤ −Lo_j  (skip Lo≈0)
         if Lo (Lo'First + J - 1) > Epsilon_Tol then
            Row := Row + 1;
            if Row > Max_Constraints then
               raise Invalid_Argument with "Apply_Bound: LB overflow";
            end if;
            for K in 1 .. N_Dec loop
               A_Out (Row, K) := 0.0;
            end loop;
            A_Out (Row, J) := -1.0;
            B_Out (Row) := -Lo (Lo'First + J - 1);
         end if;
      end loop;

      M_Out := Constraint_Count (Row);
   end Apply_Bound;

   -------------------------------------------------------------------------
   -- Solve — branch and cut
   -------------------------------------------------------------------------

   Max_Queue : constant := 512;

   type Node_Rec is record
      Lo     : Vector (1 .. Max_Problem_Vars) := [others => 0.0];
      Hi     : Vector (1 .. Max_Problem_Vars) := [others => No_Upper];
      Est_UB : Real := Real'Last;
      Used   : Boolean := False;
   end record;

   type Node_Store is array (1 .. Max_Queue) of Node_Rec;

   function Solve
     (A        : Matrix;
      B        : Vector;
      C        : Vector;
      Required : Integer_Flags;
      Cfg      : Config := (others => <>)) return Result
   is
      N_Dec : constant Var_Count := A'Length (2);
      M_Orig : constant Constraint_Count := A'Length (1);

      Queue   : Node_Store;
      Q_Count : Natural := 0;

      Incumbent     : Real := -Real'Last / 4.0;
      Have_Incumbent : Boolean := False;
      Best_X        : Vector (1 .. Max_Vars) := [others => 0.0];

      Nodes_Done : Natural := 0;
      Cuts_Done  : Natural := 0;
      Hit_Limit  : Boolean := False;

      A_Work : Matrix (1 .. Max_Constraints, 1 .. Max_Problem_Vars) :=
        [others => [others => 0.0]];
      B_Work : Vector (1 .. Max_Constraints) := [others => 0.0];
      A_Copy : Matrix (1 .. Max_Constraints, 1 .. Max_Problem_Vars) :=
        [others => [others => 0.0]];
      B_Copy : Vector (1 .. Max_Constraints) := [others => 0.0];
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
         Idx  : Natural := 0;
         Best : Real;
         N    : Node_Rec;
      begin
         if Q_Count = 0 then
            raise Invalid_Argument with "Dequeue: empty";
         end if;

         if Cfg.Use_Best_Bound then
            Best := -Real'Last;
            for I in 1 .. Q_Count loop
               if Queue (I).Used and then Queue (I).Est_UB > Best then
                  Best := Queue (I).Est_UB;
                  Idx := I;
               end if;
            end loop;
         else
            --  FIFO: first used slot
            for I in 1 .. Q_Count loop
               if Queue (I).Used then
                  Idx := I;
                  exit;
               end if;
            end loop;
         end if;

         N := Queue (Idx);
         --  Compact: move last into hole
         Queue (Idx) := Queue (Q_Count);
         Queue (Q_Count).Used := False;
         Q_Count := Q_Count - 1;
         return N;
      end Dequeue;

      function Queue_Nonempty return Boolean is
      begin
         return Q_Count > 0;
      end Queue_Nonempty;

      procedure Process_Node (N : Node_Rec) is
         Tab    : Tableau;
         LP     : Result;
         Budget : Natural;
         Dual_S : Status;
         Row    : Natural;
         Gc     : Cut;
         Br     : Natural;
         Floor_X, Ceil_X : Real;
         Child  : Node_Rec;
         Dec    : Vector (1 .. Max_Vars);
         Local_Cuts : Natural := 0;
         Feasible_Bounds : Boolean := True;
      begin
         Nodes_Done := Nodes_Done + 1;

         --  Trivial bound inconsistency
         for J in 1 .. N_Dec loop
            if N.Lo (J) > N.Hi (J) + Cfg.Tol then
               Feasible_Bounds := False;
               exit;
            end if;
         end loop;
         if not Feasible_Bounds then
            return;
         end if;

         --  Copy original A,B into work buffers then apply bounds
         for I in 1 .. M_Orig loop
            for J in 1 .. N_Dec loop
               A_Copy (I, J) :=
                 A (A'First (1) + I - 1, A'First (2) + J - 1);
            end loop;
            B_Copy (I) := B (B'First + I - 1);
         end loop;

         Apply_Bound
           (A_Copy, A_Work, B_Copy, B_Work,
            N.Lo (1 .. N_Dec), N.Hi (1 .. N_Dec),
            M_Orig, N_Dec, M_Work);

         if M_Work = 0 then
            return;
         end if;

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

         --  Bound prune
         if Have_Incumbent and then LP.Objective <= Incumbent + Cfg.Tol then
            return;
         end if;

         --  Optional local Gomory cuts (pure IP only: classical
         --  fractional Gomory assumes integer decision vars).
         declare
            Pure_IP : Boolean := True;
         begin
            for J in 1 .. N_Dec loop
               if not Required (Required'First + J - 1) then
                  Pure_IP := False;
                  exit;
               end if;
            end loop;

            if Pure_IP then
               Budget := Cfg.Max_Pivots;
               for Cut_Iter in 1 .. Cfg.Max_Cuts_Per_Node loop
                  Dec := Extract_Primal (Tab, Tab.N_Decision);
                  if Required_Are_Integer
                       (Dec (1 .. N_Dec), Required, Cfg.Integer_Tol)
                  then
                     exit;
                  end if;
                  Row := First_Fractional_Row (Tab, Cfg.Integer_Tol);
                  if Row = 0 then
                     exit;
                  end if;
                  Gc := Gomory_Cut_From_Row (Tab, Row, Cfg.Integer_Tol);
                  if not Gc.Valid then
                     exit;
                  end if;
                  if Tab.M = Max_Constraints or else Tab.N = Max_Vars then
                     exit;
                  end if;
                  Add_Gomory_Cut (Tab, Gc);
                  Local_Cuts := Local_Cuts + 1;
                  Cuts_Done := Cuts_Done + 1;
                  Dual_S := Dual_Restore (Tab, Cfg, Budget);
                  if Dual_S /= Optimal then
                     return;  -- cut made node infeasible / exhausted
                  end if;
                  --  Reoptimize primal
                  Dual_S := Run_Phase (Tab, Cfg, Budget);
                  if Dual_S /= Optimal then
                     return;
                  end if;
                  LP.Objective := Tab.T (0, 0);
                  Dec := Extract_Primal (Tab, Tab.N_Decision);
                  for J in 1 .. N_Dec loop
                     LP.X (J) := Dec (J);
                  end loop;
                  if Have_Incumbent
                    and then LP.Objective <= Incumbent + Cfg.Tol
                  then
                     return;
                  end if;
               end loop;
            end if;
         end;


         Dec := Extract_Primal (Tab, Tab.N_Decision);
         for J in 1 .. N_Dec loop
            LP.X (J) := Dec (J);
         end loop;
         LP.Objective := Tab.T (0, 0);

         if Required_Are_Integer
              (Dec (1 .. N_Dec), Required, Cfg.Integer_Tol)
         then
            if (not Have_Incumbent) or else LP.Objective > Incumbent then
               Have_Incumbent := True;
               Incumbent := LP.Objective;
               for J in 1 .. N_Dec loop
                  if Required (Required'First + J - 1) then
                     Best_X (J) := Real'Rounding (Dec (J));
                  else
                     Best_X (J) := Dec (J);
                  end if;
               end loop;
            end if;
            return;
         end if;

         --  Branch
         Br := Branch_Variable
           (Dec (1 .. N_Dec), Required, Cfg.Integer_Tol);
         if Br = 0 then
            return;
         end if;

         Floor_X := Real'Floor (Dec (Br));
         Ceil_X  := Real'Ceiling (Dec (Br));
         if Near (Floor_X, Ceil_X, Cfg.Integer_Tol) then
            --  Numerically integer but failed Required check — snap
            return;
         end if;

         --  Left: x_Br ≤ floor
         Child := N;
         Child.Est_UB := LP.Objective;
         if Floor_X < Child.Hi (Br) then
            Child.Hi (Br) := Floor_X;
         end if;
         Enqueue (Child);

         --  Right: x_Br ≥ ceil
         Child := N;
         Child.Est_UB := LP.Objective;
         if Ceil_X > Child.Lo (Br) then
            Child.Lo (Br) := Ceil_X;
         end if;
         Enqueue (Child);

         pragma Unreferenced (Local_Cuts);
      end Process_Node;

      Root : Node_Rec;
      Out_R : Result;
   begin
      if N_Dec = 0 or else M_Orig = 0 then
         raise Invalid_Argument with "Solve: empty problem";
      end if;

      Root.Est_UB := Real'Last;
      for J in 1 .. N_Dec loop
         Root.Lo (J) := 0.0;
         Root.Hi (J) := No_Upper;
      end loop;
      Enqueue (Root);

      while Queue_Nonempty loop
         if Nodes_Done >= Cfg.Max_Nodes then
            Hit_Limit := True;
            exit;
         end if;
         declare
            N : constant Node_Rec := Dequeue;
         begin
            Process_Node (N);
         end;
      end loop;

      Out_R.N_Vars := N_Dec;
      Out_R.Nodes := Nodes_Done;
      Out_R.Cuts := Cuts_Done;

      if Have_Incumbent then
         Out_R.Stat := Optimal;
         Out_R.Objective := Incumbent;
         for J in 1 .. N_Dec loop
            Out_R.X (J) := Best_X (J);
         end loop;
         Out_R.Success := True;
      elsif Hit_Limit then
         Out_R.Stat := Node_Limit;
         Out_R.Success := False;
      else
         Out_R.Stat := Infeasible;
         Out_R.Success := False;
      end if;

      return Out_R;
   end Solve;

end Branch_And_Cut;
