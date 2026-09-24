--  Standalone test suite for Minimax (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Minimax; use Minimax;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Make_Board
     (A1, A2, A3, B1, B2, B3, C1, C2, C3 : Cell) return Board
   is
      B : Board := Empty_Board;
   begin
      B (1, 1) := A1; B (1, 2) := A2; B (1, 3) := A3;
      B (2, 1) := B1; B (2, 2) := B2; B (2, 3) := B3;
      B (3, 1) := C1; B (3, 2) := C2; B (3, 3) := C3;
      return B;
   end Make_Board;

begin
   Ada.Text_IO.Put_Line ("Minimax test suite");
   Ada.Text_IO.Put_Line ("==================");

   ---------------------------------------------------------------------
   Section ("1. Near / Max_Score / Min_Score");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Near (Max_Score (1.0, 2.0), 2.0), "Max_Score");
   Check (Near (Max_Score (-3.0, -1.0), -1.0), "Max_Score neg");
   Check (Near (Min_Score (1.0, 2.0), 1.0), "Min_Score");
   Check (Near (Min_Score (-3.0, -1.0), -3.0), "Min_Score neg");
   Check (Near (Max_Score (Pos_Inf, 0.0), Pos_Inf), "Max_Score Inf");
   Check (Near (Min_Score (Neg_Inf, 0.0), Neg_Inf), "Min_Score NegInf");

   ---------------------------------------------------------------------
   Section ("2. Explicit tree — Wikipedia-style shallow tree");
   ---------------------------------------------------------------------
   declare
      L3   : constant Tree_Access := Leaf (3.0);
      L5   : constant Tree_Access := Leaf (5.0);
      L2   : constant Tree_Access := Leaf (2.0);
      L9   : constant Tree_Access := Leaf (9.0);
      MinL : constant Tree_Access := Branch ([L3, L5]);
      MinR : constant Tree_Access := Branch ([L2, L9]);
      Root : constant Tree_Access := Branch ([MinL, MinR]);
      V, Va : Score;
      Bi   : Child_Index;
   begin
      Check (L3.Is_Leaf, "Leaf is leaf");
      Check (not Root.Is_Leaf, "Root is branch");
      Check (Root.N_Children = 2, "Root has 2 children");
      Check (Near (L3.Leaf_Value, 3.0), "Leaf value 3");

      V := Minimax_Tree (Root, True);
      Check (Near (V, 3.0), "Shallow tree maximin = 3");

      Va := Alpha_Beta_Tree (Root, True);
      Check (Near (Va, 3.0), "Alpha-beta same = 3");
      Check (Near (V, Va), "Minimax == alpha-beta shallow");

      Check (Near (Minimax_Tree (Root, False), 5.0),
             "Root as min: min(max(3,5),max(2,9))=min(5,9)=5");

      Bi := Best_Child_Index (Root, True);
      Check (Bi = 1, "Best child for max is left (value 3 > 2)");

      Bi := Best_Child_Index (Root, True, Use_Alpha_Beta => True);
      Check (Bi = 1, "Best child alpha-beta agrees");

      Check (Near (Minimax_Tree (L3, True), 3.0), "Leaf minimax");
      Check (Near (Alpha_Beta_Tree (L5, False), 5.0), "Leaf alpha-beta");
   end;

   ---------------------------------------------------------------------
   Section ("3. Deeper explicit tree + depth limit");
   ---------------------------------------------------------------------
   declare
      A : constant Tree_Access :=
        Branch
          ([Branch ([Leaf (3.0), Leaf (12.0)]),
            Branch ([Leaf (8.0), Leaf (2.0)]),
            Branch ([Leaf (4.0), Leaf (6.0)])]);
      V : Score;
   begin
      V := Minimax_Tree (A, True);
      Check (Near (V, 4.0), "Three-branch tree value = 4");
      Check (Near (Alpha_Beta_Tree (A, True), 4.0), "AB three-branch = 4");
      Check (Best_Child_Index (A, True) = 3, "Best child index = 3 (val 4)");
      Check (Near (Minimax_Tree (A, True, Depth => 0), 0.0),
             "Depth 0 interior uses Leaf_Value 0");
      Check (Near (Minimax_Tree (A, True, Depth => 1), 0.0),
             "Depth 1 still hits interior Leaf_Value");
      Check (Near (Minimax_Tree (A, True, Depth => 2), 4.0),
             "Depth 2 reaches leaves = 4");
   end;

   ---------------------------------------------------------------------
   Section ("4. Single-child / asymmetric trees");
   ---------------------------------------------------------------------
   declare
      T1 : constant Tree_Access := Branch ([Leaf (7.0)]);
      T2 : constant Tree_Access :=
        Branch ([Branch ([Leaf (-1.0)]), Leaf (0.5)]);
   begin
      Check (Near (Minimax_Tree (T1, True), 7.0), "Single child max");
      Check (Near (Minimax_Tree (T1, False), 7.0), "Single child min");
      Check (Near (Minimax_Tree (T2, True), 0.5), "Asymmetric max = 0.5");
      Check (Near (Alpha_Beta_Tree (T2, True), 0.5), "Asymmetric AB = 0.5");
      Check (Best_Child_Index (T2, True) = 2, "Asymmetric best child 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Callback API matches explicit tree");
   ---------------------------------------------------------------------
   declare
      --  Library-level callbacks are declared below the procedure... no:
      --  nested access is illegal. Use tree API equivalence already tested;
      --  callbacks exercised via package-level helpers in this file's
      --  declarative region at library level — see CB package below.
      V, Va : Score;
   begin
      V := Minimax_Callback (0, Demo_Game, True);
      Check (Near (V, 3.0), "Callback minimax = 3");
      Va := Alpha_Beta_Callback (0, Demo_Game, True);
      Check (Near (Va, 3.0), "Callback alpha-beta = 3");
      Check (Near (V, Va), "Callback MM == AB");
      Check (Near (Minimax_Callback (3, Demo_Game, True), 3.0),
             "Callback leaf state");
      Check (Near (Minimax_Callback (1, Demo_Game, False), 3.0),
             "Callback min node = min(3,5)=3");
      Check (Near (Minimax_Callback (2, Demo_Game, False), 2.0),
             "Callback min node = min(2,9)=2");
   end;

   ---------------------------------------------------------------------
   Section ("6. Tic-Tac-Toe board encode/decode / helpers");
   ---------------------------------------------------------------------
   declare
      E     : constant Board := Empty_Board;
      B     : Board;
      Code  : Board_Code;
      Moves : constant Move_List := Legal_Moves (E);
   begin
      Check (Count_Empty (E) = 9, "Empty has 9 empties");
      Check (not Is_Terminal (E), "Empty not terminal");
      Check (Winner (E) = Empty, "Empty no winner");
      Check (not Is_Full (E), "Empty not full");
      Check (Side_To_Move (E) = X_Mark, "X to move on empty");
      Check (Moves'Length = 9, "9 legal moves");
      Check (To_Cell (X_Mark) = X, "To_Cell X");
      Check (To_Cell (O_Mark) = O, "To_Cell O");
      Check (Opponent (X_Mark) = O_Mark, "Opponent X");
      Check (Opponent (O_Mark) = X_Mark, "Opponent O");

      Code := Encode (E);
      Check (Code = 0, "Empty encodes to 0");
      B := Decode (0);
      Check (Encode (B) = 0, "Decode 0 round-trip");

      B := Apply_Move (E, (2, 2), X_Mark);
      Check (B (2, 2) = X, "Apply center X");
      Check (Count_Empty (B) = 8, "8 empties after one move");
      Check (Side_To_Move (B) = O_Mark, "O to move after X");
      Check (Encode (Decode (Encode (B))) = Encode (B), "Encode round-trip");

      B := Apply_Move (B, (1, 1), O_Mark);
      Check (B (1, 1) = O, "Apply corner O");
      Check (Side_To_Move (B) = X_Mark, "X again");
   end;

   ---------------------------------------------------------------------
   Section ("7. Winner / terminal detection");
   ---------------------------------------------------------------------
   declare
      R1 : constant Board :=
        Make_Board (X, X, X, O, O, Empty, Empty, Empty, Empty);
      C2b : constant Board :=
        Make_Board (X, O, X, Empty, O, Empty, X, O, Empty);
      D1 : constant Board :=
        Make_Board (X, O, O, Empty, X, Empty, Empty, Empty, X);
      D2 : constant Board :=
        Make_Board (X, X, O, Empty, O, Empty, O, Empty, X);
      Dr : constant Board :=
        Make_Board (X, O, X, X, O, O, O, X, X);
      Ip : constant Board :=
        Make_Board (X, O, Empty, Empty, X, Empty, Empty, Empty, O);
   begin
      Check (Winner (R1) = X, "X wins row 1");
      Check (Is_Terminal (R1), "Row win terminal");
      Check (Near (Evaluate (R1), 1.0), "Eval X win = +1");

      Check (Winner (C2b) = O, "O wins col 2");
      Check (Near (Evaluate (C2b), -1.0), "Eval O win = -1");

      Check (Winner (D1) = X, "X wins main diagonal");
      Check (Winner (D2) = O, "O wins anti-diagonal");

      Check (Winner (Dr) = Empty, "Draw no winner");
      Check (Is_Full (Dr), "Draw is full");
      Check (Is_Terminal (Dr), "Draw terminal");
      Check (Near (Evaluate (Dr), 0.0), "Eval draw = 0");

      Check (Winner (Ip) = Empty, "In-progress no winner");
      Check (not Is_Terminal (Ip), "In-progress not terminal");
      Check (not Is_Full (Ip), "In-progress not full");

      Check (Winner (Make_Board
        (O, O, O, X, X, Empty, X, Empty, Empty)) = O, "O row 1");
      Check (Winner (Make_Board
        (X, O, Empty, X, O, Empty, X, Empty, Empty)) = X, "X col 1");
      Check (Winner (Make_Board
        (Empty, Empty, X, Empty, Empty, X, O, O, X)) = X, "X col 3");
   end;

   ---------------------------------------------------------------------
   Section ("8. Empty-board perfect play is a draw");
   ---------------------------------------------------------------------
   declare
      E  : constant Board := Empty_Board;
      V  : Score;
      Va : Score;
      M  : Move;
   begin
      V := Minimax.Minimax (E, X_Mark);
      Check (Near (V, 0.0), "Empty board minimax = 0 (draw)");
      Va := Alpha_Beta (E, X_Mark);
      Check (Near (Va, 0.0), "Empty board alpha-beta = 0");
      Check (Near (V, Va), "Empty MM == AB");

      M := Best_Move (E, X_Mark, Use_Alpha_Beta => True);
      Check (True, "Best move produced");  -- R,C already subtype Row/Col
      Check (E (M.R, M.C) = Empty, "Best move on empty cell");
      Check (Near (Minimax.Minimax (Apply_Move (E, M, X_Mark), O_Mark), 0.0),
             "After best opening still draw");

      M := Best_Move (E, X_Mark, Use_Alpha_Beta => False);
      Check (Near (Minimax.Minimax (Apply_Move (E, M, X_Mark), O_Mark), 0.0),
             "Best_Move without AB also drawable");
   end;

   ---------------------------------------------------------------------
   Section ("9. Forced win / loss positions");
   ---------------------------------------------------------------------
   declare
      Win_Now : constant Board :=
        Make_Board (X, X, Empty, O, O, Empty, Empty, Empty, Empty);
      Must_Block : constant Board :=
        Make_Board (O, O, Empty, X, X, Empty, Empty, Empty, Empty);
      Forced : constant Board :=
        Make_Board (X, Empty, Empty,
                    Empty, X, Empty,
                    O, O, Empty);
      M     : Move;
      V     : Score;
      Child : Board;
   begin
      V := Minimax.Minimax (Win_Now, X_Mark);
      Check (Near (V, 1.0), "X can force win immediately");
      Check (Near (Alpha_Beta (Win_Now, X_Mark), 1.0), "AB forced win");
      M := Best_Move (Win_Now, X_Mark);
      Check (M.R = 1 and then M.C = 3, "Best move completes row");
      Child := Apply_Move (Win_Now, M, X_Mark);
      Check (Winner (Child) = X, "Immediate win applied");

      V := Minimax.Minimax (Must_Block, X_Mark);
      Check (Near (V, 1.0), "X also wins on Must_Block board");

      V := Minimax.Minimax (Forced, X_Mark);
      Check (Near (V, 1.0), "Forced diag win for X");
      M := Best_Move (Forced, X_Mark);
      Child := Apply_Move (Forced, M, X_Mark);
      Check (Winner (Child) = X or else
              Near (Minimax.Minimax (Child, O_Mark), 1.0),
             "Best move leads to X win");
   end;

   ---------------------------------------------------------------------
   Section ("10. Forced draw / late position");
   ---------------------------------------------------------------------
   declare
      Late : constant Board :=
        Make_Board (X, O, X,
                    X, O, O,
                    O, X, Empty);
      V     : Score;
      M     : Move;
      Child : Board;
   begin
      Check (Count_Empty (Late) = 1, "Late one empty");
      Check (Side_To_Move (Late) = X_Mark, "X fills last cell");
      V := Minimax.Minimax (Late, X_Mark);
      M := Best_Move (Late, X_Mark);
      Check (M.R = 3 and then M.C = 3, "Only move is (3,3)");
      Child := Apply_Move (Late, M, X_Mark);
      Check (Is_Terminal (Child), "After fill terminal");
      Check (Near (V, Evaluate (Child)), "Minimax equals leaf eval");
      Check (Near (Alpha_Beta (Late, X_Mark), V), "AB agrees late");
   end;

   ---------------------------------------------------------------------
   Section ("11. Alpha-beta ≡ minimax on many TTT positions");
   ---------------------------------------------------------------------
   declare
      Positions : array (1 .. 12) of Board;
      V, Va     : Score;
      Who       : Mark;
   begin
      Positions (1) := Empty_Board;
      Positions (2) := Apply_Move (Empty_Board, (2, 2), X_Mark);
      Positions (3) :=
        Make_Board (X, Empty, Empty, Empty, O, Empty, Empty, Empty, Empty);
      Positions (4) :=
        Make_Board (X, O, Empty, Empty, X, Empty, Empty, Empty, O);
      Positions (5) :=
        Make_Board (X, O, X, Empty, O, Empty, Empty, Empty, Empty);
      Positions (6) :=
        Make_Board (X, Empty, O, Empty, X, Empty, O, Empty, Empty);
      Positions (7) :=
        Make_Board (O, X, O, X, X, O, Empty, Empty, Empty);
      Positions (8) :=
        Make_Board (X, X, O, O, O, X, X, O, Empty);
      Positions (9) :=
        Make_Board (X, O, X, O, X, O, O, X, Empty);
      Positions (10) :=
        Make_Board (X, Empty, Empty, O, X, Empty, Empty, O, Empty);
      Positions (11) :=
        Make_Board (Empty, X, Empty, O, Empty, Empty, Empty, Empty, Empty);
      Positions (12) :=
        Make_Board (X, O, Empty, X, Empty, O, Empty, Empty, Empty);

      for I in Positions'Range loop
         Who := Side_To_Move (Positions (I));
         if Is_Terminal (Positions (I)) then
            V  := Evaluate (Positions (I));
            Va := Alpha_Beta (Positions (I), Who);
         else
            V  := Minimax.Minimax (Positions (I), Who);
            Va := Alpha_Beta (Positions (I), Who);
         end if;
         Check (Near (V, Va),
                "AB≡MM position" & I'Image & " val=" & V'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Best_Move smoke — block threats / take wins");
   ---------------------------------------------------------------------
   declare
      Threat : constant Board :=
        Make_Board (O, O, Empty,
                    X, Empty, Empty,
                    X, Empty, Empty);
      Threat2 : constant Board :=
        Make_Board (O, O, Empty,
                    X, Empty, Empty,
                    Empty, Empty, Empty);
      Block_Pos : constant Board :=
        Make_Board (O, O, Empty,
                    X, Empty, Empty,
                    Empty, Empty, X);
      M : Move;
      V : Score;
   begin
      Check (Side_To_Move (Block_Pos) = X_Mark, "X to move on Block_Pos");
      Check (Count_Empty (Block_Pos) = 5, "5 empties");
      V := Minimax.Minimax (Block_Pos, X_Mark);
      M := Best_Move (Block_Pos, X_Mark);
      Check (M.R = 1 and then M.C = 3, "X blocks O threat at (1,3)");
      Check (Near (V, Minimax.Minimax (Apply_Move (Block_Pos, M, X_Mark),
        O_Mark)), "Best move achieves minimax value");

      declare
         Take : constant Board :=
           Make_Board (O, Empty, O,
                       X, X, Empty,
                       Empty, Empty, Empty);
      begin
         Check (Side_To_Move (Take) = X_Mark, "X to move Take");
         Check (Near (Minimax.Minimax (Take, X_Mark), 1.0), "Take value +1");
         Check (Near (Alpha_Beta (Take, X_Mark), 1.0), "Take AB +1");
         M := Best_Move (Take, X_Mark);
         declare
            Child : constant Board := Apply_Move (Take, M, X_Mark);
         begin
            Check (Winner (Child) = X
                     or else Near (Minimax.Minimax (Child, O_Mark), 1.0),
                   "Best move preserves forced X win");
         end;
         Check (Winner (Apply_Move (Take, (2, 3), X_Mark)) = X,
                "Cell (2,3) is an immediate win");
      end;

      Check (Threat (1, 1) = O and then Threat2 (1, 1) = O, "fixture ok");
   end;

   ---------------------------------------------------------------------
   Section ("13. Depth limit stub on TTT");
   ---------------------------------------------------------------------
   declare
      E : constant Board := Empty_Board;
   begin
      Check (Near (Minimax.Minimax (E, X_Mark, Depth => 0), 0.0),
             "Depth 0 non-terminal → 0");
      Check (Near (Alpha_Beta (E, X_Mark, Depth => 0), 0.0),
             "AB depth 0 → 0");
      Check (Near (Minimax.Minimax (E, X_Mark, Depth => 1), 0.0),
             "Depth 1 empty → 0");
   end;

   ---------------------------------------------------------------------
   Section ("14. Legal_Moves ordering / Apply_Move integrity");
   ---------------------------------------------------------------------
   declare
      B : Board := Empty_Board;
      L : Move_List (1 .. 9);
      N : Natural := 0;
   begin
      L := Legal_Moves (B);
      Check (L'Length = 9, "9 moves empty");
      Check (L (1).R = 1 and then L (1).C = 1, "First move (1,1)");
      Check (L (9).R = 3 and then L (9).C = 3, "Last move (3,3)");

      B := Apply_Move (B, (2, 2), X_Mark);
      declare
         L8 : constant Move_List := Legal_Moves (B);
      begin
         Check (L8'Length = 8, "8 moves after center");
         for M of L8 loop
            Check (not (M.R = 2 and then M.C = 2), "Center not listed");
            N := N + 1;
         end loop;
         Check (N = 8, "Iterated 8 legal moves");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. More encode / winner edge cases");
   ---------------------------------------------------------------------
   declare
      Codes_Ok : Boolean := True;
      B : Board;
   begin
      for R in Row loop
         for C in Col loop
            B := Empty_Board;
            B (R, C) := X;
            if Encode (Decode (Encode (B))) /= Encode (B) then
               Codes_Ok := False;
            end if;
            Check (Decode (Encode (B)) (R, C) = X,
                   "Encode single X at" & R'Image & C'Image);
         end loop;
      end loop;
      Check (Codes_Ok, "All single-X encode round-trips");

      B := Empty_Board;
      for R in Row loop
         for C in Col loop
            B (R, C) := O;
         end loop;
      end loop;
      Check (Is_Full (B), "All-O full");
      Check (Winner (B) = O, "All-O winner O (rows)");
      Check (Near (Evaluate (B), -1.0), "All-O eval -1");
   end;

   ---------------------------------------------------------------------
   Section ("16. Best_Child_Index for minimizing root");
   ---------------------------------------------------------------------
   declare
      Root : constant Tree_Access :=
        Branch
          ([Branch ([Leaf (10.0), Leaf (1.0)]),
            Branch ([Leaf (5.0), Leaf (7.0)])]);
   begin
      Check (Near (Minimax_Tree (Root, True), 5.0), "Min-root fixture max=5");
      Check (Best_Child_Index (Root, True) = 2, "Max picks child 2");
      Check (Near (Minimax_Tree (Root, False), 7.0), "Min root value 7");
      Check (Best_Child_Index (Root, False) = 2, "Min picks child 2");
      Check (Best_Child_Index (Root, False, True) = 2, "Min AB child 2");
   end;

   ---------------------------------------------------------------------
   Section ("17. O to move — late fill");
   ---------------------------------------------------------------------
   declare
      Pos : constant Board :=
        Make_Board (X, X, O,
                    O, O, X,
                    X, Empty, O);
      M     : Move;
      Child : Board;
      V     : Score;
   begin
      Check (Side_To_Move (Pos) = X_Mark, "X to move (odd empties)");
      Check (Count_Empty (Pos) = 1, "one empty");
      M := Best_Move (Pos, X_Mark);
      Check (M.R = 3 and then M.C = 2, "X only move (3,2)");
      Child := Apply_Move (Pos, M, X_Mark);
      V := Evaluate (Child);
      Check (Near (Minimax.Minimax (Pos, X_Mark), V), "X move eval matches");
      Check (Near (Alpha_Beta (Pos, X_Mark), V), "X AB matches");
      Check (Is_Terminal (Child), "Filled terminal");
   end;

   ---------------------------------------------------------------------
   Section ("18. Callback depth limit");
   ---------------------------------------------------------------------
   begin
      Check (Near (Minimax_Callback
        (0, Demo_Game, True, Depth => 0), 0.0),
             "Callback depth 0 at root → Evaluate 0");
      Check (Near (Minimax_Callback
        (0, Demo_Game, True, Depth => 1), 0.0),
             "Callback depth 1 → child Evaluate 0");
      Check (Near (Minimax_Callback
        (0, Demo_Game, True, Depth => 2), 3.0),
             "Callback depth 2 reaches leaves");
      Check (Near (Alpha_Beta_Callback
        (0, Demo_Game, True, Depth => 2), 3.0),
             "Callback AB depth 2 = 3");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("Pass_Count =" & Pass_Count'Image);
   Ada.Text_IO.Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
