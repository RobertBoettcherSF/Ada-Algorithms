generic
   type State_Type is (<>);
   type Action_Type is (<>);
   type Value_Type is digits <>;
package Q_Learning
  with SPARK_Mode => On
is
   --  The Q-Table represents the expected future rewards for each state-action pair.
   type Q_Table is array (State_Type, Action_Type) of Value_Type;

   --  Restricted subtype for parameters that must be bounded between 0 and 1.
   subtype Probability is Value_Type range 0.0 .. 1.0;

   --  Standard Q-Learning algorithm update step.
   --  It updates the Q-value for a given state-action pair using the Bellman equation.
   procedure Update_Q_Value
     (Table           : in out Q_Table;
      State           : in State_Type;
      Action          : in Action_Type;
      Reward          : in Value_Type;
      Next_State      : in State_Type;
      Learning_Rate   : in Probability;
      Discount_Factor : in Probability)
     with Global => null,
          Pre    => True;

   --  Double Q-Learning algorithm update step.
   --  Uses two decoupled Q-tables to separate action selection from action evaluation,
   --  which mitigates the overestimation bias intrinsic to standard Q-learning.
   procedure Update_Double_Q_Value
     (Table_A         : in out Q_Table;
      Table_B         : in out Q_Table;
      State           : in State_Type;
      Action          : in Action_Type;
      Reward          : in Value_Type;
      Next_State      : in State_Type;
      Learning_Rate   : in Probability;
      Discount_Factor : in Probability;
      Update_A        : in Boolean)
     with Global => null,
          Pre    => True;

   --  Returns the maximum Q-value across all available actions for a specific state.
   function Max_Q_Value
     (Table : Q_Table;
      State : State_Type) return Value_Type
     with Global => null,
          Pre    => True;

   --  Returns the action that yields the maximum Q-value for a specific state.
   function Best_Action
     (Table : Q_Table;
      State : State_Type) return Action_Type
     with Global => null,
          Pre    => True;

   --  Implements the Epsilon-Greedy strategy for exploration vs exploitation.
   --  Random_Value should be a uniformly distributed float [0.0, 1.0).
   --  Random_Action should be a randomly chosen valid action.
   function Epsilon_Greedy_Action
     (Table         : Q_Table;
      State         : State_Type;
      Epsilon       : Probability;
      Random_Value  : Probability;
      Random_Action : Action_Type) return Action_Type
     with Global => null,
          Pre    => True;

end Q_Learning;
