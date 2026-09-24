--  Minimax — Ada 2023 educational package for Wikipedia "Minimax"
--  (alternate-moves two-player zero-sum game tree). Implements
--  recursive Max_Value / Min_Value, optional alpha–beta pruning,
--  Best_Move, an explicit numeric game-tree fixture, and a concrete
--  Tic-Tac-Toe (3×3) board with perfect-play evaluation (+1 / 0 / −1).
--  Primary source: https://en.wikipedia.org/wiki/Minimax
--  Siblings: Ada-Viterbi / Ada-BFGS (README links).

pragma Ada_2022;

package Minimax
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;
   subtype Score is Real;

   --  Maximizing player seeks high Score; Minimizing seeks low Score.
   type Side is (Maximizing, Minimizing);

   Epsilon_Tol : constant Real := 1.0E-10;

   Neg_Inf : constant Score := -1.0E20;
   Pos_Inf : constant Score := 1.0E20;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

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
   -- Explicit numeric game tree (Wikipedia-style leaf scores)
   ---------------------------------------------------------------------------

   --  Small fixed-arity tree for unit tests of pure minimax values.
   Max_Children : constant := 8;
   subtype Child_Count is Natural range 0 .. Max_Children;
   subtype Child_Index is Positive range 1 .. Max_Children;

   type Tree_Node;
   type Tree_Access is access all Tree_Node;

   type Child_List is array (Child_Index range <>) of Tree_Access;

   type Tree_Node is record
      Leaf_Value : Score       := 0.0;
      Is_Leaf    : Boolean     := True;
      N_Children : Child_Count := 0;
      Children   : Child_List (1 .. Max_Children) := [others => null];
   end record;

   --  Convenience constructors (heap-allocated; caller owns lifetime).
   function Leaf (V : Score) return Tree_Access
     with Global => null;

   function Branch
     (Kids : Child_List) return Tree_Access
     with Pre => Kids'Length > 0 and then Kids'Length <= Max_Children,
          Global => null;

   --  Depth-limited minimax over an explicit tree.
   --  Maximizing_Player = True  → Max_Value at the root.
   function Minimax_Tree
     (Node              : Tree_Access;
      Maximizing_Player : Boolean;
      Depth             : Natural := Natural'Last) return Score
     with Pre => Node /= null, Global => null;

   function Max_Value_Tree
     (Node : Tree_Access; Depth : Natural) return Score
     with Pre => Node /= null, Global => null;

   function Min_Value_Tree
     (Node : Tree_Access; Depth : Natural) return Score
     with Pre => Node /= null, Global => null;

   --  Alpha–beta pruning; same root value as Minimax_Tree on finite trees.
   function Alpha_Beta_Tree
     (Node              : Tree_Access;
      Maximizing_Player : Boolean;
      Alpha             : Score   := Neg_Inf;
      Beta              : Score   := Pos_Inf;
      Depth             : Natural := Natural'Last) return Score
     with Pre => Node /= null, Global => null;

   --  Index (1-based among Node.Children) of the best root move for Max/Min.
   function Best_Child_Index
     (Node              : Tree_Access;
      Maximizing_Player : Boolean;
      Use_Alpha_Beta    : Boolean := False) return Child_Index
     with Pre =>
       Node /= null
       and then not Node.Is_Leaf
       and then Node.N_Children > 0;

   ---------------------------------------------------------------------------
   -- Tic-Tac-Toe (3×3) — concrete alternate-moves game
   ---------------------------------------------------------------------------

   type Cell is (Empty, X, O);
   --  X = Maximizing (+1 win), O = Minimizing (−1 means X lost / O won).

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

   --  Encode / decode board as base-3 integer in 0 .. 3^9−1.
   Max_Board_Code : constant := 19682;  -- 3^9 - 1
   subtype Board_Code is Natural range 0 .. Max_Board_Code;

   function Encode (B : Board) return Board_Code
     with Global => null;

   function Decode (Code : Board_Code) return Board
     with Global => null;

   --  Winner: Empty = none / draw-in-progress; X or O if that mark won.
   function Winner (B : Board) return Cell
     with Global => null;

   function Is_Full (B : Board) return Boolean
     with Global => null;

   function Is_Terminal (B : Board) return Boolean
     with Global => null;

   --  Leaf evaluation from X's perspective: +1 X win, −1 O win, 0 draw.
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

   --  Whose turn given empty-cell parity from a fresh board (X starts).
   function Side_To_Move (B : Board) return Mark
     with Global => null;

   ---------------------------------------------------------------------------
   -- Minimax / alpha–beta over Tic-Tac-Toe boards
   ---------------------------------------------------------------------------

   --  Value of position for the maximizing player (X), assuming perfect play
   --  and that `To_Move` is about to play. Depth limits plies remaining;
   --  when Depth = 0 on a non-terminal, returns 0.0 (heuristic stub).
   function Minimax
     (B       : Board;
      To_Move : Mark;
      Depth   : Natural := 9) return Score
     with Global => null;

   function Max_Value
     (B : Board; Depth : Natural) return Score
     with Global => null;

   function Min_Value
     (B : Board; Depth : Natural) return Score
     with Global => null;

   function Alpha_Beta
     (B       : Board;
      To_Move : Mark;
      Alpha   : Score   := Neg_Inf;
      Beta    : Score   := Pos_Inf;
      Depth   : Natural := 9) return Score
     with Global => null;

   --  Best cell for the maximizing / current side at B.
   function Best_Move
     (B              : Board;
      To_Move        : Mark;
      Use_Alpha_Beta : Boolean := True) return Move
     with Pre => not Is_Terminal (B) and then Count_Empty (B) > 0;

   ---------------------------------------------------------------------------
   -- Callback / access-to-subprogram game API (generic over State)
   ---------------------------------------------------------------------------

   --  Opaque small-integer state for callback demos (e.g. tree-node ids).
   type State_Id is new Natural;

   type Is_Terminal_Fn is access function (S : State_Id) return Boolean;
   type Evaluate_Fn    is access function (S : State_Id) return Score;
   type Child_Count_Fn is access function (S : State_Id) return Natural;
   type Child_At_Fn    is access function (S : State_Id; I : Positive)
     return State_Id;

   type Game_Callbacks is record
      Is_Terminal : Is_Terminal_Fn;
      Evaluate    : Evaluate_Fn;
      Child_Count : Child_Count_Fn;
      Child_At    : Child_At_Fn;
   end record;

   function Minimax_Callback
     (S                 : State_Id;
      G                 : Game_Callbacks;
      Maximizing_Player : Boolean;
      Depth             : Natural := Natural'Last) return Score
     with Pre =>
       G.Is_Terminal /= null
       and then G.Evaluate /= null
       and then G.Child_Count /= null
       and then G.Child_At /= null;

   function Alpha_Beta_Callback
     (S                 : State_Id;
      G                 : Game_Callbacks;
      Maximizing_Player : Boolean;
      Alpha             : Score   := Neg_Inf;
      Beta              : Score   := Pos_Inf;
      Depth             : Natural := Natural'Last) return Score
     with Pre =>
       G.Is_Terminal /= null
       and then G.Evaluate /= null
       and then G.Child_Count /= null
       and then G.Child_At /= null;


   ---------------------------------------------------------------------------
   -- Demo callback fixture (Wikipedia shallow tree, State_Id 0..6)
   ---------------------------------------------------------------------------

   --  Root 0 (max) → 1,2 (min) → leaves 3,4,5,6 with values 3,5,2,9.
   --  Perfect value at root: max(min(3,5), min(2,9)) = 3.
   function Demo_Is_Terminal (S : State_Id) return Boolean
     with Global => null;

   function Demo_Evaluate (S : State_Id) return Score
     with Global => null;

   function Demo_Child_Count (S : State_Id) return Natural
     with Global => null;

   function Demo_Child_At (S : State_Id; I : Positive) return State_Id
     with Global => null;

   function Demo_Game return Game_Callbacks
     with Global => null;

end Minimax;
