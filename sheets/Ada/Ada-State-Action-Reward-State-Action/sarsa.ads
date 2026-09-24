with Ada.Numerics.Float_Random;

package Sarsa is

   -- Domain-specific types for strong typing
   type State_Index is new Positive;
   type Action_Index is new Positive;

   type Q_Value is new Float;
   type Reward_Value is new Float;

   subtype Rate is Float range 0.0 .. 1.0;
   subtype Trace_Value is Float range 0.0 .. Float'Last;

   -- Matrices for Q-values and Eligibility Traces
   type Q_Table is array (State_Index range <>, Action_Index range <>) of Q_Value;
   type Trace_Table is array (State_Index range <>, Action_Index range <>) of Trace_Value;

   -- Named exceptions for explicit error handling
   State_Out_Of_Bounds  : exception;
   Action_Out_Of_Bounds : exception;
   Table_Size_Mismatch  : exception;

   -- Initializes a Q-Table with zeros
   function Initialize_Q_Table (States, Actions : Positive) return Q_Table
     with Post => Initialize_Q_Table'Result'Length (1) = States and then
                  Initialize_Q_Table'Result'Length (2) = Actions;

   -- Initializes an Eligibility Trace table with zeros
   function Initialize_Trace_Table (States, Actions : Positive) return Trace_Table
     with Post => Initialize_Trace_Table'Result'Length (1) = States and then
                  Initialize_Trace_Table'Result'Length (2) = Actions;

   -- Variant 1: Standard SARSA (On-Policy TD Control)
   -- Updates the Q-value for (S, A) using the observed Reward and next (S_Next, A_Next).
   procedure Update_Standard
     (Q       : in out Q_Table;
      S       : State_Index;
      A       : Action_Index;
      R       : Reward_Value;
      S_Next  : State_Index;
      A_Next  : Action_Index;
      Alpha   : Rate;
      Gamma   : Rate)
     with Pre => (S in Q'Range (1) and S_Next in Q'Range (1)) and then
                 (A in Q'Range (2) and A_Next in Q'Range (2));

   -- Variant 2: Expected SARSA
   -- Uses the expected value of the next state under an epsilon-greedy policy,
   -- rather than the specific next action taken.
   procedure Update_Expected
     (Q       : in out Q_Table;
      S       : State_Index;
      A       : Action_Index;
      R       : Reward_Value;
      S_Next  : State_Index;
      Alpha   : Rate;
      Gamma   : Rate;
      Epsilon : Rate)
     with Pre => (S in Q'Range (1) and S_Next in Q'Range (1)) and then
                 (A in Q'Range (2));

   -- Variant 3a: SARSA(Lambda) Trace Increment
   -- Increments the eligibility trace for a visited state-action pair (Accumulating Traces).
   procedure Increment_Trace
     (Traces : in out Trace_Table;
      S      : State_Index;
      A      : Action_Index)
     with Pre => S in Traces'Range (1) and A in Traces'Range (2);

   -- Variant 3b: SARSA(Lambda) Global Update Step
   -- Applies the TD error scaled by traces to the entire Q-Table, then decays all traces.
   procedure Update_Lambda_Step
     (Q           : in out Q_Table;
      Traces      : in out Trace_Table;
      TD_Error    : Q_Value;
      Alpha       : Rate;
      Gamma       : Rate;
      Lambda      : Rate)
     with Pre => Q'Length (1) = Traces'Length (1) and Q'Length (2) = Traces'Length (2);

   -- Helper: Calculate Temporal Difference (TD) Error for Standard SARSA
   function Calculate_TD_Error
     (Q      : Q_Table;
      S      : State_Index;
      A      : Action_Index;
      R      : Reward_Value;
      S_Next : State_Index;
      A_Next : Action_Index;
      Gamma  : Rate) return Q_Value
     with Pre => (S in Q'Range (1) and S_Next in Q'Range (1)) and then
                 (A in Q'Range (2) and A_Next in Q'Range (2));

   -- Helper: Returns the action with the maximum Q-value for a given state (Greedy choice).
   function Best_Action (Q : Q_Table; S : State_Index) return Action_Index
     with Pre => S in Q'Range (1);

   -- Helper: Returns an action based on the Epsilon-Greedy policy.
   function Epsilon_Greedy_Action
     (Q       : Q_Table;
      S       : State_Index;
      Epsilon : Rate;
      Gen     : in out Ada.Numerics.Float_Random.Generator) return Action_Index
     with Pre => S in Q'Range (1);

end Sarsa;
