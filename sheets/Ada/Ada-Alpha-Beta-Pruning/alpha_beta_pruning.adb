--  Alpha_Beta_Pruning body — minimax baseline + alpha–beta with stats.

pragma Ada_2022;

package body Alpha_Beta_Pruning
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

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

   -------------------------------------------------------------------------
   -- Tree constructors
   -------------------------------------------------------------------------

   function Leaf (V : Score) return Node_Access is
      N : constant Node_Access := new Tree_Node;
   begin
      N.Leaf_Value := V;
      N.Is_Leaf    := True;
      N.N_Children := 0;
      N.Children   := [others => null];
      return N;
   end Leaf;

   function Branch (Kids : Child_List) return Node_Access is
      N : constant Node_Access := new Tree_Node;
      K : Child_Count := 0;
   begin
      N.Is_Leaf    := False;
      N.Leaf_Value := 0.0;
      N.Children   := [others => null];
      for I in Kids'Range loop
         K := K + 1;
         N.Children (K) := Kids (I);
      end loop;
      N.N_Children := K;
      return N;
   end Branch;

   -------------------------------------------------------------------------
   -- Internal minimax / alpha–beta over trees (mutating Result counters)
   -------------------------------------------------------------------------

   procedure Acc_Minimax
     (N           : Node_Access;
      Maximizing  : Boolean;
      Acc         : in out Result;
      Out_Value   : out Score;
      Out_Best    : out Natural);

   procedure Acc_Alpha_Beta
     (N           : Node_Access;
      Maximizing  : Boolean;
      Alpha       : Score;
      Beta        : Score;
      Acc         : in out Result;
      Out_Value   : out Score;
      Out_Best    : out Natural);

   procedure Acc_Minimax
     (N           : Node_Access;
      Maximizing  : Boolean;
      Acc         : in out Result;
      Out_Value   : out Score;
      Out_Best    : out Natural)
   is
      Best_V : Score;
      Child_V : Score;
      Dummy   : Natural;
   begin
      Acc.Nodes_Visited := Acc.Nodes_Visited + 1;
      Out_Best := 0;

      if N.Is_Leaf or else N.N_Children = 0 then
         Out_Value := N.Leaf_Value;
         return;
      end if;

      if Maximizing then
         Best_V := Neg_Inf;
         for I in 1 .. N.N_Children loop
            Acc_Minimax
              (N.Children (I), False, Acc, Child_V, Dummy);
            if Child_V > Best_V then
               Best_V  := Child_V;
               Out_Best := Natural (I);
            end if;
         end loop;
      else
         Best_V := Pos_Inf;
         for I in 1 .. N.N_Children loop
            Acc_Minimax
              (N.Children (I), True, Acc, Child_V, Dummy);
            if Child_V < Best_V then
               Best_V  := Child_V;
               Out_Best := Natural (I);
            end if;
         end loop;
      end if;

      Out_Value := Best_V;
   end Acc_Minimax;

   procedure Acc_Alpha_Beta
     (N           : Node_Access;
      Maximizing  : Boolean;
      Alpha       : Score;
      Beta        : Score;
      Acc         : in out Result;
      Out_Value   : out Score;
      Out_Best    : out Natural)
   is
      A       : Score := Alpha;
      Bt      : Score := Beta;
      Best_V  : Score;
      Child_V : Score;
      Dummy   : Natural;
   begin
      Acc.Nodes_Visited := Acc.Nodes_Visited + 1;
      Out_Best := 0;

      if N.Is_Leaf or else N.N_Children = 0 then
         Out_Value := N.Leaf_Value;
         return;
      end if;

      if Maximizing then
         Best_V := Neg_Inf;
         for I in 1 .. N.N_Children loop
            Acc_Alpha_Beta
              (N.Children (I), False, A, Bt, Acc, Child_V, Dummy);
            if Child_V > Best_V then
               Best_V   := Child_V;
               Out_Best := Natural (I);
            end if;
            A := Max_Score (A, Best_V);
            if Bt <= A then
               Acc.Cutoffs := Acc.Cutoffs + 1;
               exit;
            end if;
         end loop;
      else
         Best_V := Pos_Inf;
         for I in 1 .. N.N_Children loop
            Acc_Alpha_Beta
              (N.Children (I), True, A, Bt, Acc, Child_V, Dummy);
            if Child_V < Best_V then
               Best_V   := Child_V;
               Out_Best := Natural (I);
            end if;
            Bt := Min_Score (Bt, Best_V);
            if Bt <= A then
               Acc.Cutoffs := Acc.Cutoffs + 1;
               exit;
            end if;
         end loop;
      end if;

      Out_Value := Best_V;
   end Acc_Alpha_Beta;

   function Minimax
     (Root       : Node_Access;
      Maximizing : Boolean := True) return Result
   is
      Acc : Result;
      V   : Score;
      B   : Natural;
   begin
      Acc_Minimax (Root, Maximizing, Acc, V, B);
      Acc.Value      := V;
      Acc.Best_Child := B;
      Acc.Cutoffs    := 0;
      return Acc;
   end Minimax;

   function Alpha_Beta
     (Root       : Node_Access;
      Maximizing : Boolean := True;
      Alpha      : Score   := Neg_Inf;
      Beta       : Score   := Pos_Inf) return Result
   is
      Acc : Result;
      V   : Score;
      B   : Natural;
   begin
      Acc_Alpha_Beta (Root, Maximizing, Alpha, Beta, Acc, V, B);
      Acc.Value      := V;
      Acc.Best_Child := B;
      return Acc;
   end Alpha_Beta;

   function Best_Move_Minimax
     (Root       : Node_Access;
      Maximizing : Boolean := True) return Child_Index
   is
      R : constant Result := Minimax (Root, Maximizing);
   begin
      if R.Best_Child < 1 or else R.Best_Child > Natural (Root.N_Children) then
         raise No_Legal_Move;
      end if;
      return Child_Index (R.Best_Child);
   end Best_Move_Minimax;

   function Best_Move_Alpha_Beta
     (Root       : Node_Access;
      Maximizing : Boolean := True;
      Alpha      : Score   := Neg_Inf;
      Beta       : Score   := Pos_Inf) return Child_Index
   is
      R : constant Result :=
        Alpha_Beta (Root, Maximizing, Alpha, Beta);
   begin
      if R.Best_Child < 1 or else R.Best_Child > Natural (Root.N_Children) then
         raise No_Legal_Move;
      end if;
      return Child_Index (R.Best_Child);
   end Best_Move_Alpha_Beta;

   function Best_Move
     (Root           : Node_Access;
      Maximizing     : Boolean := True;
      Use_Alpha_Beta : Boolean := True) return Child_Index
   is
   begin
      if Use_Alpha_Beta then
         return Best_Move_Alpha_Beta (Root, Maximizing);
      else
         return Best_Move_Minimax (Root, Maximizing);
      end if;
   end Best_Move;

   -------------------------------------------------------------------------
   -- Tic-Tac-Toe
   -------------------------------------------------------------------------

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
      B : constant Board := [others => [others => Empty]];
   begin
      return B;
   end Empty_Board;

   function Winner (B : Board) return Cell is
   begin
      for R in Row loop
         if B (R, 1) /= Empty
           and then B (R, 1) = B (R, 2)
           and then B (R, 2) = B (R, 3)
         then
            return B (R, 1);
         end if;
      end loop;
      for C in Col loop
         if B (1, C) /= Empty
           and then B (1, C) = B (2, C)
           and then B (2, C) = B (3, C)
         then
            return B (1, C);
         end if;
      end loop;
      if B (1, 1) /= Empty
        and then B (1, 1) = B (2, 2)
        and then B (2, 2) = B (3, 3)
      then
         return B (1, 1);
      end if;
      if B (1, 3) /= Empty
        and then B (1, 3) = B (2, 2)
        and then B (2, 2) = B (3, 1)
      then
         return B (1, 3);
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

   function Legal_Moves (B : Board) return Move_List is
      Tmp   : Move_List (1 .. Max_Moves);
      Count : Move_Count := 0;
   begin
      for R in Row loop
         for C in Col loop
            if B (R, C) = Empty then
               Count := Count + 1;
               Tmp (Count) := (R => R, C => C);
            end if;
         end loop;
      end loop;
      return Tmp (1 .. Count);
   end Legal_Moves;

   function Apply_Move (B : Board; M : Move; Who : Mark) return Board is
      Nb : Board := B;
   begin
      Nb (M.R, M.C) := To_Cell (Who);
      return Nb;
   end Apply_Move;

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

   function Side_To_Move (B : Board) return Mark is
      Empties : constant Move_Count := Count_Empty (B);
   begin
      --  X starts; empty count odd ⇒ X to move on a fresh board path.
      if Empties rem 2 = 1 then
         return X_Mark;
      else
         return O_Mark;
      end if;
   end Side_To_Move;

   procedure Acc_Minimax_TTT
     (B       : Board;
      To_Move : Mark;
      Depth   : Natural;
      Acc     : in out Result;
      Out_V   : out Score);

   procedure Acc_AB_TTT
     (B       : Board;
      To_Move : Mark;
      Alpha   : Score;
      Beta    : Score;
      Depth   : Natural;
      Acc     : in out Result;
      Out_V   : out Score);

   procedure Acc_Minimax_TTT
     (B       : Board;
      To_Move : Mark;
      Depth   : Natural;
      Acc     : in out Result;
      Out_V   : out Score)
   is
      Moves   : constant Move_List := Legal_Moves (B);
      Best_V  : Score;
      Child_V : Score;
      Child   : Board;
   begin
      Acc.Nodes_Visited := Acc.Nodes_Visited + 1;

      if Is_Terminal (B) or else Depth = 0 or else Moves'Length = 0 then
         if Is_Terminal (B) then
            Out_V := Evaluate (B);
         else
            Out_V := 0.0;
         end if;
         return;
      end if;

      case To_Move is
         when X_Mark =>
            Best_V := Neg_Inf;
            for I in Moves'Range loop
               Child := Apply_Move (B, Moves (I), X_Mark);
               Acc_Minimax_TTT
                 (Child, O_Mark, Depth - 1, Acc, Child_V);
               Best_V := Max_Score (Best_V, Child_V);
            end loop;
         when O_Mark =>
            Best_V := Pos_Inf;
            for I in Moves'Range loop
               Child := Apply_Move (B, Moves (I), O_Mark);
               Acc_Minimax_TTT
                 (Child, X_Mark, Depth - 1, Acc, Child_V);
               Best_V := Min_Score (Best_V, Child_V);
            end loop;
      end case;
      Out_V := Best_V;
   end Acc_Minimax_TTT;

   procedure Acc_AB_TTT
     (B       : Board;
      To_Move : Mark;
      Alpha   : Score;
      Beta    : Score;
      Depth   : Natural;
      Acc     : in out Result;
      Out_V   : out Score)
   is
      Moves   : constant Move_List := Legal_Moves (B);
      A       : Score := Alpha;
      Bt      : Score := Beta;
      Best_V  : Score;
      Child_V : Score;
      Child   : Board;
   begin
      Acc.Nodes_Visited := Acc.Nodes_Visited + 1;

      if Is_Terminal (B) or else Depth = 0 or else Moves'Length = 0 then
         if Is_Terminal (B) then
            Out_V := Evaluate (B);
         else
            Out_V := 0.0;
         end if;
         return;
      end if;

      case To_Move is
         when X_Mark =>
            Best_V := Neg_Inf;
            for I in Moves'Range loop
               Child := Apply_Move (B, Moves (I), X_Mark);
               Acc_AB_TTT
                 (Child, O_Mark, A, Bt, Depth - 1, Acc, Child_V);
               Best_V := Max_Score (Best_V, Child_V);
               A := Max_Score (A, Best_V);
               if Bt <= A then
                  Acc.Cutoffs := Acc.Cutoffs + 1;
                  exit;
               end if;
            end loop;
         when O_Mark =>
            Best_V := Pos_Inf;
            for I in Moves'Range loop
               Child := Apply_Move (B, Moves (I), O_Mark);
               Acc_AB_TTT
                 (Child, X_Mark, A, Bt, Depth - 1, Acc, Child_V);
               Best_V := Min_Score (Best_V, Child_V);
               Bt := Min_Score (Bt, Best_V);
               if Bt <= A then
                  Acc.Cutoffs := Acc.Cutoffs + 1;
                  exit;
               end if;
            end loop;
      end case;
      Out_V := Best_V;
   end Acc_AB_TTT;

   function Minimax_TTT
     (B       : Board;
      To_Move : Mark;
      Depth   : Natural := 9) return Result
   is
      Acc : Result;
      V   : Score;
   begin
      Acc_Minimax_TTT (B, To_Move, Depth, Acc, V);
      Acc.Value   := V;
      Acc.Cutoffs := 0;
      return Acc;
   end Minimax_TTT;

   function Alpha_Beta_TTT
     (B       : Board;
      To_Move : Mark;
      Alpha   : Score   := Neg_Inf;
      Beta    : Score   := Pos_Inf;
      Depth   : Natural := 9) return Result
   is
      Acc : Result;
      V   : Score;
   begin
      Acc_AB_TTT (B, To_Move, Alpha, Beta, Depth, Acc, V);
      Acc.Value := V;
      return Acc;
   end Alpha_Beta_TTT;

   function Best_Move_TTT
     (B              : Board;
      To_Move        : Mark;
      Use_Alpha_Beta : Boolean := True) return Move
   is
      Moves   : constant Move_List := Legal_Moves (B);
      Best    : Move;
      Best_V  : Score;
      Child_V : Score;
      Child   : Board;
      R       : Result;
      First   : Boolean := True;
   begin
      if Moves'Length = 0 then
         raise No_Legal_Move;
      end if;

      if To_Move = X_Mark then
         Best_V := Neg_Inf;
      else
         Best_V := Pos_Inf;
      end if;
      Best := Moves (Moves'First);

      for I in Moves'Range loop
         Child := Apply_Move (B, Moves (I), To_Move);
         if Use_Alpha_Beta then
            R := Alpha_Beta_TTT (Child, Opponent (To_Move));
         else
            R := Minimax_TTT (Child, Opponent (To_Move));
         end if;
         Child_V := R.Value;
         if First then
            Best_V := Child_V;
            Best   := Moves (I);
            First  := False;
         elsif To_Move = X_Mark and then Child_V > Best_V then
            Best_V := Child_V;
            Best   := Moves (I);
         elsif To_Move = O_Mark and then Child_V < Best_V then
            Best_V := Child_V;
            Best   := Moves (I);
         end if;
      end loop;
      return Best;
   end Best_Move_TTT;

end Alpha_Beta_Pruning;
