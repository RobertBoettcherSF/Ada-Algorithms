-- regret_theory.ads
-- Regret (Decision Theory) Algorithm 
-- Implements Minimax Regret generation and evaluation for Payoff and Cost variants.

package Regret_Theory is

   -- Custom types for algorithm-specific data
   type Payoff_Value is new Float;
   
   -- 2D Array: First index (1) = Actions/Alternatives, Second index (2) = States of Nature
   type Matrix is array (Positive range <>, Positive range <>) of Payoff_Value;

   -- Exceptions
   Empty_Matrix_Error : exception;

   -- Variant 1: Calculate Regret Matrix from a Payoff Matrix (Maximize)
   -- Regret = Maximum payoff in state - actual payoff
   function Regret_From_Payoffs (Payoffs : Matrix) return Matrix;

   -- Variant 2: Calculate Regret Matrix from a Cost/Loss Matrix (Minimize)
   -- Regret = Actual cost - minimum cost in state
   function Regret_From_Costs (Costs : Matrix) return Matrix;

   -- Helper: Get maximum regret for a specific action across all states
   function Max_Regret_For_Action (Regrets : Matrix; Action : Positive) return Payoff_Value;

   -- Variant 3: Minimax Regret Decision
   -- Evaluates the Regret Matrix and returns the Action that minimizes the maximum regret
   procedure Minimax_Regret 
     (Regrets     : in Matrix; 
      Best_Action : out Positive; 
      Min_Max     : out Payoff_Value);

end Regret_Theory;
