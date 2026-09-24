--  Minimax body — alternate-moves game tree, alpha–beta, Tic-Tac-Toe.

pragma Ada_2022;

package body Minimax
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Max_Score (A, B : Score) return Score is
   begin
      if A >= B then
         return A;
      else
         return B;
      end if;
   end Max_Score;

   function Min_Score (A, B : Score) return Score is
   begin
      if A <= B then
         return A;
      else
         return B;
      end if;
   end Min_Score;

   ---------------------------------------------------------------------------
   -- Explicit tree constructors
   ---------------------------------------------------------------------------

   function Leaf (V : Score) return Tree_Access is
      N : constant Tree_Access := new Tree_Node;
   begin
      N.Leaf_Value := V;
      N.Is_Leaf    := True;
      N.N_Children := 0;
      return N;
   end Leaf;

   function Branch (Kids : Child_List) return Tree_Access is
      N : constant Tree_Access := new Tree_Node;
      K : Child_Count := 0;
   begin
      N.Is_Leaf := False;
      for C of Kids loop
         if C = null then
            raise Invalid_Argument with "Branch: null child";
         end if;
         K := K + 1;
         N.Children (K) := C;
      end loop;
      N.N_Children := K;
      return N;
   end Branch;

   ---------------------------------------------------------------------------
   -- Tree minimax
   ---------------------------------------------------------------------------

   function Max_Value_Tree
     (Node : Tree_Access; Depth : Natural) return Score
   is
      V : Score;
   begin
      if Node.Is_Leaf or else Depth = 0 or else Node.N_Children = 0 then
         return Node.Leaf_Value;
      end if;
      V := Neg_Inf;
      for I in 1 .. Node.N_Children loop
         V := Max_Score
           (V, Min_Value_Tree (Node.Children (I), Depth - 1));
      end loop;
      return V;
   end Max_Value_Tree;

   function Min_Value_Tree
     (Node : Tree_Access; Depth : Natural) return Score
   is
      V : Score;
   begin
      if Node.Is_Leaf or else Depth = 0 or else Node.N_Children = 0 then
         return Node.Leaf_Value;
      end if;
      V := Pos_Inf;
      for I in 1 .. Node.N_Children loop
         V := Min_Score
           (V, Max_Value_Tree (Node.Children (I), Depth - 1));
      end loop;
      return V;
   end Min_Value_Tree;

   function Minimax_Tree
     (Node              : Tree_Access;
      Maximizing_Player : Boolean;
      Depth             : Natural := Natural'Last) return Score
   is
   begin
      if Maximizing_Player then
         return Max_Value_Tree (Node, Depth);
      else
         return Min_Value_Tree (Node, Depth);
      end if;
   end Minimax_Tree;

   function Alpha_Beta_Tree
     (Node              : Tree_Access;
      Maximizing_Player : Boolean;
      Alpha             : Score   := Neg_Inf;
      Beta              : Score   := Pos_Inf;
      Depth             : Natural := Natural'Last) return Score
   is
      A : Score := Alpha;
      B : Score := Beta;
      V : Score;
   begin
      if Node.Is_Leaf or else Depth = 0 or else Node.N_Children = 0 then
         return Node.Leaf_Value;
      end if;

      if Maximizing_Player then
         V := Neg_Inf;
         for I in 1 .. Node.N_Children loop
            V := Max_Score
              (V,
               Alpha_Beta_Tree
                 (Node.Children (I), False, A, B, Depth - 1));
            A := Max_Score (A, V);
            if V >= B then
               return V;
            end if;
         end loop;
         return V;
      else
         V := Pos_Inf;
         for I in 1 .. Node.N_Children loop
            V := Min_Score
              (V,
               Alpha_Beta_Tree
                 (Node.Children (I), True, A, B, Depth - 1));
            B := Min_Score (B, V);
            if V <= A then
               return V;
            end if;
         end loop;
         return V;
      end if;
   end Alpha_Beta_Tree;

   function Best_Child_Index
     (Node              : Tree_Access;
      Maximizing_Player : Boolean;
      Use_Alpha_Beta    : Boolean := False) return Child_Index
   is
      Best_I : Child_Index := 1;
      Best_V : Score;
      V      : Score;
   begin
      if Maximizing_Player then
         Best_V := Neg_Inf;
      else
         Best_V := Pos_Inf;
      end if;

      for I in 1 .. Node.N_Children loop
         if Use_Alpha_Beta then
            V := Alpha_Beta_Tree
              (Node.Children (I), not Maximizing_Player);
         else
            V := Minimax_Tree
              (Node.Children (I), not Maximizing_Player);
         end if;

         if Maximizing_Player then
            if V > Best_V then
               Best_V := V;
               Best_I := I;
            end if;
         else
            if V < Best_V then
               Best_V := V;
               Best_I := I;
            end if;
         end if;
      end loop;
      return Best_I;
   end Best_Child_Index;

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

   function Encode (B : Board) return Board_Code is
      Code : Natural := 0;
      Dig  : Natural;
   begin
      for R in Row loop
         for C in Col loop
            case B (R, C) is
               when Empty => Dig := 0;
               when X     => Dig := 1;
               when O     => Dig := 2;
            end case;
            Code := Code * 3 + Dig;
         end loop;
      end loop;
      return Board_Code (Code);
   end Encode;

   function Decode (Code : Board_Code) return Board is
      B    : Board := Empty_Board;
      Remn : Natural := Natural (Code);
      Dig  : Natural;
   begin
      for R in reverse Row loop
         for C in reverse Col loop
            Dig  := Remn mod 3;
            Remn := Remn / 3;
            case Dig is
               when 0 => B (R, C) := Empty;
               when 1 => B (R, C) := X;
               when 2 => B (R, C) := O;
               when others => null;
            end case;
         end loop;
      end loop;
      return B;
   end Decode;

   function Line_Winner (A, B, C : Cell) return Cell is
   begin
      if A /= Empty and then A = B and then B = C then
         return A;
      else
         return Empty;
      end if;
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
      W := Line_Winner (B (1, 3), B (2, 2), B (3, 1));
      if W /= Empty then
         return W;
      end if;
      return Empty;
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

   function Evaluate (B : Board) return Score is
      W : constant Cell := Winner (B);
   begin
      case W is
         when X     => return 1.0;
         when O     => return -1.0;
         when Empty => return 0.0;
      end case;
   end Evaluate;

   function Count_Empty (B : Board) return Move_Count is
      N : Move_Count := 0;
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

   function Legal_Moves (B : Board) return Move_List is
      Buf : Move_List (1 .. Max_Moves);
      N   : Move_Count := 0;
   begin
      for R in Row loop
         for C in Col loop
            if B (R, C) = Empty then
               N := N + 1;
               Buf (N) := (R => R, C => C);
            end if;
         end loop;
      end loop;
      return Buf (1 .. N);
   end Legal_Moves;

   function Apply_Move (B : Board; M : Move; Who : Mark) return Board is
      Outb : Board := B;
   begin
      Outb (M.R, M.C) := To_Cell (Who);
      return Outb;
   end Apply_Move;

   function Side_To_Move (B : Board) return Mark is
      Empties : constant Move_Count := Count_Empty (B);
   begin
      --  X started on a full-empty board (9 empties). After k plies,
      --  empties = 9 − k. Even empties ⇒ O to move; odd ⇒ X.
      if Empties mod 2 = 1 then
         return X_Mark;
      else
         return O_Mark;
      end if;
   end Side_To_Move;

   ---------------------------------------------------------------------------
   -- Tic-Tac-Toe minimax
   ---------------------------------------------------------------------------

   function Max_Value
     (B : Board; Depth : Natural) return Score
   is
      V     : Score;
      Moves : constant Move_List := Legal_Moves (B);
      Child : Board;
   begin
      if Is_Terminal (B) then
         return Evaluate (B);
      end if;
      if Depth = 0 then
         return 0.0;
      end if;
      V := Neg_Inf;
      for M of Moves loop
         Child := Apply_Move (B, M, X_Mark);
         V := Max_Score (V, Min_Value (Child, Depth - 1));
      end loop;
      return V;
   end Max_Value;

   function Min_Value
     (B : Board; Depth : Natural) return Score
   is
      V     : Score;
      Moves : constant Move_List := Legal_Moves (B);
      Child : Board;
   begin
      if Is_Terminal (B) then
         return Evaluate (B);
      end if;
      if Depth = 0 then
         return 0.0;
      end if;
      V := Pos_Inf;
      for M of Moves loop
         Child := Apply_Move (B, M, O_Mark);
         V := Min_Score (V, Max_Value (Child, Depth - 1));
      end loop;
      return V;
   end Min_Value;

   function Minimax
     (B       : Board;
      To_Move : Mark;
      Depth   : Natural := 9) return Score
   is
   begin
      if Is_Terminal (B) then
         return Evaluate (B);
      end if;
      if Depth = 0 then
         return 0.0;
      end if;
      case To_Move is
         when X_Mark => return Max_Value (B, Depth);
         when O_Mark => return Min_Value (B, Depth);
      end case;
   end Minimax;

   function Alpha_Beta_Max
     (B : Board; Alpha, Beta : Score; Depth : Natural) return Score;

   function Alpha_Beta_Min
     (B : Board; Alpha, Beta : Score; Depth : Natural) return Score;

   function Alpha_Beta_Max
     (B : Board; Alpha, Beta : Score; Depth : Natural) return Score
   is
      A     : Score := Alpha;
      V     : Score;
      Moves : constant Move_List := Legal_Moves (B);
      Child : Board;
   begin
      if Is_Terminal (B) then
         return Evaluate (B);
      end if;
      if Depth = 0 then
         return 0.0;
      end if;
      V := Neg_Inf;
      for M of Moves loop
         Child := Apply_Move (B, M, X_Mark);
         V := Max_Score (V, Alpha_Beta_Min (Child, A, Beta, Depth - 1));
         A := Max_Score (A, V);
         if V >= Beta then
            return V;
         end if;
      end loop;
      return V;
   end Alpha_Beta_Max;

   function Alpha_Beta_Min
     (B : Board; Alpha, Beta : Score; Depth : Natural) return Score
   is
      Bt    : Score := Beta;
      V     : Score;
      Moves : constant Move_List := Legal_Moves (B);
      Child : Board;
   begin
      if Is_Terminal (B) then
         return Evaluate (B);
      end if;
      if Depth = 0 then
         return 0.0;
      end if;
      V := Pos_Inf;
      for M of Moves loop
         Child := Apply_Move (B, M, O_Mark);
         V := Min_Score (V, Alpha_Beta_Max (Child, Alpha, Bt, Depth - 1));
         Bt := Min_Score (Bt, V);
         if V <= Alpha then
            return V;
         end if;
      end loop;
      return V;
   end Alpha_Beta_Min;

   function Alpha_Beta
     (B       : Board;
      To_Move : Mark;
      Alpha   : Score   := Neg_Inf;
      Beta    : Score   := Pos_Inf;
      Depth   : Natural := 9) return Score
   is
   begin
      if Is_Terminal (B) then
         return Evaluate (B);
      end if;
      if Depth = 0 then
         return 0.0;
      end if;
      case To_Move is
         when X_Mark => return Alpha_Beta_Max (B, Alpha, Beta, Depth);
         when O_Mark => return Alpha_Beta_Min (B, Alpha, Beta, Depth);
      end case;
   end Alpha_Beta;

   function Best_Move
     (B              : Board;
      To_Move        : Mark;
      Use_Alpha_Beta : Boolean := True) return Move
   is
      Moves  : constant Move_List := Legal_Moves (B);
      Best   : Move;
      Best_V : Score;
      V      : Score;
      Child   : Board;
      First  : Boolean := True;
   begin
      if Moves'Length = 0 then
         raise No_Legal_Move with "Best_Move: no empty cells";
      end if;

      Best := Moves (Moves'First);
      if To_Move = X_Mark then
         Best_V := Neg_Inf;
      else
         Best_V := Pos_Inf;
      end if;

      for M of Moves loop
         Child := Apply_Move (B, M, To_Move);
         if Use_Alpha_Beta then
            V := Alpha_Beta (Child, Opponent (To_Move));
         else
            V := Minimax (Child, Opponent (To_Move));
         end if;

         if First then
            Best   := M;
            Best_V := V;
            First  := False;
         elsif To_Move = X_Mark then
            if V > Best_V then
               Best_V := V;
               Best   := M;
            end if;
         else
            if V < Best_V then
               Best_V := V;
               Best   := M;
            end if;
         end if;
      end loop;
      return Best;
   end Best_Move;

   ---------------------------------------------------------------------------
   -- Callback API
   ---------------------------------------------------------------------------

   function Minimax_Callback
     (S                 : State_Id;
      G                 : Game_Callbacks;
      Maximizing_Player : Boolean;
      Depth             : Natural := Natural'Last) return Score
   is
      V : Score;
      N : Natural;
   begin
      if G.Is_Terminal (S) or else Depth = 0 then
         return G.Evaluate (S);
      end if;
      N := G.Child_Count (S);
      if N = 0 then
         return G.Evaluate (S);
      end if;

      if Maximizing_Player then
         V := Neg_Inf;
         for I in 1 .. N loop
            V := Max_Score
              (V,
               Minimax_Callback
                 (G.Child_At (S, I), G, False, Depth - 1));
         end loop;
         return V;
      else
         V := Pos_Inf;
         for I in 1 .. N loop
            V := Min_Score
              (V,
               Minimax_Callback
                 (G.Child_At (S, I), G, True, Depth - 1));
         end loop;
         return V;
      end if;
   end Minimax_Callback;

   function Alpha_Beta_Callback
     (S                 : State_Id;
      G                 : Game_Callbacks;
      Maximizing_Player : Boolean;
      Alpha             : Score   := Neg_Inf;
      Beta              : Score   := Pos_Inf;
      Depth             : Natural := Natural'Last) return Score
   is
      A : Score := Alpha;
      B : Score := Beta;
      V : Score;
      N : Natural;
   begin
      if G.Is_Terminal (S) or else Depth = 0 then
         return G.Evaluate (S);
      end if;
      N := G.Child_Count (S);
      if N = 0 then
         return G.Evaluate (S);
      end if;

      if Maximizing_Player then
         V := Neg_Inf;
         for I in 1 .. N loop
            V := Max_Score
              (V,
               Alpha_Beta_Callback
                 (G.Child_At (S, I), G, False, A, B, Depth - 1));
            A := Max_Score (A, V);
            if V >= B then
               return V;
            end if;
         end loop;
         return V;
      else
         V := Pos_Inf;
         for I in 1 .. N loop
            V := Min_Score
              (V,
               Alpha_Beta_Callback
                 (G.Child_At (S, I), G, True, A, B, Depth - 1));
            B := Min_Score (B, V);
            if V <= A then
               return V;
            end if;
         end loop;
         return V;
      end if;
   end Alpha_Beta_Callback;


   ---------------------------------------------------------------------------
   -- Demo callback fixture
   ---------------------------------------------------------------------------

   function Demo_Is_Terminal (S : State_Id) return Boolean is
   begin
      return Natural (S) >= 3;
   end Demo_Is_Terminal;

   function Demo_Evaluate (S : State_Id) return Score is
   begin
      case Natural (S) is
         when 3 => return 3.0;
         when 4 => return 5.0;
         when 5 => return 2.0;
         when 6 => return 9.0;
         when others => return 0.0;
      end case;
   end Demo_Evaluate;

   function Demo_Child_Count (S : State_Id) return Natural is
   begin
      case Natural (S) is
         when 0 | 1 | 2 => return 2;
         when others => return 0;
      end case;
   end Demo_Child_Count;

   function Demo_Child_At (S : State_Id; I : Positive) return State_Id is
   begin
      case Natural (S) is
         when 0 =>
            if I = 1 then return 1; else return 2; end if;
         when 1 =>
            if I = 1 then return 3; else return 4; end if;
         when 2 =>
            if I = 1 then return 5; else return 6; end if;
         when others =>
            return S;
      end case;
   end Demo_Child_At;

   function Demo_Game return Game_Callbacks is
   begin
      return
        (Is_Terminal => Demo_Is_Terminal'Access,
         Evaluate    => Demo_Evaluate'Access,
         Child_Count => Demo_Child_Count'Access,
         Child_At    => Demo_Child_At'Access);
   end Demo_Game;

end Minimax;
