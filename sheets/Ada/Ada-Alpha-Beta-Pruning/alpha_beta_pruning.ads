--  Alpha_Beta_Pruning — Ada 2023 educational package for Wikipedia
--  "Alpha–beta pruning": adversarial search that returns the same
--  root decision as minimax while pruning branches that cannot
--  influence the final value. Explicit numeric game trees with
--  Nodes_Visited / Cutoffs stats; optional Tic-Tac-Toe (3×3).
--  Primary source:
--  https://en.wikipedia.org/wiki/Alpha–beta_pruning
--  Siblings (README links only — no package deps):
--  Ada-Minimax, Ada-Branch-and-Bound.

pragma Ada_2022;

package Alpha_Beta_Pruning
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;
   subtype Score is Real;

   Epsilon_Tol : constant Real := 1.0E-10;

   Neg_Inf : constant Score := -1.0E20;
   Pos_Inf : constant Score := 1.0E20;

   Invalid_Argument : exception;
   No_Legal_Move    : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Max_Score (A, B : Score) return Score
     with Global => null;

   function Min_Score (A, B : Score) return Score
     with Global => null;

   ---------------------------------------------------------------------------
   -- Explicit game tree (children arrays + leaf scores)
   ---------------------------------------------------------------------------

   Max_Children : constant := 8;
   subtype Child_Count is Natural range 0 .. Max_Children;
   subtype Child_Index is Positive range 1 .. Max_Children;

   type Tree_Node;
   type Node_Access is access all Tree_Node;

   --  Public aliases matching the requested API vocabulary.
   subtype Node is Tree_Node;
   subtype Tree is Node_Access;

   type Child_List is array (Child_Index range <>) of Node_Access;

   type Tree_Node is record
      Leaf_Value : Score       := 0.0;
      Is_Leaf    : Boolean     := True;
      N_Children : Child_Count := 0;
      Children   : Child_List (1 .. Max_Children) := [others => null];
   end record;

   --  Heap constructors; caller owns lifetime (tests are short-lived).
   function Leaf (V : Score) return Node_Access
     with Global => null;

   function Branch (Kids : Child_List) return Node_Access
     with Pre => Kids'Length > 0 and then Kids'Length <= Max_Children,
          Global => null;

   ---------------------------------------------------------------------------
   -- Search result (value + move index + counters)
   ---------------------------------------------------------------------------

   --  Best_Child : 1-based child index among Root.Children, or 0 on a leaf.
   --  Nodes_Visited : every recursive entry (including the root).
   --  Cutoffs : beta <= alpha prunes (Alpha_Beta only; Minimax keeps 0).
   type Result is record
      Value         : Score   := 0.0;
      Best_Child    : Natural := 0;
      Nodes_Visited : Natural := 0;
      Cutoffs       : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Minimax baseline and alpha–beta (same value, fewer nodes when pruning)
   ---------------------------------------------------------------------------

   --  Full minimax over an explicit tree; Maximizing = True at the root
   --  means Max ply. Counts every visited node; Cutoffs always 0.
   function Minimax
     (Root       : Node_Access;
      Maximizing : Boolean := True) return Result
     with Pre => Root /= null;

   --  Alpha–beta with initial window (Alpha, Beta). Returns the same
   --  root Value (and a Best_Child attaining it) as Minimax on finite
   --  trees; may visit fewer nodes and report Cutoffs > 0 when ordering
   --  allows pruning.
   function Alpha_Beta
     (Root       : Node_Access;
      Maximizing : Boolean := True;
      Alpha      : Score   := Neg_Inf;
      Beta       : Score   := Pos_Inf) return Result
     with Pre => Root /= null;

   --  Best root child index (1-based) for Max / Min at Root.
   function Best_Move_Minimax
     (Root       : Node_Access;
      Maximizing : Boolean := True) return Child_Index
     with Pre =>
       Root /= null
       and then not Root.Is_Leaf
       and then Root.N_Children > 0;

   function Best_Move_Alpha_Beta
     (Root       : Node_Access;
      Maximizing : Boolean := True;
      Alpha      : Score   := Neg_Inf;
      Beta       : Score   := Pos_Inf) return Child_Index
     with Pre =>
       Root /= null
       and then not Root.Is_Leaf
       and then Root.N_Children > 0;

   --  Convenience aliases.
   function Best_Move
     (Root           : Node_Access;
      Maximizing     : Boolean := True;
      Use_Alpha_Beta : Boolean := True) return Child_Index
     with Pre =>
       Root /= null
       and then not Root.Is_Leaf
       and then Root.N_Children > 0;

   ---------------------------------------------------------------------------
   -- Optional Tic-Tac-Toe (3×3) — perfect play + node counts
   ---------------------------------------------------------------------------

   type Cell is (Empty, X, O);
   --  X maximizes (+1), O minimizes (−1); X moves first on Empty_Board.

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

   function Is_Full (B : Board) return Boolean
     with Global => null;

   function Is_Terminal (B : Board) return Boolean
     with Global => null;

   function Evaluate (B : Board) return Score
     with Pre => Is_Terminal (B), Global => null;

   type Move is record
      R : Row := 1;
      C : Col := 1;
   end record;

   Max_Moves : constant := 9;
   subtype Move_Count is Natural range 0 .. Max_Moves;
   subtype Move_Index is Positive range 1 .. Max_Moves;

   type Move_List is array (Move_Index range <>) of Move;

   function Legal_Moves (B : Board) return Move_List
     with Global => null;

   function Apply_Move (B : Board; M : Move; Who : Mark) return Board
     with Pre => B (M.R, M.C) = Empty, Global => null;

   function Count_Empty (B : Board) return Move_Count
     with Global => null;

   function Side_To_Move (B : Board) return Mark
     with Global => null;

   --  Perfect-play value for the side to move, with node / cutoff stats.
   function Minimax_TTT
     (B       : Board;
      To_Move : Mark;
      Depth   : Natural := 9) return Result
     with Global => null;

   function Alpha_Beta_TTT
     (B       : Board;
      To_Move : Mark;
      Alpha   : Score   := Neg_Inf;
      Beta    : Score   := Pos_Inf;
      Depth   : Natural := 9) return Result
     with Global => null;

   function Best_Move_TTT
     (B              : Board;
      To_Move        : Mark;
      Use_Alpha_Beta : Boolean := True) return Move
     with Pre => not Is_Terminal (B) and then Count_Empty (B) > 0;

end Alpha_Beta_Pruning;
