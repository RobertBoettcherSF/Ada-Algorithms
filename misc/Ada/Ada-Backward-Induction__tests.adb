--  Standalone test suite for Backward_Induction.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Backward_Induction; use Backward_Induction;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Pos (X : Positive) return Positive is (X);
   function Pf (X : Payoff) return Payoff is (X);
   function Pl (X : Player_Id) return Player_Id is (X);
   function Ci (X : Child_Index) return Child_Index is (X);

   ---------------------------------------------------------------------------
   -- Exception helpers
   ---------------------------------------------------------------------------

   function Near_Raises (Tol : Payoff) return Boolean is
      Unused : Boolean;
   begin
      Unused := Near (0.0, 0.0, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Near_Raises;

   function Value_Raises_Null return Boolean is
      Unused : Payoff_Vector;
      pragma Unreferenced (Unused);
   begin
      declare
         V : constant Payoff_Vector := Value (null);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Value_Raises_Null;

   function Decision_Raises_Empty return Boolean is
      Unused : Node_Access;
      pragma Unreferenced (Unused);
      Empty : Node_List (1 .. 0);
   begin
      declare
         N : constant Node_Access := Make_Decision (1, Empty);
         pragma Unreferenced (N);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Decision_Raises_Empty;

   function Decision_Raises_Null_Child return Boolean is
      Unused : Node_Access;
      pragma Unreferenced (Unused);
   begin
      declare
         N : constant Node_Access :=
           Make_Decision (1, [Node_Access'(null)]);
         pragma Unreferenced (N);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Decision_Raises_Null_Child;

   function Optimal_On_Terminal_Raises return Boolean is
      T : constant Node_Access := Make_Terminal (1.0, 2.0);
      Unused : Child_Index;
      pragma Unreferenced (Unused);
   begin
      declare
         A : constant Child_Index := Optimal_Action (T);
         pragma Unreferenced (A);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Optimal_On_Terminal_Raises;

   function Action_Path_Raises (Root : Node_Access; Step : Positive)
     return Boolean
   is
      Unused : Child_Index;
      pragma Unreferenced (Unused);
   begin
      declare
         A : constant Child_Index := Action_On_Path (Root, Step);
         pragma Unreferenced (A);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Action_Path_Raises;

   function Ultimatum_Raises (Pot, Offer : Payoff) return Boolean is
      Unused : Node_Access;
      pragma Unreferenced (Unused);
   begin
      declare
         N : constant Node_Access := Ultimatum (Pot, Offer);
         pragma Unreferenced (N);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Ultimatum_Raises;

   function Ult_Disc_Raises (U : Natural) return Boolean is
      Unused : Node_Access;
      pragma Unreferenced (Unused);
   begin
      declare
         N : constant Node_Access := Ultimatum_Discrete (U);
         pragma Unreferenced (N);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Ult_Disc_Raises;

   function Sub_Raises (H : Natural; M : Positive) return Boolean is
      Unused : Node_Access;
      pragma Unreferenced (Unused);
   begin
      declare
         N : constant Node_Access := Subtraction_Game (H, M);
         pragma Unreferenced (N);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Sub_Raises;

   function ZS_Raises_Empty return Boolean is
      Unused : Node_Access;
      pragma Unreferenced (Unused);
      Empty : Score_List (1 .. 0);
   begin
      declare
         N : constant Node_Access := Zero_Sum_Choice (Empty);
         pragma Unreferenced (N);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end ZS_Raises_Empty;

   function Node_Count_Raises_Null return Boolean is
      Unused : Natural;
      pragma Unreferenced (Unused);
   begin
      declare
         C : constant Natural := Node_Count (null);
         pragma Unreferenced (C);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Node_Count_Raises_Null;

   ---------------------------------------------------------------------------
   -- Tests
   ---------------------------------------------------------------------------

   procedure Test_Near is
   begin
      Section ("Near / Near_Vector");
      Check (Near (Pf (1.0), Pf (1.0)), "Near equal");
      Check (Near (Pf (1.0), Pf (1.0 + 1.0E-12)), "Near within default tol");
      Check (not Near (Pf (1.0), Pf (2.0)), "Near far");
      Check (Near_Raises (Pf (-1.0)), "Near negative tol raises");
      Check (Near (Pf (0.0), Pf (0.5), Pf (0.5)), "Near custom tol");
      Check (Near_Vector ([1 => Pf (1.0), 2 => Pf (2.0)],
                          [1 => Pf (1.0), 2 => Pf (2.0)]),
             "Near_Vector equal");
      Check (not Near_Vector ([1 => Pf (1.0), 2 => Pf (2.0)],
                              [1 => Pf (1.0), 2 => Pf (3.0)]),
             "Near_Vector differs");
   end Test_Near;

   procedure Test_Terminals_And_Form is
      T : constant Node_Access := Make_Terminal (Pf (3.0), Pf (-1.0));
      V : Payoff_Vector;
   begin
      Section ("Terminals and well-formedness");
      Check (T /= null, "Make_Terminal non-null");
      Check (T.Kind = Terminal, "terminal kind");
      Check (T.N_Children = Nat (0), "terminal no children");
      Check (Is_Well_Formed (T), "terminal well-formed");
      Check (not Is_Well_Formed (null), "null not well-formed");
      V := Value (T);
      Check (Near (V (1), Pf (3.0)) and Near (V (2), Pf (-1.0)),
             "Value of terminal");
      Check (Node_Count (T) = Nat (1), "Node_Count terminal = 1");
      Check (Depth (T) = Nat (0), "Depth terminal = 0");
      Check (Value_Raises_Null, "Value null raises");
      Check (Node_Count_Raises_Null, "Node_Count null raises");
      Check (Optimal_On_Terminal_Raises, "Optimal_Action on terminal raises");
   end Test_Terminals_And_Form;

   procedure Test_Make_Decision_Errors is
   begin
      Section ("Make_Decision errors");
      Check (Decision_Raises_Empty, "empty kids raise");
      Check (Decision_Raises_Null_Child, "null child raises");
   end Test_Make_Decision_Errors;

   procedure Test_Simple_Binary is
      G : constant Node_Access := Simple_Binary_Tree;
      V : Payoff_Vector;
      P : Equilibrium_Profile;
   begin
      Section ("Simple_Binary_Tree");
      Check (Is_Well_Formed (G), "binary well-formed");
      Check (Depth (G) = Nat (2), "binary depth 2");
      Check (Node_Count (G) = Nat (7), "binary 7 nodes");
      --  P2 under L: max own → (0,2) index 2; under R: max → (1,3) index 1.
      --  P1 compares L→(0,2) vs R→(1,3) → chooses R (1 > 0).
      --  Wait: under L P2 gets 1 vs 2 → chooses (0,2). Under R P2 gets 3 vs 0
      --  → chooses (1,3). P1 gets 0 vs 1 → chooses R → (1,3).
      --  Re-read Simple_Binary_Tree comment in ads: "SPNE: L then (3,1)".
      --  That assumed P2 under L picks (3,1) — but P2 maximises OWN payoff,
      --  so under L picks (0,2) with P2=2 > 1. Fix expectation to actual BI.
      V := Value (G);
      Check (Near (V (1), Pf (1.0)) and Near (V (2), Pf (3.0)),
             "binary SPNE payoffs (1,3)");
      Check (Optimal_Action (G) = Ci (2), "binary root action R");
      P := Solve (G);
      Check (P.Length = Nat (2), "binary path length 2");
      Check (P.Actions (1) = Ci (2), "binary step1 = R");
      Check (P.Actions (2) = Ci (1), "binary step2 = High for P2");
      Check (Near_Vector (P.Payoffs, V), "Solve payoffs match Value");
      Check (Equilibrium_Path_Length (G) = Nat (2), "path length helper");
      Check (Action_On_Path (G, Pos (1)) = Ci (2), "Action_On_Path 1");
      Check (Action_On_Path (G, Pos (2)) = Ci (1), "Action_On_Path 2");
      Check (Action_Path_Raises (G, Pos (3)), "Action_On_Path OOR raises");
   end Test_Simple_Binary;

   procedure Test_P1_Max_Under_L is
      --  Rebuild so P2 prefers (3,1) under L: give P2 more there.
      Left : constant Node_Access :=
        Make_Decision
          (Pl (2),
           [Make_Terminal (Pf (3.0), Pf (4.0)),
            Make_Terminal (Pf (0.0), Pf (2.0))]);
      Right : constant Node_Access :=
        Make_Decision
          (Pl (2),
           [Make_Terminal (Pf (1.0), Pf (3.0)),
            Make_Terminal (Pf (2.0), Pf (0.0))]);
      G : constant Node_Access := Make_Decision (Pl (1), [Left, Right]);
      V : Payoff_Vector;
   begin
      Section ("Binary where L is SPNE");
      V := Value (G);
      Check (Near (V (1), Pf (3.0)) and Near (V (2), Pf (4.0)),
             "L-SPNE payoffs (3,4)");
      Check (Optimal_Action (G) = Ci (1), "root chooses L");
   end Test_P1_Max_Under_L;

   procedure Test_Ultimatum is
      U : Node_Access;
      V : Payoff_Vector;
   begin
      Section ("Ultimatum");
      U := Ultimatum (Pf (10.0), Pf (3.0));
      Check (Is_Well_Formed (U), "ultimatum well-formed");
      V := Value (U);
      Check (Near (V (1), Pf (7.0)) and Near (V (2), Pf (3.0)),
             "accept offer 3 from 10");
      Check (Optimal_Action (U) = Ci (1), "responder accepts");
      U := Ultimatum (Pf (10.0), Pf (0.0));
      V := Value (U);
      Check (Near (V (1), Pf (10.0)) and Near (V (2), Pf (0.0)),
             "accept zero offer (money-max)");
      Check (Ultimatum_Raises (Pf (-1.0), Pf (0.0)), "neg pot raises");
      Check (Ultimatum_Raises (Pf (5.0), Pf (6.0)), "offer > pot raises");
      Check (Ultimatum_Raises (Pf (5.0), Pf (-0.1)), "neg offer raises");
   end Test_Ultimatum;

   procedure Test_Ultimatum_Discrete is
      U : Node_Access;
      P : Equilibrium_Profile;
   begin
      Section ("Ultimatum_Discrete");
      U := Ultimatum_Discrete (Nat (5));
      Check (Is_Well_Formed (U), "discrete well-formed");
      P := Solve (U);
      Check (Near (P.Payoffs (1), Pf (5.0))
               and Near (P.Payoffs (2), Pf (0.0)),
             "discrete SPNE offer 0 accept");
      Check (P.Actions (1) = Ci (1), "propose k=0 (first child)");
      Check (P.Actions (2) = Ci (1), "accept");
      Check (Ult_Disc_Raises (Nat (0)), "Pot_Units 0 raises");
      Check (Ult_Disc_Raises (Nat (16)), "Pot_Units 16 raises");
      for K in 1 .. 10 loop
         U := Ultimatum_Discrete (K);
         P := Solve (U);
         Check (Near (P.Payoffs (1), Pf (Payoff (K)))
                  and Near (P.Payoffs (2), Pf (0.0)),
                "discrete pot" & Integer'Image (K) & " SPNE");
      end loop;
   end Test_Ultimatum_Discrete;

   procedure Test_Entry is
      G : constant Node_Access := Entry_Deterrence;
      P : Equilibrium_Profile;
   begin
      Section ("Entry_Deterrence");
      Check (Is_Well_Formed (G), "entry well-formed");
      P := Solve (G);
      Check (Near (P.Payoffs (1), Pf (1.0))
               and Near (P.Payoffs (2), Pf (1.0)),
             "entry SPNE (1,1)");
      Check (P.Length = Nat (2), "entry path length 2");
      Check (P.Actions (1) = Ci (2), "entrant In");
      Check (P.Actions (2) = Ci (2), "incumbent Accommodate");
      --  Subgame after In: incumbent prefers Accommodate.
      Check (Optimal_Action (G.Children (2)) = Ci (2),
             "incumbent subgame Accommodate");
   end Test_Entry;

   procedure Test_Stackelberg is
      G : constant Node_Access := Stackelberg_Toy;
      P : Equilibrium_Profile;
   begin
      Section ("Stackelberg_Toy");
      Check (Is_Well_Formed (G), "stackelberg well-formed");
      P := Solve (G);
      --  After High: P2 picks Low → (5,2); after Low: P2 picks High → (3,4).
      --  P1 picks High → (5,2).
      Check (Near (P.Payoffs (1), Pf (5.0))
               and Near (P.Payoffs (2), Pf (2.0)),
             "stackelberg SPNE (5,2)");
      Check (P.Actions (1) = Ci (1), "leader High");
      Check (P.Actions (2) = Ci (2), "follower Low");
   end Test_Stackelberg;

   procedure Test_Centipede is
      G : Node_Access;
      P : Equilibrium_Profile;
   begin
      Section ("Centipede");
      for S in 1 .. 8 loop
         G := Centipede (S);
         Check (Is_Well_Formed (G),
                "centipede" & Integer'Image (S) & " well-formed");
         P := Solve (G);
         Check (P.Actions (1) = Ci (1),
                "centipede" & Integer'Image (S) & " Take immediately");
         Check (Near (P.Payoffs (1), Pf (1.0))
                  and Near (P.Payoffs (2), Pf (0.0)),
                "centipede" & Integer'Image (S) & " first-take payoffs");
      end loop;
   end Test_Centipede;

   procedure Test_Subtraction is
      G : Node_Access;
      P : Equilibrium_Profile;
      Win : Boolean;
   begin
      Section ("Subtraction_Game");
      --  Max_Take=3: positions with Rem mod 4 = 0 are losing if both optimal.
      for H in 0 .. 12 loop
         G := Subtraction_Game (H, Pos (3));
         Check (Is_Well_Formed (G),
                "sub H=" & Integer'Image (H) & " well-formed");
         P := Solve (G);
         Win := (H mod 4) /= 0;
         if Win then
            Check (Near (P.Payoffs (1), Pf (1.0)),
                   "sub H=" & Integer'Image (H) & " P1 wins");
         else
            Check (Near (P.Payoffs (1), Pf (0.0)),
                   "sub H=" & Integer'Image (H) & " P1 loses");
         end if;
      end loop;
      Check (Sub_Raises (Nat (41), Pos (3)), "heap 41 raises");
      Check (Sub_Raises (Nat (5), Pos (17)), "Max_Take 17 raises");
      --  Max_Take=1: alternate; P1 wins iff Heap odd.
      for H in 0 .. 7 loop
         G := Subtraction_Game (H, Pos (1));
         P := Solve (G);
         if H mod 2 = 1 then
            Check (Near (P.Payoffs (1), Pf (1.0)),
                   "take1 H=" & Integer'Image (H) & " P1 win");
         else
            Check (Near (P.Payoffs (1), Pf (0.0)),
                   "take1 H=" & Integer'Image (H) & " P1 lose");
         end if;
      end loop;
   end Test_Subtraction;

   procedure Test_Zero_Sum is
      G : constant Node_Access :=
        Zero_Sum_Choice ([Pf (-2.0), Pf (5.0), Pf (1.0), Pf (4.0)]);
      P : Equilibrium_Profile;
   begin
      Section ("Zero_Sum_Choice");
      Check (Is_Well_Formed (G), "zs well-formed");
      P := Solve (G);
      Check (Near (P.Payoffs (1), Pf (5.0))
               and Near (P.Payoffs (2), Pf (-5.0)),
             "zs picks max score 5");
      Check (P.Actions (1) = Ci (2), "zs action index 2");
      Check (ZS_Raises_Empty, "zs empty raises");
   end Test_Zero_Sum;

   procedure Test_Take_Or_Leave is
      G : Node_Access;
      P : Equilibrium_Profile;
   begin
      Section ("Take_Or_Leave_Chain");
      for R in 1 .. 6 loop
         G := Take_Or_Leave_Chain (R);
         Check (Is_Well_Formed (G),
                "tol" & Integer'Image (R) & " well-formed");
         P := Solve (G);
         --  Last mover must Take; working back, first mover Takes if High
         --  beats continuation. With High=2, Low=1: at last node Take is
         --  only move. Previous mover compares Take (High,Low) vs leaving
         --  the last mover Take — leaving gives Low for self, so Take.
         Check (P.Actions (1) = Ci (1),
                "tol" & Integer'Image (R) & " Take at root");
         Check (Near (P.Payoffs (1), Pf (2.0))
                  and Near (P.Payoffs (2), Pf (1.0)),
                "tol" & Integer'Image (R) & " (2,1) when P1 starts");
      end loop;
   end Test_Take_Or_Leave;

   procedure Test_Tie_Break is
      --  Equal own payoffs → lowest index wins.
      G : constant Node_Access :=
        Make_Decision
          (Pl (1),
           [Make_Terminal (Pf (1.0), Pf (0.0)),
            Make_Terminal (Pf (1.0), Pf (9.0)),
            Make_Terminal (Pf (1.0), Pf (-1.0))]);
   begin
      Section ("Tie-break lowest index");
      Check (Optimal_Action (G) = Ci (1), "tie → index 1");
      Check (Near (Value (G) (2), Pf (0.0)), "tie keeps first child's P2");
   end Test_Tie_Break;

   procedure Test_Equilibrium_Helpers is
      G : constant Node_Access := Entry_Deterrence;
      V : constant Payoff_Vector := Equilibrium_Payoffs (G);
   begin
      Section ("Equilibrium helpers");
      Check (Near_Vector (V, [1 => Pf (1.0), 2 => Pf (1.0)]),
             "Equilibrium_Payoffs entry");
      Check (Equilibrium_Path_Length (Make_Terminal (Pf (0.0), Pf (0.0)))
               = Nat (0),
             "terminal path length 0");
   end Test_Equilibrium_Helpers;

   procedure Test_Deeper_Manual is
      --  Three-ply: P1 → P2 → P1.
      Leaf_A : constant Node_Access := Make_Terminal (Pf (4.0), Pf (1.0));
      Leaf_B : constant Node_Access := Make_Terminal (Pf (0.0), Pf (5.0));
      Leaf_C : constant Node_Access := Make_Terminal (Pf (3.0), Pf (2.0));
      Leaf_D : constant Node_Access := Make_Terminal (Pf (6.0), Pf (0.0));
      N_P1_L : constant Node_Access :=
        Make_Decision (Pl (1), [Leaf_A, Leaf_B]);
      N_P1_R : constant Node_Access :=
        Make_Decision (Pl (1), [Leaf_C, Leaf_D]);
      N_P2   : constant Node_Access :=
        Make_Decision (Pl (2), [N_P1_L, N_P1_R]);
      Root   : constant Node_Access :=
        Make_Decision (Pl (1), [N_P2, Make_Terminal (Pf (2.0), Pf (2.0))]);
      P : Equilibrium_Profile;
   begin
      Section ("Deeper manual tree");
      --  Under N_P1_L: P1 picks A (4>0). Under N_P1_R: P1 picks D (6>3).
      --  P2 compares L→(4,1) vs R→(6,0) → picks L (1>0).
      --  Root P1 compares N_P2→(4,1) vs terminal (2,2) → picks N_P2 (4>2).
      P := Solve (Root);
      Check (Near (P.Payoffs (1), Pf (4.0))
               and Near (P.Payoffs (2), Pf (1.0)),
             "deep SPNE (4,1)");
      Check (P.Length = Nat (3), "deep path length 3");
      Check (P.Actions (1) = Ci (1), "deep step1");
      Check (P.Actions (2) = Ci (1), "deep step2");
      Check (P.Actions (3) = Ci (1), "deep step3");
      Check (Depth (Root) = Nat (3), "deep depth 3");
   end Test_Deeper_Manual;

   procedure Test_Many_Subtraction_Max_Take is
      G : Node_Access;
      P : Equilibrium_Profile;
   begin
      Section ("Subtraction Max_Take=2");
      --  Losing positions: Rem mod 3 = 0.
      for H in 0 .. 15 loop
         G := Subtraction_Game (H, Pos (2));
         P := Solve (G);
         if (H mod 3) = 0 then
            Check (Near (P.Payoffs (1), Pf (0.0)),
                   "mt2 H=" & Integer'Image (H) & " lose");
         else
            Check (Near (P.Payoffs (1), Pf (1.0)),
                   "mt2 H=" & Integer'Image (H) & " win");
         end if;
      end loop;
   end Test_Many_Subtraction_Max_Take;

   procedure Test_Ultimatum_Grid is
      U : Node_Access;
      V : Payoff_Vector;
   begin
      Section ("Ultimatum offer grid");
      for K in 0 .. 10 loop
         U := Ultimatum (Pf (10.0), Pf (Payoff (K)));
         V := Value (U);
         Check (Near (V (1), Pf (10.0 - Payoff (K)))
                  and Near (V (2), Pf (Payoff (K))),
                "ult offer" & Integer'Image (K));
      end loop;
   end Test_Ultimatum_Grid;

   procedure Test_Centipede_Custom is
      G : constant Node_Access :=
        Centipede (Pos (4), Pf (2.0), Pf (1.0), Pf (0.5));
      P : Equilibrium_Profile;
   begin
      Section ("Centipede custom pots");
      Check (Is_Well_Formed (G), "custom centipede well-formed");
      P := Solve (G);
      Check (P.Actions (1) = Ci (1), "custom Take first");
      Check (Near (P.Payoffs (1), Pf (2.0))
               and Near (P.Payoffs (2), Pf (1.0)),
             "custom first-take pots");
   end Test_Centipede_Custom;

   procedure Test_Stackelberg_Subgames is
      G : constant Node_Access := Stackelberg_Toy;
   begin
      Section ("Stackelberg subgames");
      Check (Optimal_Action (G.Children (1)) = Ci (2),
             "after High follower Low");
      Check (Optimal_Action (G.Children (2)) = Ci (1),
             "after Low follower High");
      Check (Near_Vector (Value (G.Children (1)),
                         [1 => Pf (5.0), 2 => Pf (2.0)]),
             "after High value");
      Check (Near_Vector (Value (G.Children (2)),
                         [1 => Pf (3.0), 2 => Pf (4.0)]),
             "after Low value");
   end Test_Stackelberg_Subgames;

   procedure Test_Single_Child is
      G : constant Node_Access :=
        Make_Decision (Pl (2), [Make_Terminal (Pf (7.0), Pf (8.0))]);
      P : Equilibrium_Profile;
   begin
      Section ("Single-child decision");
      P := Solve (G);
      Check (P.Length = Nat (1), "single path len");
      Check (Near (P.Payoffs (1), Pf (7.0)), "single P1");
      Check (Near (P.Payoffs (2), Pf (8.0)), "single P2");
   end Test_Single_Child;

   procedure Test_Malformed_Detection is
      Bad : constant Node_Access := new Game_Node;
   begin
      Section ("Malformed detection");
      Bad.Kind       := Decision;
      Bad.N_Children := 0;
      Check (not Is_Well_Formed (Bad), "decision zero kids malformed");
      Bad.N_Children := 1;
      Bad.Children (1) := null;
      Check (not Is_Well_Formed (Bad), "null child malformed");
      Bad.Kind       := Terminal;
      Bad.N_Children := 1;
      Bad.Children (1) := Make_Terminal (0.0, 0.0);
      Check (not Is_Well_Formed (Bad), "terminal with child malformed");
   end Test_Malformed_Detection;

   procedure Test_Large_Zero_Sum is
      Scores : Score_List (1 .. 8);
      G : Node_Access;
      P : Equilibrium_Profile;
      Best : Payoff := -1.0E10;
      Best_I : Child_Index := 1;
   begin
      Section ("Larger zero-sum choice");
      for I in Scores'Range loop
         Scores (I) := Payoff (I * I - 10);
         if Scores (I) > Best then
            Best   := Scores (I);
            Best_I := Ci (I);
         end if;
      end loop;
      G := Zero_Sum_Choice (Scores);
      P := Solve (G);
      Check (Near (P.Payoffs (1), Best), "large zs best score");
      Check (P.Actions (1) = Best_I, "large zs best index");
   end Test_Large_Zero_Sum;

   procedure Test_Entry_Out_Payoff is
      G : constant Node_Access := Entry_Deterrence;
   begin
      Section ("Entry Out leaf");
      Check (G.Children (1).Kind = Terminal, "Out is terminal");
      Check (Near (G.Children (1).Payoffs (1), Pf (0.0)), "Out P1=0");
      Check (Near (G.Children (1).Payoffs (2), Pf (2.0)), "Out P2=2");
   end Test_Entry_Out_Payoff;

   procedure Test_Depth_Node_Counts is
      G : Node_Access;
   begin
      Section ("Depth / Node_Count classics");
      G := Entry_Deterrence;
      Check (Depth (G) = Nat (2), "entry depth");
      Check (Node_Count (G) = Nat (5), "entry nodes");
      G := Stackelberg_Toy;
      Check (Depth (G) = Nat (2), "stack depth");
      Check (Node_Count (G) = Nat (7), "stack nodes");
      G := Ultimatum (Pf (1.0), Pf (0.5));
      Check (Depth (G) = Nat (1), "ult depth");
      Check (Node_Count (G) = Nat (3), "ult nodes");
   end Test_Depth_Node_Counts;

   procedure Test_Subtraction_Optimal_Take is
      G : constant Node_Access := Subtraction_Game (Nat (5), Pos (3));
      P : Equilibrium_Profile;
   begin
      Section ("Subtraction optimal first take");
      --  H=5, m=3: winning; optimal leave multiple of 4 → take 1 → leave 4.
      P := Solve (G);
      Check (Near (P.Payoffs (1), Pf (1.0)), "H5 P1 wins");
      Check (P.Actions (1) = Ci (1), "H5 take 1 first");
   end Test_Subtraction_Optimal_Take;

   procedure Test_More_Near is
   begin
      Section ("More Near cases");
      Check (Near (Pf (-3.5), Pf (-3.5)), "Near negatives equal");
      Check (not Near (Pf (-3.5), Pf (-3.4), Pf (0.05)), "Near neg far");
      Check (Near (Pf (-3.5), Pf (-3.45), Pf (0.1)), "Near neg close");
      Check (Near_Vector ([1 => Pf (0.0), 2 => Pf (0.0)],
                          [1 => Pf (0.0), 2 => Pf (0.0)]),
             "Near_Vector zeros");
   end Test_More_Near;

   procedure Test_Take_Or_Leave_Last_Only is
      G : constant Node_Access := Take_Or_Leave_Chain (Pos (1), Pf (9.0), Pf (1.0));
      P : Equilibrium_Profile;
   begin
      Section ("Take_Or_Leave single round");
      P := Solve (G);
      Check (P.Length = Nat (1), "single round path");
      Check (Near (P.Payoffs (1), Pf (9.0))
               and Near (P.Payoffs (2), Pf (1.0)),
             "single round payoffs");
   end Test_Take_Or_Leave_Last_Only;

begin
   Put_Line ("Backward_Induction test suite");
   Put_Line ("==============================");

   Test_Near;
   Test_Terminals_And_Form;
   Test_Make_Decision_Errors;
   Test_Simple_Binary;
   Test_P1_Max_Under_L;
   Test_Ultimatum;
   Test_Ultimatum_Discrete;
   Test_Entry;
   Test_Stackelberg;
   Test_Centipede;
   Test_Subtraction;
   Test_Zero_Sum;
   Test_Take_Or_Leave;
   Test_Tie_Break;
   Test_Equilibrium_Helpers;
   Test_Deeper_Manual;
   Test_Many_Subtraction_Max_Take;
   Test_Ultimatum_Grid;
   Test_Centipede_Custom;
   Test_Stackelberg_Subgames;
   Test_Single_Child;
   Test_Malformed_Detection;
   Test_Large_Zero_Sum;
   Test_Entry_Out_Payoff;
   Test_Depth_Node_Counts;
   Test_Subtraction_Optimal_Take;
   Test_More_Near;
   Test_Take_Or_Leave_Last_Only;

   New_Line;
   Put_Line ("==============================");
   Put_Line ("PASS:" & Natural'Image (Pass_Count));
   Put_Line ("FAIL:" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
