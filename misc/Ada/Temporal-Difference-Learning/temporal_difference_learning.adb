package body Temporal_Difference_Learning is

   -----------------------------------------------------------------------------
   --  Helper Functions
   -----------------------------------------------------------------------------

   function Max_Action_Value (Q : Q_Table; S : State_Index) return Value_Type is
      Max_Val : Value_Type := Value_Type'First;
   begin
      for A in Q'Range (2) loop
         if Q (S, A) > Max_Val then
            Max_Val := Q (S, A);
         end if;
      end loop;
      return Max_Val;
   end Max_Action_Value;

   function Is_Valid_Policy (Pi : Policy_Distribution) return Boolean is
      Sum : Value_Type := 0.0;
   begin
      if Pi'Length = 0 then
         return False;
      end if;
      
      for A in Pi'Range loop
         Sum := Sum + Pi (A);
      end loop;
      
      --  Allow a small epsilon for floating-point inaccuracies
      return abs (Sum - 1.0) < 0.0001;
   end Is_Valid_Policy;

   -----------------------------------------------------------------------------
   --  Tabular TD(0)
   -----------------------------------------------------------------------------
   
   procedure Update_TD_0
     (V      : in out Value_Table;
      S      : State_Index;
      S_Next : State_Index;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
   is
      TD_Target : Value_Type;
      TD_Error  : Value_Type;
   begin
      --  Validate states exist in the table
      if S not in V'Range or else S_Next not in V'Range then
         raise Invalid_State_Error with "State index out of Value_Table bounds";
      end if;

      --  TD Target = R + Gamma * V(S')
      TD_Target := Value_Type (R) + Gamma * V (S_Next);
      
      --  TD Error = TD Target - V(S)
      TD_Error := TD_Target - V (S);
      
      --  V(S) <- V(S) + Alpha * TD_Error
      V (S) := V (S) + Alpha * TD_Error;
   end Update_TD_0;

   -----------------------------------------------------------------------------
   --  Q-Learning
   -----------------------------------------------------------------------------
   
   procedure Update_Q_Learning
     (Q      : in out Q_Table;
      S      : State_Index;
      A      : Action_Index;
      S_Next : State_Index;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
   is
      Max_Next_Q : Value_Type;
      TD_Target  : Value_Type;
      TD_Error   : Value_Type;
   begin
      --  Validate boundaries
      if S not in Q'Range (1) or else S_Next not in Q'Range (1) then
         raise Invalid_State_Error with "State index out of Q_Table bounds";
      end if;
      if A not in Q'Range (2) then
         raise Invalid_Action_Error with "Action index out of Q_Table bounds";
      end if;

      --  Max_Next_Q = max_a Q(S_Next, a)
      Max_Next_Q := Max_Action_Value (Q, S_Next);
      
      --  TD Target = R + Gamma * max_a Q(S_Next, a)
      TD_Target := Value_Type (R) + Gamma * Max_Next_Q;
      
      --  TD Error = TD Target - Q(S, A)
      TD_Error := TD_Target - Q (S, A);
      
      --  Q(S, A) <- Q(S, A) + Alpha * TD_Error
      Q (S, A) := Q (S, A) + Alpha * TD_Error;
   end Update_Q_Learning;

   -----------------------------------------------------------------------------
   --  SARSA
   -----------------------------------------------------------------------------
   
   procedure Update_SARSA
     (Q      : in out Q_Table;
      S      : State_Index;
      A      : Action_Index;
      S_Next : State_Index;
      A_Next : Action_Index;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
   is
      TD_Target  : Value_Type;
      TD_Error   : Value_Type;
   begin
      --  Validate boundaries
      if S not in Q'Range (1) or else S_Next not in Q'Range (1) then
         raise Invalid_State_Error with "State index out of Q_Table bounds";
      end if;
      if A not in Q'Range (2) or else A_Next not in Q'Range (2) then
         raise Invalid_Action_Error with "Action index out of Q_Table bounds";
      end if;

      --  TD Target = R + Gamma * Q(S_Next, A_Next)
      TD_Target := Value_Type (R) + Gamma * Q (S_Next, A_Next);
      
      --  TD Error = TD Target - Q(S, A)
      TD_Error := TD_Target - Q (S, A);
      
      --  Q(S, A) <- Q(S, A) + Alpha * TD_Error
      Q (S, A) := Q (S, A) + Alpha * TD_Error;
   end Update_SARSA;

   -----------------------------------------------------------------------------
   --  Expected SARSA
   -----------------------------------------------------------------------------
   
   procedure Update_Expected_SARSA
     (Q      : in out Q_Table;
      S      : State_Index;
      A      : Action_Index;
      S_Next : State_Index;
      Pi     : Policy_Distribution;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
   is
      Expected_Next_Q : Value_Type := 0.0;
      TD_Target       : Value_Type;
      TD_Error        : Value_Type;
   begin
      --  Validate boundaries
      if S not in Q'Range (1) or else S_Next not in Q'Range (1) then
         raise Invalid_State_Error with "State index out of Q_Table bounds";
      end if;
      if A not in Q'Range (2) then
         raise Invalid_Action_Error with "Action index out of Q_Table bounds";
      end if;
      
      --  Validate Policy bounds match Action bounds
      if Pi'First /= Q'First (2) or else Pi'Last /= Q'Last (2) then
         raise Policy_Mismatch_Error with "Policy indices must match Q_Table actions";
      end if;

      --  Expected_Next_Q = sum_a (Pi(a|S_Next) * Q(S_Next, a))
      for A_Iter in Q'Range (2) loop
         Expected_Next_Q := Expected_Next_Q + Pi (A_Iter) * Q (S_Next, A_Iter);
      end loop;

      --  TD Target = R + Gamma * Expected_Next_Q
      TD_Target := Value_Type (R) + Gamma * Expected_Next_Q;
      
      --  TD Error = TD Target - Q(S, A)
      TD_Error := TD_Target - Q (S, A);
      
      --  Q(S, A) <- Q(S, A) + Alpha * TD_Error
      Q (S, A) := Q (S, A) + Alpha * TD_Error;
   end Update_Expected_SARSA;

end Temporal_Difference_Learning;
