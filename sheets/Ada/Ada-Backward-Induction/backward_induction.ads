--  Backward_Induction — Ada 2023 educational package for Wikipedia
--  "Backward induction": solve finite extensive-form games of perfect
--  information from terminal nodes back to the root, yielding a
--  subgame-perfect Nash equilibrium (SPNE) path and payoff vector.
--  Classroom scope: two-player pure strategies on finite trees (no
--  imperfect information sets required). Classic constructors:
--  Ultimatum, Entry deterrence / Stackelberg toy, Finite Centipede,
--  Subtraction / Nim heap, and small hand-built binary trees.
--  Primary source: https://en.wikipedia.org/wiki/Backward_induction
--  Sibling sheets (README only — do not `with`): Bayesian Nash
--  Equilibrium, Minimax / Alpha–Beta — RobertBoettcherSF Ada series.

pragma Ada_2022;

package Backward_Induction
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational finite trees)
   ---------------------------------------------------------------------------

   Max_Children : constant Positive := 16;
   Max_Path     : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Player_Id is range 1 .. 2;
   --  Player 1 moves first at the root of classic constructors unless noted.

   subtype Payoff is Long_Float;
   type Payoff_Vector is array (Player_Id) of Payoff;

   subtype Child_Count is Natural range 0 .. Max_Children;
   subtype Child_Index is Positive range 1 .. Max_Children;

   type Node_Kind is (Terminal, Decision);
   --  Terminal: leaf payoffs. Decision: exactly one player chooses among
   --  Children (1 .. N_Children). No chance moves in the core API.

   type Game_Node;
   type Node_Access is access all Game_Node;

   type Child_Array is array (Child_Index) of Node_Access;

   type Game_Node is record
      Kind       : Node_Kind     := Terminal;
      Player     : Player_Id     := 1;              -- Decision: who maximises
      Payoffs    : Payoff_Vector := [1 => 0.0, 2 => 0.0];  -- Terminal only
      N_Children : Child_Count   := 0;
      Children   : Child_Array   := [others => null];
   end record;

   --  Unconstrained list for Decision constructors.
   type Node_List is array (Positive range <>) of Node_Access;

   --  Zero-sum leaf scores for player 1 (player 2 gets the negation).
   type Score_List is array (Positive range <>) of Payoff;

   --  SPNE outcome: equilibrium payoff vector plus the sequence of
   --  Child_Index choices from the root under optimal play.
   type Path_Array is array (1 .. Max_Path) of Child_Index;

   type Equilibrium_Profile is record
      Payoffs : Payoff_Vector := [1 => 0.0, 2 => 0.0];
      Length  : Natural       := 0;
      Actions : Path_Array    := [others => 1];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for null roots, empty / oversized child lists, malformed
   --  trees (decision with zero children, null child pointers, terminal
   --  with children), out-of-range indices, or negative tolerances.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol : constant Payoff := 1.0E-9;

   function Near
     (X, Y : Payoff; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;
   --  |X − Y| ≤ Tol. Tol must be ≥ 0 (else Invalid_Argument).

   function Near_Vector
     (A, B : Payoff_Vector; Tol : Payoff := Default_Tol) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Tree constructors (heap-allocated; caller owns lifetime)
   ---------------------------------------------------------------------------

   function Make_Terminal (P1, P2 : Payoff) return Node_Access
     with Global => null;
   --  Leaf with payoff vector (P1, P2).

   function Make_Decision
     (Who  : Player_Id;
      Kids : Node_List) return Node_Access
     with Global => null;
   --  Decision node for Who with Kids as ordered actions (1-based).
   --  Raises Invalid_Argument if Kids is empty, longer than Max_Children,
   --  or contains a null entry.

   function Is_Well_Formed (Root : Node_Access) return Boolean
     with Global => null;
   --  True iff Root is non-null and every reachable node is either a
   --  Terminal with N_Children = 0 or a Decision with 1 .. Max_Children
   --  non-null children that are themselves well-formed. Cycles are not
   --  detected (classroom trees are acyclic by construction).

   function Node_Count (Root : Node_Access) return Natural
     with Global => null;
   --  Number of nodes in the tree. Raises if Root is null.

   function Depth (Root : Node_Access) return Natural
     with Global => null;
   --  Longest root-to-leaf edge count. Raises if Root is null.

   ---------------------------------------------------------------------------
   -- Backward induction core
   ---------------------------------------------------------------------------

   function Value (Node : Node_Access) return Payoff_Vector
     with Global => null;
   --  SPNE payoff vector of the subgame rooted at Node. At a Terminal,
   --  returns Payoffs. At a Decision for player i, returns Value of the
   --  child that maximises coordinate i (lowest Child_Index on ties).
   --  Raises Invalid_Argument if Node is null or the tree is malformed.

   function Optimal_Action (Node : Node_Access) return Child_Index
     with Global => null;
   --  1-based index of the SPNE-optimal child at a Decision node
   --  (lowest index on ties). Raises if Node is null, Terminal, or
   --  malformed.

   function Solve (Root : Node_Access) return Equilibrium_Profile
     with Global => null;
   --  Full SPNE: equilibrium payoffs plus the action path from Root
   --  under optimal play until a Terminal is reached. Raises if Root
   --  is null / malformed, or the path would exceed Max_Path.

   function Equilibrium_Payoffs (Root : Node_Access) return Payoff_Vector
     with Global => null;
   --  Same as Solve (Root).Payoffs.

   function Equilibrium_Path_Length (Root : Node_Access) return Natural
     with Global => null;

   function Action_On_Path
     (Root : Node_Access; Step : Positive) return Child_Index
     with Global => null;
   --  Solve(Root).Actions (Step). Raises if Step out of 1 .. Length.

   ---------------------------------------------------------------------------
   -- Classic classroom games
   ---------------------------------------------------------------------------

   function Ultimatum
     (Pot   : Payoff;
      Offer : Payoff) return Node_Access
     with Global => null;
   --  Tiny ultimatum: Player 1 has already proposed Offer to Player 2
   --  from pot Pot (keeps Pot − Offer). Player 2 Accepts →
   --  (Pot−Offer, Offer) or Rejects → (0, 0). Raises if Pot < 0 or
   --  Offer not in [0, Pot]. Money-maximising SPNE: Accept any Offer ≥ 0.

   function Ultimatum_Discrete
     (Pot_Units : Natural) return Node_Access
     with Global => null;
   --  Proposer chooses integer offer k = 0 .. Pot_Units; Responder
   --  Accept/Reject at each offer. SPNE: offer 0, accept. Raises if
   --  Pot_Units = 0 or Pot_Units + 1 > Max_Children (Pot_Units ≤ 15).

   function Entry_Deterrence return Node_Access
     with Global => null;
   --  Entrant (P1): Out → (0, 2); In → Incumbent (P2) Fight (−1, −1)
   --  or Accommodate (1, 1). SPNE: In, Accommodate → (1, 1).

   function Stackelberg_Toy return Node_Access
     with Global => null;
   --  Quantity leadership toy: Leader (P1) High / Low; Follower (P2)
   --  responds High / Low with classroom payoffs. SPNE documented in
   --  tests / README.

   function Centipede
     (Stages          : Positive;
      Start_Take_P1   : Payoff := 1.0;
      Start_Take_P2   : Payoff := 0.0;
      Growth          : Payoff := 1.0) return Node_Access
     with Global => null;
   --  Finite Centipede of Stages decision plies. Odd plies: P1; even: P2.
   --  At ply k the mover may Take (current pot split) or Pass (pot grows
   --  by Growth for the continuing side). After the last Pass the
   --  terminal awards the grown pot. SPNE: Take at the first node.
   --  Raises if Stages > Max_Path.

   function Subtraction_Game
     (Heap     : Natural;
      Max_Take : Positive) return Node_Access
     with Global => null;
   --  Impartial takeaway / Nim heap: players alternate removing
   --  1 .. Max_Take objects from Heap. Player who faces 0 loses
   --  (payoffs (0,1) if P1 to move, (1,0) if P2). P1 moves first.
   --  Raises if Max_Take > Max_Children or Heap > 40 (node budget).

   function Simple_Binary_Tree return Node_Access
     with Global => null;
   --  Fixed depth-2 binary example used in unit tests:
   --  P1 chooses L/R; under L, P2 chooses (3,1) vs (0,2); under R,
   --  P2 chooses (1,3) vs (2,0). SPNE: R then (1,3) → (1, 3) (P2 maximises own payoff under each branch).

   function Zero_Sum_Choice
     (Scores_For_P1 : Score_List) return Node_Access
     with Global => null;
   --  P1 chooses among terminals with payoffs (s, −s) for each score s.
   --  Raises if Scores_For_P1 is empty or longer than Max_Children.

   function Take_Or_Leave_Chain
     (Rounds : Positive;
      High   : Payoff := 2.0;
      Low    : Payoff := 1.0) return Node_Access
     with Global => null;
   --  Alternating take-or-leave: at each round the mover takes High for
   --  self / Low for other and ends, or leaves (continues). Last mover
   --  must take. Related to ultimatum / centipede classroom variants.
   --  Raises if Rounds > Max_Path.

end Backward_Induction;
