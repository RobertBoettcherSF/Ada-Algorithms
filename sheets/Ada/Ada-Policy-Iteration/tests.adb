--  Standalone test suite for Policy_Iteration.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Policy_Iteration; use Policy_Iteration;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Rf (X : Real) return Real is (X);
   function Nat (X : Natural) return Natural is (X);
   function Pos (X : Positive) return Positive is (X);
   function Ai (X : Action_Index) return Action_Index is (X);

   function Pow (Base : Real; N : Natural) return Real is
      Acc : Real := 1.0;
   begin
      for K in 1 .. N loop
         Acc := Acc * Base;
      end loop;
      return Acc;
   end Pow;

   --  Independent value-iteration reimplementation (no `with` of the
   --  Value_Iteration sibling) for cross-checking optimal values.
   function Independent_VI
     (Model     : MDP;
      Epsilon   : Real := 1.0E-10;
      Max_Iters : Positive := 20_000) return Value_Function
   is
      V     : Value_Function (1 .. Model.N_States) := [others => 0.0];
      V_New : Value_Function (1 .. Model.N_States);
      Res   : Real;
      It    : Natural := 0;
   begin
      loop
         for S in 1 .. Model.N_States loop
            declare
               Best : Real := Real'First;
            begin
               for A in 1 .. Model.N_Actions loop
                  declare
                     Q : Real := 0.0;
                  begin
                     for Sp in 1 .. Model.N_States loop
                        Q := Q + Model.P (S, A, Sp)
                          * (Model.R (S, A, Sp) + Model.Gamma * V (Sp));
                     end loop;
                     if Q > Best then
                        Best := Q;
                     end if;
                  end;
               end loop;
               V_New (S) := Best;
            end;
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
   end Independent_VI;

   ---------------------------------------------------------------------------
   -- Exception helpers
   ---------------------------------------------------------------------------

   function Near_Raises (Tol : Real) return Boolean is
      Unused : Boolean;
   begin
      Unused := Near (0.0, 0.0, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Near_Raises;

   function Near_Values_Raises_Len return Boolean is
      A : constant Value_Function (1 .. 2) := [others => 0.0];
      B : constant Value_Function (1 .. 3) := [others => 0.0];
      Unused : Boolean;
   begin
      Unused := Near_Values (A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Near_Values_Raises_Len;

   function Same_Policy_Raises_Len return Boolean is
      A : constant Policy_Vector (1 .. 2) := [others => 1];
      B : constant Policy_Vector (1 .. 3) := [others => 1];
      Unused : Boolean;
   begin
      Unused := Same_Policy (A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Same_Policy_Raises_Len;

   function Empty_Raises (NS, NA : Positive; G : Real) return Boolean is
      Unused : MDP (0, 0);
      pragma Unreferenced (Unused);
   begin
      declare
         M : constant MDP := Empty_MDP (NS, NA, G);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Raises;

   function Set_P_Raises
     (NS, NA, S, A, Sp : Positive; Prob : Real) return Boolean
   is
      M : MDP := Empty_MDP (NS, NA, 0.5);
   begin
      Set_Transition (M, S, A, Sp, Prob);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_P_Raises;

   function Set_R_Raises
     (NS, NA, S, A, Sp : Positive) return Boolean
   is
      M : MDP := Empty_MDP (NS, NA, 0.5);
   begin
      Set_Reward (M, S, A, Sp, 0.0);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_R_Raises;

   function Make_Raises_Gamma (G : Real) return Boolean is
      P : constant Transition_Tensor (1 .. 1, 1 .. 1, 1 .. 1) :=
        [others => [others => [others => 1.0]]];
      R : constant Reward_Tensor (1 .. 1, 1 .. 1, 1 .. 1) :=
        [others => [others => [others => 0.0]]];
   begin
      declare
         M : constant MDP := Make_MDP (P, R, G);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Raises_Gamma;

   function Make_Raises_Nonstoch return Boolean is
      P : Transition_Tensor (1 .. 2, 1 .. 1, 1 .. 2) :=
        [others => [others => [others => 0.0]]];
      R : constant Reward_Tensor (1 .. 2, 1 .. 1, 1 .. 2) :=
        [others => [others => [others => 0.0]]];
   begin
      P (1, 1, 1) := 1.0;
      P (2, 1, 1) := 0.4;
      P (2, 1, 2) := 0.4;
      declare
         M : constant MDP := Make_MDP (P, R, 0.5);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Raises_Nonstoch;

   function Make_Raises_Neg_P return Boolean is
      P : constant Transition_Tensor (1 .. 1, 1 .. 1, 1 .. 1) :=
        [others => [others => [others => -0.1]]];
      R : constant Reward_Tensor (1 .. 1, 1 .. 1, 1 .. 1) :=
        [others => [others => [others => 0.0]]];
   begin
      declare
         M : constant MDP := Make_MDP (P, R, 0.5);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Raises_Neg_P;

   function Chain_Raises (L : Positive; G : Real) return Boolean is
   begin
      declare
         M : constant MDP := Tiny_Chain (L, G);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Chain_Raises;

   function Goal_Raises (G : Real) return Boolean is
   begin
      declare
         M : constant MDP := Absorbing_Goal (G);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Goal_Raises;

   function Grid_Raises (G, Slip : Real) return Boolean is
   begin
      declare
         M : constant MDP :=
           Gridworld_3x3 (Gamma => G, Slip => Slip, Use_Pit => False);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Grid_Raises;

   function Gambler_Raises
     (Goal : Positive; P_H, G : Real) return Boolean
   is
   begin
      declare
         M : constant MDP := Gambler_Toy (Goal, P_H, G);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument | Constraint_Error =>
         return True;
   end Gambler_Raises;

   function Q_Raises_State return Boolean is
      M : constant MDP := Absorbing_Goal;
      V : constant Value_Function (1 .. 2) := [others => 0.0];
      Unused : Real;
   begin
      Unused := Q_Value (M, V, 3, 1);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Q_Raises_State;

   function Q_Raises_Values return Boolean is
      M : constant MDP := Absorbing_Goal;
      V : constant Value_Function (1 .. 3) := [others => 0.0];
      Unused : Real;
   begin
      Unused := Q_Value (M, V, 1, 1);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Q_Raises_Values;

   function Solve_Raises_Eps return Boolean is
      M : constant MDP := Absorbing_Goal;
   begin
      declare
         S : constant Solution := Solve (M, Epsilon => -1.0E-6);
         pragma Unreferenced (S);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Solve_Raises_Eps;

   function Solve_Raises_Invalid return Boolean is
      M : constant MDP := Empty_MDP (2, 2, 0.5);
   begin
      declare
         S : constant Solution := Solve (M);
         pragma Unreferenced (S);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Solve_Raises_Invalid;

   function Eval_Raises_Bad_Pi return Boolean is
      M  : constant MDP := Absorbing_Goal;
      Pi : Policy_Vector (1 .. 2) := [1 => 1, 2 => 1];
   begin
      Pi (1) := 7;
      declare
         V : constant Value_Function := Evaluate_Policy (M, Pi);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Eval_Raises_Bad_Pi;

   function Eval_Raises_Len return Boolean is
      M  : constant MDP := Absorbing_Goal;
      Pi : constant Policy_Vector (1 .. 3) := [others => 1];
   begin
      declare
         V : constant Value_Function := Evaluate_Policy (M, Pi);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Eval_Raises_Len;

   function Eval_Raises_Eps return Boolean is
      M  : constant MDP := Absorbing_Goal;
      Pi : constant Policy_Vector (1 .. 2) := [others => 1];
   begin
      declare
         V : constant Value_Function :=
           Evaluate_Policy (M, Pi, Mode => Iterative, Epsilon => -0.1);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Eval_Raises_Eps;

   function Stoch_Raises_Idx return Boolean is
      M : constant MDP := Absorbing_Goal;
      Unused : Boolean;
   begin
      Unused := Is_Stochastic (M, 9, 1);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Stoch_Raises_Idx;

   function Trans_Raises return Boolean is
      M : constant MDP := Absorbing_Goal;
      Unused : Probability;
   begin
      Unused := Transition (M, 1, 1, 9);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Trans_Raises;

   function Valid_Raises_Tol return Boolean is
      M : constant MDP := Absorbing_Goal;
      Unused : Boolean;
   begin
      Unused := Is_Valid_MDP (M, Tol => -0.1);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Valid_Raises_Tol;

   ---------------------------------------------------------------------------
   -- Tests
   ---------------------------------------------------------------------------

   procedure Test_Near is
   begin
      Section ("Near / Near_Values / Same_Policy");
      Check (Near (Rf (1.0), Rf (1.0)), "Near equal");
      Check (Near (Rf (1.0), Rf (1.0) + 1.0E-12), "Near tiny delta");
      Check (not Near (Rf (1.0), Rf (2.0)), "Near rejects large delta");
      Check (Near (Rf (-3.5), Rf (-3.5), Rf (0.0)), "Near zero tol equal");
      Check (not Near (Rf (0.0), Rf (1.0E-8), Rf (1.0E-12)),
             "Near tight tol rejects");
      Check (Near_Raises (Rf (-1.0)), "Near negative tol raises");
      declare
         A : constant Value_Function (1 .. 3) := [1.0, 2.0, 3.0];
         B : constant Value_Function (1 .. 3) := [1.0, 2.0, 3.0];
         C : constant Value_Function (1 .. 3) := [1.0, 2.1, 3.0];
         P1 : constant Policy_Vector (1 .. 3) := [1, 2, 1];
         P2 : constant Policy_Vector (1 .. 3) := [1, 2, 1];
         P3 : constant Policy_Vector (1 .. 3) := [1, 1, 1];
      begin
         Check (Near_Values (A, B), "Near_Values equal");
         Check (not Near_Values (A, C, Rf (0.01)), "Near_Values mismatch");
         Check (Near_Values (A, C, Rf (0.2)), "Near_Values loose tol");
         Check (Same_Policy (P1, P2), "Same_Policy equal");
         Check (not Same_Policy (P1, P3), "Same_Policy mismatch");
      end;
      Check (Near_Values_Raises_Len, "Near_Values length mismatch raises");
      Check (Same_Policy_Raises_Len, "Same_Policy length mismatch raises");
   end Test_Near;

   procedure Test_Builders_And_Validation is
   begin
      Section ("Builders / validation");
      Check (Empty_Raises (Pos (33), Pos (2), Rf (0.5)),
             "Empty_MDP oversize states raises");
      Check (Empty_Raises (Pos (2), Pos (9), Rf (0.5)),
             "Empty_MDP oversize actions raises");
      Check (Empty_Raises (Pos (2), Pos (2), Rf (1.0)),
             "Empty_MDP gamma=1 raises");
      Check (Empty_Raises (Pos (2), Pos (2), Rf (-0.1)),
             "Empty_MDP gamma<0 raises");
      Check (Empty_Raises (Pos (2), Pos (2), Rf (1.5)),
             "Empty_MDP gamma>1 raises");

      declare
         M : MDP := Empty_MDP (Pos (2), Pos (2), Rf (0.8));
      begin
         Check (not Is_Valid_MDP (M), "empty tensors not valid");
         Check (M.N_States = 2, "Empty_MDP N_States");
         Check (M.N_Actions = 2, "Empty_MDP N_Actions");
         Check (Near (M.Gamma, Rf (0.8)), "Empty_MDP Gamma");
         Set_Deterministic (M, 1, 1, 1, 0.0);
         Set_Deterministic (M, 1, 2, 2, 1.0);
         Set_Deterministic (M, 2, 1, 2, 0.0);
         Set_Deterministic (M, 2, 2, 2, 0.0);
         Check (Is_Valid_MDP (M), "filled Empty_MDP is valid");
         Check (Is_Stochastic (M, 1, 1), "row (1,1) stochastic");
         Check (Is_Stochastic (M, 1, 2), "row (1,2) stochastic");
         Check (Near (Transition (M, 1, 2, 2), Rf (1.0)), "Go is deterministic");
         Check (Near (Reward_Of (M, 1, 2, 2), Rf (1.0)), "Go reward 1");
         Check (Near (Expected_Reward (M, 1, 2), Rf (1.0)), "E[R|1,Go]=1");
         Check (Near (Expected_Reward (M, 1, 1), Rf (0.0)), "E[R|1,Stay]=0");
         Set_Reward_SA (M, 2, 1, 0.25);
         Check (Near (Reward_Of (M, 2, 1, 1), Rf (0.25)), "Set_Reward_SA s'=1");
         Check (Near (Reward_Of (M, 2, 1, 2), Rf (0.25)), "Set_Reward_SA s'=2");
      end;

      Check (Set_P_Raises (2, 2, 3, 1, 1, 1.0), "Set_P bad state raises");
      Check (Set_P_Raises (2, 2, 1, 3, 1, 1.0), "Set_P bad action raises");
      Check (Set_P_Raises (2, 2, 1, 1, 3, 1.0), "Set_P bad next raises");
      Check (Set_P_Raises (2, 2, 1, 1, 1, -0.2), "Set_P negative p raises");
      Check (Set_R_Raises (2, 2, 1, 1, 4), "Set_R bad next raises");
      Check (Make_Raises_Gamma (Rf (1.0)), "Make_MDP gamma=1 raises");
      Check (Make_Raises_Gamma (Rf (-0.01)), "Make_MDP gamma<0 raises");
      Check (Make_Raises_Nonstoch, "Make_MDP non-stochastic raises");
      Check (Make_Raises_Neg_P, "Make_MDP negative p raises");
      Check (Valid_Raises_Tol, "Is_Valid_MDP negative tol raises");
      Check (Stoch_Raises_Idx, "Is_Stochastic bad index raises");
      Check (Trans_Raises, "Transition bad next raises");
   end Test_Builders_And_Validation;

   procedure Test_Make_MDP_SA is
      P : Transition_Tensor (1 .. 2, 1 .. 2, 1 .. 2) :=
        [others => [others => [others => 0.0]]];
      R : Reward_SA_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
   begin
      Section ("Make_MDP / Make_MDP_SA");
      P (1, 1, 1) := 1.0;
      P (1, 2, 2) := 1.0;
      P (2, 1, 2) := 1.0;
      P (2, 2, 2) := 1.0;
      R (1, 1) := 0.0;
      R (1, 2) := 5.0;
      R (2, 1) := 0.0;
      R (2, 2) := 0.0;
      declare
         M : constant MDP := Make_MDP_SA (P, R, 0.5);
         V : constant Value_Function (1 .. 2) := [others => 0.0];
      begin
         Check (Is_Valid_MDP (M), "Make_MDP_SA valid");
         Check (Near (Q_Value (M, V, 1, 2), Rf (5.0)), "R(s,a) form Q");
         Check (Near (Reward_Of (M, 1, 2, 1), Rf (5.0)), "broadcast R to s'=1");
         Check (Near (Reward_Of (M, 1, 2, 2), Rf (5.0)), "broadcast R to s'=2");
      end;
      declare
         Rt : Reward_Tensor (1 .. 2, 1 .. 2, 1 .. 2) :=
           [others => [others => [others => 0.0]]];
      begin
         Rt (1, 2, 2) := 5.0;
         declare
            M : constant MDP := Make_MDP (P, Rt, 0.5);
            V : constant Value_Function (1 .. 2) := [others => 0.0];
         begin
            Check (Is_Valid_MDP (M), "Make_MDP valid");
            Check (Near (Q_Value (M, V, 1, 2), Rf (5.0)), "R(s,a,s') form Q");
            Check (Near (Reward_Of (M, 1, 2, 1), Rf (0.0)), "unspecified s' is 0");
         end;
      end;
   end Test_Make_MDP_SA;

   procedure Test_Absorbing is
   begin
      Section ("Absorbing_Goal");
      declare
         M : constant MDP := Absorbing_Goal (0.9);
         S : constant Solution := Solve (M);
         Z : constant Value_Function (1 .. 2) := [others => 0.0];
      begin
         Check (Is_Valid_MDP (M), "Absorbing_Goal valid");
         Check (S.Converged, "Absorbing_Goal converged");
         Check (S.Iterations >= Nat (1), "Absorbing_Goal did >=1 outer");
         Check (Near (S.Values (1), Rf (1.0), 1.0E-6), "V*(1)=1");
         Check (Near (S.Values (2), Rf (0.0), 1.0E-6), "V*(2)=0");
         Check (S.Policy (1) = Ai (2), "pi*(1)=Go");
         Check (Near (Q_Value (M, Z, 1, 1), Rf (0.0)), "Q(1,Stay;0)=0");
         Check (Near (Q_Value (M, Z, 1, 2), Rf (1.0)), "Q(1,Go;0)=1");
         Check (Greedy_Action (M, Z, 1) = Ai (2), "greedy from 0 is Go");
         Check (Near (Policy_Residual (M, S.Values, S.Policy), Rf (0.0), 1.0E-6),
                "||V*-T^pi V*|| ~ 0");
      end;
      declare
         M : constant MDP := Absorbing_Goal (0.8, Living => True);
         S : constant Solution := Solve (M);
         Live : constant Real := 1.0 / (1.0 - 0.8);
      begin
         Check (S.Converged, "living goal converged");
         Check (Near (S.Values (2), Live, 1.0E-5), "V*(2)=1/(1-g)");
         Check (Near (S.Values (1), 1.0 + 0.8 * Live, 1.0E-5),
                "V*(1)=1+g/(1-g)");
         Check (S.Policy (1) = Ai (2), "living pi*(1)=Go");
      end;
      Check (Goal_Raises (Rf (1.0)), "Absorbing_Goal gamma=1 raises");
      Check (Goal_Raises (Rf (-0.2)), "Absorbing_Goal gamma<0 raises");
   end Test_Absorbing;

   procedure Test_Tiny_Chain is
      Gammas : constant array (1 .. 4) of Real := [0.0, 0.5, 0.9, 0.99];
   begin
      Section ("Tiny_Chain");
      Check (Chain_Raises (Pos (1), Rf (0.9)), "Tiny_Chain L=1 raises");
      Check (Chain_Raises (Pos (3), Rf (1.0)), "Tiny_Chain gamma=1 raises");
      Check (Chain_Raises (Pos (3), Rf (-0.01)), "Tiny_Chain gamma<0 raises");

      for L in 2 .. 5 loop
         declare
            M : constant MDP := Tiny_Chain (L, 0.9);
            S : constant Solution := Solve (M);
         begin
            Check (Is_Valid_MDP (M),
                   "chain L=" & L'Image & " valid");
            Check (S.Converged,
                   "chain L=" & L'Image & " converged");
            Check (M.N_States = State_Count (L),
                   "chain L=" & L'Image & " N_States");
            Check (M.N_Actions = 2,
                   "chain L=" & L'Image & " N_Actions");
            Check (Near (S.Values (State_Index (L)), Rf (0.0), 1.0E-6),
                   "chain L=" & L'Image & " V(goal)=0");
            Check (S.Policy (State_Index (L)) = Ai (1),
                   "chain L=" & L'Image & " goal ties to action 1");
            for K in 1 .. L - 1 loop
               declare
                  Exp : constant Real := Pow (0.9, L - 1 - K);
               begin
                  Check (Near (S.Values (State_Index (K)), Exp, 1.0E-5),
                         "chain L=" & L'Image
                         & " V(" & K'Image & ")");
                  Check (S.Policy (State_Index (K)) = Ai (2),
                         "chain L=" & L'Image
                         & " pi(" & K'Image & ")=Right");
               end;
            end loop;
         end;
      end loop;

      for Gi in Gammas'Range loop
         declare
            G : constant Real := Gammas (Gi);
            M : constant MDP := Tiny_Chain (4, G);
            S : constant Solution := Solve (M);
         begin
            Check (S.Converged, "chain-4 gamma sweep converged");
            Check (Near (S.Values (3), Rf (1.0), 1.0E-5),
                   "chain-4 V(3)=1 at gamma");
            Check (Near (S.Values (2), G, 1.0E-5),
                   "chain-4 V(2)=gamma");
            Check (Near (S.Values (1), G * G, 1.0E-5),
                   "chain-4 V(1)=gamma^2");
         end;
      end loop;
   end Test_Tiny_Chain;

   procedure Test_Q_And_Greedy is
      M : constant MDP := Tiny_Chain (3, 0.9);
      Z : constant Value_Function (1 .. 3) := [others => 0.0];
      S : constant Solution := Solve (M);
   begin
      Section ("Q_Value / Greedy / Improve");
      Check (Near (Q_Value (M, Z, 2, 2), Rf (1.0)), "Q(2,Right;0)=1");
      Check (Near (Q_Value (M, Z, 2, 1), Rf (0.0)), "Q(2,Left;0)=0");
      Check (Near (Q_Value (M, Z, 1, 2), Rf (0.0)), "Q(1,Right;0)=0");
      Check (Greedy_Action (M, Z, 2) = Ai (2), "greedy(2;0)=Right");
      declare
         Row : constant Q_Row := Q_Values (M, S.Values, 2);
         Pi  : constant Policy_Vector := Improve_Policy (M, S.Values);
         Gp  : constant Policy_Vector := Greedy_Policy (M, S.Values);
      begin
         Check (Row'First = 1 and then Row'Last = 2, "Q_Row bounds");
         Check (Row (2) >= Row (1), "Q(2,Right) >= Q(2,Left) at V*");
         Check (Near (Row (2), S.Values (2), 1.0E-6),
                "max Q(2,·)=V*(2)");
         Check (Same_Policy (Pi, Gp), "Improve_Policy = Greedy_Policy");
         Check (Same_Policy (Pi, S.Policy), "Improve on V* is stable");
      end;
      Check (Q_Raises_State, "Q_Value bad state raises");
      Check (Q_Raises_Values, "Q_Value bad V length raises");
   end Test_Q_And_Greedy;

   procedure Test_Evaluate_Exact_Vs_Iterative is
      M  : constant MDP := Tiny_Chain (5, 0.9);
      Pi : constant Policy_Vector :=
        [1 => 2, 2 => 2, 3 => 2, 4 => 2, 5 => 1];
   begin
      Section ("Evaluate_Policy Exact vs Iterative");
      declare
         Ve : constant Value_Function :=
           Evaluate_Policy (M, Pi, Mode => Exact);
         Vi : constant Value_Function :=
           Evaluate_Policy (M, Pi, Mode => Iterative, Epsilon => 1.0E-12);
      begin
         Check (Near_Values (Ve, Vi, 1.0E-6), "Exact ≈ Iterative on optimal pi");
         Check (Near (Ve (4), Rf (1.0), 1.0E-8), "Exact V(4)=1");
         Check (Near (Ve (3), Rf (0.9), 1.0E-8), "Exact V(3)=0.9");
         Check (Near (Policy_Residual (M, Ve, Pi), Rf (0.0), 1.0E-8),
                "Exact residual ~ 0");
      end;
      declare
         Bad : constant Policy_Vector (1 .. 5) := [others => 1];
         Ve  : constant Value_Function :=
           Evaluate_Policy (M, Bad, Mode => Exact);
      begin
         Check (Near (Ve (5), Rf (0.0), 1.0E-8), "always-Left V(goal)=0");
         Check (Near (Ve (1), Rf (0.0), 1.0E-8), "always-Left never scores");
      end;
      Check (Eval_Raises_Bad_Pi, "Evaluate_Policy illegal action raises");
      Check (Eval_Raises_Len, "Evaluate_Policy bad length raises");
      Check (Eval_Raises_Eps, "Evaluate_Policy negative eps raises");
   end Test_Evaluate_Exact_Vs_Iterative;

   procedure Test_Iterate_And_Solve is
      M : constant MDP := Tiny_Chain (4, 0.9);
   begin
      Section ("Iterate / Solve / Solve_From");
      declare
         Pi0 : constant Policy_Vector := Initial_Policy (M);
         One : constant Solution := Iterate (M, Pi0);
         Full : constant Solution := Solve (M);
      begin
         Check (Pi0 (1) = Ai (1), "Initial_Policy is action 1");
         Check (One.Iterations = Nat (1), "Iterate reports 1 outer");
         Check (Full.Converged, "Solve converged");
         Check (Full.Iterations >= Nat (1), "Solve >=1 outer");
         Check (Full.Iterations <= Nat (10), "Solve few outers on chain");
         Check (Near (Full.Values (3), Rf (1.0), 1.0E-6), "Solve V(3)=1");
         Check (Full.Policy (1) = Ai (2), "Solve pi(1)=Right");
      end;
      declare
         Opt : constant Solution := Solve (M);
         Warm : constant Solution := Solve_From (M, Opt.Policy);
      begin
         Check (Warm.Converged, "Solve_From optimal start converged");
         Check (Warm.Iterations = Nat (1),
                "already-optimal start takes 1 outer");
         Check (Near_Values (Opt.Values, Warm.Values, 1.0E-8),
                "warm start matches Solve");
         Check (Same_Policy (Opt.Policy, Warm.Policy),
                "warm policy matches");
      end;
      declare
         Cap : constant Solution := Solve (M, Max_Outer => 1);
      begin
         Check (Cap.Iterations = Nat (1), "Max_Outer=1 performs 1 round");
      end;
      declare
         Se : constant Solution := Solve (M, Mode => Exact);
         Si : constant Solution :=
           Solve (M, Mode => Iterative, Epsilon => 1.0E-12);
      begin
         Check (Se.Converged and then Si.Converged,
                "Exact and Iterative Solve converge");
         Check (Near_Values (Se.Values, Si.Values, 1.0E-5),
                "Exact ≈ Iterative Solve values");
         Check (Same_Policy (Se.Policy, Si.Policy),
                "Exact = Iterative Solve policy");
      end;
      Check (Solve_Raises_Eps, "Solve negative eps raises");
      Check (Solve_Raises_Invalid, "Solve invalid MDP raises");
   end Test_Iterate_And_Solve;

   procedure Test_Gamma_Zero is
      M : constant MDP := Tiny_Chain (5, 0.0);
      S : constant Solution := Solve (M);
   begin
      Section ("Gamma = 0 (myopic)");
      Check (S.Converged, "gamma-0 converged");
      Check (Near (S.Values (4), Rf (1.0)), "myopic V(pre-goal)=1");
      Check (Near (S.Values (3), Rf (0.0)), "myopic V(far)=0");
      Check (Near (S.Values (2), Rf (0.0)), "myopic V(2)=0");
      Check (Near (S.Values (1), Rf (0.0)), "myopic V(1)=0");
      Check (S.Policy (4) = Ai (2), "myopic still goes Right at 4");
      Check (S.Policy (1) = Ai (1), "myopic tie at 1 -> action 1");
   end Test_Gamma_Zero;

   procedure Test_Gridworld_No_Pit is
      M : constant MDP :=
        Gridworld_3x3 (0.9, Step_Cost => 0.0, Slip => 0.0, Use_Pit => False);
      S : constant Solution := Solve (M);
   begin
      Section ("Gridworld_3x3 (no pit)");
      Check (Is_Valid_MDP (M), "grid no-pit valid");
      Check (M.N_States = 9, "grid 9 states");
      Check (M.N_Actions = 4, "grid 4 actions");
      Check (S.Converged, "grid no-pit converged");
      Check (Near (S.Values (9), Rf (0.0), 1.0E-6), "V(goal)=0");
      Check (Near (S.Values (6), Rf (1.0), 1.0E-5), "V(6)=1 South to goal");
      Check (Near (S.Values (8), Rf (1.0), 1.0E-5), "V(8)=1 East to goal");
      Check (Near (S.Values (5), Rf (0.9), 1.0E-5), "V(5)=0.9");
      Check (Near (S.Values (3), Rf (0.9), 1.0E-5), "V(3)=0.9");
      Check (Near (S.Values (7), Rf (0.9), 1.0E-5), "V(7)=0.9 (no pit)");
      Check (Near (S.Values (2), Pow (0.9, 2), 1.0E-5), "V(2)=0.81");
      Check (Near (S.Values (4), Pow (0.9, 2), 1.0E-5), "V(4)=0.81");
      Check (Near (S.Values (1), Pow (0.9, 3), 1.0E-5), "V(1)=0.729");
      Check (S.Policy (6) = Ai (3), "pi(6)=South");
      Check (S.Policy (8) = Ai (2), "pi(8)=East");
      Check (S.Policy (5) = Ai (2), "pi(5) ties to East");
      Check (S.Policy (9) = Ai (1), "goal ties to North");
      for St in 1 .. 9 loop
         Check (Is_Stochastic (M, St, 1)
                  and then Is_Stochastic (M, St, 2)
                  and then Is_Stochastic (M, St, 3)
                  and then Is_Stochastic (M, St, 4),
                "grid rows stochastic @ " & St'Image);
         Check (S.Policy (State_Index (St)) in 1 .. 4
                  and then Near (Policy_Backup (M, S.Values, S.Policy, St),
                                 S.Values (State_Index (St)), 1.0E-5),
                "grid policy + fixed point @ " & St'Image);
      end loop;
   end Test_Gridworld_No_Pit;

   procedure Test_Gridworld_Pit_And_Slip is
      Pit : constant MDP :=
        Gridworld_3x3 (0.9, Step_Cost => 0.0, Slip => 0.0, Use_Pit => True);
      Slip : constant MDP :=
        Gridworld_3x3 (0.9, Step_Cost => -0.04, Slip => 0.2, Use_Pit => True);
      Sp : constant Solution := Solve (Pit);
      Ss : constant Solution := Solve (Slip);
   begin
      Section ("Gridworld pit / slip / step cost");
      Check (Is_Valid_MDP (Pit), "pit grid valid");
      Check (Is_Valid_MDP (Slip), "slip grid valid");
      Check (Sp.Converged, "pit grid converged");
      Check (Ss.Converged, "slip grid converged");
      Check (Near (Sp.Values (7), Rf (0.0), 1.0E-6), "V(pit)=0");
      Check (Near (Sp.Values (9), Rf (0.0), 1.0E-6), "V(goal)=0");
      Check (Near (Sp.Values (6), Rf (1.0), 1.0E-5), "pit: V(6)=1");
      Check (Near (Sp.Values (8), Rf (1.0), 1.0E-5), "pit: V(8)=1");
      Check (Sp.Policy (4) /= Ai (3), "pit: pi(4) is not South");
      Check (Sp.Values (4) > Rf (0.0), "pit: V(4)>0 (path exists)");
      Check (Sp.Values (1) > Rf (0.0), "pit: V(1)>0");
      for St in 1 .. 9 loop
         Check (Ss.Policy (State_Index (St)) in 1 .. 4
                  and then Ss.Values (State_Index (St)) <= Rf (2.0)
                  and then Ss.Values (State_Index (St)) >= Rf (-2.0),
                "slip policy+V @ " & St'Image);
      end loop;
      Check (Grid_Raises (Rf (1.0), Rf (0.0)), "grid gamma=1 raises");
      Check (Grid_Raises (Rf (0.9), Rf (-0.1)), "grid slip<0 raises");
      Check (Grid_Raises (Rf (0.9), Rf (1.1)), "grid slip>1 raises");
      Check (Grid_Raises (Rf (-0.5), Rf (0.0)), "grid gamma<0 raises");
   end Test_Gridworld_Pit_And_Slip;

   procedure Test_Gambler is
      M : constant MDP := Gambler_Toy (4, 0.5, 0.99);
      S : constant Solution := Solve (M);
   begin
      Section ("Gambler_Toy");
      Check (Is_Valid_MDP (M), "gambler valid");
      Check (M.N_States = 5, "gambler N=4 -> 5 states");
      Check (M.N_Actions = 2, "gambler max bet = 2");
      Check (S.Converged, "gambler converged");
      Check (Near (S.Values (1), Rf (0.0), 1.0E-6), "V(cap 0)=0");
      Check (Near (S.Values (5), Rf (0.0), 1.0E-6), "V(cap 4)=0");
      Check (S.Values (2) > S.Values (1), "V(1)>V(0)");
      Check (S.Values (3) > S.Values (2), "V(2)>V(1)");
      Check (S.Values (4) > S.Values (3), "V(3)>V(2)");
      Check (S.Values (4) < Rf (1.01), "V(3) < ~1");
      Check (abs (S.Values (2) - 0.25) < 0.05, "V(1) ~ 0.25");
      Check (abs (S.Values (3) - 0.50) < 0.05, "V(2) ~ 0.50");
      Check (abs (S.Values (4) - 0.75) < 0.05, "V(3) ~ 0.75");
      for St in 1 .. 5 loop
         Check (Is_Stochastic (M, St, 1) and then Is_Stochastic (M, St, 2)
                  and then S.Policy (State_Index (St)) in 1 .. 2,
                "gambler row+pi @ " & St'Image);
      end loop;
      Check (Near (Reward_Of (M, 4, 1, 5), Rf (1.0)), "bet-1 from 3 pays +1");
      Check (Near (Transition (M, 4, 1, 5), Rf (0.5)), "heads 1/2");
      Check (Near (Transition (M, 4, 1, 3), Rf (0.5)), "tails 1/2");
      Check (Gambler_Raises (Pos (1), Rf (0.5), Rf (0.9)),
             "gambler Goal=1 raises");
      Check (Gambler_Raises (Pos (4), Rf (-0.1), Rf (0.9)),
             "gambler p<0 raises");
      Check (Gambler_Raises (Pos (4), Rf (1.1), Rf (0.9)),
             "gambler p>1 raises");
      Check (Gambler_Raises (Pos (4), Rf (0.5), Rf (1.0)),
             "gambler gamma=1 raises");
   end Test_Gambler;

   procedure Test_Gambler_Biased is
      Fair : constant MDP := Gambler_Toy (6, 0.5, 0.95);
      Bias : constant MDP := Gambler_Toy (6, 0.9, 0.95);
      Sf   : constant Solution := Solve (Fair);
      Sb   : constant Solution := Solve (Bias);
   begin
      Section ("Gambler biased coin");
      Check (Sf.Converged and then Sb.Converged, "both gamblers converged");
      for Cap in 2 .. 6 loop
         Check (Sb.Values (State_Index (Cap))
                  >= Sf.Values (State_Index (Cap)) - 1.0E-9,
                "p=0.9 V >= p=0.5 V at cap " & Cap'Image);
      end loop;
      Check (Sb.Values (4) > Sf.Values (4), "strictly larger at mid capital");
   end Test_Gambler_Biased;

   procedure Check_Opt (M : MDP; Label : String) is
      S   : constant Solution := Solve (M);
      Vpi : constant Value_Function :=
        Evaluate_Policy (M, S.Policy, Mode => Exact);
      VI  : constant Value_Function := Independent_VI (M);
   begin
      Check (S.Converged, Label & " converged");
      Check (Near_Values (Vpi, S.Values, 1.0E-6), Label & " V^{pi*}=V*");
      Check (Near_Values (S.Values, VI, 1.0E-4),
             Label & " PI matches independent VI");
      for St in 1 .. Positive (M.N_States) loop
         declare
            Row : constant Q_Row := Q_Values (M, S.Values, St);
            Mx  : Real := Row (1);
         begin
            for A in 2 .. M.N_Actions loop
               if Row (A) > Mx then
                  Mx := Row (A);
               end if;
            end loop;
            Check (Near (S.Values (State_Index (St)), Mx, 1.0E-5),
                   Label & " V=max Q @" & St'Image);
            Check (Near (Row (S.Policy (State_Index (St))), Mx, 1.0E-5),
                   Label & " pi attains max @" & St'Image);
         end;
      end loop;
   end Check_Opt;

   procedure Test_Optimality_Identities is
   begin
      Section ("Optimality identities + independent VI");
      Check_Opt (Tiny_Chain (5, 0.85), "chain");
      Check_Opt (Absorbing_Goal (0.7), "goal");
      Check_Opt (Gridworld_3x3 (0.8, 0.0, 0.0, False), "grid");
      Check_Opt (Gambler_Toy (4, 0.4, 0.9), "gambler");
   end Test_Optimality_Identities;

   procedure Test_Policy_Improvement_Monotone is
      M  : constant MDP := Tiny_Chain (6, 0.9);
      Pi : Policy_Vector (1 .. 6) := [others => 1];
      Prev_Sum : Real := Real'First;
   begin
      Section ("Policy improvement raises value");
      for Round in 1 .. 6 loop
         declare
            V  : constant Value_Function :=
              Evaluate_Policy (M, Pi, Mode => Exact);
            Acc : Real := 0.0;
            Np  : constant Policy_Vector := Improve_Policy (M, V);
         begin
            for St in 1 .. 6 loop
               Acc := Acc + V (State_Index (St));
            end loop;
            Check (Acc + 1.0E-12 >= Prev_Sum,
                   "sum V^pi nondecreasing round" & Round'Image);
            Prev_Sum := Acc;
            exit when Same_Policy (Pi, Np);
            Pi := Np;
         end;
      end loop;
   end Test_Policy_Improvement_Monotone;

   procedure Test_Accessors_Grid is
      M : constant MDP :=
        Gridworld_3x3 (0.9, 0.0, 0.0, Use_Pit => False);
   begin
      Section ("Accessors on grid");
      Check (Near (Transition (M, 1, 2, 2), Rf (1.0)), "from 1 East -> 2");
      Check (Near (Transition (M, 1, 4, 1), Rf (1.0)), "from 1 West bounce");
      Check (Near (Transition (M, 6, 3, 9), Rf (1.0)), "from 6 South -> goal");
      Check (Near (Reward_Of (M, 6, 3, 9), Rf (1.0)), "entry reward +1");
      Check (Near (Reward_Of (M, 5, 2, 6), Rf (0.0)), "ordinary step 0");
      Check (Near (Expected_Reward (M, 8, 2), Rf (1.0)), "E[R|8,East]=1");
   end Test_Accessors_Grid;

   procedure Check_Modes (M : MDP; Label : String) is
      Se : constant Solution := Solve (M, Mode => Exact);
      Si : constant Solution :=
        Solve (M, Mode => Iterative, Epsilon => 1.0E-12);
   begin
      Check (Se.Converged and then Si.Converged,
             Label & " both modes converge");
      Check (Near_Values (Se.Values, Si.Values, 1.0E-4),
             Label & " values match");
      Check (Same_Policy (Se.Policy, Si.Policy),
             Label & " policies match");
   end Check_Modes;

   procedure Test_Modes_On_Toys is
   begin
      Section ("Exact vs Iterative on toys");
      Check_Modes (Tiny_Chain (4, 0.8), "chain");
      Check_Modes (Absorbing_Goal (0.75), "goal");
      Check_Modes (Gridworld_3x3 (0.85, 0.0, 0.0, False), "grid");
      Check_Modes (Gambler_Toy (4, 0.55, 0.9), "gambler");
   end Test_Modes_On_Toys;

   procedure Test_Policy_Operator is
      M  : constant MDP := Tiny_Chain (3, 0.5);
      Pi : constant Policy_Vector := [1 => 2, 2 => 2, 3 => 1];
      Z  : constant Value_Function (1 .. 3) := [others => 0.0];
      V1 : constant Value_Function := Policy_Operator (M, Z, Pi);
      V2 : constant Value_Function := Policy_Operator (M, V1, Pi);
   begin
      Section ("Policy_Operator / Backup");
      Check (Near (V1 (2), Rf (1.0)), "T^pi 0 at pre-goal = 1");
      Check (Near (V1 (1), Rf (0.0)), "T^pi 0 at start = 0");
      Check (Near (V2 (1), Rf (0.5)), "second backup propagates");
      Check (Near (Policy_Backup (M, Z, Pi, 2), Rf (1.0)),
             "Policy_Backup matches");
      Check (Policy_Residual (M, V2, Pi) < Rf (1.0),
             "residual after 2 backups finite");
   end Test_Policy_Operator;

   procedure Test_Many_Gammas_Goal is
   begin
      Section ("Absorbing_Goal gamma grid");
      for K in 0 .. 4 loop
         declare
            G : constant Real := Real (K) * 0.2;
            M : constant MDP := Absorbing_Goal (G);
            S : constant Solution := Solve (M);
         begin
            Check (S.Converged, "goal g-grid converged k=" & K'Image);
            Check (Near (S.Values (1), Rf (1.0), 1.0E-6),
                   "goal g-grid V(1)=1 k=" & K'Image);
            Check (Near (S.Values (2), Rf (0.0), 1.0E-6),
                   "goal g-grid V(2)=0 k=" & K'Image);
            Check (S.Policy (1) = Ai (2),
                   "goal g-grid Go k=" & K'Image);
         end;
      end loop;
   end Test_Many_Gammas_Goal;

begin
   Put_Line ("Policy_Iteration test suite");
   Put_Line ("==========================");

   Test_Near;
   Test_Builders_And_Validation;
   Test_Make_MDP_SA;
   Test_Absorbing;
   Test_Tiny_Chain;
   Test_Q_And_Greedy;
   Test_Evaluate_Exact_Vs_Iterative;
   Test_Iterate_And_Solve;
   Test_Gamma_Zero;
   Test_Gridworld_No_Pit;
   Test_Gridworld_Pit_And_Slip;
   Test_Gambler;
   Test_Gambler_Biased;
   Test_Optimality_Identities;
   Test_Policy_Improvement_Monotone;
   Test_Accessors_Grid;
   Test_Modes_On_Toys;
   Test_Policy_Operator;
   Test_Many_Gammas_Goal;

   New_Line;
   Put_Line ("==========================");
   Put_Line ("PASS: " & Pass_Count'Image);
   Put_Line ("FAIL: " & Fail_Count'Image);

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
