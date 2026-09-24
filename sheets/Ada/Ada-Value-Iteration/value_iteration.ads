--  Value_Iteration — Ada 2023 educational package for Wikipedia
--  "Markov decision process / Value iteration": synchronous Bellman
--  optimality backups on a finite discounted MDP until the max residual
--  drops below ε (or a fixed iteration budget). The greedy policy
--  π*(s) = arg max_a Q(s, a) is extracted from the converged V.
--  Classroom constructors: Tiny_Chain, Gridworld_3x3, Gambler_Toy,
--  Absorbing_Goal, plus Make_MDP / Make_MDP_SA for explicit P, R arrays.
--  Primary source:
--  https://en.wikipedia.org/wiki/Markov_decision_process#Value_iteration
--  Sibling sheet (README only — do not `with`): Policy Iteration —
--  RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Value_Iteration
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational finite MDPs)
   ---------------------------------------------------------------------------

   Max_States  : constant Positive := 32;
   Max_Actions : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type State_Index  is range 1 .. Max_States;
   type Action_Index is range 1 .. Max_Actions;

   --  Share 'Base so slices 1 .. S / 1 .. A type-check with discriminants.
   subtype State_Count  is State_Index'Base  range 0 .. State_Index'Base (Max_States);
   subtype Action_Count is Action_Index'Base range 0 .. Action_Index'Base (Max_Actions);

   subtype Real        is Long_Float;
   subtype Probability is Real;
   subtype Reward      is Real;

   --  P (s, a, s') = Pr (s' | s, a).  R (s, a, s') is the immediate reward
   --  on that transition.  The R(s, a) form is recovered by making R
   --  independent of s' (see Make_MDP_SA).
   type Transition_Tensor is
     array (State_Index range <>,
            Action_Index range <>,
            State_Index range <>) of Probability;

   type Reward_Tensor is
     array (State_Index range <>,
            Action_Index range <>,
            State_Index range <>) of Reward;

   type Reward_SA_Matrix is
     array (State_Index range <>, Action_Index range <>) of Reward;

   type Value_Function is array (State_Index range <>) of Real;
   type Policy_Vector  is array (State_Index range <>) of Action_Index;
   type Q_Row          is array (Action_Index range <>) of Real;

   --  Finite discounted MDP: states 1 .. N_States, actions 1 .. N_Actions,
   --  discount Gamma in [0, 1).  Every (s, a) row of P must be a
   --  probability distribution (non-negative, sums to 1).
   type MDP
     (N_States  : State_Count;
      N_Actions : Action_Count) is
   record
      P     : Transition_Tensor (1 .. N_States, 1 .. N_Actions, 1 .. N_States);
      R     : Reward_Tensor (1 .. N_States, 1 .. N_Actions, 1 .. N_States);
      Gamma : Real := 0.9;
   end record;

   --  Value-iteration outcome: V, greedy π, sweep count, leftover residual.
   type Solution (N_States : State_Count) is
   record
      Values     : Value_Function (1 .. N_States) := [others => 0.0];
      Policy     : Policy_Vector (1 .. N_States)  := [others => 1];
      Iterations : Natural := 0;
      Residual   : Real    := 0.0;
      Converged  : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for zero / oversized dimensions, Gamma not in [0, 1),
   --  non-stochastic (s, a) rows, negative probabilities, mismatched
   --  array bounds, out-of-range indices, or a negative tolerance / ε.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol     : constant Real     := 1.0E-9;
   Prob_Tol        : constant Real     := 1.0E-8;
   Default_Epsilon : constant Real     := 1.0E-8;
   Default_Max_Iters : constant Positive := 10_000;

   function Near
     (X, Y : Real; Tol : Real := Default_Tol) return Boolean
     with Global => null;
   --  |X − Y| ≤ Tol.  Tol must be ≥ 0 (else Invalid_Argument).

   function Near_Values
     (A, B : Value_Function; Tol : Real := Default_Tol) return Boolean
     with Global => null;
   --  Same bounds and componentwise Near.  Raises if lengths differ
   --  or Tol < 0.

   ---------------------------------------------------------------------------
   -- Validation / accessors
   ---------------------------------------------------------------------------

   function Is_Stochastic
     (Model  : MDP;
      State  : Positive;
      Action : Positive;
      Tol    : Real := Prob_Tol) return Boolean
     with Global => null;
   --  True iff P (State, Action, ·) is non-negative and sums to 1 ± Tol.
   --  Raises if State / Action are outside 1 .. N_* or Tol < 0.

   function Is_Valid_MDP
     (Model : MDP; Tol : Real := Prob_Tol) return Boolean
     with Global => null;
   --  N_States ≥ 1, N_Actions ≥ 1, Gamma ∈ [0, 1), every (s, a) row
   --  stochastic.  Tol < 0 raises.

   function Transition
     (Model : MDP; State, Action, Next_State : Positive) return Probability
     with Global => null;

   function Reward_Of
     (Model : MDP; State, Action, Next_State : Positive) return Reward
     with Global => null;

   function Expected_Reward
     (Model : MDP; State, Action : Positive) return Reward
     with Global => null;
   --  Σ_{s'} P(s'|s,a) R(s,a,s').

   ---------------------------------------------------------------------------
   -- Builders (explicit P, R)
   ---------------------------------------------------------------------------

   function Empty_MDP
     (N_States  : Positive;
      N_Actions : Positive;
      Gamma     : Real) return MDP
     with Global => null;
   --  Zero tensors.  Not yet stochastic — fill with Set_* then solve.
   --  Raises if N_* exceeds Max_* or Gamma is out of range.

   procedure Set_Transition
     (Model      : in out MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Prob       : Probability)
     with Global => null;
   --  Raises if indices are out of range or Prob < 0.

   procedure Set_Reward
     (Model      : in out MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Value      : Reward)
     with Global => null;

   procedure Set_Reward_SA
     (Model  : in out MDP;
      State  : Positive;
      Action : Positive;
      Value  : Reward)
     with Global => null;
   --  Broadcasts R(s, a, s') := Value for every s' (R(s, a) form).

   procedure Set_Deterministic
     (Model      : in out MDP;
      State      : Positive;
      Action     : Positive;
      Next_State : Positive;
      Value      : Reward)
     with Global => null;
   --  One-hot P(s'|s,a) and matching R(s,a,s') := Value (0 elsewhere).

   function Make_MDP
     (P     : Transition_Tensor;
      R     : Reward_Tensor;
      Gamma : Real) return MDP
     with Global => null;
   --  Copy 1-based tensors of matching shape.  Validates stochastic rows
   --  and Gamma.  Raises Invalid_Argument on any defect.

   function Make_MDP_SA
     (P     : Transition_Tensor;
      R     : Reward_SA_Matrix;
      Gamma : Real) return MDP
     with Global => null;
   --  R(s, a) form: stored as R(s, a, s') = R_sa(s, a) for all s'.

   ---------------------------------------------------------------------------
   -- Bellman operators
   ---------------------------------------------------------------------------

   function Q_Value
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive;
      Action : Positive) return Real
     with Global => null;
   --  Q(s, a) = Σ_{s'} P(s'|s,a) (R(s,a,s') + γ V(s')).
   --  Raises if Model is invalid, Values is the wrong length, or
   --  State / Action is out of range.

   function Q_Values
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive) return Q_Row
     with Global => null;
   --  Q(s, ·) over 1 .. N_Actions.

   function Bellman_Backup
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive) return Real
     with Global => null;
   --  (T* V)(s) = max_a Q(s, a).

   function Bellman_Operator
     (Model  : MDP;
      Values : Value_Function) return Value_Function
     with Global => null;
   --  Synchronous backup: V'(s) = max_a Q(s, a) for every s.

   function Greedy_Action
     (Model  : MDP;
      Values : Value_Function;
      State  : Positive) return Action_Index
     with Global => null;
   --  arg max_a Q(s, a); lowest Action_Index on ties.

   function Greedy_Policy
     (Model  : MDP; Values : Value_Function) return Policy_Vector
     with Global => null;

   function Bellman_Residual
     (Model  : MDP; Values : Value_Function) return Real
     with Global => null;
   --  ||V − T* V||_∞ = max_s |V(s) − (T* V)(s)|.

   function Iterate
     (Model  : MDP;
      Values : Value_Function;
      Sweeps : Positive := 1) return Value_Function
     with Global => null;
   --  Apply Bellman_Operator Sweeps times (synchronous).

   function Solve
     (Model     : MDP;
      Epsilon   : Real     := Default_Epsilon;
      Max_Iters : Positive := Default_Max_Iters) return Solution
     with Global => null;
   --  Value iteration from V ≡ 0.  Stops when the max residual is
   --  < Epsilon or Max_Iters backups have been performed.  Returns V,
   --  the greedy policy, the sweep count, the leftover residual of the
   --  returned V, and Converged = (residual < Epsilon).
   --  Raises if Model is invalid or Epsilon < 0.

   function Solve_From
     (Model     : MDP;
      Start     : Value_Function;
      Epsilon   : Real     := Default_Epsilon;
      Max_Iters : Positive := Default_Max_Iters) return Solution
     with Global => null;
   --  Same as Solve, but starts from Start instead of the zero vector.

   function Evaluate_Policy
     (Model     : MDP;
      Policy    : Policy_Vector;
      Epsilon   : Real     := Default_Epsilon;
      Max_Iters : Positive := Default_Max_Iters) return Value_Function
     with Global => null;
   --  Iterative policy evaluation: V ← T^π V until the residual is
   --  < Epsilon (or Max_Iters).  README contrast only — this is not
   --  the Policy Iteration sibling package.  Raises if Policy has the
   --  wrong length or names an illegal action.

   ---------------------------------------------------------------------------
   -- Classic classroom MDPs
   ---------------------------------------------------------------------------

   function Tiny_Chain
     (Length : Positive := 3;
      Gamma  : Real     := 0.9) return MDP
     with Global => null;
   --  Line 1 .. Length; actions Left = 1, Right = 2.  Deterministic
   --  walk; Left at 1 stays; Length is absorbing.  Reward +1 on the
   --  transition that first enters Length, else 0.
   --  Exact: V(Length) = 0 and V(k) = γ^{Length-1-k} for k < Length
   --  (so V(Length−1) = 1).  Greedy policy is Right on every transient.
   --  Raises if Length < 2 or Length > Max_States, or Gamma out of range.

   function Absorbing_Goal
     (Gamma  : Real    := 0.9;
      Living : Boolean := False) return MDP
     with Global => null;
   --  Two states, two actions.  s1 Stay (1) → s1, reward 0; Go (2) → s2,
   --  reward 1.  s2 is absorbing.  If Living is False (default) the
   --  absorbing reward is 0, so V*(2) = 0 and V*(1) = 1, π*(1) = Go.
   --  If Living is True, R(2, a, 2) = 1 and V*(2) = 1/(1−γ).

   function Gridworld_3x3
     (Gamma     : Real    := 0.9;
      Step_Cost : Real    := 0.0;
      Slip      : Real    := 0.0;
      Use_Pit   : Boolean := True) return MDP
     with Global => null;
   --  3×3 cells, row-major states 1 .. 9:
   --     1 2 3
   --     4 5 6
   --     7 8 9
   --  Actions North=1, East=2, South=3, West=4.  Off-grid moves bounce
   --  (stay).  Cell 9 is an absorbing goal (+1 on entry).  Cell 7 is an
   --  absorbing pit (−1 on entry) when Use_Pit is True.  Every other
   --  transition pays Step_Cost.  Slip ∈ [0, 1]: intended direction
   --  with probability 1−Slip, each perpendicular with Slip/2.
   --  Raises if Gamma or Slip is out of range.

   function Gambler_Toy
     (Goal_Capital : Positive := 4;
      P_Heads      : Real     := 0.5;
      Gamma        : Real     := 0.99) return MDP
     with Global => null;
   --  Sutton & Barto gambler (classroom scale).  States 1 .. Goal+1
   --  encode capital 0 .. Goal.  Action a is a stake of a units; a is
   --  legal when 1 ≤ a ≤ min(capital, Goal−capital).  Illegal stakes
   --  are no-ops (stay, reward 0).  Heads (prob P_Heads) adds the
   --  stake; tails subtracts it.  Reward +1 on first reaching Goal;
   --  capitals 0 and Goal are absorbing with reward 0.
   --  For P_Heads = 1/2 and γ → 1, V(capital) → capital / Goal.
   --  Raises if Goal < 2, Goal+1 > Max_States, Goal/2 > Max_Actions,
   --  P_Heads not in [0, 1], or Gamma out of range.

end Value_Iteration;
