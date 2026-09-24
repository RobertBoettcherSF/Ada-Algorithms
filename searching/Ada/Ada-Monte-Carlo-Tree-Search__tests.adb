--  Standalone test suite for Monte_Carlo_Tree_Search (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Monte_Carlo_Tree_Search; use Monte_Carlo_Tree_Search;

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

   function Is_Legal_TTT (B : Board; M : Move) return Boolean is
      L : constant TTT_Move_List := Legal_Moves_TTT (B);
   begin
      for I in L'Range loop
         if Moves_Equal (L (I), M) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Legal_TTT;

   procedure Expect_Invalid (Message : String; Thunk : access procedure) is
      Raised : Boolean := False;
   begin
      begin
         Thunk.all;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, Message);
   end Expect_Invalid;

   procedure Expect_No_Move (Message : String; Thunk : access procedure) is
      Raised : Boolean := False;
   begin
      begin
         Thunk.all;
      exception
         when No_Legal_Move => Raised := True;
      end;
      Check (Raised, Message);
   end Expect_No_Move;

begin
   Ada.Text_IO.Put_Line ("Monte Carlo Tree Search test suite");
   Ada.Text_IO.Put_Line ("===================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp_Unit / Default_C");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Near (Clamp_Unit (-0.5), 0.0), "Clamp below");
   Check (Near (Clamp_Unit (1.5), 1.0), "Clamp above");
   Check (Near (Clamp_Unit (0.3), 0.3), "Clamp mid");
   Check (Near (Default_C, 1.4142135623730951), "Default_C is sqrt(2)");
   Check (Near (Default_C * Default_C, 2.0, 1.0E-9), "Default_C squared is 2");

   declare
      procedure Bad is
         Ok : Boolean;
      begin
         Ok := Near (1.0, 1.0, -0.1);
         raise Program_Error with "expected exception " & Boolean'Image (Ok);
      end Bad;
   begin
      Expect_Invalid ("Near rejects negative Tol", Bad'Access);
   end;

   ---------------------------------------------------------------------
   Section ("2. UCT_Score");
   ---------------------------------------------------------------------
   declare
      S_Inf : constant Real := UCT_Score (0.0, 0, 10, 1.4);
      S1    : constant Real := UCT_Score (0.5, 10, 100, 1.4);
      S2    : constant Real := UCT_Score (0.5, 50, 100, 1.4);
      S3    : constant Real := UCT_Score (0.9, 10, 100, 1.4);
      S4    : constant Real := UCT_Score (0.0, 1, 1, 0.0);
      S5    : constant Real := UCT_Score (1.0, 5, 0, 1.4);
   begin
      Check (S_Inf = Real'Last, "UCT unvisited = +inf");
      Check (S1 > S2, "UCT prefers less-visited at equal mean");
      Check (S3 > S1, "UCT prefers higher mean at equal visits");
      Check (Near (S4, 0.0), "UCT with C=0 is pure exploitation");
      Check (Near (S5, 1.0), "UCT Parent_Visits=0 returns mean");
   end;

   declare
      procedure Bad is
         Dummy : Real;
      begin
         Dummy := UCT_Score (0.0, 1, 1, -1.0);
         raise Program_Error with "expected exception " & Dummy'Image;
      end Bad;
   begin
      Expect_Invalid ("UCT_Score rejects C < 0", Bad'Access);
   end;

   ---------------------------------------------------------------------
   Section ("3. Seeded RNG");
   ---------------------------------------------------------------------
   declare
      G1 : RNG := Make_RNG (42);
      G2 : RNG := Make_RNG (42);
      G3 : RNG := Make_RNG (99);
      U1, U2, U3 : Unit_Interval;
      Match : Boolean := True;
      Diff  : Boolean := False;
   begin
      for I in 1 .. 8 loop
         U1 := Random_Unit (G1);
         U2 := Random_Unit (G2);
         U3 := Random_Unit (G3);
         if not Near (U1, U2) then
            Match := False;
         end if;
         if not Near (U1, U3) then
            Diff := True;
         end if;
         Check (U1 >= 0.0 and then U1 < 1.0, "Random_Unit in [0,1)");
      end loop;
      Check (Match, "Same seed same stream");
      Check (Diff, "Different seed different stream");
   end;

   declare
      G : RNG := Make_RNG (7);
      Counts : array (1 .. 4) of Natural := [others => 0];
      Idx : Positive;
      All_Hit : Boolean := True;
      All_In : Boolean := True;
   begin
      for I in 1 .. 80 loop
         Idx := Random_Index (G, 1, 4);
         if Idx not in 1 .. 4 then
            All_In := False;
         else
            Counts (Idx) := Counts (Idx) + 1;
         end if;
      end loop;
      for I in 1 .. 4 loop
         if Counts (I) = 0 then
            All_Hit := False;
         end if;
      end loop;
      Check (All_In, "Random_Index always in 1..4");
      Check (All_Hit, "Random_Index covers 1..4");
   end;

   declare
      G0 : RNG := Make_RNG (0);
      Gn : RNG := Make_RNG (-3);
      U0 : constant Unit_Interval := Random_Unit (G0);
      Un : constant Unit_Interval := Random_Unit (Gn);
   begin
      Check (U0 >= 0.0 and then U0 < 1.0, "Seed 0 works");
      Check (Un >= 0.0 and then Un < 1.0, "Negative seed works");
   end;

   ---------------------------------------------------------------------
   Section ("4. Select_UCT_Child");
   ---------------------------------------------------------------------
   declare
      Stats : Child_Stat_Array := [others => <>];
      Pick  : Positive;
   begin
      Stats (1) := (Visits => 10, Total_Reward => 5.0, Mean_Reward => 0.5);
      Stats (2) := (Visits => 0,  Total_Reward => 0.0, Mean_Reward => 0.0);
      Stats (3) := (Visits => 10, Total_Reward => 8.0, Mean_Reward => 0.8);
      Pick := Select_UCT_Child (Stats, 3, 20, Default_C);
      Check (Pick = 2, "Select prefers unvisited");
   end;

   declare
      Stats : Child_Stat_Array := [others => <>];
      Pick  : Positive;
   begin
      Stats (1) := (10, 5.0, 0.5);
      Stats (2) := (10, 8.0, 0.8);
      Stats (3) := (10, 2.0, 0.2);
      Pick := Select_UCT_Child (Stats, 3, 30, 0.0);
      Check (Pick = 2, "Select C=0 picks highest mean");
   end;

   declare
      Stats : Child_Stat_Array := [others => <>];
      Pick  : Positive;
   begin
      Stats (1) := (0, 0.0, 0.0);
      Stats (2) := (0, 0.0, 0.0);
      Pick := Select_UCT_Child (Stats, 2, 0, Default_C);
      Check (Pick = 1, "Select unvisited tie -> lowest index");
   end;

   ---------------------------------------------------------------------
   Section ("5. Tic-Tac-Toe rules");
   ---------------------------------------------------------------------
   declare
      B : constant Board := Empty_Board;
   begin
      Check (Count_Empty (B) = 9, "Empty board 9 empties");
      Check (not Is_Terminal (B), "Empty not terminal");
      Check (Winner (B) = Empty, "Empty no winner");
      Check (Side_To_Move_TTT (B) = X_Mark, "X to move empty");
      Check (Legal_Moves_TTT (B)'Length = 9, "9 legal moves");
      Check (Opponent (X_Mark) = O_Mark, "Opponent X->O");
      Check (Opponent (O_Mark) = X_Mark, "Opponent O->X");
      Check (To_Cell (X_Mark) = X, "To_Cell X");
      Check (To_Cell (O_Mark) = O, "To_Cell O");
   end;

   declare
      B : constant Board := Make_Board
        (X, X, X, O, O, Empty, Empty, Empty, Empty);
   begin
      Check (Winner (B) = X, "Row win X");
      Check (Is_Terminal (B), "Row win terminal");
      Check (Near (Terminal_Reward (B, X_Mark), 1.0), "X reward +1");
      Check (Near (Terminal_Reward (B, O_Mark), -1.0), "O reward -1");
   end;

   declare
      B : constant Board := Make_Board
        (O, X, X, O, X, Empty, O, Empty, Empty);
   begin
      Check (Winner (B) = O, "Col win O");
      Check (Near (Terminal_Reward (B, O_Mark), 1.0), "O col +1");
   end;

   declare
      B : constant Board := Make_Board
        (X, O, Empty, O, X, Empty, Empty, Empty, X);
   begin
      Check (Winner (B) = X, "Diag win X");
   end;

   declare
      B : constant Board := Make_Board
        (Empty, O, X, Empty, X, O, X, Empty, Empty);
   begin
      Check (Winner (B) = X, "Anti-diag win X");
   end;

   declare
      B : constant Board := Make_Board
        (X, O, X, X, O, O, O, X, X);
   begin
      Check (Winner (B) = Empty, "Draw no winner");
      Check (Is_Full (B), "Draw full");
      Check (Is_Terminal (B), "Draw terminal");
      Check (Near (Terminal_Reward (B, X_Mark), 0.0), "Draw reward 0");
      Check (Count_Empty (B) = 0, "Draw 0 empty");
   end;

   declare
      B  : constant Board := Empty_Board;
      B2 : constant Board := Apply_Move_TTT (B, (2, 2), X_Mark);
   begin
      Check (B2 (2, 2) = X, "Apply center X");
      Check (Count_Empty (B2) = 8, "After one move 8 empty");
      Check (Side_To_Move_TTT (B2) = O_Mark, "O to move after X");
      Check (Legal_Moves_TTT (B2)'Length = 8, "8 legal after center");
   end;

   declare
      procedure Bad is
         B2 : constant Board := Apply_Move_TTT (Empty_Board, (1, 1), X_Mark);
         B3 : Board;
      begin
         B3 := Apply_Move_TTT (B2, (1, 1), O_Mark);
         raise Program_Error with "expected exception " & Cell'Image (B3 (1, 1));
      end Bad;
   begin
      Expect_Invalid ("Apply rejects occupied", Bad'Access);
   end;

   Check (Moves_Equal ((1, 2), (1, 2)), "Moves_equal true");
   Check (not Moves_equal ((1, 2), (2, 1)), "Moves_equal false");

   ---------------------------------------------------------------------
   Section ("6. Nim rules");
   ---------------------------------------------------------------------
   declare
      S : constant Nim_State := (Heap => 0, Max_Take => 3);
   begin
      Check (Is_Terminal_Nim (S), "Heap 0 terminal");
      Check (Near (Terminal_Reward_Nim (S), -1.0), "Terminal reward -1");
      Check (Legal_Moves_Nim (S)'Length = 0, "No moves at 0");
      Check (Is_Losing_Position (S), "0 is losing");
   end;

   declare
      S : constant Nim_State := (Heap => 5, Max_Take => 3);
      L : constant Nim_Move_List := Legal_Moves_Nim (S);
   begin
      Check (L'Length = 3, "Heap 5 Max 3 -> 3 moves");
      Check (L (1) = 1 and then L (2) = 2 and then L (3) = 3, "Moves 1,2,3");
      Check (not Is_Losing_Position (S), "5 mod 4 = 1 not losing");
   end;

   declare
      S : constant Nim_State := (Heap => 4, Max_Take => 3);
   begin
      Check (Is_Losing_Position (S), "4 mod 4 = 0 losing");
   end;

   declare
      S  : constant Nim_State := (Heap => 2, Max_Take => 3);
      L  : constant Nim_Move_List := Legal_Moves_Nim (S);
      S2 : constant Nim_State := Apply_Move_Nim (S, 2);
   begin
      Check (L'Length = 2, "Heap 2 -> take 1 or 2");
      Check (S2.Heap = 0, "Take all -> 0");
      Check (Is_Terminal_Nim (S2), "After take-all terminal");
   end;

   declare
      procedure Bad is
         S  : constant Nim_State := (Heap => 3, Max_Take => 2);
         S2 : Nim_State;
      begin
         S2 := Apply_Move_Nim (S, 3);
         raise Program_Error with "expected exception " & S2.Heap'Image;
      end Bad;
   begin
      Expect_Invalid ("Apply_Move_Nim rejects Take > Max", Bad'Access);
   end;

   for H in 0 .. 7 loop
      declare
         S    : constant Nim_State := (Heap => H, Max_Take => 3);
         Lose : constant Boolean := (H rem 4) = 0;
      begin
         Check (Is_Losing_Position (S) = Lose,
                "Losing iff H mod 4 = 0");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("7. Rollouts");
   ---------------------------------------------------------------------
   declare
      G : RNG := Make_RNG (123);
      R : Real;
      B : constant Board := Empty_Board;
      Ok : Boolean;
   begin
      for I in 1 .. 10 loop
         R := Rollout_TTT (B, X_Mark, G);
         Ok := Near (R, 1.0) or else Near (R, -1.0) or else Near (R, 0.0);
         Check (Ok, "TTT rollout in {-1,0,1}");
      end loop;
   end;

   declare
      G : RNG := Make_RNG (55);
      R : Real;
      S : constant Nim_State := (Heap => 7, Max_Take => 3);
      Ok : Boolean;
   begin
      for I in 1 .. 10 loop
         R := Rollout_Nim (S, G);
         Ok := Near (R, 1.0) or else Near (R, -1.0);
         Check (Ok, "Nim rollout in {-1,1}");
      end loop;
   end;

   declare
      G : RNG := Make_RNG (1);
      B : constant Board := Make_Board
        (X, X, X, O, O, Empty, Empty, Empty, Empty);
      R : constant Real := Rollout_TTT (B, O_Mark, G);
   begin
      Check (Near (R, -1.0), "Rollout on X-won board from O = -1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Search_TTT prefers wins / legal");
   ---------------------------------------------------------------------
   declare
      B   : constant Board := Make_Board
        (X, X, Empty, O, O, Empty, Empty, Empty, Empty);
      Res : constant Search_Result :=
        Search_TTT (B, X_Mark, 200, Default_C, 42);
   begin
      Check (Is_Legal_TTT (B, Res.Best_TTT), "Win: legal move");
      Check (Moves_equal (Res.Best_TTT, (1, 3)), "X completes row (1,3)");
      Check (Res.Best_Index >= 1, "Best_Index set");
      Check (Res.Iterations = 200, "Iterations recorded");
      Check (Res.Root_Visits = 200, "Root visits = iterations");
      Check (Res.N_Children = Legal_Moves_TTT (B)'Length, "N_Children");
   end;

   declare
      B   : constant Board := Make_Board
        (O, O, Empty, X, Empty, Empty, X, Empty, Empty);
      Res : constant Search_Result :=
        Search_TTT (B, X_Mark, 300, Default_C, 7);
   begin
      Check (Is_Legal_TTT (B, Res.Best_TTT), "Block: legal");
      Check (Moves_equal (Res.Best_TTT, (1, 3)), "X blocks O at (1,3)");
   end;

   declare
      B   : constant Board := Empty_Board;
      Res : constant Search_Result :=
        Search_TTT (B, X_Mark, 100, Default_C, 1);
   begin
      Check (Is_Legal_TTT (B, Res.Best_TTT), "Opening move legal");
      Check (Res.Stats (Res.Best_Index).Visits > 0, "Best has visits");
   end;

   for Seed in 1 .. 3 loop
      declare
         B   : constant Board := Make_Board
           (X, O, X, O, X, Empty, O, Empty, Empty);
         Res : constant Search_Result :=
           Search_TTT (B, O_Mark, 80, Default_C, Seed);
      begin
         Check (Is_Legal_TTT (B, Res.Best_TTT), "Seed legal O to move");
      end;
   end loop;

   declare
      B   : constant Board := Make_Board
        (X, O, Empty, X, O, Empty, Empty, Empty, Empty);
      Res : constant Search_Result :=
        Search_TTT (B, X_Mark, 250, Default_C, 99);
   begin
      Check (Moves_equal (Res.Best_TTT, (3, 1)), "X completes column (3,1)");
   end;

   declare
      B   : constant Board := Make_Board
        (X, O, X, X, O, O, O, X, Empty);
      Res : constant Search_Result :=
        Search_TTT (B, X_Mark, 20, Default_C, 5);
   begin
      Check (Legal_Moves_TTT (B)'Length = 1, "One move left");
      Check (Side_To_Move_TTT (B) = X_Mark, "X takes last");
      Check (Moves_equal (Res.Best_TTT, (3, 3)), "Only move (3,3)");
   end;

   for C_I in 1 .. 2 loop
      declare
         B     : constant Board := Empty_Board;
         C_Val : constant Real := Real (C_I) * 0.5;
         Res   : constant Search_Result :=
           Search_TTT (B, X_Mark, 40, C_Val, C_I);
      begin
         Check (Is_Legal_TTT (B, Res.Best_TTT), "Various C legal");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("9. Search_Nim prefers winning takes");
   ---------------------------------------------------------------------
   declare
      S   : constant Nim_State := (Heap => 5, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 400, Default_C, 42);
   begin
      Check (Res.Best_Nim = 1, "Nim 5: take 1 leaves 4");
      Check (Res.Best_Index >= 1, "Nim Best_Index set");
      Check (Res.Iterations = 400, "Nim iterations");
   end;

   declare
      S   : constant Nim_State := (Heap => 3, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 100, Default_C, 3);
   begin
      Check (Res.Best_Nim = 3, "Nim 3: take all wins");
   end;

   declare
      S   : constant Nim_State := (Heap => 1, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 50, Default_C, 1);
   begin
      Check (Res.Best_Nim = 1, "Nim 1: only take 1");
      Check (Res.N_Children = 1, "Nim 1: one child");
   end;

   declare
      S   : constant Nim_State := (Heap => 6, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 500, Default_C, 11);
   begin
      Check (Res.Best_Nim = 2, "Nim 6: take 2 leaves 4");
   end;

   declare
      S   : constant Nim_State := (Heap => 7, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 500, Default_C, 13);
   begin
      Check (Res.Best_Nim = 3, "Nim 7: take 3 leaves 4");
   end;

   declare
      S   : constant Nim_State := (Heap => 9, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 400, Default_C, 9);
   begin
      Check (Res.Best_Nim = 1, "Nim 9: take 1 leaves 8");
   end;

   for H in 1 .. 5 loop
      declare
         S   : constant Nim_State := (Heap => H, Max_Take => 3);
         Res : constant Search_Result := Search_Nim (S, 60, Default_C, H * 17);
         L   : constant Nim_Move_List := Legal_Moves_Nim (S);
         Ok  : Boolean := False;
      begin
         for I in L'Range loop
            if L (I) = Res.Best_Nim then
               Ok := True;
            end if;
         end loop;
         Check (Ok, "Nim legal take");
      end;
   end loop;

   declare
      S   : constant Nim_State := (Heap => 4, Max_Take => 3);
      Res : constant Search_Result := Search_Nim (S, 200, Default_C, 8);
      L   : constant Nim_Move_List := Legal_Moves_Nim (S);
      Ok  : Boolean := False;
   begin
      Check (Is_Losing_Position (S), "4 is losing");
      for I in L'Range loop
         if L (I) = Res.Best_Nim then
            Ok := True;
         end if;
      end loop;
      Check (Ok, "Losing position still legal");
   end;

   for H in 1 .. 2 loop
      declare
         S   : constant Nim_State := (Heap => H, Max_Take => 1);
         Res : constant Search_Result := Search_Nim (S, 30, Default_C, H);
      begin
         Check (Res.Best_Nim = 1, "Max_Take=1 always take 1");
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("10. Pure Monte Carlo");
   ---------------------------------------------------------------------
   declare
      B   : constant Board := Make_Board
        (X, X, Empty, O, O, Empty, Empty, Empty, Empty);
      Res : constant Search_Result :=
        Pure_Monte_Carlo_TTT (B, X_Mark, 40, 42);
   begin
      Check (Moves_equal (Res.Best_TTT, (1, 3)), "Pure MC finds TTT win");
      Check (Is_Legal_TTT (B, Res.Best_TTT), "Pure MC legal");
   end;

   declare
      S   : constant Nim_State := (Heap => 5, Max_Take => 3);
      Res : constant Search_Result := Pure_Monte_Carlo_Nim (S, 80, 42);
   begin
      Check (Res.Best_Nim = 1, "Pure MC Nim 5 -> take 1");
   end;

   declare
      S   : constant Nim_State := (Heap => 3, Max_Take => 3);
      Res : constant Search_Result := Pure_Monte_Carlo_Nim (S, 20, 1);
   begin
      Check (Res.Best_Nim = 3, "Pure MC Nim 3 -> take 3");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exceptions");
   ---------------------------------------------------------------------
   declare
      procedure Bad is
         B   : constant Board := Make_Board
           (X, X, X, O, O, Empty, Empty, Empty, Empty);
         Res : Search_Result;
      begin
         Res := Search_TTT (B, O_Mark, 10, Default_C, 1);
         raise Program_Error with "expected exception " & Res.Best_Index'Image;
      end Bad;
   begin
      Expect_No_Move ("Search_TTT terminal -> No_Legal_Move", Bad'Access);
   end;

   declare
      procedure Bad is
         S   : constant Nim_State := (Heap => 0, Max_Take => 3);
         Res : Search_Result;
      begin
         Res := Search_Nim (S, 10, Default_C, 1);
         raise Program_Error with "expected exception " & Res.Best_Index'Image;
      end Bad;
   begin
      Expect_No_Move ("Search_Nim terminal -> No_Legal_Move", Bad'Access);
   end;

   declare
      procedure Bad is
         Res : Search_Result;
      begin
         Res := Search_TTT (Empty_Board, X_Mark, 10, -0.5, 1);
         raise Program_Error with "expected exception " & Res.Best_Index'Image;
      end Bad;
   begin
      Expect_Invalid ("Search_TTT C < 0 rejected", Bad'Access);
   end;

   declare
      procedure Bad is
         S   : constant Nim_State := (Heap => 5, Max_Take => 20);
         Res : Search_Result;
      begin
         Res := Search_Nim (S, 10, Default_C, 1);
         raise Program_Error with "expected exception " & Res.Best_Index'Image;
      end Bad;
   begin
      Expect_Invalid ("Search_Nim Max_Take too large", Bad'Access);
   end;

   declare
      procedure Bad is
         Res : Search_Result;
      begin
         Res := Pure_Monte_Carlo_TTT
           (Make_Board (X, X, X, O, O, Empty, Empty, Empty, Empty),
            O_Mark, 5, 1);
         raise Program_Error with "expected exception " & Res.Best_Index'Image;
      end Bad;
   begin
      Expect_No_Move ("Pure MC TTT terminal -> No_Legal_Move", Bad'Access);
   end;

   ---------------------------------------------------------------------
   Section ("12. Determinism and stats");
   ---------------------------------------------------------------------
   declare
      B  : constant Board := Empty_Board;
      R1 : constant Search_Result :=
        Search_TTT (B, X_Mark, 50, Default_C, 12345);
      R2 : constant Search_Result :=
        Search_TTT (B, X_Mark, 50, Default_C, 12345);
   begin
      Check (Moves_Equal (R1.Best_TTT, R2.Best_TTT), "TTT same seed same best");
      Check (R1.Stats (1).Visits = R2.Stats (1).Visits, "TTT same visit[1]");
   end;

   declare
      S  : constant Nim_State := (Heap => 8, Max_Take => 3);
      R1 : constant Search_Result := Search_Nim (S, 80, Default_C, 777);
      R2 : constant Search_Result := Search_Nim (S, 80, Default_C, 777);
   begin
      Check (R1.Best_Nim = R2.Best_Nim, "Nim same seed same best");
      Check (R1.Stats (1).Visits = R2.Stats (1).Visits, "Nim same visit[1]");
   end;

   declare
      B     : constant Board := Empty_Board;
      Res   : constant Search_Result :=
        Search_TTT (B, X_Mark, 90, Default_C, 2);
      Sum_V : Natural := 0;
   begin
      for I in 1 .. Res.N_Children loop
         Sum_V := Sum_V + Res.Stats (I).Visits;
         if Res.Stats (I).Visits > 0 then
            Check
              (Near
                 (Res.Stats (I).Mean_Reward,
                  Res.Stats (I).Total_Reward / Real (Res.Stats (I).Visits)),
               "Mean = Total/Visits");
            Check
              (Res.Stats (I).Mean_Reward >= -1.0 - 1.0E-6
               and then Res.Stats (I).Mean_Reward <= 1.0 + 1.0E-6,
               "TTT mean in [-1,1]");
         end if;
      end loop;
      Check (Sum_V = Res.Root_Visits, "Sum child visits = root visits");
   end;

   declare
      S     : constant Nim_State := (Heap => 5, Max_Take => 3);
      Res   : constant Search_Result := Search_Nim (S, 120, Default_C, 4);
      Sum_V : Natural := 0;
   begin
      for I in 1 .. Res.N_Children loop
         Sum_V := Sum_V + Res.Stats (I).Visits;
         if Res.Stats (I).Visits > 0 then
            Check
              (Res.Stats (I).Mean_Reward >= -1.0 - 1.0E-6
               and then Res.Stats (I).Mean_Reward <= 1.0 + 1.0E-6,
               "Nim mean in [-1,1]");
         end if;
      end loop;
      Check (Sum_V = Res.Root_Visits, "Nim sum visits = root");
      Check (Res.Stats (Res.Best_Index).Visits >= 1, "Best visited");
   end;

   ---------------------------------------------------------------------
   Section ("13. Batch win preference");
   ---------------------------------------------------------------------
   for Seed in 50 .. 52 loop
      declare
         B   : constant Board := Make_Board
           (X, Empty, Empty, X, O, Empty, Empty, O, Empty);
         Res : constant Search_Result :=
           Search_TTT (B, X_Mark, 150, Default_C, Seed);
      begin
         Check (Moves_equal (Res.Best_TTT, (3, 1)), "Batch X wins (3,1)");
      end;
   end loop;

   for Seed in 30 .. 32 loop
      declare
         S   : constant Nim_State := (Heap => 5, Max_Take => 3);
         Res : constant Search_Result := Search_Nim (S, 200, Default_C, Seed);
      begin
         Check (Res.Best_Nim = 1, "Batch Nim 5 take 1");
      end;
   end loop;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("-----------------------------------");
   Ada.Text_IO.Put_Line
     ("PASS:" & Pass_Count'Image & "  FAIL:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("RESULT: FAILED");
      raise Program_Error with "test failures";
   else
      Ada.Text_IO.Put_Line ("RESULT: ALL PASS");
   end if;
end Tests;
