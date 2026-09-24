package Temporal_Difference_Learning
  with Pure
is
   --  Strong typing for all algorithm domains
   type State_Index is new Positive;
   type Action_Index is new Positive;

   type Value_Type is new Float;
   type Reward_Type is new Value_Type;
   
   --  Rate encompasses both Learning Rate (Alpha) and Discount Factor (Gamma)
   subtype Rate is Value_Type range 0.0 .. 1.0;
   subtype Probability is Value_Type range 0.0 .. 1.0;

   --  Tabular structures for states and actions
   type Value_Table is array (State_Index range <>) of Value_Type;
   type Q_Table is array (State_Index range <>, Action_Index range <>) of Value_Type;
   type Policy_Distribution is array (Action_Index range <>) of Probability;

   --  Exceptions for error handling and edge cases
   Invalid_State_Error  : exception;
   Invalid_Action_Error : exception;
   Policy_Mismatch_Error : exception;

   -----------------------------------------------------------------------------
   --  Helper Functions
   -----------------------------------------------------------------------------
   
   --  Calculates the maximum Q-value for a given state across all actions.
   function Max_Action_Value (Q : Q_Table; S : State_Index) return Value_Type
     with Pre => S in Q'Range (1) and then Q'Length (2) > 0,
          Global => null;

   --  Validates that a policy distribution sums to approximately 1.0.
   function Is_Valid_Policy (Pi : Policy_Distribution) return Boolean
     with Global => null;

   -----------------------------------------------------------------------------
   --  Variant 1: Tabular TD(0) for State-Value Prediction
   -----------------------------------------------------------------------------
   --  Evaluates a policy by updating the state-value function V(s).
   procedure Update_TD_0
     (V      : in out Value_Table;
      S      : State_Index;
      S_Next : State_Index;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
     with Pre => V'Length > 0,
          Global => null;

   -----------------------------------------------------------------------------
   --  Variant 2: Q-Learning (Off-Policy TD Control)
   -----------------------------------------------------------------------------
   --  Updates the action-value function Q(s,a) using the maximum possible 
   --  future reward, regardless of the current policy.
   procedure Update_Q_Learning
     (Q      : in out Q_Table;
      S      : State_Index;
      A      : Action_Index;
      S_Next : State_Index;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
     with Pre => Q'Length (1) > 0 and then Q'Length (2) > 0,
          Global => null;

   -----------------------------------------------------------------------------
   --  Variant 3: SARSA (On-Policy TD Control)
   -----------------------------------------------------------------------------
   --  Updates the action-value function Q(s,a) using the action actually 
   --  taken in the next state under the current policy.
   procedure Update_SARSA
     (Q      : in out Q_Table;
      S      : State_Index;
      A      : Action_Index;
      S_Next : State_Index;
      A_Next : Action_Index;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
     with Pre => Q'Length (1) > 0 and then Q'Length (2) > 0,
          Global => null;

   -----------------------------------------------------------------------------
   --  Variant 4: Expected SARSA
   -----------------------------------------------------------------------------
   --  Updates the action-value function Q(s,a) using the expected value of 
   --  the next state, taking into account the probability of each action.
   procedure Update_Expected_SARSA
     (Q      : in out Q_Table;
      S      : State_Index;
      A      : Action_Index;
      S_Next : State_Index;
      Pi     : Policy_Distribution;
      R      : Reward_Type;
      Alpha  : Rate;
      Gamma  : Rate)
     with Pre => Q'Length (1) > 0 and then Q'Length (2) > 0,
          Global => null;

end Temporal_Difference_Learning;
