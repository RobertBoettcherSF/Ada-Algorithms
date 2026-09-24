--  Bayesian_Nash_Equilibrium — Ada 2023 educational package for Harsanyi's
--  Bayesian games and Bayesian Nash equilibrium (BNE). Incomplete information
--  is encoded by types drawn from a common prior; a strategy maps each of a
--  player's own types to a (mixed) action. A strategy profile is a BNE when
--  every type maximises expected payoff given Bayes beliefs about the other
--  player's type and the other's type-contingent strategy.
--  Classroom scope: two players, ≤ Max_Types = 3 types each, ≤ Max_Actions = 3
--  actions each; membership checks of candidate profiles; classic constructors
--  (Sheriff's dilemma / entry, auction toy, battle with private info) and the
--  degenerate single-type case (ordinary Nash of the complete-info game).
--  Reference: https://en.wikipedia.org/wiki/Bayesian_game#Bayesian_Nash_Equilibrium
--  Sibling sheets (README only — do not `with`): Correlated Equilibrium,
--  Backward Induction — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Bayesian_Nash_Equilibrium
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; ≤3 types × ≤3 actions per player)
   ---------------------------------------------------------------------------

   Max_Types   : constant Positive := 3;
   Max_Actions : constant Positive := 3;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Type_Id is range 1 .. Max_Types;
   type Action_Id is range 1 .. Max_Actions;

   --  Share 'Base so slices 1 .. T / 1 .. A type-check with discriminants.
   subtype Type_Count is Type_Id'Base range 0 .. Type_Id'Base (Max_Types);
   subtype Action_Count is Action_Id'Base range 0 .. Action_Id'Base (Max_Actions);

   subtype Payoff is Long_Float;
   subtype Probability is Long_Float;

   --  Payoff tensors indexed by (t1, a1, t2, a2): player i's utility when
   --  types are (t1, t2) and actions (a1, a2).
   type Payoff_Tensor is
     array (Type_Id range <>, Action_Id range <>,
            Type_Id range <>, Action_Id range <>) of Payoff;

   type Prior_Matrix is
     array (Type_Id range <>, Type_Id range <>) of Probability;

   --  Mixed action over 1 .. Num_Actions.
   type Mixed_Action is array (Action_Id range <>) of Probability;

   --  Type-contingent mixed strategy: Mix (t, a) = Prob[action a | type t].
   type Type_Contingent_Mix is
     array (Type_Id range <>, Action_Id range <>) of Probability;

   --  Two-player Bayesian game in Harsanyi normal form.
   type Bayesian_Game
     (T1, T2 : Type_Count;
      A1, A2 : Action_Count) is
   record
      U1    : Payoff_Tensor (1 .. T1, 1 .. A1, 1 .. T2, 1 .. A2);
      U2    : Payoff_Tensor (1 .. T1, 1 .. A1, 1 .. T2, 1 .. A2);
      Prior : Prior_Matrix (1 .. T1, 1 .. T2);
   end record;

   --  Strategy profile: S1 maps player-1 types → mixed actions; S2 likewise.
   type Strategy_Profile
     (T1, T2 : Type_Count;
      A1, A2 : Action_Count) is
   record
      S1 : Type_Contingent_Mix (1 .. T1, 1 .. A1);
      S2 : Type_Contingent_Mix (1 .. T2, 1 .. A2);
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for zero / oversized type or action sets, incompatible sizes,
   --  non-probability priors or mixed actions (when a validator requires
   --  them), negative tolerances, or type / action indices out of range.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol : constant Payoff := 1.0E-9;

   function Near
     (X, Y : Payoff; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  |X − Y| ≤ Tol. Tol must be ≥ 0 (else Invalid_Argument).

   ---------------------------------------------------------------------------
   -- Prior / belief helpers
   ---------------------------------------------------------------------------

   function Prior_Mass (G : Bayesian_Game) return Probability
     with Global => null;
   --  Σ_{t1,t2} Prior(t1, t2).

   function Is_Valid_Prior
     (G : Bayesian_Game; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Every entry ≥ −Tol and |Prior_Mass − 1| ≤ Tol. Tol ≥ 0.

   function Normalize_Prior (G : Bayesian_Game) return Bayesian_Game
     with Global => null;
   --  Scale Prior so mass = 1. Raises Invalid_Argument if mass ≤ 0.

   function Type_Marginal_1
     (G : Bayesian_Game; T : Type_Id) return Probability
     with Global => null;
   --  Σ_{t2} Prior(T, t2). Raises if T out of range for G.T1.

   function Type_Marginal_2
     (G : Bayesian_Game; T : Type_Id) return Probability
     with Global => null;
   --  Σ_{t1} Prior(t1, T). Raises if T out of range for G.T2.

   function Belief_1_About_2
     (G : Bayesian_Game; Own_Type : Type_Id; Other_Type : Type_Id)
      return Probability
     with Global => null;
   --  P(t2 = Other_Type | t1 = Own_Type) by Bayes. Raises if Own_Type has
   --  zero marginal or indices are invalid.

   function Belief_2_About_1
     (G : Bayesian_Game; Own_Type : Type_Id; Other_Type : Type_Id)
      return Probability
     with Global => null;
   --  P(t1 = Other_Type | t2 = Own_Type). Same zero-marginal rule.

   ---------------------------------------------------------------------------
   -- Strategy helpers
   ---------------------------------------------------------------------------

   function Is_Mixed_Action
     (P : Mixed_Action; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Nonempty 1-based vector, nonnegative within Tol, sums to 1 within Tol.

   function Is_Valid_Strategy_Profile
     (P : Strategy_Profile; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Every type of each player has a valid mixed action.

   function Pure_Mixed_Action
     (Num_Actions : Action_Count; A : Action_Id) return Mixed_Action
     with Global => null;
   --  Dirac on A. Raises if Num_Actions = 0 or A out of range.

   function Uniform_Mixed_Action
     (Num_Actions : Action_Count) return Mixed_Action
     with Global => null;
   --  1/Num_Actions each. Raises if Num_Actions = 0.

   function Pure_Strategy_Profile
     (G : Bayesian_Game;
      A1_Of_Type : Type_Contingent_Mix;
      A2_Of_Type : Type_Contingent_Mix) return Strategy_Profile
     with Global => null;
   --  Build a (possibly mixed) profile from type-contingent mixes matching
   --  G's dimensions. Raises on size mismatch. Does not require purity.

   function Pure_Actions_Profile
     (G              : Bayesian_Game;
      Player1_Action : Action_Id;
      Player2_Action : Action_Id) return Strategy_Profile
     with Global => null;
   --  Every type of player 1 plays Player1_Action; every type of player 2
   --  plays Player2_Action. Raises if actions out of range.

   function Extract_Mixed_1
     (P : Strategy_Profile; T : Type_Id) return Mixed_Action
     with Global => null;

   function Extract_Mixed_2
     (P : Strategy_Profile; T : Type_Id) return Mixed_Action
     with Global => null;

   procedure Require_Compatible
     (G : Bayesian_Game; P : Strategy_Profile)
     with Global => null;
   --  Raises unless G and P share T1,T2,A1,A2 > 0.

   ---------------------------------------------------------------------------
   -- Expected payoffs (interim / type-contingent)
   ---------------------------------------------------------------------------

   function Expected_Payoff_Pure_1
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id;
      Own_Action : Action_Id) return Payoff
     with Global => null;
   --  Interim EU for player 1 of type Own_Type playing Own_Action vs P.S2,
   --  using Bayes beliefs. Raises if Own_Type has zero marginal.

   function Expected_Payoff_Pure_2
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id;
      Own_Action : Action_Id) return Payoff
     with Global => null;

   function Expected_Payoff_1
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
     with Global => null;
   --  Interim EU for player 1 type Own_Type under P.S1(Own_Type, ·) vs P.S2.

   function Expected_Payoff_2
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
     with Global => null;

   function Best_Pure_Payoff_1
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
     with Global => null;
   --  max_{a1} Expected_Payoff_Pure_1 (...).

   function Best_Pure_Payoff_2
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
     with Global => null;

   ---------------------------------------------------------------------------
   -- Best response / BNE membership
   ---------------------------------------------------------------------------

   function Is_Best_Response_For_Type_1
     (G   : Bayesian_Game;
      P   : Strategy_Profile;
      Own_Type : Type_Id;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  If Type_Marginal_1 = 0, returns True (vacuous). Else P.S1(Own_Type, ·)
   --  must be a mixed action whose support lies in best pure replies (within
   --  Tol of Best_Pure_Payoff_1).

   function Is_Best_Response_For_Type_2
     (G   : Bayesian_Game;
      P   : Strategy_Profile;
      Own_Type : Type_Id;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;

   function Is_Bayesian_Nash
     (G   : Bayesian_Game;
      P   : Strategy_Profile;
      Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  Compatible sizes; valid prior; valid strategy profile; every type of
   --  both players is a best response (vacuous for zero-marginal types).

   ---------------------------------------------------------------------------
   -- Classic Bayesian games and known BNE profiles
   ---------------------------------------------------------------------------

   function Sheriffs_Dilemma (P_Criminal : Probability := 0.5)
     return Bayesian_Game
     with Global => null;
   --  Suspect (P1): types Criminal=1, Civilian=2; actions Shoot=1, Not=2.
   --  Sheriff (P2): one type; actions Shoot=1, Not=2.
   --  Prior: P(Criminal)=P_Criminal, P(Civilian)=1−P_Criminal.
   --  Raises if P_Criminal not in [0,1]. Classroom payoffs match the
   --  Wikipedia threshold: Sheriff shoots in pure BNE iff P_Criminal > 1/3.

   function Sheriffs_BNE (P_Criminal : Probability := 0.5)
     return Strategy_Profile
     with Global => null;
   --  Criminal→Shoot, Civilian→Not; Sheriff→Shoot if P>1/3, Not if P<1/3,
   --  and (1/2,1/2) if P=1/3. Raises if P_Criminal not in [0,1].

   function Entry_Game (P_Tough : Probability := 0.5) return Bayesian_Game
     with Global => null;
   --  Entrant (P1): one type; Enter=1, Out=2.
   --  Incumbent (P2): Tough=1, Weak=2; Fight=1, Accommodate=2.
   --  Raises if P_Tough not in [0,1].

   function Entry_BNE (P_Tough : Probability := 0.5) return Strategy_Profile
     with Global => null;
   --  Tough→Fight, Weak→Accommodate; Entrant→Out if P_Tough ≥ 1/2,
   --  Enter if P_Tough < 1/2 (at 1/2 Out is selected as a pure BNE).

   function Auction_Toy return Bayesian_Game
     with Global => null;
   --  Symmetric 2×2-type / 2-bid second-price (Vickrey) toy: types Low=1,
   --  High=2; bids Low=1, High=2; independent uniform prior; winner pays
   --  rival's bid (ties split 1/2). Classic pure BNE: bid own value.

   function Auction_Toy_BNE return Strategy_Profile
     with Global => null;
   --  Each type bids its value (Low→Low bid, High→High bid).

   function Battle_Private_Info return Bayesian_Game
     with Global => null;
   --  Battle-of-the-sexes flavour with one-sided private info:
   --  P1 has types Opera-lover=1 / Fight-lover=2; P2 has one type.
   --  Actions Opera=1, Fight=2. Prior 1/2 each on P1's types.

   function Battle_Private_Info_BNE return Strategy_Profile
     with Global => null;
   --  Each P1 type plays its preferred pure action; P2 mixes 1/2–1/2
   --  (indifferent), which is a BNE under the classroom payoffs.

   function Matching_Pennies_Complete return Bayesian_Game
     with Global => null;
   --  Degenerate Bayesian game: one type each, Matching Pennies ±1.

   function Matching_Pennies_Mixed_BNE return Strategy_Profile
     with Global => null;
   --  Ordinary mixed Nash (1/2, 1/2) × (1/2, 1/2).

   function Prisoners_Dilemma_Complete return Bayesian_Game
     with Global => null;
   --  Degenerate: one type each; Cooperate=1, Defect=2; (3,3)/(0,5)/(5,0)/(1,1).

   function Prisoners_Dilemma_BNE return Strategy_Profile
     with Global => null;
   --  Pure NE (Defect, Defect).

   function Chicken_Complete return Bayesian_Game
     with Global => null;
   --  Degenerate Chicken: Dare=1, Chicken-out=2; (0,0)/(7,2)/(2,7)/(6,6).

   function Chicken_Pure_DC_BNE return Strategy_Profile
     with Global => null;
   --  Pure NE (Dare, Chicken-out).

   function Chicken_Pure_CD_BNE return Strategy_Profile
     with Global => null;
   --  Pure NE (Chicken-out, Dare).

   function Chicken_Mixed_BNE return Strategy_Profile
     with Global => null;
   --  Mixed NE: each plays Chicken-out with probability 2/3.

end Bayesian_Nash_Equilibrium;
