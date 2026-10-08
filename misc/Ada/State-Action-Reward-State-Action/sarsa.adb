package body Sarsa is

   ------------------------
   -- Initialize_Q_Table --
   ------------------------
   function Initialize_Q_Table (States, Actions : Positive) return Q_Table is
      Result : constant Q_Table (State_Index (1) .. State_Index (States),
                                 Action_Index (1) .. Action_Index (Actions)) :=
        [others => [others => 0.0]];
   begin
      return Result;
   end Initialize_Q_Table;

   ----------------------------
   -- Initialize_Trace_Table --
   ----------------------------
   function Initialize_Trace_Table (States, Actions : Positive) return Trace_Table is
      Result : constant Trace_Table (State_Index (1) .. State_Index (States),
                                     Action_Index (1) .. Action_Index (Actions)) :=
        [others => [others => 0.0]];
   begin
      return Result;
   end Initialize_Trace_Table;

   ---------------------
   -- Update_Standard --
   ---------------------
   procedure Update_Standard
     (Q       : in out Q_Table;
      S       : State_Index;
      A       : Action_Index;
      R       : Reward_Value;
      S_Next  : State_Index;
      A_Next  : Action_Index;
      Alpha   : Rate;
      Gamma   : Rate)
   is
      TD_Err : Q_Value;
   begin
      if S not in Q'Range (1) or else S_Next not in Q'Range (1) then
         raise State_Out_Of_Bounds;
      end if;
      if A not in Q'Range (2) or else A_Next not in Q'Range (2) then
         raise Action_Out_Of_Bounds;
      end if;

      TD_Err := Calculate_TD_Error (Q, S, A, R, S_Next, A_Next, Gamma);
      Q (S, A) := Q (S, A) + Q_Value (Alpha) * TD_Err;
   end Update_Standard;

   ---------------------
   -- Update_Expected --
   ---------------------
   procedure Update_Expected
     (Q       : in out Q_Table;
      S       : State_Index;
      A       : Action_Index;
      R       : Reward_Value;
      S_Next  : State_Index;
      Alpha   : Rate;
      Gamma   : Rate;
      Epsilon : Rate)
   is
      Best_A      : Action_Index;
      Expected_Q  : Q_Value := 0.0;
      Prob        : Rate;
      Num_Actions : Float;
   begin
      if S not in Q'Range (1) or else S_Next not in Q'Range (1) then
         raise State_Out_Of_Bounds;
      end if;
      if A not in Q'Range (2) then
         raise Action_Out_Of_Bounds;
      end if;

      Best_A      := Best_Action (Q, S_Next);
      Num_Actions := Float (Q'Length (2));

      -- Calculate expected Q-value given epsilon-greedy policy probabilities
      for Act in Q'Range (2) loop
         if Act = Best_A then
            Prob := (1.0 - Epsilon) + (Epsilon / Num_Actions);
         else
            Prob := Epsilon / Num_Actions;
         end if;
         Expected_Q := Expected_Q + Q_Value (Prob) * Q (S_Next, Act);
      end loop;

      Q (S, A) := Q (S, A) + Q_Value (Alpha) * (Q_Value (R) + Q_Value (Gamma) * Expected_Q - Q (S, A));
   end Update_Expected;

   ---------------------
   -- Increment_Trace --
   ---------------------
   procedure Increment_Trace
     (Traces : in out Trace_Table;
      S      : State_Index;
      A      : Action_Index)
   is
   begin
      if S not in Traces'Range (1) then
         raise State_Out_Of_Bounds;
      end if;
      if A not in Traces'Range (2) then
         raise Action_Out_Of_Bounds;
      end if;

      Traces (S, A) := Traces (S, A) + 1.0;
   end Increment_Trace;

   ------------------------
   -- Update_Lambda_Step --
   ------------------------
   procedure Update_Lambda_Step
     (Q           : in out Q_Table;
      Traces      : in out Trace_Table;
      TD_Error    : Q_Value;
      Alpha       : Rate;
      Gamma       : Rate;
      Lambda      : Rate)
   is
   begin
      if Q'Length (1) /= Traces'Length (1) or else Q'Length (2) /= Traces'Length (2) then
         raise Table_Size_Mismatch;
      end if;

      -- Apply TD error scaled by traces to all state-actions, then decay traces
      for State in Q'Range (1) loop
         for Action in Q'Range (2) loop
            Q (State, Action) := Q (State, Action) + Q_Value (Alpha) * TD_Error * Q_Value (Traces (State, Action));
            Traces (State, Action) := Trace_Value (Float (Traces (State, Action)) * Float (Gamma) * Float (Lambda));
         end loop;
      end loop;
   end Update_Lambda_Step;

   ------------------------
   -- Calculate_TD_Error --
   ------------------------
   function Calculate_TD_Error
     (Q      : Q_Table;
      S      : State_Index;
      A      : Action_Index;
      R      : Reward_Value;
      S_Next : State_Index;
      A_Next : Action_Index;
      Gamma  : Rate) return Q_Value
   is
   begin
      if S not in Q'Range (1) or else S_Next not in Q'Range (1) then
         raise State_Out_Of_Bounds;
      end if;
      if A not in Q'Range (2) or else A_Next not in Q'Range (2) then
         raise Action_Out_Of_Bounds;
      end if;

      return Q_Value (R) + Q_Value (Gamma) * Q (S_Next, A_Next) - Q (S, A);
   end Calculate_TD_Error;

   -----------------
   -- Best_Action --
   -----------------
   function Best_Action (Q : Q_Table; S : State_Index) return Action_Index is
      Best_A : Action_Index;
      Max_Q  : Q_Value;
   begin
      if S not in Q'Range (1) then
         raise State_Out_Of_Bounds;
      end if;

      Best_A := Q'First (2);
      Max_Q  := Q (S, Best_A);

      for A in Q'Range (2) loop
         if Q (S, A) > Max_Q then
            Max_Q  := Q (S, A);
            Best_A := A;
         end if;
      end loop;

      return Best_A;
   end Best_Action;

   ---------------------------
   -- Epsilon_Greedy_Action --
   ---------------------------
   function Epsilon_Greedy_Action
     (Q       : Q_Table;
      S       : State_Index;
      Epsilon : Rate;
      Gen     : in out Ada.Numerics.Float_Random.Generator) return Action_Index
   is
      use Ada.Numerics.Float_Random;
      Rnd         : constant Float := Random (Gen);
      Num_Actions : constant Natural := Q'Length (2);
      Val         : constant Float := Random (Gen) * Float (Num_Actions);
      Idx         : Action_Index;
   begin
      if S not in Q'Range (1) then
         raise State_Out_Of_Bounds;
      end if;

      if Rnd < Float (Epsilon) then
         -- Explore: Pick uniformly across all actions
         Idx := Q'First (2);
         for I in 1 .. Num_Actions - 1 loop
            if Val < Float (I) then
               return Idx;
            end if;
            Idx := Idx + 1;
         end loop;
         return Idx;
      else
         -- Exploit: Pick best action greedily
         return Best_Action (Q, S);
      end if;
   end Epsilon_Greedy_Action;

end Sarsa;
