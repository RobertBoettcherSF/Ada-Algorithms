--  Monte_Carlo_Tree_Search body — UCT-MCTS over Tic-Tac-Toe and Nim.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Monte_Carlo_Tree_Search
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument with "Near: Tol must be >= 0";
      end if;
      return abs (A - B) <= Tol;
   end Near;

   function Clamp_Unit (X : Real) return Unit_Interval is
   begin
      if X < 0.0 then
         return 0.0;
      elsif X > 1.0 then
         return 1.0;
      else
         return X;
      end if;
   end Clamp_Unit;

   function UCT_Score
     (Mean_Reward   : Real;
      Child_Visits  : Natural;
      Parent_Visits : Natural;
      C             : Real := Default_C) return Real
   is
      Ln_N : Real;
   begin
      if C < 0.0 then
         raise Invalid_Argument with "UCT_Score: C must be >= 0";
      end if;
      if Child_Visits = 0 then
         return Real'Last;  -- treat as +∞ for selection
      end if;
      if Parent_Visits = 0 then
         return Mean_Reward;
      end if;
      Ln_N := Real (EF.Log (Float (Parent_Visits)));
      return Mean_Reward
        + C * Real (EF.Sqrt (Float (Ln_N / Real (Child_Visits))));
   end UCT_Score;

   ---------------------------------------------------------------------------
   -- PRNG
   ---------------------------------------------------------------------------

   Modulus : constant Long_Integer := 2_147_483_647;  -- 2^31 − 1
   Multiplier : constant Long_Integer := 48_271;       -- MINSTD

   function Make_RNG (Seed : Integer) return RNG is
      S : Long_Integer;
   begin
      S := Long_Integer (Seed);
      if S <= 0 then
         S := 1 - S;  -- map non-positive to positive
      end if;
      S := S rem Modulus;
      if S = 0 then
         S := 1;
      end if;
      return (State => S);
   end Make_RNG;

   function Next_State (G : in out RNG) return Long_Integer is
      S : Long_Integer;
   begin
      S := (Multiplier * G.State) rem Modulus;
      if S <= 0 then
         S := S + Modulus;
      end if;
      G.State := S;
      return S;
   end Next_State;

   function Random_Unit (G : in out RNG) return Unit_Interval is
      S : constant Long_Integer := Next_State (G);
   begin
      return Real (S - 1) / Real (Modulus - 1);
   end Random_Unit;

   function Random_Index
     (G : in out RNG; Lo, Hi : Positive) return Positive
   is
      Span : constant Natural := Hi - Lo + 1;
      U    : Unit_Interval;
      Off  : Natural;
   begin
      if Lo > Hi then
         raise Invalid_Argument with "Random_Index: Lo > Hi";
      end if;
      U := Random_Unit (G);
      Off := Natural (Real'Truncation (U * Real (Span)));
      if Off >= Span then
         Off := Span - 1;
      end if;
      return Lo + Off;
   end Random_Index;

   ---------------------------------------------------------------------------
   -- Tic-Tac-Toe helpers
   ---------------------------------------------------------------------------

   function To_Cell (M : Mark) return Cell is
   begin
      case M is
         when X_Mark => return X;
         when O_Mark => return O;
      end case;
   end To_Cell;

   function Opponent (M : Mark) return Mark is
   begin
      case M is
         when X_Mark => return O_Mark;
         when O_Mark => return X_Mark;
      end case;
   end Opponent;

   function Empty_Board return Board is
   begin
      return [others => [others => Empty]];
   end Empty_Board;

   function Line_Winner (A, B, C : Cell) return Cell is
   begin
      if A /= Empty and then A = B and then B = C then
         return A;
      end if;
      return Empty;
   end Line_Winner;

   function Winner (B : Board) return Cell is
      W : Cell;
   begin
      for R in Row loop
         W := Line_Winner (B (R, 1), B (R, 2), B (R, 3));
         if W /= Empty then
            return W;
         end if;
      end loop;
      for C in Col loop
         W := Line_Winner (B (1, C), B (2, C), B (3, C));
         if W /= Empty then
            return W;
         end if;
      end loop;
      W := Line_Winner (B (1, 1), B (2, 2), B (3, 3));
      if W /= Empty then
         return W;
      end if;
      return Line_Winner (B (1, 3), B (2, 2), B (3, 1));
   end Winner;

   function Is_Full (B : Board) return Boolean is
   begin
      for R in Row loop
         for C in Col loop
            if B (R, C) = Empty then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Full;

   function Is_Terminal (B : Board) return Boolean is
   begin
      return Winner (B) /= Empty or else Is_Full (B);
   end Is_Terminal;

   function Terminal_Reward (B : Board; Side : Mark) return Real is
      W : constant Cell := Winner (B);
   begin
      if not Is_Terminal (B) then
         raise Invalid_Argument with "Terminal_Reward: non-terminal";
      end if;
      if W = Empty then
         return 0.0;
      elsif W = To_Cell (Side) then
         return 1.0;
      else
         return -1.0;
      end if;
   end Terminal_Reward;

   function Count_Empty (B : Board) return TTT_Move_Count is
      N : TTT_Move_Count := 0;
   begin
      for R in Row loop
         for C in Col loop
            if B (R, C) = Empty then
               N := N + 1;
            end if;
         end loop;
      end loop;
      return N;
   end Count_Empty;

   function Side_To_Move_TTT (B : Board) return Mark is
      Empties : constant TTT_Move_Count := Count_Empty (B);
      Placed  : constant Natural := 9 - Natural (Empties);
   begin
      --  X placed first; after even number of stones, X to move.
      if Placed rem 2 = 0 then
         return X_Mark;
      else
         return O_Mark;
      end if;
   end Side_To_Move_TTT;

   function Legal_Moves_TTT (B : Board) return TTT_Move_List is
      Buf : TTT_Move_List (1 .. Max_TTT_Moves);
      N   : TTT_Move_Count := 0;
   begin
      for R in Row loop
         for C in Col loop
            if B (R, C) = Empty then
               N := N + 1;
               Buf (N) := (R, C);
            end if;
         end loop;
      end loop;
      return Buf (1 .. N);
   end Legal_Moves_TTT;

   function Apply_Move_TTT (B : Board; M : Move; Who : Mark) return Board is
      Out_B : Board := B;
   begin
      if B (M.R, M.C) /= Empty then
         raise Invalid_Argument with "Apply_Move_TTT: occupied";
      end if;
      Out_B (M.R, M.C) := To_Cell (Who);
      return Out_B;
   end Apply_Move_TTT;

   function Moves_Equal (A, B : Move) return Boolean is
   begin
      return A.R = B.R and then A.C = B.C;
   end Moves_Equal;

   ---------------------------------------------------------------------------
   -- Nim helpers
   ---------------------------------------------------------------------------

   function Is_Terminal_Nim (S : Nim_State) return Boolean is
   begin
      return S.Heap = 0;
   end Is_Terminal_Nim;

   function Terminal_Reward_Nim (S : Nim_State) return Real is
   begin
      if not Is_Terminal_Nim (S) then
         raise Invalid_Argument with "Terminal_Reward_Nim: non-terminal";
      end if;
      --  Player to move faces empty heap and has lost.
      return -1.0;
   end Terminal_Reward_Nim;

   function Legal_Moves_Nim (S : Nim_State) return Nim_Move_List is
      Cap : Natural;
      N   : Nim_Move_Count := 0;
      Buf : Nim_Move_List (1 .. Max_Nim_Take);
   begin
      if S.Max_Take > Max_Nim_Take then
         raise Invalid_Argument with "Legal_Moves_Nim: Max_Take too large";
      end if;
      if S.Heap = 0 then
         return Buf (1 .. 0);
      end if;
      Cap := Natural'Min (Natural (S.Max_Take), S.Heap);
      for T in 1 .. Cap loop
         N := N + 1;
         Buf (N) := Nim_Take (T);
      end loop;
      return Buf (1 .. N);
   end Legal_Moves_Nim;

   function Apply_Move_Nim (S : Nim_State; Take : Nim_Take) return Nim_State is
   begin
      if Take > S.Max_Take or else Natural (Take) > S.Heap then
         raise Invalid_Argument with "Apply_Move_Nim: illegal take";
      end if;
      return (Heap => S.Heap - Natural (Take), Max_Take => S.Max_Take);
   end Apply_Move_Nim;

   function Is_Losing_Position (S : Nim_State) return Boolean is
   begin
      if S.Max_Take > Max_Nim_Take then
         raise Invalid_Argument with "Is_Losing_Position: Max_Take";
      end if;
      return S.Heap rem (Natural (S.Max_Take) + 1) = 0;
   end Is_Losing_Position;

   ---------------------------------------------------------------------------
   -- Rollouts
   ---------------------------------------------------------------------------

   function Rollout_TTT
     (B    : Board;
      Side : Mark;
      G    : in out RNG) return Real
   is
      Cur  : Board := B;
      Who  : Mark  := Side;
      Root : constant Mark := Side;
      Moves : TTT_Move_List (1 .. Max_TTT_Moves);
      N     : Natural;
      Pick  : Positive;
   begin
      while not Is_Terminal (Cur) loop
         declare
            L : constant TTT_Move_List := Legal_Moves_TTT (Cur);
         begin
            N := L'Length;
            if N = 0 then
               exit;
            end if;
            for I in 1 .. N loop
               Moves (I) := L (I);
            end loop;
            Pick := Random_Index (G, 1, N);
            Cur := Apply_Move_TTT (Cur, Moves (Pick), Who);
            Who := Opponent (Who);
         end;
      end loop;
      return Terminal_Reward (Cur, Root);
   end Rollout_TTT;

   function Rollout_Nim
     (S : Nim_State;
      G : in out RNG) return Real
   is
      Cur   : Nim_State := S;
      Sign  : Real := 1.0;  -- flip each ply; final reward for original mover
      Moves : Nim_Move_List (1 .. Max_Nim_Take);
      N     : Natural;
      Pick  : Positive;
   begin
      while not Is_Terminal_Nim (Cur) loop
         declare
            L : constant Nim_Move_List := Legal_Moves_Nim (Cur);
         begin
            N := L'Length;
            if N = 0 then
               exit;
            end if;
            for I in 1 .. N loop
               Moves (I) := L (I);
            end loop;
            Pick := Random_Index (G, 1, N);
            Cur := Apply_Move_Nim (Cur, Moves (Pick));
            Sign := -Sign;
         end;
      end loop;
      --  Terminal: player to move lost (−1). Relative to original: Sign * (−1)
      --  After k plies Sign = (−1)^k; the loser is the one facing 0, who would
      --  have been the next mover, so reward for original = Sign * (−1)? Wait:
      --  Start Sign=1. After first move Sign=−1 (opponent to move). When we
      --  hit terminal, the player ABOUT to move lost. That player's reward
      --  from original's view: if Sign is still the "current mover relative
      --  to original" then current mover = original * Sign, and they get −1,
      --  so original gets Sign * (−1) = −Sign ... Actually:
      --  Original reward = −1 if the current (losing) mover IS original,
      --  else +1. Current mover is original when Sign = +1.
      return -Sign;
   end Rollout_Nim;

   ---------------------------------------------------------------------------
   -- Select_UCT_Child
   ---------------------------------------------------------------------------

   function Select_UCT_Child
     (Means         : Child_Stat_Array;
      N_Children    : Positive;
      Parent_Visits : Natural;
      C             : Real := Default_C) return Positive
   is
      Best_I : Positive := 1;
      Best_S : Real := Real'First;
      S      : Real;
   begin
      if C < 0.0 then
         raise Invalid_Argument with "Select_UCT_Child: C < 0";
      end if;
      if N_Children > Max_Root_Children then
         raise Invalid_Argument with "Select_UCT_Child: too many children";
      end if;
      for I in 1 .. N_Children loop
         S := UCT_Score
           (Means (I).Mean_Reward,
            Means (I).Visits,
            Parent_Visits,
            C);
         --  Prefer higher score; on tie keep lower index (so only replace
         --  when strictly greater).
         if S > Best_S then
            Best_S := S;
            Best_I := I;
         end if;
      end loop;
      return Best_I;
   end Select_UCT_Child;

   ---------------------------------------------------------------------------
   -- Internal MCTS tree for Tic-Tac-Toe
   ---------------------------------------------------------------------------

   type TTT_Node;
   type TTT_Node_Access is access all TTT_Node;

   type TTT_Child_Arr is array (1 .. Max_TTT_Moves) of TTT_Node_Access;

   type TTT_Node is record
      State        : Board;
      To_Move      : Mark;
      Parent       : TTT_Node_Access := null;
      Move_From_Parent : Move := (1, 1);
      Visits       : Natural := 0;
      Total_Reward : Real := 0.0;  -- from root-side perspective
      N_Children   : Natural := 0;
      Children     : TTT_Child_Arr := [others => null];
      Untried      : TTT_Move_List (1 .. Max_TTT_Moves) := [others => (1, 1)];
      N_Untried    : Natural := 0;
      Expanded     : Boolean := False;
   end record;

   procedure Init_Untried (N : in out TTT_Node) is
      L : constant TTT_Move_List := Legal_Moves_TTT (N.State);
   begin
      N.N_Untried := L'Length;
      for I in 1 .. L'Length loop
         N.Untried (I) := L (I);
      end loop;
      N.Expanded := True;
   end Init_Untried;

   function Mean_Of (N : TTT_Node_Access) return Real is
   begin
      if N.Visits = 0 then
         return 0.0;
      end if;
      return N.Total_Reward / Real (N.Visits);
   end Mean_Of;

   --  Select: walk fully-expanded nodes via UCT until a node with untried
   --  moves or a terminal is found. Rewards stored from root Side's view;
   --  when To_Move /= Root_Side, UCT uses negated mean (current player maximises).
   function Select_Path
     (Root_Node : TTT_Node_Access;
      Root_Side : Mark;
      C         : Real) return TTT_Node_Access
   is
      Cur : TTT_Node_Access := Root_Node;
      Stats : Child_Stat_Array;
      Pick  : Positive;
      Mean  : Real;
   begin
      loop
         if Is_Terminal (Cur.State) then
            return Cur;
         end if;
         if not Cur.Expanded then
            Init_Untried (Cur.all);
         end if;
         if Cur.N_Untried > 0 then
            return Cur;  -- expand here
         end if;
         if Cur.N_Children = 0 then
            return Cur;
         end if;
         for I in 1 .. Cur.N_Children loop
            Mean := Mean_Of (Cur.Children (I));
            --  Child stats are from Root_Side's view. Current player at Cur
            --  wants to maximise their own reward = ± Root_Side reward.
            if Cur.To_Move /= Root_Side then
               Mean := -Mean;
            end if;
            Stats (I).Mean_Reward := Mean;
            Stats (I).Visits := Cur.Children (I).Visits;
            Stats (I).Total_Reward := Cur.Children (I).Total_Reward;
         end loop;
         Pick := Select_UCT_Child (Stats, Cur.N_Children, Cur.Visits, C);
         Cur := Cur.Children (Pick);
      end loop;
   end Select_Path;

   function Expand_TTT
     (N         : TTT_Node_Access;
      G         : in out RNG) return TTT_Node_Access
   is
      Idx  : Positive;
      M    : Move;
      Child : TTT_Node_Access;
      Last  : Natural;
   begin
      if N.N_Untried = 0 then
         return N;
      end if;
      Idx := Random_Index (G, 1, N.N_Untried);
      M := N.Untried (Idx);
      --  Swap-remove from untried
      Last := N.N_Untried;
      N.Untried (Idx) := N.Untried (Last);
      N.N_Untried := Last - 1;

      Child := new TTT_Node;
      Child.State := Apply_Move_TTT (N.State, M, N.To_Move);
      Child.To_Move := Opponent (N.To_Move);
      Child.Parent := N;
      Child.Move_From_Parent := M;
      N.N_Children := N.N_Children + 1;
      N.Children (N.N_Children) := Child;
      return Child;
   end Expand_TTT;

   procedure Backup_TTT
     (Leaf      : TTT_Node_Access;
      Reward    : Real)  -- from Root_Side perspective
   is
      Cur : TTT_Node_Access := Leaf;
   begin
      while Cur /= null loop
         Cur.Visits := Cur.Visits + 1;
         Cur.Total_Reward := Cur.Total_Reward + Reward;
         Cur := Cur.Parent;
      end loop;
   end Backup_TTT;

   function Search_TTT
     (B          : Board;
      Side       : Mark;
      Iterations : Positive;
      C          : Real    := Default_C;
      Seed       : Integer := 42) return Search_Result
   is
      G     : RNG := Make_RNG (Seed);
      Root  : TTT_Node_Access;
      Leaf  : TTT_Node_Access;
      Node  : TTT_Node_Access;
      Reward : Real;
      Res   : Search_Result;
      Best_V : Natural := 0;
      Best_I : Natural := 0;
      Root_Moves : TTT_Move_List (1 .. Max_TTT_Moves);
      N_Root : Natural;
   begin
      if C < 0.0 then
         raise Invalid_Argument with "Search_TTT: C < 0";
      end if;
      if Is_Terminal (B) then
         raise No_Legal_Move with "Search_TTT: terminal position";
      end if;

      declare
         L : constant TTT_Move_List := Legal_Moves_TTT (B);
      begin
         N_Root := L'Length;
         if N_Root = 0 then
            raise No_Legal_Move with "Search_TTT: no moves";
         end if;
         for I in 1 .. N_Root loop
            Root_Moves (I) := L (I);
         end loop;
      end;

      Root := new TTT_Node;
      Root.State := B;
      Root.To_Move := Side;
      Init_Untried (Root.all);

      for Iter in 1 .. Iterations loop
         Node := Select_Path (Root, Side, C);
         if not Is_Terminal (Node.State) and then Node.N_Untried > 0 then
            Leaf := Expand_TTT (Node, G);
         else
            Leaf := Node;
         end if;
         if Is_Terminal (Leaf.State) then
            Reward := Terminal_Reward (Leaf.State, Side);
         else
            Reward := Rollout_TTT (Leaf.State, Leaf.To_Move, G);
            --  Rollout returns reward from Leaf.To_Move's perspective;
            --  convert to Root Side's perspective.
            if Leaf.To_Move /= Side then
               Reward := -Reward;
            end if;
         end if;
         Backup_TTT (Leaf, Reward);
      end loop;

      Res.Iterations := Iterations;
      Res.Root_Visits := Root.Visits;
      Res.N_Children := Root.N_Children;

      --  Map children back to root move list order for Stats.
      for I in 1 .. N_Root loop
         Res.Stats (I) := (0, 0.0, 0.0);
         for J in 1 .. Root.N_Children loop
            if Moves_Equal (Root.Children (J).Move_From_Parent, Root_Moves (I))
            then
               Res.Stats (I).Visits := Root.Children (J).Visits;
               Res.Stats (I).Total_Reward := Root.Children (J).Total_Reward;
               if Res.Stats (I).Visits > 0 then
                  Res.Stats (I).Mean_Reward :=
                    Res.Stats (I).Total_Reward / Real (Res.Stats (I).Visits);
               end if;
               exit;
            end if;
         end loop;
      end loop;
      Res.N_Children := N_Root;

      --  Robust child selection: most visits (Wikipedia); tie → higher mean,
      --  then lower index.
      for I in 1 .. N_Root loop
         if Res.Stats (I).Visits > Best_V
           or else
             (Res.Stats (I).Visits = Best_V
              and then Best_I > 0
              and then Res.Stats (I).Mean_Reward > Res.Stats (Best_I).Mean_Reward)
           or else
             (Best_I = 0 and then Res.Stats (I).Visits >= Best_V)
         then
            Best_V := Res.Stats (I).Visits;
            Best_I := I;
         end if;
      end loop;

      if Best_I = 0 then
         Best_I := 1;
      end if;
      Res.Best_Index := Best_I;
      Res.Best_TTT := Root_Moves (Best_I);
      return Res;
   end Search_TTT;

   ---------------------------------------------------------------------------
   -- Internal MCTS for Nim
   ---------------------------------------------------------------------------

   type Nim_Node;
   type Nim_Node_Access is access all Nim_Node;

   type Nim_Child_Arr is array (1 .. Max_Nim_Take) of Nim_Node_Access;

   type Nim_Node is record
      State        : Nim_State;
      Parent       : Nim_Node_Access := null;
      Take_From_Parent : Nim_Take := 1;
      Visits       : Natural := 0;
      Total_Reward : Real := 0.0;  -- from root mover's perspective
      N_Children   : Natural := 0;
      Children     : Nim_Child_Arr := [others => null];
      Untried      : Nim_Move_List (1 .. Max_Nim_Take) := [others => 1];
      N_Untried    : Natural := 0;
      Expanded     : Boolean := False;
      Depth_Parity : Integer := 0;  -- 0 = root mover to play
   end record;

   procedure Init_Untried_Nim (N : in out Nim_Node) is
      L : constant Nim_Move_List := Legal_Moves_Nim (N.State);
   begin
      N.N_Untried := L'Length;
      for I in 1 .. L'Length loop
         N.Untried (I) := L (I);
      end loop;
      N.Expanded := True;
   end Init_Untried_Nim;

   function Mean_Of_Nim (N : Nim_Node_Access) return Real is
   begin
      if N.Visits = 0 then
         return 0.0;
      end if;
      return N.Total_Reward / Real (N.Visits);
   end Mean_Of_Nim;

   function Select_Path_Nim
     (Root_Node : Nim_Node_Access;
      C         : Real) return Nim_Node_Access
   is
      Cur   : Nim_Node_Access := Root_Node;
      Stats : Child_Stat_Array;
      Pick  : Positive;
      Mean  : Real;
   begin
      loop
         if Is_Terminal_Nim (Cur.State) then
            return Cur;
         end if;
         if not Cur.Expanded then
            Init_Untried_Nim (Cur.all);
         end if;
         if Cur.N_Untried > 0 then
            return Cur;
         end if;
         if Cur.N_Children = 0 then
            return Cur;
         end if;
         for I in 1 .. Cur.N_Children loop
            Mean := Mean_Of_Nim (Cur.Children (I));
            --  Depth_Parity even: root mover to play → use Mean as-is.
            --  Odd: opponent to play → negate.
            if Cur.Depth_Parity rem 2 /= 0 then
               Mean := -Mean;
            end if;
            Stats (I).Mean_Reward := Mean;
            Stats (I).Visits := Cur.Children (I).Visits;
            Stats (I).Total_Reward := Cur.Children (I).Total_Reward;
         end loop;
         Pick := Select_UCT_Child (Stats, Cur.N_Children, Cur.Visits, C);
         Cur := Cur.Children (Pick);
      end loop;
   end Select_Path_Nim;

   function Expand_Nim
     (N : Nim_Node_Access;
      G : in out RNG) return Nim_Node_Access
   is
      Idx   : Positive;
      T     : Nim_Take;
      Child : Nim_Node_Access;
      Last  : Natural;
   begin
      if N.N_Untried = 0 then
         return N;
      end if;
      Idx := Random_Index (G, 1, N.N_Untried);
      T := N.Untried (Idx);
      Last := N.N_Untried;
      N.Untried (Idx) := N.Untried (Last);
      N.N_Untried := Last - 1;

      Child := new Nim_Node;
      Child.State := Apply_Move_Nim (N.State, T);
      Child.Parent := N;
      Child.Take_From_Parent := T;
      Child.Depth_Parity := N.Depth_Parity + 1;
      N.N_Children := N.N_Children + 1;
      N.Children (N.N_Children) := Child;
      return Child;
   end Expand_Nim;

   procedure Backup_Nim (Leaf : Nim_Node_Access; Reward : Real) is
      Cur : Nim_Node_Access := Leaf;
   begin
      while Cur /= null loop
         Cur.Visits := Cur.Visits + 1;
         Cur.Total_Reward := Cur.Total_Reward + Reward;
         Cur := Cur.Parent;
      end loop;
   end Backup_Nim;

   function Search_Nim
     (S          : Nim_State;
      Iterations : Positive;
      C          : Real    := Default_C;
      Seed       : Integer := 42) return Search_Result
   is
      G     : RNG := Make_RNG (Seed);
      Root  : Nim_Node_Access;
      Leaf  : Nim_Node_Access;
      Node  : Nim_Node_Access;
      Reward : Real;
      Res   : Search_Result;
      Best_V : Natural := 0;
      Best_I : Natural := 0;
      Root_Moves : Nim_Move_List (1 .. Max_Nim_Take);
      N_Root : Natural;
   begin
      if C < 0.0 then
         raise Invalid_Argument with "Search_Nim: C < 0";
      end if;
      if S.Max_Take > Max_Nim_Take then
         raise Invalid_Argument with "Search_Nim: Max_Take too large";
      end if;
      if Is_Terminal_Nim (S) then
         raise No_Legal_Move with "Search_Nim: terminal";
      end if;

      declare
         L : constant Nim_Move_List := Legal_Moves_Nim (S);
      begin
         N_Root := L'Length;
         if N_Root = 0 then
            raise No_Legal_Move with "Search_Nim: no moves";
         end if;
         for I in 1 .. N_Root loop
            Root_Moves (I) := L (I);
         end loop;
      end;

      Root := new Nim_Node;
      Root.State := S;
      Root.Depth_Parity := 0;
      Init_Untried_Nim (Root.all);

      for Iter in 1 .. Iterations loop
         Node := Select_Path_Nim (Root, C);
         if not Is_Terminal_Nim (Node.State) and then Node.N_Untried > 0 then
            Leaf := Expand_Nim (Node, G);
         else
            Leaf := Node;
         end if;
         if Is_Terminal_Nim (Leaf.State) then
            --  Player to move at leaf lost. Relative to root:
            --  Depth_Parity even → root mover to play → reward −1;
            --  odd → opponent to play → root gets +1.
            if Leaf.Depth_Parity rem 2 = 0 then
               Reward := -1.0;
            else
               Reward := 1.0;
            end if;
         else
            Reward := Rollout_Nim (Leaf.State, G);
            --  Rollout from leaf mover's view; convert to root view.
            if Leaf.Depth_Parity rem 2 /= 0 then
               Reward := -Reward;
            end if;
         end if;
         Backup_Nim (Leaf, Reward);
      end loop;

      Res.Iterations := Iterations;
      Res.Root_Visits := Root.Visits;
      Res.N_Children := N_Root;

      for I in 1 .. N_Root loop
         Res.Stats (I) := (0, 0.0, 0.0);
         for J in 1 .. Root.N_Children loop
            if Root.Children (J).Take_From_Parent = Root_Moves (I) then
               Res.Stats (I).Visits := Root.Children (J).Visits;
               Res.Stats (I).Total_Reward := Root.Children (J).Total_Reward;
               if Res.Stats (I).Visits > 0 then
                  Res.Stats (I).Mean_Reward :=
                    Res.Stats (I).Total_Reward / Real (Res.Stats (I).Visits);
               end if;
               exit;
            end if;
         end loop;
      end loop;

      for I in 1 .. N_Root loop
         if Res.Stats (I).Visits > Best_V
           or else
             (Res.Stats (I).Visits = Best_V
              and then Best_I > 0
              and then Res.Stats (I).Mean_Reward > Res.Stats (Best_I).Mean_Reward)
           or else
             (Best_I = 0 and then Res.Stats (I).Visits >= Best_V)
         then
            Best_V := Res.Stats (I).Visits;
            Best_I := I;
         end if;
      end loop;

      if Best_I = 0 then
         Best_I := 1;
      end if;
      Res.Best_Index := Best_I;
      Res.Best_Nim := Root_Moves (Best_I);
      return Res;
   end Search_Nim;

   ---------------------------------------------------------------------------
   -- Pure Monte Carlo (flat)
   ---------------------------------------------------------------------------

   function Pure_Monte_Carlo_TTT
     (B             : Board;
      Side          : Mark;
      Playouts_Each : Positive;
      Seed          : Integer := 42) return Search_Result
   is
      G    : RNG := Make_RNG (Seed);
      Res  : Search_Result;
      L    : constant TTT_Move_List := Legal_Moves_TTT (B);
      N    : constant Natural := L'Length;
      Child_B : Board;
      Sum  : Real;
      Best_Mean : Real := Real'First;
      Best_I : Natural := 0;
      R    : Real;
   begin
      if Is_Terminal (B) or else N = 0 then
         raise No_Legal_Move with "Pure_Monte_Carlo_TTT: no moves";
      end if;
      Res.N_Children := N;
      Res.Iterations := Playouts_Each * N;
      for I in 1 .. N loop
         Sum := 0.0;
         Child_B := Apply_Move_TTT (B, L (I), Side);
         for P in 1 .. Playouts_Each loop
            if Is_Terminal (Child_B) then
               R := Terminal_Reward (Child_B, Side);
            else
               R := Rollout_TTT (Child_B, Opponent (Side), G);
               R := -R;  -- convert from opponent view to Side
            end if;
            Sum := Sum + R;
         end loop;
         Res.Stats (I).Visits := Playouts_Each;
         Res.Stats (I).Total_Reward := Sum;
         Res.Stats (I).Mean_Reward := Sum / Real (Playouts_Each);
         if Res.Stats (I).Mean_Reward > Best_Mean then
            Best_Mean := Res.Stats (I).Mean_Reward;
            Best_I := I;
         end if;
      end loop;
      Res.Best_Index := Best_I;
      Res.Best_TTT := L (Best_I);
      Res.Root_Visits := Res.Iterations;
      return Res;
   end Pure_Monte_Carlo_TTT;

   function Pure_Monte_Carlo_Nim
     (S             : Nim_State;
      Playouts_Each : Positive;
      Seed          : Integer := 42) return Search_Result
   is
      G    : RNG := Make_RNG (Seed);
      Res  : Search_Result;
      L    : constant Nim_Move_List := Legal_Moves_Nim (S);
      N    : constant Natural := L'Length;
      Child_S : Nim_State;
      Sum  : Real;
      Best_Mean : Real := Real'First;
      Best_I : Natural := 0;
      R    : Real;
   begin
      if Is_Terminal_Nim (S) or else N = 0 then
         raise No_Legal_Move with "Pure_Monte_Carlo_Nim: no moves";
      end if;
      if S.Max_Take > Max_Nim_Take then
         raise Invalid_Argument with "Pure_Monte_Carlo_Nim: Max_Take";
      end if;
      Res.N_Children := N;
      Res.Iterations := Playouts_Each * N;
      for I in 1 .. N loop
         Sum := 0.0;
         Child_S := Apply_Move_Nim (S, L (I));
         for P in 1 .. Playouts_Each loop
            if Is_Terminal_Nim (Child_S) then
               R := 1.0;  -- opponent faces 0 → we win
            else
               R := Rollout_Nim (Child_S, G);
               R := -R;  -- convert from opponent to us
            end if;
            Sum := Sum + R;
         end loop;
         Res.Stats (I).Visits := Playouts_Each;
         Res.Stats (I).Total_Reward := Sum;
         Res.Stats (I).Mean_Reward := Sum / Real (Playouts_Each);
         if Res.Stats (I).Mean_Reward > Best_Mean then
            Best_Mean := Res.Stats (I).Mean_Reward;
            Best_I := I;
         end if;
      end loop;
      Res.Best_Index := Best_I;
      Res.Best_Nim := L (Best_I);
      Res.Root_Visits := Res.Iterations;
      return Res;
   end Pure_Monte_Carlo_Nim;

end Monte_Carlo_Tree_Search;
