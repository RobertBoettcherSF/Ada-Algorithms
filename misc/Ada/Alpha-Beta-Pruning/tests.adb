--  Standalone test suite for Alpha_Beta_Pruning (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Alpha_Beta_Pruning; use Alpha_Beta_Pruning;

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
   Ada.Text_IO.Put_Line ("Alpha–Beta Pruning test suite");
   Ada.Text_IO.Put_Line ("=============================");

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
   Section ("2. Leaf / Branch constructors");
   ---------------------------------------------------------------------
   declare
      L : constant Node_Access := Leaf (42.0);
      A : constant Node_Access := Leaf (1.0);
      B : constant Node_Access := Leaf (2.0);
      R : constant Node_Access := Branch ([A, B]);
   begin
      Check (L.Is_Leaf, "Leaf.Is_Leaf");
      Check (Near (L.Leaf_Value, 42.0), "Leaf value");
      Check (L.N_Children = 0, "Leaf N_Children=0");
      Check (not R.Is_Leaf, "Branch not leaf");
      Check (R.N_Children = 2, "Branch N_Children=2");
      Check (R.Children (1) = A, "Branch child 1");
      Check (R.Children (2) = B, "Branch child 2");
   end;

   ---------------------------------------------------------------------
   Section ("3. Wikipedia-style shallow tree value = 3");
   ---------------------------------------------------------------------
   --  max(min(3,5), min(2,9)) = 3
   declare
      L3   : constant Node_Access := Leaf (3.0);
      L5   : constant Node_Access := Leaf (5.0);
      L2   : constant Node_Access := Leaf (2.0);
      L9   : constant Node_Access := Leaf (9.0);
      MinL : constant Node_Access := Branch ([L3, L5]);
      MinR : constant Node_Access := Branch ([L2, L9]);
      Root : constant Node_Access := Branch ([MinL, MinR]);
      Mm   : Result;
      Ab   : Result;
      Bi   : Child_Index;
   begin
      Mm := Minimax (Root, True);
      Ab := Alpha_Beta (Root, True);
      Check (Near (Mm.Value, 3.0), "Minimax value 3");
      Check (Near (Ab.Value, 3.0), "Alpha_Beta value 3");
      Check (Near (Mm.Value, Ab.Value), "MM == AB value");
      Check (Mm.Best_Child = 1, "Minimax best child left");
      Check (Ab.Best_Child = 1, "AB best child left");
      Check (Mm.Cutoffs = 0, "Minimax Cutoffs=0");
      Check (Mm.Nodes_Visited > 0, "Minimax visited > 0");
      Check (Ab.Nodes_Visited > 0, "AB visited > 0");
      Check (Ab.Nodes_Visited <= Mm.Nodes_Visited,
             "AB nodes <= MM nodes (shallow)");
      Bi := Best_Move_Minimax (Root, True);
      Check (Bi = 1, "Best_Move_Minimax = 1");
      Bi := Best_Move_Alpha_Beta (Root, True);
      Check (Bi = 1, "Best_Move_Alpha_Beta = 1");
      Bi := Best_Move (Root, True, True);
      Check (Bi = 1, "Best_Move AB path");
      Bi := Best_Move (Root, True, False);
      Check (Bi = 1, "Best_Move MM path");
   end;

   ---------------------------------------------------------------------
   Section ("4. Three-child max tree value = 4");
   ---------------------------------------------------------------------
   --  max(min(1,4), min(3,5), min(2,4)) wait: better craft
   --  max(min(4,5), min(2,3), min(6,1)) = max(4,2,1) = 4
   declare
      Root : constant Node_Access :=
        Branch
          ([Branch ([Leaf (4.0), Leaf (5.0)]),
            Branch ([Leaf (2.0), Leaf (3.0)]),
            Branch ([Leaf (6.0), Leaf (1.0)])]);
      Mm : Result;
      Ab : Result;
   begin
      Mm := Minimax (Root, True);
      Ab := Alpha_Beta (Root, True);
      Check (Near (Mm.Value, 4.0), "Three-child MM=4");
      Check (Near (Ab.Value, 4.0), "Three-child AB=4");
      Check (Mm.Best_Child = 1, "Three-child best=1");
      Check (Ab.Best_Child = 1, "Three-child AB best=1");
      Check (Ab.Nodes_Visited <= Mm.Nodes_Visited,
             "Three-child AB <= MM nodes");
   end;

   ---------------------------------------------------------------------
   Section ("5. Crafted tree — pruning reduces nodes");
   ---------------------------------------------------------------------
   --  Root MAX; left MIN establishes alpha=5 via leaves 10,5;
   --  right MIN: first leaf 3 <= alpha → remaining siblings pruned.
   --  Full MM must visit both right leaves; AB cuts after 3.
   declare
      Left  : constant Node_Access :=
        Branch ([Leaf (10.0), Leaf (5.0)]);
      Right : constant Node_Access :=
        Branch ([Leaf (3.0), Leaf (99.0), Leaf (100.0)]);
      Root  : constant Node_Access := Branch ([Left, Right]);
      Mm    : Result;
      Ab    : Result;
   begin
      Mm := Minimax (Root, True);
      Ab := Alpha_Beta (Root, True);
      Check (Near (Mm.Value, 5.0), "Prune-tree MM value 5");
      Check (Near (Ab.Value, 5.0), "Prune-tree AB value 5");
      Check (Near (Mm.Value, Ab.Value), "Prune-tree same value");
      Check (Mm.Best_Child = 1, "Prune-tree best left");
      Check (Ab.Best_Child = 1, "Prune-tree AB best left");
      Check (Mm.Nodes_Visited = 8,
             "Prune-tree MM visits all 8");
      --  root + left + 2 leaves + right + first leaf (+cutoff) = 6
      Check (Ab.Nodes_Visited < Mm.Nodes_Visited,
             "Prune-tree AB visits fewer");
      Check (Ab.Cutoffs >= 1, "Prune-tree Cutoffs >= 1");
      Check (Ab.Nodes_Visited = 6, "Prune-tree AB visits 6");
   end;

   ---------------------------------------------------------------------
   Section ("6. Deeper ordered tree — more cutoffs");
   ---------------------------------------------------------------------
   --  Depth-3: MAX → MIN → MAX(leaves). Left establishes strong alpha;
   --  right branches refute early.
   declare
      --  Left MIN: max(5,6)=6 then max(7,4)=7 → min(6,7)=6
      L1 : constant Node_Access :=
        Branch
          ([Branch ([Leaf (5.0), Leaf (6.0)]),
            Branch ([Leaf (7.0), Leaf (4.0)])]);
      --  Right MIN: first MAX child max(1,2)=2 ≤ alpha 6 → prune rest
      R1 : constant Node_Access :=
        Branch
          ([Branch ([Leaf (1.0), Leaf (2.0)]),
            Branch ([Leaf (100.0), Leaf (200.0)]),
            Branch ([Leaf (50.0), Leaf (60.0)])]);
      Root : constant Node_Access := Branch ([L1, R1]);
      Mm   : Result;
      Ab   : Result;
   begin
      Mm := Minimax (Root, True);
      Ab := Alpha_Beta (Root, True);
      Check (Near (Mm.Value, 6.0), "Deep MM value 6");
      Check (Near (Ab.Value, 6.0), "Deep AB value 6");
      Check (Near (Mm.Value, Ab.Value), "Deep same value");
      Check (Ab.Nodes_Visited < Mm.Nodes_Visited, "Deep AB fewer nodes");
      Check (Ab.Cutoffs >= 1, "Deep Cutoffs >= 1");
      Check (Mm.Cutoffs = 0, "Deep MM Cutoffs=0");
      Check (Mm.Best_Child = 1, "Deep best child 1");
      Check (Ab.Best_Child = 1, "Deep AB best child 1");
   end;

   ---------------------------------------------------------------------
   Section ("7. Minimizing root");
   ---------------------------------------------------------------------
   declare
      Root : constant Node_Access :=
        Branch
          ([Branch ([Leaf (8.0), Leaf (2.0)]),
            Branch ([Leaf (3.0), Leaf (9.0)])]);
      --  At MIN root: min(max(8,2), max(3,9)) = min(8,9) = 8
      Mm : Result;
      Ab : Result;
   begin
      Mm := Minimax (Root, False);
      Ab := Alpha_Beta (Root, False);
      Check (Near (Mm.Value, 8.0), "Min-root MM=8");
      Check (Near (Ab.Value, 8.0), "Min-root AB=8");
      Check (Mm.Best_Child = 1, "Min-root best=1");
      Check (Near (Mm.Value, Ab.Value), "Min-root same");
   end;

   ---------------------------------------------------------------------
   Section ("8. Single leaf / single child");
   ---------------------------------------------------------------------
   declare
      L  : constant Node_Access := Leaf (-7.5);
      Mm : Result;
      Ab : Result;
      Ch : constant Node_Access := Branch ([Leaf (11.0)]);
   begin
      Mm := Minimax (L, True);
      Ab := Alpha_Beta (L, True);
      Check (Near (Mm.Value, -7.5), "Leaf MM value");
      Check (Near (Ab.Value, -7.5), "Leaf AB value");
      Check (Mm.Best_Child = 0, "Leaf Best_Child=0");
      Check (Mm.Nodes_Visited = 1, "Leaf visits 1");
      Mm := Minimax (Ch, True);
      Ab := Alpha_Beta (Ch, True);
      Check (Near (Mm.Value, 11.0), "Unary MM=11");
      Check (Near (Ab.Value, 11.0), "Unary AB=11");
      Check (Mm.Best_Child = 1, "Unary best=1");
   end;

   ---------------------------------------------------------------------
   Section ("9. No pruning when ordered poorly (same nodes)");
   ---------------------------------------------------------------------
   --  Right-first good move: AB still correct; may still visit many.
   declare
      Root : constant Node_Access :=
        Branch
          ([Branch ([Leaf (1.0), Leaf (0.0)]),   -- min=0
            Branch ([Leaf (4.0), Leaf (5.0)])]);  -- min=4 → value 4
      Mm : Result;
      Ab : Result;
   begin
      Mm := Minimax (Root, True);
      Ab := Alpha_Beta (Root, True);
      Check (Near (Mm.Value, 4.0), "Pessimal order MM=4");
      Check (Near (Ab.Value, 4.0), "Pessimal order AB=4");
      Check (Mm.Best_Child = 2, "Pessimal best=2");
      Check (Ab.Best_Child = 2, "Pessimal AB best=2");
      Check (Ab.Nodes_Visited = Mm.Nodes_Visited
             or else Ab.Nodes_Visited <= Mm.Nodes_Visited,
             "Pessimal AB never exceeds MM");
   end;

   ---------------------------------------------------------------------
   Section ("10. Tic-Tac-Toe board helpers");
   ---------------------------------------------------------------------
   declare
      E : constant Board := Empty_Board;
      W : Board;
   begin
      Check (Count_Empty (E) = 9, "Empty has 9");
      Check (not Is_Terminal (E), "Empty not terminal");
      Check (Winner (E) = Empty, "Empty no winner");
      Check (Side_To_Move (E) = X_Mark, "X to move empty");
      Check (To_Cell (X_Mark) = X, "To_Cell X");
      Check (To_Cell (O_Mark) = O, "To_Cell O");
      Check (Opponent (X_Mark) = O_Mark, "Opponent X");
      Check (Opponent (O_Mark) = X_Mark, "Opponent O");
      Check (Legal_Moves (E)'Length = 9, "9 legal moves");
      Check (not Is_Full (E), "Empty not full");

      W := Make_Board
        (X, X, X,
         O, O, Empty,
         Empty, Empty, Empty);
      Check (Winner (W) = X, "Row win X");
      Check (Is_Terminal (W), "Row win terminal");
      Check (Near (Evaluate (W), 1.0), "X win +1");

      W := Make_Board
        (O, X, X,
         O, X, Empty,
         O, Empty, Empty);
      Check (Winner (W) = O, "Col win O");
      Check (Near (Evaluate (W), -1.0), "O win -1");

      W := Make_Board
        (X, O, O,
         O, X, Empty,
         Empty, Empty, X);
      Check (Winner (W) = X, "Diag win X");

      W := Make_Board
        (X, O, X,
         X, O, O,
         O, X, X);
      Check (Is_Full (W), "Draw board full");
      Check (Winner (W) = Empty, "Draw no winner");
      Check (Is_Terminal (W), "Draw terminal");
      Check (Near (Evaluate (W), 0.0), "Draw 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Tic-Tac-Toe perfect play — MM == AB");
   ---------------------------------------------------------------------
   declare
      E  : constant Board := Empty_Board;
      Mm : Result;
      Ab : Result;
      Mv : Move;
      B  : Board;
   begin
      Mm := Minimax_TTT (E, X_Mark);
      Ab := Alpha_Beta_TTT (E, X_Mark);
      Check (Near (Mm.Value, 0.0), "Empty MM draw");
      Check (Near (Ab.Value, 0.0), "Empty AB draw");
      Check (Near (Mm.Value, Ab.Value), "Empty MM==AB");
      Check (Ab.Nodes_Visited < Mm.Nodes_Visited,
             "Empty AB fewer nodes than MM");
      Check (Ab.Cutoffs > 0, "Empty AB Cutoffs > 0");
      Check (Mm.Cutoffs = 0, "Empty MM Cutoffs=0");

      Mv := Best_Move_TTT (E, X_Mark, True);
      Check (E (Mv.R, Mv.C) = Empty, "Best move empty cell");
      B := Apply_Move (E, Mv, X_Mark);
      Check (Count_Empty (B) = 8, "After first move 8 empty");

      --  X can force win: two in a row, O elsewhere
      B := Make_Board
        (X, X, Empty,
         O, O, Empty,
         Empty, Empty, Empty);
      Mm := Minimax_TTT (B, X_Mark);
      Ab := Alpha_Beta_TTT (B, X_Mark);
      Check (Near (Mm.Value, 1.0), "Forced X win MM");
      Check (Near (Ab.Value, 1.0), "Forced X win AB");
      Mv := Best_Move_TTT (B, X_Mark, True);
      Check (Mv.R = 1 and then Mv.C = 3, "Take winning cell 1,3");

      B := Make_Board
        (X, Empty, Empty,
         Empty, O, Empty,
         Empty, Empty, Empty);
      Mm := Minimax_TTT (B, X_Mark);
      Ab := Alpha_Beta_TTT (B, X_Mark);
      Check (Near (Mm.Value, Ab.Value), "Midgame MM==AB");
      Check (Ab.Nodes_Visited <= Mm.Nodes_Visited,
             "Midgame AB <= MM nodes");
   end;

   ---------------------------------------------------------------------
   Section ("12. Apply_Move / Side_To_Move parity");
   ---------------------------------------------------------------------
   declare
      B : Board := Empty_Board;
      M : constant Move := (R => 2, C => 2);
   begin
      B := Apply_Move (B, M, X_Mark);
      Check (B (2, 2) = X, "Center X");
      Check (Side_To_Move (B) = O_Mark, "O after X");
      B := Apply_Move (B, (1, 1), O_Mark);
      Check (B (1, 1) = O, "Corner O");
      Check (Side_To_Move (B) = X_Mark, "X after O");
      Check (Count_Empty (B) = 7, "7 empty");
      Check (Legal_Moves (B)'Length = 7, "7 legal");
   end;

   ---------------------------------------------------------------------
   Section ("13. Windowed Alpha_Beta still matches when window wide");
   ---------------------------------------------------------------------
   declare
      Root : constant Node_Access :=
        Branch
          ([Branch ([Leaf (3.0), Leaf (5.0)]),
            Branch ([Leaf (2.0), Leaf (9.0)])]);
      Ab : Result;
   begin
      Ab := Alpha_Beta (Root, True, -100.0, 100.0);
      Check (Near (Ab.Value, 3.0), "Wide window value 3");
      Ab := Alpha_Beta (Root, True, Neg_Inf, Pos_Inf);
      Check (Near (Ab.Value, 3.0), "Inf window value 3");
   end;

   ---------------------------------------------------------------------
   Section ("14. Stats sanity across several trees");
   ---------------------------------------------------------------------
   declare
      T1 : constant Node_Access :=
        Branch ([Leaf (1.0), Leaf (2.0), Leaf (3.0)]);
      T2 : constant Node_Access :=
        Branch
          ([Branch ([Leaf (0.0), Leaf (-1.0)]),
            Branch ([Leaf (4.0), Leaf (4.0)])]);
      Mm, Ab : Result;
   begin
      Mm := Minimax (T1, True);
      Ab := Alpha_Beta (T1, True);
      Check (Near (Mm.Value, 3.0), "Flat max=3");
      Check (Near (Ab.Value, 3.0), "Flat AB=3");
      Check (Mm.Best_Child = 3, "Flat best=3");

      Mm := Minimax (T2, True);
      Ab := Alpha_Beta (T2, True);
      Check (Near (Mm.Value, 4.0), "T2 MM=4");
      Check (Near (Ab.Value, 4.0), "T2 AB=4");
      Check (Ab.Nodes_Visited <= Mm.Nodes_Visited, "T2 AB<=MM");
      Check (Mm.Nodes_Visited >= Ab.Nodes_Visited, "T2 MM>=AB");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: Pass_Count="
      & Natural'Image (Pass_Count)
      & " Fail_Count="
      & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
   elsif Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED (but Pass_Count < 80)");
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      raise Program_Error with "tests failed";
   end if;
end Tests;
