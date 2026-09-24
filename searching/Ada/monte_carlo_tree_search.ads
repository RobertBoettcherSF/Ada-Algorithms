--  Monte_Carlo_Tree_Search — Ada 2023 educational package for Wikipedia
--  "Monte Carlo tree search" (MCTS): heuristic game-tree search via
--  selection, expansion, simulation (rollout), and backpropagation,
--  guided by UCT (Upper Confidence Bound applied to Trees).
--  Classroom domains: Tic-Tac-Toe (3×3) and Nim / subtraction heap,
--  with a seeded PRNG for reproducible tests.
--  Primary source:
--  https://en.wikipedia.org/wiki/Monte_Carlo_tree_search
--  Siblings (README links only — no package `with`):
--  Ada-Backward-Induction, Ada-Alpha-Beta-Pruning, Ada-Minimax.

pragma Ada_2022;

package Monte_Carlo_Tree_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   --  Default UCT exploration constant C = √2 (Kocsis & Szepesvári).
   Default_C : constant Real := 1.4142135623730951;

   Epsilon_Tol : constant Real := 1.0E-10;

   Invalid_Argument : exception;
   --  Raised for zero iterations, negative C, empty move lists where a
   --  move is required, out-of-range indices, or malformed game params.

   No_Legal_Move : exception;
   --  Raised when Search is asked for a move on a terminal position.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp_Unit (X : Real) return Unit_Interval
     with Global => null;

   --  UCT score for a child:  X̄ + C √(ln N / n).
   --  Unvisited children (n = 0) return +∞ so selection prefers them.
   function UCT_Score
     (Mean_Reward   : Real;
      Child_Visits  : Natural;
      Parent_Visits : Natural;
      C             : Real := Default_C) return Real
     with Pre => C >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Seeded educational PRNG (LCG; reproducible across platforms)
   ---------------------------------------------------------------------------

   type RNG is private;

   function Make_RNG (Seed : Integer) return RNG
     with Global => null;
   --  Seed may be any Integer; internally mapped to a positive state.

   function Random_Unit (G : in out RNG) return Unit_Interval
     with Global => null;
   --  Uniform in [0, 1).

   function Random_Index
     (G : in out RNG; Lo, Hi : Positive) return Positive
     with Pre => Lo <= Hi, Global => null;
   --  Uniform integer in Lo .. Hi inclusive.

   ---------------------------------------------------------------------------
   -- Tic-Tac-Toe (3×3)
   ---------------------------------------------------------------------------

   type Cell is (Empty, X, O);
   --  X maximizes (+1), O is the opponent (−1 from X's view at root).

   subtype Row is Positive range 1 .. 3;
   subtype Col is Positive range 1 .. 3;

   type Board is array (Row, Col) of Cell;

   type Mark is (X_Mark, O_Mark);

   function To_Cell (M : Mark) return Cell
     with Global => null;

   function Opponent (M : Mark) return Mark
     with Global => null;

   function Empty_Board return Board
     with Global => null;

   function Winner (B : Board) return Cell
     with Global => null;
   --  Empty if no winner yet (may still be non-terminal if board not full).

   function Is_Full (B : Board) return Boolean
     with Global => null;

   function Is_Terminal (B : Board) return Boolean
     with Global => null;

   --  Terminal reward from Side_To_Move's perspective: +1 win, −1 loss, 0 draw.
   function Terminal_Reward (B : Board; Side : Mark) return Real
     with Pre => Is_Terminal (B), Global => null;

   type Move is record
      R : Row := 1;
      C : Col := 1;
   end record;

   Max_TTT_Moves : constant := 9;
   subtype TTT_Move_Count is Natural range 0 .. Max_TTT_Moves;
   subtype TTT_Move_Index is Positive range 1 .. Max_TTT_Moves;

   type TTT_Move_List is array (TTT_Move_Index range <>) of Move;

   function Legal_Moves_TTT (B : Board) return TTT_Move_List
     with Global => null;

   function Apply_Move_TTT (B : Board; M : Move; Who : Mark) return Board
     with Pre => B (M.R, M.C) = Empty, Global => null;

   function Count_Empty (B : Board) return TTT_Move_Count
     with Global => null;

   function Side_To_Move_TTT (B : Board) return Mark
     with Global => null;
   --  X starts; alternate by empty-cell parity (X if odd empties remain
   --  on a fresh board count: 9 empty → X). Equivalent: X if (9−empties)
   --  is even.

   function Moves_Equal (A, B : Move) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Nim / subtraction heap
   ---------------------------------------------------------------------------

   --  Players alternately remove 1 .. Max_Take objects from Heap.
   --  Facing Heap = 0 loses (terminal reward −1 for the side to move).
   Max_Nim_Take : constant Positive := 8;

   type Nim_State is record
      Heap     : Natural  := 0;
      Max_Take : Positive := 3;
   end record;

   function Is_Terminal_Nim (S : Nim_State) return Boolean
     with Global => null;

   --  +1 if Side_To_Move wins under optimal play is NOT computed here;
   --  terminal reward for the player who faces Heap = 0 is −1.
   function Terminal_Reward_Nim (S : Nim_State) return Real
     with Pre => Is_Terminal_Nim (S), Global => null;

   subtype Nim_Take is Positive range 1 .. Max_Nim_Take;
   subtype Nim_Move_Count is Natural range 0 .. Max_Nim_Take;
   subtype Nim_Move_Index is Positive range 1 .. Max_Nim_Take;

   type Nim_Move_List is array (Nim_Move_Index range <>) of Nim_Take;

   function Legal_Moves_Nim (S : Nim_State) return Nim_Move_List
     with Global => null;
   --  Raises Invalid_Argument if Max_Take > Max_Nim_Take or Max_Take = 0
   --  is impossible (Positive). Empty list when Heap = 0.

   function Apply_Move_Nim (S : Nim_State; Take : Nim_Take) return Nim_State
     with Global => null;
   --  Raises Invalid_Argument if Take > S.Max_Take or Take > S.Heap.

   --  Losing positions under optimal play: Heap mod (Max_Take+1) = 0.
   function Is_Losing_Position (S : Nim_State) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Search result (recommended root move + per-child stats)
   ---------------------------------------------------------------------------

   Max_Root_Children : constant := 16;

   type Child_Stat is record
      Visits      : Natural := 0;
      Total_Reward : Real   := 0.0;
      Mean_Reward  : Real   := 0.0;
   end record;

   type Child_Stat_Array is
     array (1 .. Max_Root_Children) of Child_Stat;

   --  Best_Index : 1-based index into the root legal-move list.
   --  Best_*     : the corresponding concrete move (TTT or Nim).
   --  Iterations : completed MCTS iterations (playouts).
   --  Root_Visits: visit count at the root after search.
   --  N_Children : how many root children were expanded / considered.
   --  Stats      : per-child visit / reward aggregates (side-to-move view).
   type Search_Result is record
      Best_Index  : Natural := 0;
      Best_TTT    : Move    := (1, 1);
      Best_Nim    : Nim_Take := 1;
      Iterations  : Natural := 0;
      Root_Visits : Natural := 0;
      N_Children  : Natural := 0;
      Stats       : Child_Stat_Array := [others => <>];
   end record;

   ---------------------------------------------------------------------------
   -- MCTS search
   ---------------------------------------------------------------------------

   --  Run Iterations of UCT-MCTS from Board with Side to move.
   --  C is the exploration constant; Seed initialises the PRNG.
   --  Raises Invalid_Argument if Iterations = 0 or C < 0.
   --  Raises No_Legal_Move if the position is terminal.
   function Search_TTT
     (B          : Board;
      Side       : Mark;
      Iterations : Positive;
      C          : Real    := Default_C;
      Seed       : Integer := 42) return Search_Result
     with Pre => C >= 0.0;

   --  Same for Nim / subtraction. Side to move faces S.Heap.
   function Search_Nim
     (S          : Nim_State;
      Iterations : Positive;
      C          : Real    := Default_C;
      Seed       : Integer := 42) return Search_Result
     with Pre => C >= 0.0;

   --  Pure Monte Carlo (flat): equal rollouts per legal root move, pick
   --  the move with highest mean reward (ties → lowest index).
   function Pure_Monte_Carlo_TTT
     (B             : Board;
      Side          : Mark;
      Playouts_Each : Positive;
      Seed          : Integer := 42) return Search_Result;

   function Pure_Monte_Carlo_Nim
     (S             : Nim_State;
      Playouts_Each : Positive;
      Seed          : Integer := 42) return Search_Result;

   ---------------------------------------------------------------------------
   -- Exposed helpers (teaching / tests)
   ---------------------------------------------------------------------------

   --  One random playout from B with Side to move; returns terminal
   --  reward from the original Side's perspective.
   function Rollout_TTT
     (B    : Board;
      Side : Mark;
      G    : in out RNG) return Real;

   function Rollout_Nim
     (S : Nim_State;
      G : in out RNG) return Real;
   --  Reward from the player about to move at S.

   --  Select child index maximizing UCT among 1 .. N with given stats.
   --  Parent_Visits is the parent's N; unvisited children score +∞.
   --  On ties among finite scores, the lowest index wins; among +∞,
   --  the lowest unvisited index wins.
   function Select_UCT_Child
     (Means         : Child_Stat_Array;
      N_Children    : Positive;
      Parent_Visits : Natural;
      C             : Real := Default_C) return Positive
     with Pre =>
       N_Children <= Max_Root_Children and then C >= 0.0;

private

   --  Park–Miller / MINSTD-style LCG: state' = (A * state) mod M.
   type RNG is record
      State : Long_Integer := 1;
   end record;

end Monte_Carlo_Tree_Search;
