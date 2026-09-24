--  Value_Iteration body — synchronous Bellman optimality backups.

pragma Ada_2022;

package body Value_Iteration is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   procedure Raise_Bad (Msg : String) is
   begin
      raise Invalid_Argument with Msg;
   end Raise_Bad;

   procedure Check_Tol (Tol : Real; Where : String) is
   begin
      if Tol < 0.0 then
         Raise_Bad (Where & ": Tol must be >= 0");
      end if;
   end Check_Tol;

   procedure Check_Index
     (Model  : MDP;
      State  : Positive;
      Action : Positive;
      Where  : String)
   is
   begin
      if State > Positive (Model.N_States)
        or else Action > Positive (Model.N_Actions)
      then
         Raise_Bad (Where & ": state/action out of range");
      end if;
   end Check_Index;

   procedure Check_Triple
     (Model      : MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Where      : String)
   is
   begin
      Check_Index (Model, State, Action, Where);
      if Next_State > Positive (Model.N_States) then
         Raise_Bad (Where & ": next state out of range");
      end if;
   end Check_Triple;

   procedure Check_Values
     (Model  : MDP;
      Values : Value_Function;
      Where  : String)
   is
   begin
      if Values'First /= 1
        or else Values'Last /= State_Index (Model.N_States)
      then
         Raise_Bad (Where & ": value function has the wrong length");
      end if;
   end Check_Values;

   procedure Check_Gamma (Gamma : Real; Where : String) is
   begin
      if Gamma < 0.0 or else Gamma >= 1.0 then
         Raise_Bad (Where & ": Gamma must be in [0, 1)");
      end if;
   end Check_Gamma;

   procedure Check_Dims
     (N_States, N_Actions : Positive; Where : String)
   is
   begin
      if N_States > Max_States or else N_Actions > Max_Actions then
         Raise_Bad (Where & ": dimension exceeds capacity");
      end if;
   end Check_Dims;

   function Row_Is_Stochastic
     (Model  : MDP;
      State  : State_Index;
      Action : Action_Index;
      Tol    : Real) return Boolean
   is
      Sum : Real := 0.0;
      P   : Probability;
   begin
      for Sp in 1 .. Model.N_States loop
         P := Model.P (State, Action, Sp);
         if P < 0.0 then
            return False;
         end if;
         Sum := Sum + P;
      end loop;
      return abs (Sum - 1.0) <= Tol;
   end Row_Is_Stochastic;

   procedure Validate_MDP (Model : MDP; Where : String) is
   begin
      if Model.N_States = 0 or else Model.N_Actions = 0 then
         Raise_Bad (Where & ": empty state or action set");
      end if;
      Check_Gamma (Model.Gamma, Where);
      for S in 1 .. Model.N_States loop
         for A in 1 .. Model.N_Actions loop
            if not Row_Is_Stochastic (Model, S, A, Prob_Tol) then
               Raise_Bad (Where & ": non-stochastic transition row");
            end if;
         end loop;
      end loop;
   end Validate_MDP;

   function Q_Unchecked
     (Model  : MDP;
      Values : Value_Function;
      State  : State_Index;
      Action : Action_Index) return Real
   is
      Acc : Real := 0.0;
      P   : Probability;
   begin
      for Sp in 1 .. Model.N_States loop
         P := Model.P (State, Action, Sp);
         if P /= 0.0 then
            Acc := Acc + P * (Model.R (State, Action, Sp)
                              + Model.Gamma * Values (Sp));
         end if;
      end loop;
      return Acc;
   end Q_Unchecked;

   function Backup_Unchecked
     (Model  : MDP;
      Values : Value_Function;
      State  : State_Index) return Real
   is
      Best : Real := Q_Unchecked (Model, Values, State, 1);
      Q    : Real;
   begin
      for A in 2 .. Model.N_Actions loop
         Q := Q_Unchecked (Model, Values, State, A);
         if Q > Best then
            Best := Q;
         end if;
      end loop;
      return Best;
   end Backup_Unchecked;

   function Greedy_Unchecked
     (Model  : MDP;
      Values : Value_Function;
      State  : State_Index) return Action_Index
   is
      Best_A : Action_Index := 1;
      Best_Q : Real := Q_Unchecked (Model, Values, State, 1);
      Q      : Real;
   begin
      for A in 2 .. Model.N_Actions loop
         Q := Q_Unchecked (Model, Values, State, A);
         if Q > Best_Q then
            Best_Q := Q;
            Best_A := A;
         end if;
      end loop;
      return Best_A;
   end Greedy_Unchecked;

   function Zero_Values (N : State_Count) return Value_Function is
      V : constant Value_Function (1 .. N) := [others => 0.0];
   begin
      return V;
   end Zero_Values;

   -------------------------------------------------------------------------
   -- Near
   -------------------------------------------------------------------------

   function Near
     (X, Y : Real; Tol : Real := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol, "Near");
      return abs (X - Y) <= Tol;
   end Near;

   function Near_Values
     (A, B : Value_Function; Tol : Real := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol, "Near_Values");
      if A'First /= B'First or else A'Last /= B'Last then
         Raise_Bad ("Near_Values: length mismatch");
      end if;
      for I in A'Range loop
         if not Near (A (I), B (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Near_Values;

   -------------------------------------------------------------------------
   -- Validation / accessors
   -------------------------------------------------------------------------

   function Is_Stochastic
     (Model  : MDP;
      State  : Positive;
      Action : Positive;
      Tol    : Real := Prob_Tol) return Boolean
   is
   begin
      Check_Tol (Tol, "Is_Stochastic");
      Check_Index (Model, State, Action, "Is_Stochastic");
      return Row_Is_Stochastic
        (Model, State_Index (State), Action_Index (Action), Tol);
   end Is_Stochastic;

   function Is_Valid_MDP
     (Model : MDP; Tol : Real := Prob_Tol) return Boolean
   is
   begin
      Check_Tol (Tol, "Is_Valid_MDP");
      if Model.N_States = 0 or else Model.N_Actions = 0 then
         return False;
      end if;
      if Model.Gamma < 0.0 or else Model.Gamma >= 1.0 then
         return False;
      end if;
      for S in 1 .. Model.N_States loop
         for A in 1 .. Model.N_Actions loop
            if not Row_Is_Stochastic (Model, S, A, Tol) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_MDP;

   function Transition
     (Model : MDP; State, Action, Next_State : Positive) return Probability
   is
   begin
      Check_Triple (Model, State, Action, Next_State, "Transition");
      return Model.P
        (State_Index (State), Action_Index (Action), State_Index (Next_State));
   end Transition;

   function Reward_Of
     (Model : MDP; State, Action, Next_State : Positive) return Reward
   is
   begin
      Check_Triple (Model, State, Action, Next_State, "Reward_Of");
      return Model.R
        (State_Index (State), Action_Index (Action), State_Index (Next_State));
   end Reward_Of;

   function Expected_Reward
     (Model : MDP; State, Action : Positive) return Reward
   is
      Acc : Real := 0.0;
   begin
      Check_Index (Model, State, Action, "Expected_Reward");
      for Sp in 1 .. Model.N_States loop
         Acc := Acc + Model.P (State_Index (State), Action_Index (Action), Sp)
           * Model.R (State_Index (State), Action_Index (Action), Sp);
      end loop;
      return Acc;
   end Expected_Reward;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Empty_MDP
     (N_States  : Positive;
      N_Actions : Positive;
      Gamma     : Real) return MDP
   is
   begin
      Check_Dims (N_States, N_Actions, "Empty_MDP");
      Check_Gamma (Gamma, "Empty_MDP");
      declare
         M : MDP
           (N_States  => State_Count (N_States),
            N_Actions => Action_Count (N_Actions));
      begin
         M.P     := [others => [others => [others => 0.0]]];
         M.R     := [others => [others => [others => 0.0]]];
         M.Gamma := Gamma;
         return M;
      end;
   end Empty_MDP;

   procedure Set_Transition
     (Model      : in out MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Prob       : Probability)
   is
   begin
      Check_Triple (Model, State, Action, Next_State, "Set_Transition");
      if Prob < 0.0 then
         Raise_Bad ("Set_Transition: negative probability");
      end if;
      Model.P
        (State_Index (State), Action_Index (Action), State_Index (Next_State))
        := Prob;
   end Set_Transition;

   procedure Set_Reward
     (Model      : in out MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Value      : Reward)
   is
   begin
      Check_Triple (Model, State, Action, Next_State, "Set_Reward");
      Model.R
        (State_Index (State), Action_Index (Action), State_Index (Next_State))
        := Value;
   end Set_Reward;

   procedure Set_Reward_SA
     (Model  : in out MDP;
      State  : Positive;
      Action : Positive;
      Value  : Reward)
   is
   begin
      Check_Index (Model, State, Action, "Set_Reward_SA");
      for Sp in 1 .. Model.N_States loop
         Model.R (State_Index (State), Action_Index (Action), Sp) := Value;
      end loop;
   end Set_Reward_SA;

   procedure Set_Deterministic
     (Model      : in out MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Value      : Reward)
   is
   begin
      Check_Triple (Model, State, Action, Next_State, "Set_Deterministic");
      for Sp in 1 .. Model.N_States loop
         Model.P (State_Index (State), Action_Index (Action), Sp) := 0.0;
         Model.R (State_Index (State), Action_Index (Action), Sp) := 0.0;
      end loop;
      Model.P
        (State_Index (State), Action_Index (Action), State_Index (Next_State))
        := 1.0;
      Model.R
        (State_Index (State), Action_Index (Action), State_Index (Next_State))
        := Value;
   end Set_Deterministic;

   function Make_MDP
     (P     : Transition_Tensor;
      R     : Reward_Tensor;
      Gamma : Real) return MDP
   is
      NS : Natural;
      NA : Natural;
   begin
      if P'First (1) /= 1 or else P'First (2) /= 1 or else P'First (3) /= 1
        or else R'First (1) /= 1 or else R'First (2) /= 1
        or else R'First (3) /= 1
      then
         Raise_Bad ("Make_MDP: tensors must be 1-based");
      end if;
      NS := Natural (P'Length (1));
      NA := Natural (P'Length (2));
      if NS = 0 or else NA = 0 then
         Raise_Bad ("Make_MDP: empty dimension");
      end if;
      if Natural (P'Length (3)) /= NS
        or else Natural (R'Length (1)) /= NS
        or else Natural (R'Length (2)) /= NA
        or else Natural (R'Length (3)) /= NS
      then
         Raise_Bad ("Make_MDP: tensor shape mismatch");
      end if;
      Check_Dims (NS, NA, "Make_MDP");
      Check_Gamma (Gamma, "Make_MDP");
      declare
         M : MDP
           (N_States  => State_Count (NS),
            N_Actions => Action_Count (NA));
      begin
         for S in 1 .. M.N_States loop
            for A in 1 .. M.N_Actions loop
               for Sp in 1 .. M.N_States loop
                  if P (S, A, Sp) < 0.0 then
                     Raise_Bad ("Make_MDP: negative probability");
                  end if;
                  M.P (S, A, Sp) := P (S, A, Sp);
                  M.R (S, A, Sp) := R (S, A, Sp);
               end loop;
            end loop;
         end loop;
         M.Gamma := Gamma;
         Validate_MDP (M, "Make_MDP");
         return M;
      end;
   end Make_MDP;

   function Make_MDP_SA
     (P     : Transition_Tensor;
      R     : Reward_SA_Matrix;
      Gamma : Real) return MDP
   is
      NS : Natural;
      NA : Natural;
   begin
      if P'First (1) /= 1 or else P'First (2) /= 1 or else P'First (3) /= 1
        or else R'First (1) /= 1 or else R'First (2) /= 1
      then
         Raise_Bad ("Make_MDP_SA: tensors must be 1-based");
      end if;
      NS := Natural (P'Length (1));
      NA := Natural (P'Length (2));
      if NS = 0 or else NA = 0 then
         Raise_Bad ("Make_MDP_SA: empty dimension");
      end if;
      if Natural (P'Length (3)) /= NS
        or else Natural (R'Length (1)) /= NS
        or else Natural (R'Length (2)) /= NA
      then
         Raise_Bad ("Make_MDP_SA: tensor shape mismatch");
      end if;
      Check_Dims (NS, NA, "Make_MDP_SA");
      Check_Gamma (Gamma, "Make_MDP_SA");
      declare
         M : MDP
           (N_States  => State_Count (NS),
            N_Actions => Action_Count (NA));
      begin
         for S in 1 .. M.N_States loop
            for A in 1 .. M.N_Actions loop
               for Sp in 1 .. M.N_States loop
                  if P (S, A, Sp) < 0.0 then
                     Raise_Bad ("Make_MDP_SA: negative probability");
                  end if;
                  M.P (S, A, Sp) := P (S, A, Sp);
                  M.R (S, A, Sp) := R (S, A);
               end loop;
            end loop;
         end loop;
         M.Gamma := Gamma;
         Validate_MDP (M, "Make_MDP_SA");
         return M;
      end;
   end Make_MDP_SA;

   -------------------------------------------------------------------------
   -- Bellman operators
   -------------------------------------------------------------------------

   function Q_Value
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive;
      Action : Positive) return Real
   is
   begin
      Validate_MDP (Model, "Q_Value");
      Check_Values (Model, Values, "Q_Value");
      Check_Index (Model, State, Action, "Q_Value");
      return Q_Unchecked
        (Model, Values, State_Index (State), Action_Index (Action));
   end Q_Value;

   function Q_Values
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive) return Q_Row
   is
      Row : Q_Row (1 .. Model.N_Actions);
   begin
      Validate_MDP (Model, "Q_Values");
      Check_Values (Model, Values, "Q_Values");
      Check_Index (Model, State, 1, "Q_Values");
      for A in 1 .. Model.N_Actions loop
         Row (A) := Q_Unchecked (Model, Values, State_Index (State), A);
      end loop;
      return Row;
   end Q_Values;

   function Bellman_Backup
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive) return Real
   is
   begin
      Validate_MDP (Model, "Bellman_Backup");
      Check_Values (Model, Values, "Bellman_Backup");
      Check_Index (Model, State, 1, "Bellman_Backup");
      return Backup_Unchecked (Model, Values, State_Index (State));
   end Bellman_Backup;

   function Bellman_Operator
     (Model  : MDP;
      Values : Value_Function) return Value_Function
   is
      V : Value_Function (1 .. Model.N_States);
   begin
      Validate_MDP (Model, "Bellman_Operator");
      Check_Values (Model, Values, "Bellman_Operator");
      for S in 1 .. Model.N_States loop
         V (S) := Backup_Unchecked (Model, Values, S);
      end loop;
      return V;
   end Bellman_Operator;

   function Greedy_Action
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive) return Action_Index
   is
   begin
      Validate_MDP (Model, "Greedy_Action");
      Check_Values (Model, Values, "Greedy_Action");
      Check_Index (Model, State, 1, "Greedy_Action");
      return Greedy_Unchecked (Model, Values, State_Index (State));
   end Greedy_Action;

   function Greedy_Policy
     (Model  : MDP; Values : Value_Function) return Policy_Vector
   is
      Pi : Policy_Vector (1 .. Model.N_States);
   begin
      Validate_MDP (Model, "Greedy_Policy");
      Check_Values (Model, Values, "Greedy_Policy");
      for S in 1 .. Model.N_States loop
         Pi (S) := Greedy_Unchecked (Model, Values, S);
      end loop;
      return Pi;
   end Greedy_Policy;

   function Bellman_Residual
     (Model  : MDP; Values : Value_Function) return Real
   is
      Best : Real := 0.0;
      D    : Real;
   begin
      Validate_MDP (Model, "Bellman_Residual");
      Check_Values (Model, Values, "Bellman_Residual");
      for S in 1 .. Model.N_States loop
         D := abs (Values (S) - Backup_Unchecked (Model, Values, S));
         if D > Best then
            Best := D;
         end if;
      end loop;
      return Best;
   end Bellman_Residual;

   function Iterate
     (Model  : MDP;
      Values : Value_Function;
      Sweeps : Positive := 1) return Value_Function
   is
      V : Value_Function (1 .. Model.N_States);
   begin
      Validate_MDP (Model, "Iterate");
      Check_Values (Model, Values, "Iterate");
      V := Values;
      for K in 1 .. Sweeps loop
         V := Bellman_Operator (Model, V);
      end loop;
      return V;
   end Iterate;

   function Solve_From
     (Model     : MDP;
      Start     : Value_Function;
      Epsilon   : Real     := Default_Epsilon;
      Max_Iters : Positive := Default_Max_Iters) return Solution
   is
      V     : Value_Function (1 .. Model.N_States);
      V_New : Value_Function (1 .. Model.N_States);
      Res   : Real;
      It    : Natural := 0;
   begin
      Validate_MDP (Model, "Solve_From");
      Check_Values (Model, Start, "Solve_From");
      if Epsilon < 0.0 then
         Raise_Bad ("Solve_From: Epsilon must be >= 0");
      end if;
      V := Start;
      loop
         V_New := Bellman_Operator (Model, V);
         Res   := 0.0;
         for S in 1 .. Model.N_States loop
            declare
               D : constant Real := abs (V_New (S) - V (S));
            begin
               if D > Res then
                  Res := D;
               end if;
            end;
         end loop;
         V  := V_New;
         It := It + 1;
         exit when Res < Epsilon or else It >= Max_Iters;
      end loop;
      declare
         Leftover : constant Real := Bellman_Residual (Model, V);
         Out_S    : Solution (N_States => Model.N_States);
      begin
         Out_S.Values     := V;
         Out_S.Policy     := Greedy_Policy (Model, V);
         Out_S.Iterations := It;
         Out_S.Residual   := Leftover;
         Out_S.Converged  := Leftover < Epsilon;
         return Out_S;
      end;
   end Solve_From;

   function Solve
     (Model     : MDP;
      Epsilon   : Real     := Default_Epsilon;
      Max_Iters : Positive := Default_Max_Iters) return Solution
   is
   begin
      Validate_MDP (Model, "Solve");
      return Solve_From
        (Model, Zero_Values (Model.N_States), Epsilon, Max_Iters);
   end Solve;

   function Evaluate_Policy
     (Model     : MDP;
      Policy    : Policy_Vector;
      Epsilon   : Real     := Default_Epsilon;
      Max_Iters : Positive := Default_Max_Iters) return Value_Function
   is
      V     : Value_Function (1 .. Model.N_States) := [others => 0.0];
      V_New : Value_Function (1 .. Model.N_States);
      Res   : Real;
      It    : Natural := 0;
   begin
      Validate_MDP (Model, "Evaluate_Policy");
      if Epsilon < 0.0 then
         Raise_Bad ("Evaluate_Policy: Epsilon must be >= 0");
      end if;
      if Policy'First /= 1
        or else Policy'Last /= State_Index (Model.N_States)
      then
         Raise_Bad ("Evaluate_Policy: policy has the wrong length");
      end if;
      for S in 1 .. Model.N_States loop
         if Policy (S) > Action_Index (Model.N_Actions) then
            Raise_Bad ("Evaluate_Policy: illegal action in policy");
         end if;
      end loop;
      loop
         for S in 1 .. Model.N_States loop
            V_New (S) := Q_Unchecked (Model, V, S, Policy (S));
         end loop;
         Res := 0.0;
         for S in 1 .. Model.N_States loop
            declare
               D : constant Real := abs (V_New (S) - V (S));
            begin
               if D > Res then
                  Res := D;
               end if;
            end;
         end loop;
         V  := V_New;
         It := It + 1;
         exit when Res < Epsilon or else It >= Max_Iters;
      end loop;
      return V;
   end Evaluate_Policy;

   -------------------------------------------------------------------------
   -- Classroom constructors
   -------------------------------------------------------------------------

   function Tiny_Chain
     (Length : Positive := 3;
      Gamma  : Real     := 0.9) return MDP
   is
   begin
      if Length < 2 then
         Raise_Bad ("Tiny_Chain: Length must be >= 2");
      end if;
      Check_Dims (Length, 2, "Tiny_Chain");
      Check_Gamma (Gamma, "Tiny_Chain");
      declare
         Goal : constant State_Index := State_Index (Length);
         M    : MDP (N_States => State_Count (Length), N_Actions => 2);
      begin
      M.P      := [others => [others => [others => 0.0]]];
      M.R      := [others => [others => [others => 0.0]]];
      M.Gamma  := Gamma;

      for S in 1 .. M.N_States loop
         if S = Goal then
            --  Absorbing goal: both actions stay, reward 0.
            M.P (S, 1, S) := 1.0;
            M.P (S, 2, S) := 1.0;
         else
            --  Left = 1: toward 1, bounce at the start.
            if S = 1 then
               M.P (S, 1, S) := 1.0;
            else
               M.P (S, 1, S - 1) := 1.0;
            end if;
            --  Right = 2: toward the goal; +1 on first entry.
            M.P (S, 2, S + 1) := 1.0;
            if S + 1 = Goal then
               M.R (S, 2, S + 1) := 1.0;
            end if;
         end if;
      end loop;
      return M;
      end;
   end Tiny_Chain;

   function Absorbing_Goal
     (Gamma  : Real    := 0.9;
      Living : Boolean := False) return MDP
   is
      M : MDP (N_States => 2, N_Actions => 2);
   begin
      Check_Gamma (Gamma, "Absorbing_Goal");
      M.P     := [others => [others => [others => 0.0]]];
      M.R     := [others => [others => [others => 0.0]]];
      M.Gamma := Gamma;
      --  s1 Stay → s1, r = 0.
      M.P (1, 1, 1) := 1.0;
      --  s1 Go → s2, r = 1.
      M.P (1, 2, 2) := 1.0;
      M.R (1, 2, 2) := 1.0;
      --  s2 absorbing.
      M.P (2, 1, 2) := 1.0;
      M.P (2, 2, 2) := 1.0;
      if Living then
         M.R (2, 1, 2) := 1.0;
         M.R (2, 2, 2) := 1.0;
      end if;
      return M;
   end Absorbing_Goal;

   function Cell (Row, Col : Positive) return State_Index is
   begin
      return State_Index ((Row - 1) * 3 + Col);
   end Cell;

   procedure Clip (Row, Col : in out Integer) is
   begin
      if Row < 1 then
         Row := 1;
      elsif Row > 3 then
         Row := 3;
      end if;
      if Col < 1 then
         Col := 1;
      elsif Col > 3 then
         Col := 3;
      end if;
   end Clip;

   --  Action 1=N, 2=E, 3=S, 4=W.  Perpendiculars: N↔{W,E}, E↔{N,S}, …
   function D_Row (A : Action_Index) return Integer is
   begin
      case A is
         when 1 => return -1;
         when 3 => return 1;
         when others => return 0;
      end case;
   end D_Row;

   function D_Col (A : Action_Index) return Integer is
   begin
      case A is
         when 2 => return 1;
         when 4 => return -1;
         when others => return 0;
      end case;
   end D_Col;

   function Perp_A (A : Action_Index) return Action_Index is
   begin
      case A is
         when 1 => return 4;  -- N → W
         when 2 => return 1;  -- E → N
         when 3 => return 2;  -- S → E
         when 4 => return 3;  -- W → S
         when others => return 1;
      end case;
   end Perp_A;

   function Perp_B (A : Action_Index) return Action_Index is
   begin
      case A is
         when 1 => return 2;  -- N → E
         when 2 => return 3;  -- E → S
         when 3 => return 4;  -- S → W
         when 4 => return 1;  -- W → N
         when others => return 1;
      end case;
   end Perp_B;

   procedure Add_Move
     (M        : in out MDP;
      From     : State_Index;
      Action   : Action_Index;
      Row, Col : Integer;
      Prob     : Probability;
      Goal     : State_Index;
      Pit      : State_Index;
      Has_Pit  : Boolean;
      Step     : Reward)
   is
      RR : Integer := Row;
      CC : Integer := Col;
      To : State_Index;
      Rv : Reward;
   begin
      Clip (RR, CC);
      To := Cell (Positive (RR), Positive (CC));
      if To = Goal then
         Rv := 1.0;
      elsif Has_Pit and then To = Pit then
         Rv := -1.0;
      else
         Rv := Step;
      end if;
      M.P (From, Action, To) := M.P (From, Action, To) + Prob;
      --  Reward is a probability-weighted average if several outcomes
      --  share a cell (bounce + intended).  Accumulate R * P, divide later.
      M.R (From, Action, To) := M.R (From, Action, To) + Prob * Rv;
   end Add_Move;

   function Gridworld_3x3
     (Gamma     : Real    := 0.9;
      Step_Cost : Real    := 0.0;
      Slip      : Real    := 0.0;
      Use_Pit   : Boolean := True) return MDP
   is
      M    : MDP (N_States => 9, N_Actions => 4);
      Goal : constant State_Index := 9;
      Pit  : constant State_Index := 7;
   begin
      Check_Gamma (Gamma, "Gridworld_3x3");
      if Slip < 0.0 or else Slip > 1.0 then
         Raise_Bad ("Gridworld_3x3: Slip must be in [0, 1]");
      end if;
      M.P     := [others => [others => [others => 0.0]]];
      M.R     := [others => [others => [others => 0.0]]];
      M.Gamma := Gamma;

      for Row in 1 .. 3 loop
         for Col in 1 .. 3 loop
            declare
               S : constant State_Index := Cell (Row, Col);
            begin
               if S = Goal or else (Use_Pit and then S = Pit) then
                  for A in 1 .. M.N_Actions loop
                     M.P (S, A, S) := 1.0;
                     M.R (S, A, S) := 0.0;
                  end loop;
               else
                  for A in 1 .. M.N_Actions loop
                     if Slip = 0.0 then
                        Add_Move
                          (M, S, A, Row + D_Row (A), Col + D_Col (A),
                           1.0, Goal, Pit, Use_Pit, Step_Cost);
                     else
                        Add_Move
                          (M, S, A, Row + D_Row (A), Col + D_Col (A),
                           1.0 - Slip, Goal, Pit, Use_Pit, Step_Cost);
                        Add_Move
                          (M, S, A,
                           Row + D_Row (Perp_A (A)), Col + D_Col (Perp_A (A)),
                           Slip / 2.0, Goal, Pit, Use_Pit, Step_Cost);
                        Add_Move
                          (M, S, A,
                           Row + D_Row (Perp_B (A)), Col + D_Col (Perp_B (A)),
                           Slip / 2.0, Goal, Pit, Use_Pit, Step_Cost);
                     end if;
                     --  Convert accumulated (P * r) into the mean reward
                     --  stored at each successor: R := (sum p r) / P.
                     for Sp in 1 .. M.N_States loop
                        if M.P (S, A, Sp) > 0.0 then
                           M.R (S, A, Sp) := M.R (S, A, Sp) / M.P (S, A, Sp);
                        end if;
                     end loop;
                  end loop;
               end if;
            end;
         end loop;
      end loop;
      return M;
   end Gridworld_3x3;

   function Gambler_Toy
     (Goal_Capital : Positive := 4;
      P_Heads      : Real     := 0.5;
      Gamma        : Real     := 0.99) return MDP
   is
   begin
      if Goal_Capital < 2 then
         Raise_Bad ("Gambler_Toy: Goal_Capital must be >= 2");
      end if;
      Check_Gamma (Gamma, "Gambler_Toy");
      if P_Heads < 0.0 or else P_Heads > 1.0 then
         Raise_Bad ("Gambler_Toy: P_Heads must be in [0, 1]");
      end if;

      declare
         N_S     : constant Positive := Goal_Capital + 1;
         Max_Bet : constant Positive := Goal_Capital / 2;
      begin
         Check_Dims (N_S, Max_Bet, "Gambler_Toy");

         declare
            M : MDP
              (N_States  => State_Count (N_S),
               N_Actions => Action_Count (Max_Bet));
            Goal_S : constant State_Index := State_Index (N_S);
         begin
            M.P     := [others => [others => [others => 0.0]]];
            M.R     := [others => [others => [others => 0.0]]];
            M.Gamma := Gamma;

            for S in 1 .. M.N_States loop
               declare
                  Cap : constant Natural := Natural (S) - 1;
               begin
                  if S = 1 or else S = Goal_S then
                     for A in 1 .. M.N_Actions loop
                        M.P (S, A, S) := 1.0;
                     end loop;
                  else
                     for A in 1 .. M.N_Actions loop
                        declare
                           Bet : constant Positive := Positive (A);
                        begin
                           if Bet > Cap or else Bet > Goal_Capital - Cap then
                              M.P (S, A, S) := 1.0;
                           else
                              declare
                                 Win_Cap  : constant Natural := Cap + Bet;
                                 Lose_Cap : constant Natural := Cap - Bet;
                                 Win_S    : constant State_Index :=
                                   State_Index (Win_Cap + 1);
                                 Lose_S   : constant State_Index :=
                                   State_Index (Lose_Cap + 1);
                              begin
                                 if Win_S = Lose_S then
                                    M.P (S, A, Win_S) := 1.0;
                                 else
                                    M.P (S, A, Win_S)  := P_Heads;
                                    M.P (S, A, Lose_S) := 1.0 - P_Heads;
                                 end if;
                                 if Win_S = Goal_S then
                                    M.R (S, A, Win_S) := 1.0;
                                 end if;
                              end;
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end loop;
            return M;
         end;
      end;
   end Gambler_Toy;

end Value_Iteration;
