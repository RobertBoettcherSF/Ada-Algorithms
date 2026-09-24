--  Multiplicative_Weight_Update_Method — Ada 2023 educational package for
--  the multiplicative weights update (MWU) method / Hedge algorithm:
--  online learning and prediction from expert advice by maintaining
--  positive weights and updating them multiplicatively from per-round
--  losses.
--
--  Two classroom update rules (selectable per learner):
--    Multiplicative :  w_i ← w_i · (1 − η)^{ℓ_i}
--    Hedge          :  w_i ← w_i · exp(−η · ℓ_i)
--
--  Play the normalized distribution p_i = w_i / Σ w. No-regret average
--  external regret is O(√((ln N)/T)) for suitably chosen η.
--
--  Reference:
--    https://en.wikipedia.org/wiki/Multiplicative_weight_update_method
--  Sibling contrast (README only — do not `with`): Ada-Mirror-Descent /
--  Ada regret-minimization packages — Hedge is entropic mirror descent.
--  Part of the RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Multiplicative_Weight_Update_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Soft classroom bound on the number of experts.
   Max_Experts : constant Positive := 64;
   subtype Expert_Count is Positive range 1 .. Max_Experts;
   subtype Expert_Index is Positive range 1 .. Max_Experts;

   --  Unconstrained arrays; callers pass slices of length N.
   type Weight_Vector is array (Positive range <>) of Real;
   type Loss_Vector is array (Positive range <>) of Real;
   type Probability_Vector is array (Positive range <>) of Real;
   subtype Reward_Vector is Loss_Vector;

   --  Multiplicative : classic MWU / weighted-majority style
   --                   w ← w · (1 − η)^ℓ   (ℓ typically in [0,1])
   --  Hedge          : exponential weights / Freund–Schapire Hedge
   --                   w ← w · exp(−η · ℓ)
   type Update_Kind is (Multiplicative, Hedge);

   ---------------------------------------------------------------------------
   -- Learner state
   ---------------------------------------------------------------------------

   --  Opaque online learner: N experts, learning rate η, update rule,
   --  positive weights, cumulative algorithm / expert losses, round count.
   type Learner is private;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for bad N, η, loss/reward/weight lengths, non-positive
   --  weights, empty learners, or out-of-range expert indices.

   ---------------------------------------------------------------------------
   -- Construction / reset
   ---------------------------------------------------------------------------

   function Create
     (N       : Expert_Count;
      Eta     : Positive_Real;
      Variant : Update_Kind := Hedge) return Learner
     with Global => null;
   --  Uniform initial weights w_i = 1. Raises Invalid_Argument if
   --  η is not finite / not positive, or (for Multiplicative) η ≥ 1.

   function Create
     (Eta     : Positive_Real;
      Initial : Weight_Vector;
      Variant : Update_Kind := Hedge) return Learner
     with Global => null;
   --  Custom positive initial weights. Length becomes N.
   --  Raises Invalid_Argument if Initial is empty / too long, any
   --  weight is non-positive or non-finite, or η is invalid for Variant.

   procedure Reset (L : in out Learner)
     with Global => null;
   --  Restore uniform weights w_i = 1, clear cumulative losses / rounds.
   --  Keeps N, η, Variant.

   procedure Reset
     (L       : in out Learner;
      Initial : Weight_Vector)
     with Global => null;
   --  Reset with custom positive weights of length Expert_Count (L).
   --  Raises Invalid_Argument on length / positivity / finiteness errors.

   ---------------------------------------------------------------------------
   -- Accessors
   ---------------------------------------------------------------------------

   function Expert_Count_Of (L : Learner) return Expert_Count
     with Global => null;

   function Learning_Rate (L : Learner) return Positive_Real
     with Global => null;

   function Variant_Of (L : Learner) return Update_Kind
     with Global => null;

   function Rounds (L : Learner) return Natural
     with Global => null;

   function Weights (L : Learner) return Weight_Vector
     with Global => null;
   --  Current (unnormalized) positive weights, length N.

   function Weight_Sum (L : Learner) return Positive_Real
     with Global => null;

   function Distribution (L : Learner) return Probability_Vector
     with Global => null;
   --  p_i = w_i / Σ_j w_j. Alias of Probabilities.

   function Probabilities (L : Learner) return Probability_Vector
     with Global => null;

   function Choose (L : Learner) return Expert_Index
     with Global => null;
   --  Deterministic classroom choice: argmax_i w_i (smallest index on ties).

   function Best_Expert (L : Learner) return Expert_Index
     with Global => null;
   --  Expert with smallest cumulative loss so far (smallest index on ties).
   --  Before any Update, returns 1.

   ---------------------------------------------------------------------------
   -- Updates
   ---------------------------------------------------------------------------

   procedure Update (L : in out Learner; Losses : Loss_Vector)
     with Global => null;
   --  One MWU / Hedge round:
   --    1. Record alg loss ⟨p, ℓ⟩ and each expert's ℓ_i.
   --    2. Multiply weights by the chosen rule.
   --  Losses must have length N and be finite; for Multiplicative each
   --  ℓ_i must lie in [0,1]. Raises Invalid_Argument otherwise.

   procedure Update_Rewards (L : in out Learner; Rewards : Reward_Vector)
     with Global => null;
   --  Reward form: treat ℓ_i = −r_i (Hedge / Multiplicative on negated
   --  rewards). For Multiplicative, each reward must lie in [−1, 0] so
   --  that −r ∈ [0,1]. Prefer Hedge for arbitrary bounded rewards.

   ---------------------------------------------------------------------------
   -- Regret / cumulative loss
   ---------------------------------------------------------------------------

   function Algorithm_Loss (L : Learner) return Real
     with Global => null;
   --  Σ_t ⟨p^t, ℓ^t⟩ cumulative expected loss of the played distribution.

   function Expert_Loss (L : Learner; I : Expert_Index) return Real
     with Global => null;
   --  Cumulative loss of expert I. Raises Invalid_Argument if I > N.

   function Best_Expert_Loss (L : Learner) return Real
     with Global => null;
   --  min_i Σ_t ℓ_i^t (0 when T = 0).

   function External_Regret (L : Learner) return Real
     with Global => null;
   --  Algorithm_Loss − Best_Expert_Loss.

   function Average_Regret (L : Learner) return Real
     with Global => null;
   --  External_Regret / T, or 0 when T = 0.

   ---------------------------------------------------------------------------
   -- Suggested learning rate / helpers
   ---------------------------------------------------------------------------

   function Suggested_Eta
     (N : Expert_Count;
      T : Positive;
      Variant : Update_Kind := Hedge) return Positive_Real
     with Global => null;
   --  Classroom schedule aiming at O(√((ln N)/T)) average regret:
   --    Hedge          : η = √(ln(N) / T)
   --    Multiplicative : η = min(1/2, √(ln(N) / T))

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Distribution_Sums_To_One
     (P : Probability_Vector; Tol : Real := 1.0E-9) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Valid_Initial (Initial : Weight_Vector) return Boolean
     with Global => null;
   --  True iff 1 ≤ Length ≤ Max_Experts and every entry is finite and > 0.

   function Expected_Loss
     (P : Probability_Vector; Losses : Loss_Vector) return Real
     with Global => null;
   --  ⟨p, ℓ⟩. Raises Invalid_Argument if lengths differ or either is empty.

private

   type Weight_Store is array (Expert_Index) of Real;
   type Loss_Store is array (Expert_Index) of Real;

   type Learner is record
      N            : Expert_Count   := 1;
      Eta          : Positive_Real  := 0.1;
      Variant      : Update_Kind    := Hedge;
      W            : Weight_Store   := [others => 1.0];
      Expert_Cum   : Loss_Store     := [others => 0.0];
      Alg_Cum      : Real           := 0.0;
      Round_Count  : Natural        := 0;
      Initialized  : Boolean        := False;
   end record;

end Multiplicative_Weight_Update_Method;
