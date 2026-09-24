-- fictitious_play.ads
-- Specification for the Fictitious Play scheduling/game-theory algorithm.

package Fictitious_Play is

   -- Strong typing for algorithm-specific data
   type Action_Index is new Positive;
   type Payoff_Value is new Float;
   type Probability is new Float range 0.0 .. 1.0;

   -- 2D Matrix for Normal-Form Games. Indexed by (Player 1 Action, Player 2 Action)
   type Payoff_Matrix is array (Action_Index range <>, Action_Index range <>) of Payoff_Value;
   
   -- Arrays for histories and beliefs
   type Action_Array is array (Positive range <>) of Action_Index;
   type Belief_Counts is array (Action_Index range <>) of Natural;

   -- Exceptions for Edge Cases
   Invalid_Matrix_Dimensions : exception;
   Invalid_History_Length    : exception;
   Invalid_Probabilities     : exception;

   -- ==========================================
   -- Core Variants of Fictitious Play
   -- ==========================================

   -- Variant 1: Simultaneous Fictitious Play
   -- Players update beliefs and choose best responses simultaneously at each step.
   procedure Simultaneous_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   );

   -- Variant 2: Alternating (Sequential) Fictitious Play
   -- Players take turns updating their beliefs and playing.
   procedure Alternating_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   );

   -- Variant 3: Smoothed (Stochastic) Fictitious Play
   -- Uses a Logit (Softmax) best response to introduce noise/exploration.
   -- Lambda is the temperature (higher = closer to strict best response).
   procedure Smoothed_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      Lambda            : in Float;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   );

   -- Variant 4: Fictitious Play with Inertia
   -- Players only update their strategy with probability (1 - Inertia_Prob).
   procedure Inertial_Play (
      P1_Payoffs        : in Payoff_Matrix;
      P2_Payoffs        : in Payoff_Matrix;
      Iterations        : in Positive;
      Inertia_Prob      : in Probability;
      P1_Initial_Action : in Action_Index;
      P2_Initial_Action : in Action_Index;
      P1_History        : out Action_Array;
      P2_History        : out Action_Array
   );

   -- ==========================================
   -- Helper Functions (Exposed for Testing)
   -- ==========================================
   function Calculate_Best_Response_P1 (
      Payoffs    : Payoff_Matrix;
      P2_Beliefs : Belief_Counts
   ) return Action_Index;

   function Calculate_Best_Response_P2 (
      Payoffs    : Payoff_Matrix;
      P1_Beliefs : Belief_Counts
   ) return Action_Index;

end Fictitious_Play;
