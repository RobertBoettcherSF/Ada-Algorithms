--  Correlated_Equilibrium — Ada 2023 educational package for Aumann's
--  correlated equilibrium (1974) on two-player bimatrix games. A joint
--  distribution μ over action profiles is a CE when, after observing a
--  recommended action a_i, no player i wants to deviate to another a_i'.
--  Classroom scope: action sets ≤ Max_Actions = 5; membership checks,
--  Nash product embeddings, classic constructors (PD, Chicken, Matching
--  Pennies, BoS / Coordination), and hand-built CE examples (traffic-light
--  Chicken). Finding a CE without LP: product of a known NE, uniform over
--  pure NE, or a tiny optional 2×2 grid search.
--  Reference: https://en.wikipedia.org/wiki/Correlated_equilibrium
--  Sibling sheets (README only — do not `with`): Nash equilibrium,
--  Bayesian Nash — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Correlated_Equilibrium
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; ≤5×5 bimatrix classroom games)
   ---------------------------------------------------------------------------

   Max_Actions : constant Positive := 5;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Action_Id is range 1 .. Max_Actions;
   --  Shares Action_Id'Base so matrix slices 1 .. Rows type-check.
   subtype Action_Count is Action_Id'Base range 0 .. Action_Id'Base (Max_Actions);

   --  Payoffs and probabilities (Long_Float for classroom precision).
   subtype Payoff is Long_Float;
   subtype Probability is Long_Float;

   type Payoff_Matrix is
     array (Action_Id range <>, Action_Id range <>) of Payoff;

   type Probability_Matrix is
     array (Action_Id range <>, Action_Id range <>) of Probability;

   type Mixed_Strategy is array (Action_Id range <>) of Probability;

   --  Two-player normal-form game: A = row-player payoffs, B = column.
   type Game (Rows, Cols : Action_Count) is record
      A : Payoff_Matrix (1 .. Rows, 1 .. Cols);
      B : Payoff_Matrix (1 .. Rows, 1 .. Cols);
   end record;

   --  Joint distribution μ over action pairs (row, column).
   type Distribution (Rows, Cols : Action_Count) is record
      Mu : Probability_Matrix (1 .. Rows, 1 .. Cols);
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for zero / oversized action sets, game↔distribution size
   --  mismatch, non-probability mixed strategies or joints (when a
   --  validator requires them), negative tolerances / grid steps, or
   --  action indices outside the game's dimensions.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol : constant Payoff := 1.0E-9;

   function Near
     (X, Y : Payoff; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  |X − Y| ≤ Tol. Tol must be ≥ 0 (else Invalid_Argument).

   ---------------------------------------------------------------------------
   -- Distribution helpers
   ---------------------------------------------------------------------------

   function Total_Mass (D : Distribution) return Probability
     with Global => null;
   --  Σ_{r,c} μ(r,c).

   function Is_Nonnegative
     (D : Distribution; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Every entry ≥ −Tol. Tol ≥ 0.

   function Is_Probability_Distribution
     (D : Distribution; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Nonnegative (within Tol) and |Total_Mass − 1| ≤ Tol.

   function Normalize (D : Distribution) return Distribution
     with Global => null;
   --  Scale so Total_Mass = 1. Raises Invalid_Argument if mass ≤ 0.

   function Pure_Distribution
     (Rows, Cols : Action_Count;
      Row_Action, Col_Action : Action_Id) return Distribution
     with Global => null;
   --  Dirac mass 1 on (Row_Action, Col_Action). Raises if sizes / indices
   --  are invalid (Rows/Cols = 0 or > Max_Actions, action out of range).

   function Uniform_Distribution
     (Rows, Cols : Action_Count) return Distribution
     with Global => null;
   --  μ(r,c) = 1/(Rows·Cols). Raises if Rows = 0 or Cols = 0.

   function Product_Distribution
     (P_Row : Mixed_Strategy; P_Col : Mixed_Strategy) return Distribution
     with Global => null;
   --  μ(r,c) = P_Row(r)·P_Col(c). Requires matching 1-based bounds and
   --  nonempty strategies; does not require them to be normalized.

   function Is_Product_Distribution
     (D   : Distribution;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  True if D is (approximately) a product of its marginals.

   function Row_Marginal
     (D : Distribution; R : Action_Id) return Probability
     with Global => null;

   function Col_Marginal
     (D : Distribution; C : Action_Id) return Probability
     with Global => null;

   ---------------------------------------------------------------------------
   -- Expected payoffs
   ---------------------------------------------------------------------------

   function Expected_Payoff_Row
     (G : Game; D : Distribution) return Payoff
     with Global => null;

   function Expected_Payoff_Col
     (G : Game; D : Distribution) return Payoff
     with Global => null;

   procedure Require_Compatible (G : Game; D : Distribution)
     with Global => null;
   --  Raises Invalid_Argument unless G and D share Rows and Cols > 0.

   ---------------------------------------------------------------------------
   -- Incentive / CE membership
   ---------------------------------------------------------------------------

   --  For recommended row action R and alternate R_Alt, the CE gap is
   --  Σ_c μ(R,c)·(A(R,c) − A(R_Alt,c)). Must be ≥ −Tol for all pairs.
   function Row_Incentive_Gap
     (G : Game; D : Distribution; R, R_Alt : Action_Id) return Payoff
     with Global => null;

   function Col_Incentive_Gap
     (G : Game; D : Distribution; C, C_Alt : Action_Id) return Payoff
     with Global => null;

   function Max_Row_Violation
     (G : Game; D : Distribution) return Payoff
     with Global => null;
   --  max(0, −min gap) over row recommendations / deviations; 0 if OK.

   function Max_Col_Violation
     (G : Game; D : Distribution) return Payoff
     with Global => null;

   function Max_Incentive_Violation
     (G : Game; D : Distribution) return Payoff
     with Global => null;
   --  max(Max_Row_Violation, Max_Col_Violation).

   function Is_Correlated_Equilibrium
     (G   : Game;
      D   : Distribution;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  D must be a probability distribution (within Tol) and all
   --  incentive gaps ≥ −Tol. Compatible sizes required.

   ---------------------------------------------------------------------------
   -- Nash product embeddings
   ---------------------------------------------------------------------------

   function Is_Best_Response_Row
     (G   : Game;
      P_Col : Mixed_Strategy;
      P_Row : Mixed_Strategy;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Every action in the support of P_Row is a best reply to P_Col
   --  (expected payoff within Tol of the max pure reply).

   function Is_Best_Response_Col
     (G   : Game;
      P_Row : Mixed_Strategy;
      P_Col : Mixed_Strategy;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;

   function Is_Nash_Product
     (G   : Game;
      P_Row, P_Col : Mixed_Strategy;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Both mixed strategies are probability vectors and mutual best
   --  responses (hence their product distribution is a CE / Nash).

   function Is_Nash_Product
     (G   : Game;
      D   : Distribution;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  D is (approx.) a product distribution and that product is Nash.

   ---------------------------------------------------------------------------
   -- Finding a CE without a general LP
   ---------------------------------------------------------------------------

   function Uniform_Over_Pure_Profiles
     (Rows, Cols : Action_Count;
      Profiles   : Probability_Matrix) return Distribution
     with Global => null;
   --  Profiles acts as a 0/1 (or nonnegative) mask; result is the
   --  normalized restriction of Profiles. Raises if total mass ≤ 0.

   --  Optional tiny grid search for 2×2 joints (classroom LP substitute).
   type Grid_CE_Result is record
      Found : Boolean := False;
      D     : Distribution (2, 2);
   end record;

   function Find_CE_Grid_2x2
     (G     : Game;
      Steps : Positive := 8;
      Tol   : Payoff := 1.0E-6) return Grid_CE_Result
     with Global => null;
   --  Requires G.Rows = G.Cols = 2. Raises Invalid_Argument otherwise
   --  or if Steps is unreasonable for classroom use (> 40). When Found
   --  is False, D is the uniform joint (not necessarily a CE).

   ---------------------------------------------------------------------------
   -- Classic games (row / column action labels documented in README)
   ---------------------------------------------------------------------------

   function Prisoners_Dilemma return Game
     with Global => null;
   --  2×2: Cooperate=1, Defect=2; payoffs (3,3)/(0,5)/(5,0)/(1,1).

   function Chicken return Game
     with Global => null;
   --  2×2 Wikipedia Chicken: Dare=1, Chicken-out=2;
   --  (0,0)/(7,2)/(2,7)/(6,6).

   function Matching_Pennies return Game
     with Global => null;
   --  2×2 zero-sum: Heads=1, Tails=2; ±1.

   function Battle_Of_Sexes return Game
     with Global => null;
   --  2×2 BoS: Opera=1, Fight=2; (2,1)/(0,0)/(0,0)/(1,2).

   function Pure_Coordination return Game
     with Global => null;
   --  2×2: (1,1)/(0,0)/(0,0)/(1,1).

   ---------------------------------------------------------------------------
   -- Classic correlated / Nash distributions
   ---------------------------------------------------------------------------

   function PD_Defect_Defect return Distribution
     with Global => null;
   --  Pure NE (Defect, Defect) as a Dirac CE.

   function Chicken_Traffic_Light_CE return Distribution
     with Global => null;
   --  Wikipedia: μ(C,C)=μ(D,C)=μ(C,D)=1/3 (Dare=1, Chicken=2).

   function Chicken_Better_CE return Distribution
     with Global => null;
   --  Wikipedia max-sum CE: μ(C,C)=1/2, μ(D,C)=μ(C,D)=1/4.

   function Chicken_Mixed_Nash_Product return Distribution
     with Global => null;
   --  Product of mixed NE: each plays Chicken-out with prob 2/3.

   function Matching_Pennies_Mixed_Nash return Distribution
     with Global => null;
   --  Product of (1/2,1/2)×(1/2,1/2).

   function BoS_Pure_Opera return Distribution
     with Global => null;

   function BoS_Pure_Fight return Distribution
     with Global => null;

   function Coordination_Diagonal_CE return Distribution
     with Global => null;
   --  Uniform on the two pure coordination profiles (A,A) and (B,B).

end Correlated_Equilibrium;
