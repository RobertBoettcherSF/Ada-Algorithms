--  Standalone test suite for Bayesian_Nash_Equilibrium.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Bayesian_Nash_Equilibrium; use Bayesian_Nash_Equilibrium;

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
   function TC (X : Natural) return Type_Count is (Type_Count (X));
   function AC (X : Natural) return Action_Count is (Action_Count (X));
   function Tid (X : Positive) return Type_Id is (Type_Id (X));
   function Aid (X : Positive) return Action_Id is (Action_Id (X));
   function Pf (X : Payoff) return Payoff is (X);
   function Pr (X : Probability) return Probability is (X);

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

   function Normalize_Raises (G : Bayesian_Game) return Boolean is
      Unused : Bayesian_Game (G.T1, G.T2, G.A1, G.A2);
      pragma Unreferenced (Unused);
   begin
      declare
         R : constant Bayesian_Game := Normalize_Prior (G);
         pragma Unreferenced (R);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Normalize_Raises;

   function Belief1_Raises
     (G : Bayesian_Game; Own, Other : Type_Id) return Boolean
   is
      Unused : Probability;
      pragma Unreferenced (Unused);
   begin
      declare
         B : constant Probability := Belief_1_About_2 (G, Own, Other);
         pragma Unreferenced (B);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Belief1_Raises;

   function Belief2_Raises
     (G : Bayesian_Game; Own, Other : Type_Id) return Boolean
   is
      Unused : Probability;
      pragma Unreferenced (Unused);
   begin
      declare
         B : constant Probability := Belief_2_About_1 (G, Own, Other);
         pragma Unreferenced (B);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Belief2_Raises;

   function Pure_Mixed_Raises
     (N : Action_Count; A : Action_Id) return Boolean
   is
   begin
      declare
         M : constant Mixed_Action := Pure_Mixed_Action (N, A);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Pure_Mixed_Raises;

   function Uniform_Mixed_Raises (N : Action_Count) return Boolean is
   begin
      declare
         M : constant Mixed_Action := Uniform_Mixed_Action (N);
         pragma Unreferenced (M);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Uniform_Mixed_Raises;

   function Compatible_Raises
     (G : Bayesian_Game; P : Strategy_Profile) return Boolean
   is
   begin
      Require_Compatible (G, P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compatible_Raises;

   function Sheriff_Raises (P : Probability) return Boolean is
   begin
      declare
         G : constant Bayesian_Game := Sheriffs_Dilemma (P);
         pragma Unreferenced (G);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Sheriff_Raises;

   function Entry_Raises (P : Probability) return Boolean is
   begin
      declare
         G : constant Bayesian_Game := Entry_Game (P);
         pragma Unreferenced (G);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Entry_Raises;

   function Pure_Actions_Raises
     (G : Bayesian_Game; A1, A2 : Action_Id) return Boolean
   is
   begin
      declare
         P : constant Strategy_Profile :=
           Pure_Actions_Profile (G, A1, A2);
         pragma Unreferenced (P);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Pure_Actions_Raises;

   ---------------------------------------------------------------------------
   -- Near / constants
   ---------------------------------------------------------------------------

   procedure Test_Near is
   begin
      Section ("Near / constants");
      Check (Nat (Max_Types) = 3, "Max_Types = 3");
      Check (Nat (Max_Actions) = 3, "Max_Actions = 3");
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near within default tol");
      Check (not Near (1.0, 2.0), "Near far apart");
      Check (Near (Pf (0.0), Pf (0.1), Pf (0.1)), "Near custom tol");
      Check (not Near (Pf (0.0), Pf (0.2), Pf (0.1)), "Near fails custom tol");
      Check (Near_Raises (Pf (-1.0)), "Near negative tol raises");
   end Test_Near;

   ---------------------------------------------------------------------------
   -- Mixed actions / strategies
   ---------------------------------------------------------------------------

   procedure Test_Mixed_Actions is
      U2 : constant Mixed_Action := Uniform_Mixed_Action (AC (2));
      U3 : constant Mixed_Action := Uniform_Mixed_Action (AC (3));
      P1 : constant Mixed_Action := Pure_Mixed_Action (AC (2), Aid (1));
      P2 : constant Mixed_Action := Pure_Mixed_Action (AC (3), Aid (3));
      Bad : Mixed_Action (1 .. 2) := [0.3, 0.3];
   begin
      Section ("Mixed actions");
      Check (Is_Mixed_Action (U2), "Uniform 2 is mixed");
      Check (Near (U2 (1), 0.5) and then Near (U2 (2), 0.5),
             "Uniform 2 values");
      Check (Is_Mixed_Action (U3), "Uniform 3 is mixed");
      Check (Near (U3 (1), 1.0 / 3.0), "Uniform 3 value");
      Check (Is_Mixed_Action (P1), "Pure action 1 mixed");
      Check (Near (P1 (1), 1.0) and then Near (P1 (2), 0.0),
             "Pure action 1 values");
      Check (Is_Mixed_Action (P2), "Pure action 3 of 3");
      Check (Near (P2 (3), 1.0), "Pure action 3 mass");
      Check (not Is_Mixed_Action (Bad), "Non-normalised rejected");
      Bad := [-0.1, 1.1];
      Check (not Is_Mixed_Action (Bad), "Negative entry rejected");
      Check (Uniform_Mixed_Raises (AC (0)), "Uniform empty raises");
      Check (Pure_Mixed_Raises (AC (0), Aid (1)), "Pure empty raises");
      Check (Pure_Mixed_Raises (AC (2), Aid (3)), "Pure OOB raises");
   end Test_Mixed_Actions;

   ---------------------------------------------------------------------------
   -- Prior / beliefs (Sheriff)
   ---------------------------------------------------------------------------

   procedure Test_Prior_Beliefs is
      G   : constant Bayesian_Game := Sheriffs_Dilemma (Pr (0.4));
      G0  : Bayesian_Game (2, 1, 2, 2);
      Gn  : Bayesian_Game (2, 1, 2, 2);
   begin
      Section ("Prior and beliefs");
      Check (Is_Valid_Prior (G), "Sheriff prior valid");
      Check (Near (Prior_Mass (G), 1.0), "Sheriff prior mass 1");
      Check (Near (Type_Marginal_1 (G, Tid (1)), 0.4), "Marginal Criminal");
      Check (Near (Type_Marginal_1 (G, Tid (2)), 0.6), "Marginal Civilian");
      Check (Near (Type_Marginal_2 (G, Tid (1)), 1.0), "Sheriff type mass");
      Check (Near (Belief_1_About_2 (G, Tid (1), Tid (1)), 1.0),
             "Criminal believes sheriff type 1");
      Check (Near (Belief_2_About_1 (G, Tid (1), Tid (1)), 0.4),
             "Sheriff P(Criminal)");
      Check (Near (Belief_2_About_1 (G, Tid (1), Tid (2)), 0.6),
             "Sheriff P(Civilian)");

      G0 := G;
      G0.Prior (1, 1) := 0.0;
      G0.Prior (2, 1) := 0.0;
      Check (Normalize_Raises (G0), "Normalize zero mass raises");
      Check (Belief1_Raises (G0, Tid (1), Tid (1)),
             "Belief1 zero marginal raises");
      Check (Belief2_Raises (G0, Tid (1), Tid (1)),
             "Belief2 zero marginal raises");

      G0.Prior (1, 1) := 2.0;
      G0.Prior (2, 1) := 2.0;
      Check (not Is_Valid_Prior (G0), "Unnormalised prior invalid");
      Gn := Normalize_Prior (G0);
      Check (Is_Valid_Prior (Gn), "Normalised prior valid");
      Check (Near (Gn.Prior (1, 1), 0.5), "Normalised half");

      Check (Sheriff_Raises (Pr (-0.1)), "Sheriff p<0 raises");
      Check (Sheriff_Raises (Pr (1.1)), "Sheriff p>1 raises");
      Check (Entry_Raises (Pr (-0.01)), "Entry p<0 raises");
      Check (Entry_Raises (Pr (1.01)), "Entry p>1 raises");
   end Test_Prior_Beliefs;

   ---------------------------------------------------------------------------
   -- Sheriff's dilemma BNE
   ---------------------------------------------------------------------------

   procedure Test_Sheriff is
      G_Hi : constant Bayesian_Game := Sheriffs_Dilemma (Pr (0.5));
      P_Hi : constant Strategy_Profile := Sheriffs_BNE (Pr (0.5));
      G_Lo : constant Bayesian_Game := Sheriffs_Dilemma (Pr (0.2));
      P_Lo : constant Strategy_Profile := Sheriffs_BNE (Pr (0.2));
      G_Eq : constant Bayesian_Game := Sheriffs_Dilemma (Pr (1.0 / 3.0));
      P_Eq : constant Strategy_Profile := Sheriffs_BNE (Pr (1.0 / 3.0));
      Bad  : Strategy_Profile := P_Hi;
   begin
      Section ("Sheriff's dilemma");
      Check (Is_Valid_Strategy_Profile (P_Hi), "Hi profile valid");
      Check (Is_Bayesian_Nash (G_Hi, P_Hi), "BNE at p=0.5");
      Check (Near (P_Hi.S1 (1, 1), 1.0), "Criminal shoots");
      Check (Near (P_Hi.S1 (2, 2), 1.0), "Civilian not");
      Check (Near (P_Hi.S2 (1, 1), 1.0), "Sheriff shoots when p>1/3");

      Check (Is_Bayesian_Nash (G_Lo, P_Lo), "BNE at p=0.2");
      Check (Near (P_Lo.S2 (1, 2), 1.0), "Sheriff not when p<1/3");

      Check (Is_Bayesian_Nash (G_Eq, P_Eq), "BNE at p=1/3 mixed");
      Check (Near (P_Eq.S2 (1, 1), 0.5), "Sheriff mix at threshold");

      --  Expected sheriff payoffs at p=0.5 with Criminal Shoot / Civilian Not
      Check (Near (Expected_Payoff_Pure_2 (G_Hi, P_Hi, Tid (1), Aid (1)),
                   Pf (0.5 - 1.0)),
             "Sheriff EU Shoot = p-1");
      Check (Near (Expected_Payoff_Pure_2 (G_Hi, P_Hi, Tid (1), Aid (2)),
                   Pf (-2.0 * 0.5)),
             "Sheriff EU Not = -2p");

      Check (Is_Best_Response_For_Type_1 (G_Hi, P_Hi, Tid (1)),
             "Criminal BR");
      Check (Is_Best_Response_For_Type_1 (G_Hi, P_Hi, Tid (2)),
             "Civilian BR");
      Check (Is_Best_Response_For_Type_2 (G_Hi, P_Hi, Tid (1)),
             "Sheriff BR hi");

      Bad.S2 (1, 1) := 0.0;
      Bad.S2 (1, 2) := 1.0;
      Check (not Is_Bayesian_Nash (G_Hi, Bad),
             "Sheriff Not not BNE at p=0.5");

      Bad := P_Lo;
      Bad.S2 (1, 1) := 1.0;
      Bad.S2 (1, 2) := 0.0;
      Check (not Is_Bayesian_Nash (G_Lo, Bad),
             "Sheriff Shoot not BNE at p=0.2");

      Bad := P_Hi;
      Bad.S1 (1, 1) := 0.0;
      Bad.S1 (1, 2) := 1.0;
      Check (not Is_Best_Response_For_Type_1 (G_Hi, Bad, Tid (1)),
             "Criminal Not not BR");
   end Test_Sheriff;

   ---------------------------------------------------------------------------
   -- Entry game
   ---------------------------------------------------------------------------

   procedure Test_Entry is
      G_Hi : constant Bayesian_Game := Entry_Game (Pr (0.7));
      P_Hi : constant Strategy_Profile := Entry_BNE (Pr (0.7));
      G_Lo : constant Bayesian_Game := Entry_Game (Pr (0.3));
      P_Lo : constant Strategy_Profile := Entry_BNE (Pr (0.3));
      G_Eq : constant Bayesian_Game := Entry_Game (Pr (0.5));
      P_Eq : constant Strategy_Profile := Entry_BNE (Pr (0.5));
      Bad  : Strategy_Profile := P_Lo;
   begin
      Section ("Entry game");
      Check (Is_Bayesian_Nash (G_Hi, P_Hi), "BNE stay out when tough likely");
      Check (Near (P_Hi.S1 (1, 2), 1.0), "Entrant Out at p=0.7");
      Check (Near (P_Hi.S2 (1, 1), 1.0), "Tough Fights");
      Check (Near (P_Hi.S2 (2, 2), 1.0), "Weak Accommodates");

      Check (Is_Bayesian_Nash (G_Lo, P_Lo), "BNE enter when tough rare");
      Check (Near (P_Lo.S1 (1, 1), 1.0), "Entrant Enter at p=0.3");

      Check (Is_Bayesian_Nash (G_Eq, P_Eq), "BNE at p=0.5 Out");
      Check (Near (Expected_Payoff_Pure_1 (G_Lo, P_Lo, Tid (1), Aid (1)),
                   Pf (1.0 - 2.0 * 0.3)),
             "EU Enter = 1-2p");
      Check (Near (Expected_Payoff_Pure_1 (G_Lo, P_Lo, Tid (1), Aid (2)),
                   0.0),
             "EU Out = 0");

      Bad.S1 (1, 1) := 0.0;
      Bad.S1 (1, 2) := 1.0;
      Check (not Is_Bayesian_Nash (G_Lo, Bad),
             "Out not BNE when p=0.3");

      Check (Is_Best_Response_For_Type_2 (G_Lo, P_Lo, Tid (1)),
             "Tough BR when Enter");
      Check (Is_Best_Response_For_Type_2 (G_Lo, P_Lo, Tid (2)),
             "Weak BR when Enter");
   end Test_Entry;

   ---------------------------------------------------------------------------
   -- Auction toy
   ---------------------------------------------------------------------------

   procedure Test_Auction is
      G   : constant Bayesian_Game := Auction_Toy;
      P   : constant Strategy_Profile := Auction_Toy_BNE;
      Bad : Strategy_Profile := P;
   begin
      Section ("Auction toy (Vickrey)");
      Check (Is_Valid_Prior (G), "Auction prior valid");
      Check (Near (Prior_Mass (G), 1.0), "Auction prior mass");
      Check (Near (G.Prior (1, 2), 0.25), "Independent cell");
      Check (Is_Bayesian_Nash (G, P), "Truthful bidding BNE");
      Check (Near (P.S1 (1, 1), 1.0) and then Near (P.S1 (2, 2), 1.0),
             "P1 bids value");
      Check (Near (P.S2 (1, 1), 1.0) and then Near (P.S2 (2, 2), 1.0),
             "P2 bids value");

      --  High type EU of truthful vs deviate low
      Check
        (Expected_Payoff_Pure_1 (G, P, Tid (2), Aid (2))
         >= Expected_Payoff_Pure_1 (G, P, Tid (2), Aid (1)) - 1.0E-12,
         "High prefers bid High");
      Check
        (Expected_Payoff_Pure_1 (G, P, Tid (1), Aid (1))
         >= Expected_Payoff_Pure_1 (G, P, Tid (1), Aid (2)) - 1.0E-12,
         "Low prefers bid Low");

      Bad.S1 (2, 2) := 0.0;
      Bad.S1 (2, 1) := 1.0;
      Check (not Is_Best_Response_For_Type_1 (G, Bad, Tid (2)),
             "High bid Low not BR");
   end Test_Auction;

   ---------------------------------------------------------------------------
   -- Battle private info
   ---------------------------------------------------------------------------

   procedure Test_Battle is
      G   : constant Bayesian_Game := Battle_Private_Info;
      P   : constant Strategy_Profile := Battle_Private_Info_BNE;
      Bad : Strategy_Profile := P;
   begin
      Section ("Battle with private info");
      Check (Is_Bayesian_Nash (G, P), "Battle BNE");
      Check (Near (Expected_Payoff_Pure_2 (G, P, Tid (1), Aid (1)), 1.0),
             "P2 EU Opera = 1");
      Check (Near (Expected_Payoff_Pure_2 (G, P, Tid (1), Aid (2)), 1.0),
             "P2 EU Fight = 1");
      Check (Near (Expected_Payoff_1 (G, P, Tid (1)), 1.5),
             "Opera-lover EU 1.5");
      Check (Near (Expected_Payoff_1 (G, P, Tid (2)), 1.5),
             "Fight-lover EU 1.5");

      Bad.S1 (1, 1) := 0.0;
      Bad.S1 (1, 2) := 1.0;
      Check (not Is_Best_Response_For_Type_1 (G, Bad, Tid (1)),
             "Opera-lover Fight not BR");

      --  Separating P1 + pure Opera P2 is NOT a BNE: Fight-lover would
      --  switch to Opera. Coordination BNE: both types play Opera, P2 Opera.
      Bad := P;
      Bad.S1 (1, 1) := 1.0;
      Bad.S1 (1, 2) := 0.0;
      Bad.S1 (2, 1) := 1.0;
      Bad.S1 (2, 2) := 0.0;
      Bad.S2 (1, 1) := 1.0;
      Bad.S2 (1, 2) := 0.0;
      Check (Is_Bayesian_Nash (G, Bad),
             "Battle pooling Opera BNE");

      Bad.S1 (1, 1) := 0.0;
      Bad.S1 (1, 2) := 1.0;
      Bad.S1 (2, 1) := 0.0;
      Bad.S1 (2, 2) := 1.0;
      Bad.S2 (1, 1) := 0.0;
      Bad.S2 (1, 2) := 1.0;
      Check (Is_Bayesian_Nash (G, Bad),
             "Battle pooling Fight BNE");

      --  Separating + pure Opera fails
      Bad := P;
      Bad.S2 (1, 1) := 1.0;
      Bad.S2 (1, 2) := 0.0;
      Check (not Is_Bayesian_Nash (G, Bad),
             "Separating + pure Opera not BNE");
   end Test_Battle;

   ---------------------------------------------------------------------------
   -- Degenerate complete-info → ordinary Nash
   ---------------------------------------------------------------------------

   procedure Test_Matching_Pennies is
      G   : constant Bayesian_Game := Matching_Pennies_Complete;
      P   : constant Strategy_Profile := Matching_Pennies_Mixed_BNE;
      Bad : Strategy_Profile := P;
   begin
      Section ("Matching Pennies (degenerate)");
      Check (G.T1 = TC (1) and then G.T2 = TC (1), "Single types");
      Check (Is_Bayesian_Nash (G, P), "Mixed Nash is BNE");
      Check (Near (Expected_Payoff_1 (G, P, Tid (1)), 0.0), "EU P1 = 0");
      Check (Near (Expected_Payoff_2 (G, P, Tid (1)), 0.0), "EU P2 = 0");
      Check (Near (Best_Pure_Payoff_1 (G, P, Tid (1)), 0.0),
             "Best pure also 0");

      Bad.S1 (1, 1) := 1.0;
      Bad.S1 (1, 2) := 0.0;
      Check (not Is_Bayesian_Nash (G, Bad), "Pure Heads not NE");
   end Test_Matching_Pennies;

   procedure Test_PD is
      G   : constant Bayesian_Game := Prisoners_Dilemma_Complete;
      P   : constant Strategy_Profile := Prisoners_Dilemma_BNE;
      Coop : constant Strategy_Profile :=
        Pure_Actions_Profile (G, Aid (1), Aid (1));
   begin
      Section ("Prisoner's Dilemma (degenerate)");
      Check (Is_Bayesian_Nash (G, P), "Defect-Defect BNE");
      Check (not Is_Bayesian_Nash (G, Coop), "Cooperate not NE");
      Check (Near (Expected_Payoff_1 (G, P, Tid (1)), 1.0), "PD EU = 1");
      Check (Is_Best_Response_For_Type_1 (G, P, Tid (1)), "P1 BR Defect");
      Check (Is_Best_Response_For_Type_2 (G, P, Tid (1)), "P2 BR Defect");
   end Test_PD;

   procedure Test_Chicken is
      G    : constant Bayesian_Game := Chicken_Complete;
      PDC  : constant Strategy_Profile := Chicken_Pure_DC_BNE;
      PCD  : constant Strategy_Profile := Chicken_Pure_CD_BNE;
      Mix  : constant Strategy_Profile := Chicken_Mixed_BNE;
      Crash : constant Strategy_Profile :=
        Pure_Actions_Profile (G, Aid (1), Aid (1));
   begin
      Section ("Chicken (degenerate)");
      Check (Is_Bayesian_Nash (G, PDC), "Pure (D,C) BNE");
      Check (Is_Bayesian_Nash (G, PCD), "Pure (C,D) BNE");
      Check (Is_Bayesian_Nash (G, Mix), "Mixed Chicken BNE");
      Check (not Is_Bayesian_Nash (G, Crash), "(D,D) not NE");
      Check (Near (Mix.S1 (1, 2), 2.0 / 3.0), "Mix Chicken-out 2/3");
      --  Mixed EU vs (1/3 D, 2/3 C):
      --  EU = (1/3)*((1/3)*0+(2/3)*7) + (2/3)*((1/3)*2+(2/3)*6) = 14/3
      Check (Near (Expected_Payoff_1 (G, Mix, Tid (1)), Pf (14.0 / 3.0)),
             "Mixed Chicken EU = 14/3");
      Check (Near (Expected_Payoff_Pure_1 (G, Mix, Tid (1), Aid (1)),
                   Pf (14.0 / 3.0)),
             "Dare EU = 14/3 under mix");
      Check (Near (Expected_Payoff_Pure_1 (G, Mix, Tid (1), Aid (2)),
                   Pf (14.0 / 3.0)),
             "Chicken-out EU = 14/3 under mix");
   end Test_Chicken;

   ---------------------------------------------------------------------------
   -- Compatibility / extract / pure profile builders
   ---------------------------------------------------------------------------

   procedure Test_Builders is
      G  : constant Bayesian_Game := Matching_Pennies_Complete;
      P  : constant Strategy_Profile := Matching_Pennies_Mixed_BNE;
      Sp : constant Strategy_Profile := Sheriffs_BNE (Pr (0.5));
      M1 : constant Mixed_Action := Extract_Mixed_1 (P, Tid (1));
      M2 : constant Mixed_Action := Extract_Mixed_2 (P, Tid (1));
      S1m : Type_Contingent_Mix (1 .. 1, 1 .. 2);
      S2m : Type_Contingent_Mix (1 .. 1, 1 .. 2);
      Built : Strategy_Profile (1, 1, 2, 2);
   begin
      Section ("Builders and compatibility");
      Check (Is_Mixed_Action (M1) and then Is_Mixed_Action (M2),
             "Extract mixed OK");
      Check (Near (M1 (1), 0.5), "Extract P1 Heads 1/2");
      Check (Compatible_Raises (G, Sp), "Size mismatch raises");
      Check (Pure_Actions_Raises (G, Aid (1), Aid (3)),
             "Pure action OOB raises");

      S1m (1, 1) := 1.0;
      S1m (1, 2) := 0.0;
      S2m (1, 1) := 0.0;
      S2m (1, 2) := 1.0;
      Built := Pure_Strategy_Profile (G, S1m, S2m);
      Check (Near (Built.S1 (1, 1), 1.0), "Built P1 pure Heads");
      Check (Near (Built.S2 (1, 2), 1.0), "Built P2 pure Tails");
      Check (not Is_Bayesian_Nash (G, Built), "Built pure not NE for MP");
   end Test_Builders;

   ---------------------------------------------------------------------------
   -- Vacuous zero-marginal type
   ---------------------------------------------------------------------------

   procedure Test_Zero_Marginal is
      G : constant Bayesian_Game := Sheriffs_Dilemma (Pr (1.0));
      P : Strategy_Profile := Sheriffs_BNE (Pr (1.0));
   begin
      Section ("Zero-marginal vacuous BR");
      --  p=1: Civilian has zero mass; any Civilian mix is vacuous BR
      Check (Near (Type_Marginal_1 (G, Tid (2)), 0.0), "Civilian mass 0");
      Check (Is_Best_Response_For_Type_1 (G, P, Tid (2)),
             "Vacuous BR for zero-mass Civilian");
      P.S1 (2, 1) := 0.7;
      P.S1 (2, 2) := 0.3;
      --  Profile no longer valid overall, but vacuous type check still True
      Check (Is_Best_Response_For_Type_1 (G, P, Tid (2)),
             "Vacuous still True with odd Civilian mix");
      Check (Is_Bayesian_Nash (G, Sheriffs_BNE (Pr (1.0))),
             "BNE at p=1 Criminal only");
   end Test_Zero_Marginal;

   ---------------------------------------------------------------------------
   -- Extra numeric / API surface for PASS volume
   ---------------------------------------------------------------------------

   procedure Test_Extra_API is
      G  : constant Bayesian_Game := Entry_Game (Pr (0.25));
      P  : constant Strategy_Profile := Entry_BNE (Pr (0.25));
      Gs : constant Bayesian_Game := Sheriffs_Dilemma (Pr (0.0));
      Ps : constant Strategy_Profile := Sheriffs_BNE (Pr (0.0));
      Ga : constant Bayesian_Game := Auction_Toy;
      Pa : constant Strategy_Profile := Auction_Toy_BNE;
   begin
      Section ("Extra API / edge priors");
      Check (Is_Bayesian_Nash (G, P), "Entry BNE p=0.25");
      Check (Is_Bayesian_Nash (Gs, Ps), "Sheriff BNE p=0");
      Check (Near (Ps.S2 (1, 2), 1.0), "Sheriff Not at p=0");
      Check (Near (Ps.S1 (2, 2), 1.0), "Civilian Not at p=0");
      Check (Is_Valid_Strategy_Profile (Pa), "Auction profile valid");
      Check (Near (Type_Marginal_1 (Ga, Tid (1)), 0.5), "Auction marg Low");
      Check (Near (Type_Marginal_2 (Ga, Tid (2)), 0.5), "Auction marg High");
      Check (Near (Belief_1_About_2 (Ga, Tid (1), Tid (1)), 0.5),
             "Auction belief independent");
      Check (Near (Belief_1_About_2 (Ga, Tid (2), Tid (2)), 0.5),
             "Auction belief High|High");

      Check (Near (Best_Pure_Payoff_1 (G, P, Tid (1)),
                   Expected_Payoff_1 (G, P, Tid (1))),
             "Entry best pure = strategy EU");
      Check (Near (Best_Pure_Payoff_2 (G, P, Tid (1)),
                   Expected_Payoff_2 (G, P, Tid (1))),
             "Tough best pure = strategy EU");
      Check (Near (Best_Pure_Payoff_2 (G, P, Tid (2)),
                   Expected_Payoff_2 (G, P, Tid (2))),
             "Weak best pure = strategy EU");

      --  Negative tol on validators
      declare
         Raised : Boolean := False;
      begin
         declare
            Unused : Boolean;
         begin
            Unused := Is_Valid_Prior (G, Pf (-0.01));
            pragma Unreferenced (Unused);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Is_Valid_Prior neg tol raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         declare
            Unused : Boolean;
         begin
            Unused := Is_Mixed_Action
              (Uniform_Mixed_Action (AC (2)), Pf (-1.0));
            pragma Unreferenced (Unused);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Is_Mixed_Action neg tol raises");
      end;

      declare
         Raised : Boolean := False;
      begin
         declare
            Unused : Boolean;
         begin
            Unused := Is_Bayesian_Nash (G, P, Pf (-1.0E-6));
            pragma Unreferenced (Unused);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Is_Bayesian_Nash neg tol raises");
      end;
   end Test_Extra_API;

   procedure Test_More_Sheriff_Grid is
   begin
      Section ("Sheriff prior grid");
      for K in 0 .. 10 loop
         declare
            Pk : constant Probability := Probability (K) / 10.0;
            G  : constant Bayesian_Game := Sheriffs_Dilemma (Pk);
            P  : constant Strategy_Profile := Sheriffs_BNE (Pk);
         begin
            Check (Is_Bayesian_Nash (G, P),
                   "Sheriff BNE grid p=" &
                   Probability'Image (Pk));
         end;
      end loop;
   end Test_More_Sheriff_Grid;

   procedure Test_More_Entry_Grid is
   begin
      Section ("Entry prior grid");
      for K in 0 .. 10 loop
         declare
            Pk : constant Probability := Probability (K) / 10.0;
            G  : constant Bayesian_Game := Entry_Game (Pk);
            P  : constant Strategy_Profile := Entry_BNE (Pk);
         begin
            Check (Is_Bayesian_Nash (G, P),
                   "Entry BNE grid p=" & Probability'Image (Pk));
         end;
      end loop;
   end Test_More_Entry_Grid;

   procedure Test_Reject_Non_BNE_Complete is
      G  : constant Bayesian_Game := Chicken_Complete;
      P  : Strategy_Profile := Chicken_Mixed_BNE;
   begin
      Section ("Reject non-BNE profiles");
      P.S1 (1, 1) := 0.9;
      P.S1 (1, 2) := 0.1;
      Check (not Is_Bayesian_Nash (G, P), "Wrong Chicken mix rejected");

      declare
         PD : constant Bayesian_Game := Prisoners_Dilemma_Complete;
         Only_Row_Defect : constant Strategy_Profile :=
           Pure_Actions_Profile (PD, Aid (2), Aid (1));
      begin
         Check (not Is_Bayesian_Nash (PD, Only_Row_Defect),
                "PD (D,C) rejected");
      end;

      declare
         MP : constant Bayesian_Game := Matching_Pennies_Complete;
         Pure : constant Strategy_Profile :=
           Pure_Actions_Profile (MP, Aid (2), Aid (2));
      begin
         Check (not Is_Bayesian_Nash (MP, Pure), "MP (T,T) rejected");
      end;
   end Test_Reject_Non_BNE_Complete;

   procedure Test_Payoff_Symmetry_Auction is
      G : constant Bayesian_Game := Auction_Toy;
      P : constant Strategy_Profile := Auction_Toy_BNE;
   begin
      Section ("Auction symmetry");
      Check (Near (Expected_Payoff_1 (G, P, Tid (1)),
                   Expected_Payoff_2 (G, P, Tid (1))),
             "Low-type EU symmetric");
      Check (Near (Expected_Payoff_1 (G, P, Tid (2)),
                   Expected_Payoff_2 (G, P, Tid (2))),
             "High-type EU symmetric");
      Check (Near (Expected_Payoff_1 (G, P, Tid (1)), 0.0),
             "Low-type truthful EU 0");
      Check (Near (Expected_Payoff_1 (G, P, Tid (2)), 0.5),
             "High-type truthful EU 0.5");
   end Test_Payoff_Symmetry_Auction;

begin
   Put_Line ("Bayesian_Nash_Equilibrium test suite");
   Put_Line ("====================================");

   Test_Near;
   Test_Mixed_Actions;
   Test_Prior_Beliefs;
   Test_Sheriff;
   Test_Entry;
   Test_Auction;
   Test_Battle;
   Test_Matching_Pennies;
   Test_PD;
   Test_Chicken;
   Test_Builders;
   Test_Zero_Marginal;
   Test_Extra_API;
   Test_More_Sheriff_Grid;
   Test_More_Entry_Grid;
   Test_Reject_Non_BNE_Complete;
   Test_Payoff_Symmetry_Auction;

   New_Line;
   Put_Line ("====================================");
   Put_Line ("PASS:" & Natural'Image (Pass_Count));
   Put_Line ("FAIL:" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
