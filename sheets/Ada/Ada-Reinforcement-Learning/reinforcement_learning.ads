package Reinforcement_Learning is

   -- Strongly typed domains for the Reinforcement Learning environment
   type State_ID is new Positive;
   type Action_ID is new Positive;
   type Q_Value is new Float;
   type Reward_Type is new Float;
   type Probability is new Float range 0.0 .. 1.0;

   -- The Q-Table maps (State, Action) pairs to their learned Q-Values
   type Q_Table is array (State_ID range <>, Action_ID range <>) of Q_Value;

   Invalid_State  : exception;
   Invalid_Action : exception;

   -- Initialize the Q-Table with zeros
   procedure Initialize (Table : out Q_Table)
     with Post => (for all S in Table'Range(1) =>
                     (for all A in Table'Range(2) => Table (S, A) = 0.0));

   -- Get the best action for a given state (Action maximizing Q)
   function Get_Best_Action (Table : in Q_Table; State : in State_ID) return Action_ID
     with Pre => (Table'Length (1) > 0 and then Table'Length (2) > 0) and then
                 (State in Table'Range (1) or else raise Invalid_State);

   -- Get the maximum Q-value for a given state across all actions
   function Get_Max_Q (Table : in Q_Table; State : in State_ID) return Q_Value
     with Pre => (Table'Length (1) > 0 and then Table'Length (2) > 0) and then
                 (State in Table'Range (1) or else raise Invalid_State);

   -- Variant 1: Q-Learning (Off-Policy Temporal Difference Control)
   -- Updates the Q-Table using the maximum possible reward of the next state
   procedure Update_Q_Learning
     (Table         : in out Q_Table;
      Current_State : in State_ID;
      Action        : in Action_ID;
      Reward        : in Reward_Type;
      Next_State    : in State_ID;
      Alpha         : in Probability; -- Learning rate
      Gamma         : in Probability) -- Discount factor
     with Pre => (Table'Length (1) > 0 and then Table'Length (2) > 0) and then
                 (Current_State in Table'Range (1) or else raise Invalid_State) and then
                 (Next_State in Table'Range (1) or else raise Invalid_State) and then
                 (Action in Table'Range (2) or else raise Invalid_Action);

   -- Variant 2: SARSA (On-Policy Temporal Difference Control)
   -- Updates the Q-Table using the specific action taken in the next state
   procedure Update_SARSA
     (Table         : in out Q_Table;
      Current_State : in State_ID;
      Action        : in Action_ID;
      Reward        : in Reward_Type;
      Next_State    : in State_ID;
      Next_Action   : in Action_ID;
      Alpha         : in Probability;
      Gamma         : in Probability)
     with Pre => (Table'Length (1) > 0 and then Table'Length (2) > 0) and then
                 (Current_State in Table'Range (1) or else raise Invalid_State) and then
                 (Next_State in Table'Range (1) or else raise Invalid_State) and then
                 (Action in Table'Range (2) or else raise Invalid_Action) and then
                 (Next_Action in Table'Range (2) or else raise Invalid_Action);

   -- Helper function to compare Q_Values safely due to floating point math
   function Almost_Equal (Left, Right : Q_Value; Epsilon : Q_Value := 0.00001) return Boolean;

end Reinforcement_Learning;
