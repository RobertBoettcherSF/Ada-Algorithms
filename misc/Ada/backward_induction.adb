--  Backward_Induction body — finite perfect-information SPNE via BI.

pragma Ada_2022;

package body Backward_Induction is

   -------------------------------------------------------------------------
   -- Near
   -------------------------------------------------------------------------

   function Near
     (X, Y : Payoff; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument with "Near: Tol must be >= 0";
      end if;
      return abs (X - Y) <= Tol;
   end Near;

   function Near_Vector
     (A, B : Payoff_Vector; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      return Near (A (1), B (1), Tol) and then Near (A (2), B (2), Tol);
   end Near_Vector;

   -------------------------------------------------------------------------
   -- Constructors
   -------------------------------------------------------------------------

   function Make_Terminal (P1, P2 : Payoff) return Node_Access is
      N : constant Node_Access := new Game_Node;
   begin
      N.Kind       := Terminal;
      N.Payoffs    := [1 => P1, 2 => P2];
      N.N_Children := 0;
      N.Children   := [others => null];
      return N;
   end Make_Terminal;

   function Make_Decision
     (Who  : Player_Id;
      Kids : Node_List) return Node_Access
   is
      N : Node_Access;
      K : Child_Count;
   begin
      if Kids'Length = 0 or else Kids'Length > Max_Children then
         raise Invalid_Argument with "Make_Decision: bad child count";
      end if;
      for C of Kids loop
         if C = null then
            raise Invalid_Argument with "Make_Decision: null child";
         end if;
      end loop;

      N            := new Game_Node;
      N.Kind       := Decision;
      N.Player     := Who;
      N.Payoffs    := [1 => 0.0, 2 => 0.0];
      K            := Child_Count (Kids'Length);
      N.N_Children := K;
      N.Children   := [others => null];
      for I in 1 .. K loop
         N.Children (I) := Kids (Kids'First + Integer (I) - 1);
      end loop;
      return N;
   end Make_Decision;

   -------------------------------------------------------------------------
   -- Well-formed / size helpers
   -------------------------------------------------------------------------

   function Well_Formed_Rec (Node : Node_Access) return Boolean is
   begin
      if Node = null then
         return False;
      end if;
      case Node.Kind is
         when Terminal =>
            return Node.N_Children = 0;
         when Decision =>
            if Node.N_Children = 0 then
               return False;
            end if;
            for I in 1 .. Node.N_Children loop
               if Node.Children (I) = null
                 or else not Well_Formed_Rec (Node.Children (I))
               then
                  return False;
               end if;
            end loop;
            return True;
      end case;
   end Well_Formed_Rec;

   function Is_Well_Formed (Root : Node_Access) return Boolean is
   begin
      return Well_Formed_Rec (Root);
   end Is_Well_Formed;

   function Node_Count_Rec (Node : Node_Access) return Natural is
      Total : Natural := 1;
   begin
      if Node.Kind = Decision then
         for I in 1 .. Node.N_Children loop
            Total := Total + Node_Count_Rec (Node.Children (I));
         end loop;
      end if;
      return Total;
   end Node_Count_Rec;

   function Node_Count (Root : Node_Access) return Natural is
   begin
      if Root = null then
         raise Invalid_Argument with "Node_Count: null root";
      end if;
      return Node_Count_Rec (Root);
   end Node_Count;

   function Depth_Rec (Node : Node_Access) return Natural is
      Best : Natural := 0;
      D    : Natural;
   begin
      if Node.Kind = Terminal then
         return 0;
      end if;
      for I in 1 .. Node.N_Children loop
         D := Depth_Rec (Node.Children (I));
         if D + 1 > Best then
            Best := D + 1;
         end if;
      end loop;
      return Best;
   end Depth_Rec;

   function Depth (Root : Node_Access) return Natural is
   begin
      if Root = null then
         raise Invalid_Argument with "Depth: null root";
      end if;
      return Depth_Rec (Root);
   end Depth;

   procedure Require_Well_Formed (Node : Node_Access) is
   begin
      if not Is_Well_Formed (Node) then
         raise Invalid_Argument with "malformed or null game tree";
      end if;
   end Require_Well_Formed;

   -------------------------------------------------------------------------
   -- Core BI
   -------------------------------------------------------------------------

   function Value_Rec (Node : Node_Access) return Payoff_Vector is
      Best      : Payoff_Vector;
      Candidate : Payoff_Vector;
      First     : Boolean := True;
      Own       : Payoff;
   begin
      case Node.Kind is
         when Terminal =>
            return Node.Payoffs;
         when Decision =>
            for I in 1 .. Node.N_Children loop
               Candidate := Value_Rec (Node.Children (I));
               if First then
                  Best  := Candidate;
                  First := False;
               else
                  Own := Candidate (Node.Player);
                  if Own > Best (Node.Player) then
                     Best := Candidate;
                  end if;
               end if;
            end loop;
            return Best;
      end case;
   end Value_Rec;

   function Value (Node : Node_Access) return Payoff_Vector is
   begin
      Require_Well_Formed (Node);
      return Value_Rec (Node);
   end Value;

   function Optimal_Action_Rec (Node : Node_Access) return Child_Index is
      Best_Idx  : Child_Index := 1;
      Best_Pay  : Payoff;
      Candidate : Payoff_Vector;
      First     : Boolean := True;
   begin
      for I in 1 .. Node.N_Children loop
         Candidate := Value_Rec (Node.Children (I));
         if First then
            Best_Idx := I;
            Best_Pay := Candidate (Node.Player);
            First    := False;
         elsif Candidate (Node.Player) > Best_Pay then
            Best_Idx := I;
            Best_Pay := Candidate (Node.Player);
         end if;
      end loop;
      return Best_Idx;
   end Optimal_Action_Rec;

   function Optimal_Action (Node : Node_Access) return Child_Index is
   begin
      Require_Well_Formed (Node);
      if Node.Kind /= Decision then
         raise Invalid_Argument with "Optimal_Action: not a decision node";
      end if;
      return Optimal_Action_Rec (Node);
   end Optimal_Action;

   function Solve (Root : Node_Access) return Equilibrium_Profile is
      Result : Equilibrium_Profile;
      Cur    : Node_Access;
      A      : Child_Index;
   begin
      Require_Well_Formed (Root);
      Result.Payoffs := Value_Rec (Root);
      Cur            := Root;
      Result.Length  := 0;
      while Cur.Kind = Decision loop
         if Result.Length >= Max_Path then
            raise Invalid_Argument with "Solve: path exceeds Max_Path";
         end if;
         A := Optimal_Action_Rec (Cur);
         Result.Length := Result.Length + 1;
         Result.Actions (Result.Length) := A;
         Cur := Cur.Children (A);
      end loop;
      return Result;
   end Solve;

   function Equilibrium_Payoffs (Root : Node_Access) return Payoff_Vector is
   begin
      return Solve (Root).Payoffs;
   end Equilibrium_Payoffs;

   function Equilibrium_Path_Length (Root : Node_Access) return Natural is
   begin
      return Solve (Root).Length;
   end Equilibrium_Path_Length;

   function Action_On_Path
     (Root : Node_Access; Step : Positive) return Child_Index
   is
      P : constant Equilibrium_Profile := Solve (Root);
   begin
      if Step > P.Length then
         raise Invalid_Argument with "Action_On_Path: step out of range";
      end if;
      return P.Actions (Step);
   end Action_On_Path;

   -------------------------------------------------------------------------
   -- Classic games
   -------------------------------------------------------------------------

   function Ultimatum
     (Pot   : Payoff;
      Offer : Payoff) return Node_Access
   is
   begin
      if Pot < 0.0 or else Offer < 0.0 or else Offer > Pot then
         raise Invalid_Argument with "Ultimatum: bad Pot/Offer";
      end if;
      --  Action 1 = Accept, 2 = Reject. Root is Player 2's response.
      return Make_Decision
        (2,
         [Make_Terminal (Pot - Offer, Offer),
          Make_Terminal (0.0, 0.0)]);
   end Ultimatum;

   function Ultimatum_Discrete
     (Pot_Units : Natural) return Node_Access
   is
      Kids : Node_List (1 .. Pot_Units + 1);
      Offer : Payoff;
   begin
      if Pot_Units = 0 or else Pot_Units + 1 > Max_Children then
         raise Invalid_Argument with "Ultimatum_Discrete: bad Pot_Units";
      end if;
      for K in 0 .. Pot_Units loop
         Offer := Payoff (K);
         --  Child K+1: propose offer K; responder Accept / Reject.
         Kids (K + 1) := Make_Decision
           (2,
            [Make_Terminal (Payoff (Pot_Units) - Offer, Offer),
             Make_Terminal (0.0, 0.0)]);
      end loop;
      return Make_Decision (1, Kids);
   end Ultimatum_Discrete;

   function Entry_Deterrence return Node_Access is
      Incumbent : constant Node_Access :=
        Make_Decision
          (2,
           [Make_Terminal (-1.0, -1.0),   -- Fight
            Make_Terminal (1.0, 1.0)]);    -- Accommodate
   begin
      --  Action 1 = Out, 2 = In.
      return Make_Decision
        (1,
         [Make_Terminal (0.0, 2.0),
          Incumbent]);
   end Entry_Deterrence;

   function Stackelberg_Toy return Node_Access is
      --  Leader High → Follower High (2,1) / Low (5,2)
      --  Leader Low  → Follower High (3,4) / Low (1,0)
      --  Follower max: after High chooses Low (2 > 1 for P2? wait P2 gets
      --  1 vs 2 → Low); after Low chooses High (4 > 0).
      --  Leader then compares High→(5,2) vs Low→(3,4) → High.
      After_High : constant Node_Access :=
        Make_Decision
          (2,
           [Make_Terminal (2.0, 1.0),    -- Follower High
            Make_Terminal (5.0, 2.0)]);  -- Follower Low
      After_Low : constant Node_Access :=
        Make_Decision
          (2,
           [Make_Terminal (3.0, 4.0),    -- Follower High
            Make_Terminal (1.0, 0.0)]);  -- Follower Low
   begin
      return Make_Decision (1, [After_High, After_Low]);
   end Stackelberg_Toy;

   function Centipede
     (Stages          : Positive;
      Start_Take_P1   : Payoff := 1.0;
      Start_Take_P2   : Payoff := 0.0;
      Growth          : Payoff := 1.0) return Node_Access
   is
      --  Classic finite centipede: at stage s the mover may Take the stage
      --  pot or Pass. Pots grow so that, working backwards, Take is always
      --  strictly better than leaving the next mover to Take — hence SPNE
      --  is Take at the root.
      type Pot_Pair is record
         A, B : Payoff;
      end record;
      Pots : array (1 .. Stages) of Pot_Pair;
      Node : Node_Access;
      Who  : Player_Id;
      Take_Leaf : Node_Access;
      Pass_Cont : Node_Access;
      Final_P1, Final_P2 : Payoff;
      Step : Payoff;
   begin
      if Stages > Max_Path then
         raise Invalid_Argument with "Centipede: Stages too large";
      end if;

      --  Stage-1 Take = (Start_Take_P1, Start_Take_P2).
      --  Each later stage adds Growth to the mover's coordinate and
      --  Growth to the opponent relative to the pattern:
      --    odd s (P1):  (Start_P1 + Growth*(s-1), Start_P2 + Growth*(s-2)
      --                 for s>=3, with floor at Start_P2 for s=1)
      --    even s (P2): (Start_P1 + Growth*(s-2), Start_P2 + Growth*(s-1)
      --                 with Start_P1 floored for s=2 via max-style).
      --  Concrete classroom default (1,0) / Growth=1:
      --    (1,0), (0,2), (3,1), (2,4), (5,3), (4,6), ...
      for S in 1 .. Stages loop
         Step := Growth * Payoff (S - 1);
         if S mod 2 = 1 then
            --  P1 moves: P1 gets Start_P1 + Growth*(S-1);
            --  P2 gets Start_P2 + Growth*(S-1) - Growth (i.e. one Growth less).
            Pots (S).A := Start_Take_P1 + Step;
            if S = 1 then
               Pots (S).B := Start_Take_P2;
            else
               Pots (S).B := Start_Take_P2 + Step - Growth;
            end if;
         else
            --  P2 moves: P2 gets Start_P2 + Growth*S;
            --  P1 gets Start_P1 + Growth*(S-2) (zero Growth below stage 2).
            Pots (S).B := Start_Take_P2 + Growth * Payoff (S);
            if S = 2 then
               Pots (S).A := Start_Take_P1 - Growth;
            else
               Pots (S).A := Start_Take_P1 + Growth * Payoff (S - 2);
            end if;
         end if;
      end loop;

      --  Terminal after final Pass: give the last mover strictly less than
      --  their Take payoff so Take is uniquely optimal at the last node.
      if Stages mod 2 = 1 then
         Final_P1 := Pots (Stages).A - Growth;
         Final_P2 := Pots (Stages).B + Growth + Growth;
      else
         Final_P1 := Pots (Stages).A + Growth + Growth;
         Final_P2 := Pots (Stages).B - Growth;
      end if;
      Pass_Cont := Make_Terminal (Final_P1, Final_P2);

      for S in reverse 1 .. Stages loop
         if S mod 2 = 1 then
            Who := 1;
         else
            Who := 2;
         end if;
         Take_Leaf := Make_Terminal (Pots (S).A, Pots (S).B);
         if S = Stages then
            Node := Make_Decision (Who, [Take_Leaf, Pass_Cont]);
         else
            Node := Make_Decision (Who, [Take_Leaf, Node]);
         end if;
      end loop;
      return Node;
   end Centipede;

   function Subtraction_Game
     (Heap     : Natural;
      Max_Take : Positive) return Node_Access
   is
      --  Memoised nodes for (remaining, player-to-move).
      --  Index remaining 0 .. Heap; player 1 or 2.
      Max_Heap : constant := 40;
      type Memo is array (0 .. Max_Heap, Player_Id) of Node_Access;
      Store : Memo := [others => [others => null]];

      function Build (Remaining : Natural; Who : Player_Id) return Node_Access;

      function Build (Remaining : Natural; Who : Player_Id) return Node_Access is
         N     : Node_Access;
         Kids  : Node_List (1 .. Max_Take);
         Count : Natural := 0;
         Next  : Player_Id;
         Take  : Natural;
      begin
         if Store (Remaining, Who) /= null then
            return Store (Remaining, Who);
         end if;

         if Remaining = 0 then
            --  Current player cannot move → loses.
            if Who = 1 then
               N := Make_Terminal (0.0, 1.0);
            else
               N := Make_Terminal (1.0, 0.0);
            end if;
            Store (Remaining, Who) := N;
            return N;
         end if;

         if Who = 1 then
            Next := 2;
         else
            Next := 1;
         end if;

         for T in 1 .. Max_Take loop
            if T <= Remaining then
               Take := T;
            else
               exit;
            end if;
            Count := Count + 1;
            Kids (Count) := Build (Remaining - Take, Next);
         end loop;

         N := Make_Decision (Who, Kids (1 .. Count));
         Store (Remaining, Who) := N;
         return N;
      end Build;
   begin
      if Max_Take > Max_Children then
         raise Invalid_Argument with "Subtraction_Game: Max_Take too large";
      end if;
      if Heap > Max_Heap then
         raise Invalid_Argument with "Subtraction_Game: Heap too large";
      end if;
      return Build (Heap, 1);
   end Subtraction_Game;

   function Simple_Binary_Tree return Node_Access is
      Left : constant Node_Access :=
        Make_Decision
          (2,
           [Make_Terminal (3.0, 1.0),
            Make_Terminal (0.0, 2.0)]);
      Right : constant Node_Access :=
        Make_Decision
          (2,
           [Make_Terminal (1.0, 3.0),
            Make_Terminal (2.0, 0.0)]);
   begin
      return Make_Decision (1, [Left, Right]);
   end Simple_Binary_Tree;

   function Zero_Sum_Choice
     (Scores_For_P1 : Score_List) return Node_Access
   is
      Kids : Node_List (Scores_For_P1'Range);
      S    : Payoff;
   begin
      if Scores_For_P1'Length = 0
        or else Scores_For_P1'Length > Max_Children
      then
         raise Invalid_Argument with "Zero_Sum_Choice: bad length";
      end if;
      for I in Scores_For_P1'Range loop
         S := Scores_For_P1 (I);
         Kids (I) := Make_Terminal (S, -S);
      end loop;
      return Make_Decision (1, Kids);
   end Zero_Sum_Choice;

   function Take_Or_Leave_Chain
     (Rounds : Positive;
      High   : Payoff := 2.0;
      Low    : Payoff := 1.0) return Node_Access
   is
      Node : Node_Access;
      Who  : Player_Id;
      Take : Node_Access;
      P1, P2 : Payoff;
   begin
      if Rounds > Max_Path then
         raise Invalid_Argument with "Take_Or_Leave_Chain: Rounds too large";
      end if;

      --  Build from the last round (must Take) backwards.
      for R in reverse 1 .. Rounds loop
         if R mod 2 = 1 then
            Who := 1;
            P1  := High;
            P2  := Low;
         else
            Who := 2;
            P1  := Low;
            P2  := High;
         end if;
         Take := Make_Terminal (P1, P2);
         if R = Rounds then
            Node := Make_Decision (Who, [Take]);
         else
            Node := Make_Decision (Who, [Take, Node]);
         end if;
      end loop;
      return Node;
   end Take_Or_Leave_Chain;

end Backward_Induction;
