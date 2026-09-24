--  Vickrey_Clarke_Groves_Mechanism — Ada 2023 educational package for
--  the Vickrey–Clarke–Groves (VCG) mechanism: choose an outcome that
--  maximises reported social welfare and charge each agent its Clarke
--  pivot (externality) payment. Dominant-strategy incentive compatible
--  for quasilinear utilities. Classroom scope: finite outcome sets,
--  few agents; single-item Vickrey; public-project / binary choice;
--  tiny two-item combinatorial allocation.
--  Reference: https://en.wikipedia.org/wiki/Vickrey%E2%80%93Clarke%E2%80%93Groves_mechanism
--  Sibling sheets (README only — do not `with`): Combinatorial Auction,
--  Top Trading Cycle — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Vickrey_Clarke_Groves_Mechanism
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational finite social-choice instances)
   ---------------------------------------------------------------------------

   Max_Agents   : constant Positive := 12;
   Max_Outcomes : constant Positive := 24;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Agent_Id is range 1 .. Max_Agents;
   type Outcome_Id is range 1 .. Max_Outcomes;
   subtype Agent_Count is Natural range 0 .. Max_Agents;
   subtype Outcome_Count is Natural range 0 .. Max_Outcomes;

   --  Reported valuations, Clarke payments, and quasilinear utilities.
   --  Payment p_i is the amount agent i pays the mechanism (positive =
   --  transfer from the agent). Utility is v_i(o*) − p_i.
   subtype Money is Long_Float;

   --  V(i, o) = reported v_i(o). Both indices must be 1-based.
   type Valuation_Matrix is
     array (Agent_Id range <>, Outcome_Id range <>) of Money;

   --  Bids, payments, utilities, outcome costs, weights, one-row reports.
   type Money_Vector is array (Positive range <>) of Money;

   --  Two-item combinatorial toy: each agent reports a value for the
   --  empty bundle, item A, item B, and {A, B}.
   type Bundle is (Empty, A_Only, B_Only, Both);
   type Bundle_Values is array (Bundle) of Money;
   type Agent_Bundles is array (Positive range <>) of Bundle_Values;

   --  Full VCG run: efficient outcome, Clarke payments, utilities.
   --  Payments / Utilities are populated in 1 .. N (remaining slots 0).
   type Mechanism_Result is record
      N         : Agent_Count := 0;
      Chosen    : Outcome_Id  := 1;
      Welfare   : Money       := 0.0;  -- Σ_i v_i(o*) − c(o*)
      Payments  : Money_Vector (1 .. Max_Agents) := [others => 0.0];
      Utilities : Money_Vector (1 .. Max_Agents) := [others => 0.0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for empty agent / outcome / bid sets, non-1-based tables,
   --  sizes above Max_Agents / Max_Outcomes, agent or outcome ids
   --  outside the instance, cost / weight / report vectors of the wrong
   --  length, non-positive weights, negative reserve, or Tol < 0.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol : constant Money := 1.0E-9;

   function Near
     (A, B : Money; Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  |A − B| ≤ Tol. Tol must be ≥ 0 (else Invalid_Argument).

   function Near_Vector
     (A, B : Money_Vector; Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  Same length and componentwise Near. Mismatched bounds → False.
   --  Tol must be ≥ 0.

   ---------------------------------------------------------------------------
   -- Matrix shape
   ---------------------------------------------------------------------------

   function N_Agents (V : Valuation_Matrix) return Positive
     with Global => null;
   --  Number of agents (V'Length (1)). Validates a non-empty 1-based
   --  table within capacity.

   function N_Outcomes (V : Valuation_Matrix) return Positive
     with Global => null;
   --  Number of outcomes (V'Length (2)).

   function Report
     (V : Valuation_Matrix; I : Agent_Id; O : Outcome_Id) return Money
     with Global => null;
   --  V(I, O). Raises if I or O is outside the table.

   ---------------------------------------------------------------------------
   -- Social welfare and efficient outcome
   ---------------------------------------------------------------------------

   function Social_Welfare
     (V : Valuation_Matrix; O : Outcome_Id) return Money
     with Global => null;
   --  Σ_i v_i(O)  (reported utilitarian welfare, no outcome cost).

   function Others_Welfare
     (V : Valuation_Matrix; O : Outcome_Id; I : Agent_Id) return Money
     with Global => null;
   --  Σ_{j≠i} v_j(O).

   function Net_Welfare
     (V : Valuation_Matrix; O : Outcome_Id; Cost : Money) return Money
     with Global => null;
   --  Σ_i v_i(O) − Cost.

   function Efficient_Outcome (V : Valuation_Matrix) return Outcome_Id
     with Global => null;
   --  o* = arg max_o Σ_i v_i(o). Lowest Outcome_Id on ties.

   function Efficient_Outcome
     (V : Valuation_Matrix; Costs : Money_Vector) return Outcome_Id
     with Global => null;
   --  o* = arg max_o [Σ_i v_i(o) − c(o)]. Costs'Length = N_Outcomes,
   --  1-based. Lowest index on ties.

   function Efficient_Outcome_Without
     (V : Valuation_Matrix; I : Agent_Id) return Outcome_Id
     with Global => null;
   --  o*_{-i} = arg max_o Σ_{j≠i} v_j(o).

   function Efficient_Outcome_Without
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Outcome_Id
     with Global => null;

   function Efficient_Welfare (V : Valuation_Matrix) return Money
     with Global => null;
   --  Σ_i v_i(o*).

   function Efficient_Welfare
     (V : Valuation_Matrix; Costs : Money_Vector) return Money
     with Global => null;
   --  Σ_i v_i(o*) − c(o*).

   function Is_Welfare_Maximizing
     (V   : Valuation_Matrix;
      O   : Outcome_Id;
      Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  True iff Social_Welfare(V, O) ≈ Efficient_Welfare(V).

   ---------------------------------------------------------------------------
   -- Clarke pivot rule / VCG payments
   ---------------------------------------------------------------------------

   function Clarke_H
     (V : Valuation_Matrix; I : Agent_Id) return Money
     with Global => null;
   --  h_i(v_{-i}) = Σ_{j≠i} v_j(o*_{-i}).

   function Clarke_H
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Money
     with Global => null;
   --  h_i = max_o [Σ_{j≠i} v_j(o) − c(o)].

   function Clarke_Payment
     (V : Valuation_Matrix; I : Agent_Id) return Money
     with Global => null;
   --  p_i = h_i(v_{-i}) − Σ_{j≠i} v_j(o*).  The externality of i.

   function Clarke_Payment
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Money
     with Global => null;
   --  p_i = h_i − [Σ_{j≠i} v_j(o*) − c(o*)].

   function VCG_Payments (V : Valuation_Matrix) return Money_Vector
     with Global => null;
   --  Clarke payment of every agent (index 1 .. N).

   function VCG_Payments
     (V : Valuation_Matrix; Costs : Money_Vector) return Money_Vector
     with Global => null;

   function VCG_Utility
     (V : Valuation_Matrix; I : Agent_Id) return Money
     with Global => null;
   --  u_i = v_i(o*) − p_i.

   function VCG_Utility
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Money
     with Global => null;

   function VCG_Utilities (V : Valuation_Matrix) return Money_Vector
     with Global => null;

   function VCG_Utilities
     (V : Valuation_Matrix; Costs : Money_Vector) return Money_Vector
     with Global => null;

   function Changes_Outcome
     (V : Valuation_Matrix; I : Agent_Id) return Boolean
     with Global => null;
   --  True iff o* ≠ o*_{-i} (index comparison; ties may flip the label
   --  without changing welfare).

   function Changes_Outcome
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Boolean
     with Global => null;

   function Is_Pivotal
     (V   : Valuation_Matrix;
      I   : Agent_Id;
      Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  True iff |p_i| > Tol (strictly nonzero Clarke payment).

   function Is_Pivotal
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector;
      Tol   : Money := Default_Tol) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Run (outcome + payments + utilities)
   ---------------------------------------------------------------------------

   function Run (V : Valuation_Matrix) return Mechanism_Result
     with Global => null;
   --  Efficient outcome, Clarke payments, utilities v_i(o*) − p_i.

   function Run
     (V : Valuation_Matrix; Costs : Money_Vector) return Mechanism_Result
     with Global => null;

   function Total_Revenue (Payments : Money_Vector) return Money
     with Global => null;
   --  Σ_i p_i.

   function Payments_Nonnegative
     (Payments : Money_Vector; Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  True iff every p_i ≥ −Tol (Wikipedia “no positive transfers”
   --  under the pay-the-mechanism sign convention).

   function Is_Individually_Rational
     (Utilities : Money_Vector; Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  True iff every u_i ≥ −Tol.

   ---------------------------------------------------------------------------
   -- Weighted VCG (Roberts affine maximiser)
   ---------------------------------------------------------------------------

   function Weighted_Social_Welfare
     (V       : Valuation_Matrix;
      O       : Outcome_Id;
      Weights : Money_Vector) return Money
     with Global => null;
   --  Σ_i w_i v_i(O). Weights 1-based, length N, each w_i > 0.

   function Weighted_Efficient_Outcome
     (V       : Valuation_Matrix;
      Weights : Money_Vector) return Outcome_Id
     with Global => null;
   --  arg max_o Σ_i w_i v_i(o). Lowest index on ties.

   function Weighted_Clarke_Payment
     (V       : Valuation_Matrix;
      Weights : Money_Vector;
      I       : Agent_Id) return Money
     with Global => null;
   --  p_i = (1/w_i) [max_o Σ_{j≠i} w_j v_j(o) − Σ_{j≠i} w_j v_j(o*)].

   function Weighted_VCG_Payments
     (V : Valuation_Matrix; Weights : Money_Vector) return Money_Vector
     with Global => null;

   function Weighted_Run
     (V : Valuation_Matrix; Weights : Money_Vector) return Mechanism_Result
     with Global => null;
   --  Utilities remain v_i(o*) − p_i (unweighted value minus payment).

   ---------------------------------------------------------------------------
   -- Report surgery (truthfulness experiments)
   ---------------------------------------------------------------------------

   function With_Agent_Report
     (V        : Valuation_Matrix;
      I        : Agent_Id;
      New_Vals : Money_Vector) return Valuation_Matrix
     with Global => null;
   --  Copy of V in which row I is replaced by New_Vals
   --  (length N_Outcomes, 1-based).

   ---------------------------------------------------------------------------
   -- Single-item Vickrey (second-price) auction
   ---------------------------------------------------------------------------

   function Highest_Bid (Bids : Money_Vector) return Money
     with Global => null;

   function Second_Highest_Bid (Bids : Money_Vector) return Money
     with Global => null;
   --  0.0 when there is only one bid.

   function Arg_Highest_Bid (Bids : Money_Vector) return Positive
     with Global => null;
   --  Lowest index among maximisers.

   function Make_Single_Item_Valuations
     (Bids : Money_Vector) return Valuation_Matrix
     with Global => null;
   --  Outcomes 1 .. N: give the item to that agent.
   --  V(i, i) = Bids(i), other entries 0.

   function Make_Single_Item_Valuations
     (Bids : Money_Vector; Reserve : Money) return Valuation_Matrix
     with Global => null;
   --  N bidder agents plus a seller (agent N+1); outcomes 1 .. N sell
   --  to that bidder, outcome N+1 is unsold with seller value Reserve.
   --  Reserve must be ≥ 0.

   function Vickrey_Winner
     (Bids : Money_Vector; Reserve : Money := 0.0) return Natural
     with Global => null;
   --  Highest bidder at or above Reserve (lowest index on ties), or 0
   --  if no bid meets the reserve.

   function Vickrey_Price
     (Bids : Money_Vector; Reserve : Money := 0.0) return Money
     with Global => null;
   --  max(second-highest qualifying bid, Reserve) when there is a
   --  winner; 0.0 when the item is unsold.

   function Vickrey_Auction
     (Bids : Money_Vector; Reserve : Money := 0.0) return Mechanism_Result
     with Global => null;
   --  Result over the N bidders (seller omitted). Chosen is the winner
   --  agent id, or N+1 when unsold. Winner pays Vickrey_Price; others 0.

   ---------------------------------------------------------------------------
   -- Public project / binary choice
   ---------------------------------------------------------------------------

   function Make_Binary_Choice
     (Pref_Alt : Money_Vector) return Valuation_Matrix
     with Global => null;
   --  Outcome 1 = status quo (all 0); outcome 2 = alternative
   --  (agent i reports Pref_Alt(i)).

   function Make_Public_Project
     (Values : Money_Vector) return Valuation_Matrix
     with Global => null;
   --  Same shape as Make_Binary_Choice: No / Yes.

   function Should_Build
     (Values : Money_Vector; Cost : Money) return Boolean
     with Global => null;
   --  True iff Σ Values > Cost (strict; ties stay with No).

   function Public_Project_Tax
     (Values : Money_Vector;
      Cost   : Money;
      I      : Agent_Id) return Money
     with Global => null;
   --  Clarke tax of citizen I for cost Cost.

   function Public_Project
     (Values : Money_Vector; Cost : Money) return Mechanism_Result
     with Global => null;
   --  Chosen = 2 if the project is built, 1 otherwise.

   ---------------------------------------------------------------------------
   -- Tiny two-item combinatorial allocation
   ---------------------------------------------------------------------------

   function Two_Item_Outcome_Count (N : Positive) return Positive
     with Global => null;
   --  (N+1)^2 assignments of items A, B to {unsold, agent 1 .. N}.
   --  Raises if N = 0, N > Max_Agents, or the count exceeds Max_Outcomes.

   function Two_Item_Outcome
     (Owner_A, Owner_B : Natural; N : Positive) return Outcome_Id
     with Global => null;
   --  0 = unsold. Outcome index Owner_A*(N+1) + Owner_B + 1.

   procedure Decode_Two_Item_Outcome
     (O              : Outcome_Id;
      N              : Positive;
      Owner_A, Owner_B : out Natural)
     with Global => null;

   function Make_Two_Item_Valuations
     (Reports : Agent_Bundles) return Valuation_Matrix
     with Global => null;
   --  1-based Reports, length N in 1 .. 3 (so (N+1)^2 ≤ 16 ≤ Max).

   function Two_Item_Allocation
     (Reports : Agent_Bundles) return Mechanism_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Instance builder (optional imperative API)
   ---------------------------------------------------------------------------

   type Instance is limited private;

   procedure Clear
     (Inst : in out Instance; Agents, Outcomes : Natural)
     with Global => null;
   --  Reset to an Agents × Outcomes zero table (costs 0). Either
   --  dimension 0 is the empty instance. Raises if a positive size
   --  exceeds capacity.

   function Size_Agents (Inst : Instance) return Agent_Count
     with Global => null;

   function Size_Outcomes (Inst : Instance) return Outcome_Count
     with Global => null;

   procedure Set_Value
     (Inst : in out Instance;
      I    : Agent_Id;
      O    : Outcome_Id;
      X    : Money)
     with Global => null;

   function Get_Value
     (Inst : Instance; I : Agent_Id; O : Outcome_Id) return Money
     with Global => null;

   procedure Set_Cost
     (Inst : in out Instance; O : Outcome_Id; C : Money)
     with Global => null;

   function Get_Cost (Inst : Instance; O : Outcome_Id) return Money
     with Global => null;

   function As_Matrix (Inst : Instance) return Valuation_Matrix
     with Global => null;

   function Costs_Of (Inst : Instance) return Money_Vector
     with Global => null;

   function Run (Inst : Instance) return Mechanism_Result
     with Global => null;

private

   type Instance is record
      N : Agent_Count   := 0;
      M : Outcome_Count := 0;
      V : Valuation_Matrix (Agent_Id, Outcome_Id) :=
        [others => [others => 0.0]];
      C : Money_Vector (1 .. Max_Outcomes) := [others => 0.0];
   end record;

end Vickrey_Clarke_Groves_Mechanism;
