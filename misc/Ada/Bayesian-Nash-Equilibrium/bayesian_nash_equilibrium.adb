pragma Ada_2022;

package body Bayesian_Nash_Equilibrium is

   --------------------------------------------------------------------------
   -- Local helpers
   --------------------------------------------------------------------------

   procedure Check_Tol (Tol : Payoff) is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_Tol;

   procedure Check_Game_Size
     (T1, T2 : Type_Count; A1, A2 : Action_Count) is
   begin
      if T1 = 0 or else T2 = 0 or else A1 = 0 or else A2 = 0 then
         raise Invalid_Argument;
      end if;
   end Check_Game_Size;

   procedure Check_Type (T : Type_Id; Bound : Type_Count) is
   begin
      if Type_Id'Base (T) > Bound then
         raise Invalid_Argument;
      end if;
   end Check_Type;

   procedure Check_Action (A : Action_Id; Bound : Action_Count) is
   begin
      if Action_Id'Base (A) > Bound then
         raise Invalid_Argument;
      end if;
   end Check_Action;

   function Abs_Val (X : Payoff) return Payoff is
   begin
      if X >= 0.0 then
         return X;
      else
         return -X;
      end if;
   end Abs_Val;

   function Max_Payoff (X, Y : Payoff) return Payoff is
   begin
      if X >= Y then
         return X;
      else
         return Y;
      end if;
   end Max_Payoff;

   procedure Check_Prob_Unit (P : Probability) is
   begin
      if P < 0.0 or else P > 1.0 then
         raise Invalid_Argument;
      end if;
   end Check_Prob_Unit;

   function Zero_Tensor
     (T1, T2 : Type_Count; A1, A2 : Action_Count) return Payoff_Tensor
   is
      R : Payoff_Tensor (1 .. T1, 1 .. A1, 1 .. T2, 1 .. A2);
   begin
      for I in 1 .. T1 loop
         for J in 1 .. A1 loop
            for K in 1 .. T2 loop
               for L in 1 .. A2 loop
                  R (I, J, K, L) := 0.0;
               end loop;
            end loop;
         end loop;
      end loop;
      return R;
   end Zero_Tensor;

   function Zero_Prior (T1, T2 : Type_Count) return Prior_Matrix is
      R : Prior_Matrix (1 .. T1, 1 .. T2);
   begin
      for I in 1 .. T1 loop
         for J in 1 .. T2 loop
            R (I, J) := 0.0;
         end loop;
      end loop;
      return R;
   end Zero_Prior;

   function Zero_Mix
     (T : Type_Count; A : Action_Count) return Type_Contingent_Mix
   is
      R : Type_Contingent_Mix (1 .. T, 1 .. A);
   begin
      for I in 1 .. T loop
         for J in 1 .. A loop
            R (I, J) := 0.0;
         end loop;
      end loop;
      return R;
   end Zero_Mix;

   --------------------------------------------------------------------------
   -- Near
   --------------------------------------------------------------------------

   function Near
     (X, Y : Payoff; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      return Abs_Val (X - Y) <= Tol;
   end Near;

   --------------------------------------------------------------------------
   -- Prior / beliefs
   --------------------------------------------------------------------------

   function Prior_Mass (G : Bayesian_Game) return Probability is
      S : Probability := 0.0;
   begin
      for T1 in 1 .. G.T1 loop
         for T2 in 1 .. G.T2 loop
            S := S + G.Prior (T1, T2);
         end loop;
      end loop;
      return S;
   end Prior_Mass;

   function Is_Valid_Prior
     (G : Bayesian_Game; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if G.T1 = 0 or else G.T2 = 0 then
         return False;
      end if;
      for T1 in 1 .. G.T1 loop
         for T2 in 1 .. G.T2 loop
            if G.Prior (T1, T2) < -Tol then
               return False;
            end if;
         end loop;
      end loop;
      return Abs_Val (Prior_Mass (G) - 1.0) <= Tol;
   end Is_Valid_Prior;

   function Normalize_Prior (G : Bayesian_Game) return Bayesian_Game is
      M      : constant Probability := Prior_Mass (G);
      Result : Bayesian_Game (G.T1, G.T2, G.A1, G.A2);
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      if M <= 0.0 then
         raise Invalid_Argument;
      end if;
      Result.U1 := G.U1;
      Result.U2 := G.U2;
      for T1 in 1 .. G.T1 loop
         for T2 in 1 .. G.T2 loop
            Result.Prior (T1, T2) := G.Prior (T1, T2) / M;
         end loop;
      end loop;
      return Result;
   end Normalize_Prior;

   function Type_Marginal_1
     (G : Bayesian_Game; T : Type_Id) return Probability
   is
      S : Probability := 0.0;
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      Check_Type (T, G.T1);
      for T2 in 1 .. G.T2 loop
         S := S + G.Prior (T, T2);
      end loop;
      return S;
   end Type_Marginal_1;

   function Type_Marginal_2
     (G : Bayesian_Game; T : Type_Id) return Probability
   is
      S : Probability := 0.0;
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      Check_Type (T, G.T2);
      for T1 in 1 .. G.T1 loop
         S := S + G.Prior (T1, T);
      end loop;
      return S;
   end Type_Marginal_2;

   function Belief_1_About_2
     (G : Bayesian_Game; Own_Type : Type_Id; Other_Type : Type_Id)
      return Probability
   is
      M : Probability;
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      Check_Type (Own_Type, G.T1);
      Check_Type (Other_Type, G.T2);
      M := Type_Marginal_1 (G, Own_Type);
      if M <= 0.0 then
         raise Invalid_Argument;
      end if;
      return G.Prior (Own_Type, Other_Type) / M;
   end Belief_1_About_2;

   function Belief_2_About_1
     (G : Bayesian_Game; Own_Type : Type_Id; Other_Type : Type_Id)
      return Probability
   is
      M : Probability;
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      Check_Type (Own_Type, G.T2);
      Check_Type (Other_Type, G.T1);
      M := Type_Marginal_2 (G, Own_Type);
      if M <= 0.0 then
         raise Invalid_Argument;
      end if;
      return G.Prior (Other_Type, Own_Type) / M;
   end Belief_2_About_1;

   --------------------------------------------------------------------------
   -- Strategy helpers
   --------------------------------------------------------------------------

   function Is_Mixed_Action
     (P : Mixed_Action; Tol : Payoff := Default_Tol) return Boolean
   is
      S : Probability := 0.0;
   begin
      Check_Tol (Tol);
      if P'Length = 0 or else P'First /= 1 then
         return False;
      end if;
      for I in P'Range loop
         if P (I) < -Tol then
            return False;
         end if;
         S := S + P (I);
      end loop;
      return Abs_Val (S - 1.0) <= Tol;
   end Is_Mixed_Action;

   function Is_Valid_Strategy_Profile
     (P : Strategy_Profile; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if P.T1 = 0 or else P.T2 = 0 or else P.A1 = 0 or else P.A2 = 0 then
         return False;
      end if;
      for T in 1 .. P.T1 loop
         declare
            Mix : Mixed_Action (1 .. P.A1);
         begin
            for A in 1 .. P.A1 loop
               Mix (A) := P.S1 (T, A);
            end loop;
            if not Is_Mixed_Action (Mix, Tol) then
               return False;
            end if;
         end;
      end loop;
      for T in 1 .. P.T2 loop
         declare
            Mix : Mixed_Action (1 .. P.A2);
         begin
            for A in 1 .. P.A2 loop
               Mix (A) := P.S2 (T, A);
            end loop;
            if not Is_Mixed_Action (Mix, Tol) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Valid_Strategy_Profile;

   function Pure_Mixed_Action
     (Num_Actions : Action_Count; A : Action_Id) return Mixed_Action
   is
      Result : Mixed_Action (1 .. Num_Actions);
   begin
      if Num_Actions = 0 then
         raise Invalid_Argument;
      end if;
      Check_Action (A, Num_Actions);
      for I in 1 .. Num_Actions loop
         Result (I) := 0.0;
      end loop;
      Result (A) := 1.0;
      return Result;
   end Pure_Mixed_Action;

   function Uniform_Mixed_Action
     (Num_Actions : Action_Count) return Mixed_Action
   is
      Result : Mixed_Action (1 .. Num_Actions);
      P      : Probability;
   begin
      if Num_Actions = 0 then
         raise Invalid_Argument;
      end if;
      P := 1.0 / Probability (Integer (Num_Actions));
      for I in 1 .. Num_Actions loop
         Result (I) := P;
      end loop;
      return Result;
   end Uniform_Mixed_Action;

   function Pure_Strategy_Profile
     (G : Bayesian_Game;
      A1_Of_Type : Type_Contingent_Mix;
      A2_Of_Type : Type_Contingent_Mix) return Strategy_Profile
   is
      Result : Strategy_Profile (G.T1, G.T2, G.A1, G.A2);
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      if A1_Of_Type'First (1) /= 1
        or else A1_Of_Type'Last (1) /= G.T1
        or else A1_Of_Type'First (2) /= 1
        or else A1_Of_Type'Last (2) /= G.A1
        or else A2_Of_Type'First (1) /= 1
        or else A2_Of_Type'Last (1) /= G.T2
        or else A2_Of_Type'First (2) /= 1
        or else A2_Of_Type'Last (2) /= G.A2
      then
         raise Invalid_Argument;
      end if;
      Result.S1 := A1_Of_Type;
      Result.S2 := A2_Of_Type;
      return Result;
   end Pure_Strategy_Profile;

   function Pure_Actions_Profile
     (G              : Bayesian_Game;
      Player1_Action : Action_Id;
      Player2_Action : Action_Id) return Strategy_Profile
   is
      Result : Strategy_Profile (G.T1, G.T2, G.A1, G.A2);
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      Check_Action (Player1_Action, G.A1);
      Check_Action (Player2_Action, G.A2);
      Result.S1 := Zero_Mix (G.T1, G.A1);
      Result.S2 := Zero_Mix (G.T2, G.A2);
      for T in 1 .. G.T1 loop
         Result.S1 (T, Player1_Action) := 1.0;
      end loop;
      for T in 1 .. G.T2 loop
         Result.S2 (T, Player2_Action) := 1.0;
      end loop;
      return Result;
   end Pure_Actions_Profile;

   function Extract_Mixed_1
     (P : Strategy_Profile; T : Type_Id) return Mixed_Action
   is
      Result : Mixed_Action (1 .. P.A1);
   begin
      Check_Game_Size (P.T1, P.T2, P.A1, P.A2);
      Check_Type (T, P.T1);
      for A in 1 .. P.A1 loop
         Result (A) := P.S1 (T, A);
      end loop;
      return Result;
   end Extract_Mixed_1;

   function Extract_Mixed_2
     (P : Strategy_Profile; T : Type_Id) return Mixed_Action
   is
      Result : Mixed_Action (1 .. P.A2);
   begin
      Check_Game_Size (P.T1, P.T2, P.A1, P.A2);
      Check_Type (T, P.T2);
      for A in 1 .. P.A2 loop
         Result (A) := P.S2 (T, A);
      end loop;
      return Result;
   end Extract_Mixed_2;

   procedure Require_Compatible
     (G : Bayesian_Game; P : Strategy_Profile)
   is
   begin
      Check_Game_Size (G.T1, G.T2, G.A1, G.A2);
      if G.T1 /= P.T1 or else G.T2 /= P.T2
        or else G.A1 /= P.A1 or else G.A2 /= P.A2
      then
         raise Invalid_Argument;
      end if;
   end Require_Compatible;

   --------------------------------------------------------------------------
   -- Expected payoffs
   --------------------------------------------------------------------------

   function Expected_Payoff_Pure_1
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id;
      Own_Action : Action_Id) return Payoff
   is
      EU : Payoff := 0.0;
      B  : Probability;
   begin
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T1);
      Check_Action (Own_Action, G.A1);
      if Type_Marginal_1 (G, Own_Type) <= 0.0 then
         raise Invalid_Argument;
      end if;
      for T2 in 1 .. G.T2 loop
         B := Belief_1_About_2 (G, Own_Type, T2);
         for A2 in 1 .. G.A2 loop
            EU := EU + B * P.S2 (T2, A2)
              * G.U1 (Own_Type, Own_Action, T2, A2);
         end loop;
      end loop;
      return EU;
   end Expected_Payoff_Pure_1;

   function Expected_Payoff_Pure_2
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id;
      Own_Action : Action_Id) return Payoff
   is
      EU : Payoff := 0.0;
      B  : Probability;
   begin
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T2);
      Check_Action (Own_Action, G.A2);
      if Type_Marginal_2 (G, Own_Type) <= 0.0 then
         raise Invalid_Argument;
      end if;
      for T1 in 1 .. G.T1 loop
         B := Belief_2_About_1 (G, Own_Type, T1);
         for A1 in 1 .. G.A1 loop
            EU := EU + B * P.S1 (T1, A1)
              * G.U2 (T1, A1, Own_Type, Own_Action);
         end loop;
      end loop;
      return EU;
   end Expected_Payoff_Pure_2;

   function Expected_Payoff_1
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
   is
      EU : Payoff := 0.0;
   begin
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T1);
      if Type_Marginal_1 (G, Own_Type) <= 0.0 then
         raise Invalid_Argument;
      end if;
      for A1 in 1 .. G.A1 loop
         EU := EU + P.S1 (Own_Type, A1)
           * Expected_Payoff_Pure_1 (G, P, Own_Type, A1);
      end loop;
      return EU;
   end Expected_Payoff_1;

   function Expected_Payoff_2
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
   is
      EU : Payoff := 0.0;
   begin
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T2);
      if Type_Marginal_2 (G, Own_Type) <= 0.0 then
         raise Invalid_Argument;
      end if;
      for A2 in 1 .. G.A2 loop
         EU := EU + P.S2 (Own_Type, A2)
           * Expected_Payoff_Pure_2 (G, P, Own_Type, A2);
      end loop;
      return EU;
   end Expected_Payoff_2;

   function Best_Pure_Payoff_1
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
   is
      Best : Payoff;
      V    : Payoff;
   begin
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T1);
      Best := Expected_Payoff_Pure_1 (G, P, Own_Type, 1);
      for A in 2 .. G.A1 loop
         V := Expected_Payoff_Pure_1 (G, P, Own_Type, A);
         Best := Max_Payoff (Best, V);
      end loop;
      return Best;
   end Best_Pure_Payoff_1;

   function Best_Pure_Payoff_2
     (G : Bayesian_Game;
      P : Strategy_Profile;
      Own_Type : Type_Id) return Payoff
   is
      Best : Payoff;
      V    : Payoff;
   begin
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T2);
      Best := Expected_Payoff_Pure_2 (G, P, Own_Type, 1);
      for A in 2 .. G.A2 loop
         V := Expected_Payoff_Pure_2 (G, P, Own_Type, A);
         Best := Max_Payoff (Best, V);
      end loop;
      return Best;
   end Best_Pure_Payoff_2;

   --------------------------------------------------------------------------
   -- Best response / BNE
   --------------------------------------------------------------------------

   function Is_Best_Response_For_Type_1
     (G   : Bayesian_Game;
      P   : Strategy_Profile;
      Own_Type : Type_Id;
      Tol : Payoff := Default_Tol) return Boolean
   is
      Mix  : Mixed_Action (1 .. G.A1);
      Best : Payoff;
      V    : Payoff;
   begin
      Check_Tol (Tol);
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T1);
      if Type_Marginal_1 (G, Own_Type) <= Tol then
         return True;
      end if;
      for A in 1 .. G.A1 loop
         Mix (A) := P.S1 (Own_Type, A);
      end loop;
      if not Is_Mixed_Action (Mix, Tol) then
         return False;
      end if;
      Best := Best_Pure_Payoff_1 (G, P, Own_Type);
      for A in 1 .. G.A1 loop
         if Mix (A) > Tol then
            V := Expected_Payoff_Pure_1 (G, P, Own_Type, A);
            if V + Tol < Best then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Best_Response_For_Type_1;

   function Is_Best_Response_For_Type_2
     (G   : Bayesian_Game;
      P   : Strategy_Profile;
      Own_Type : Type_Id;
      Tol : Payoff := Default_Tol) return Boolean
   is
      Mix  : Mixed_Action (1 .. G.A2);
      Best : Payoff;
      V    : Payoff;
   begin
      Check_Tol (Tol);
      Require_Compatible (G, P);
      Check_Type (Own_Type, G.T2);
      if Type_Marginal_2 (G, Own_Type) <= Tol then
         return True;
      end if;
      for A in 1 .. G.A2 loop
         Mix (A) := P.S2 (Own_Type, A);
      end loop;
      if not Is_Mixed_Action (Mix, Tol) then
         return False;
      end if;
      Best := Best_Pure_Payoff_2 (G, P, Own_Type);
      for A in 1 .. G.A2 loop
         if Mix (A) > Tol then
            V := Expected_Payoff_Pure_2 (G, P, Own_Type, A);
            if V + Tol < Best then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Best_Response_For_Type_2;

   function Is_Bayesian_Nash
     (G   : Bayesian_Game;
      P   : Strategy_Profile;
      Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      Require_Compatible (G, P);
      if not Is_Valid_Prior (G, Tol) then
         return False;
      end if;
      if not Is_Valid_Strategy_Profile (P, Tol) then
         return False;
      end if;
      for T in 1 .. G.T1 loop
         if not Is_Best_Response_For_Type_1 (G, P, T, Tol) then
            return False;
         end if;
      end loop;
      for T in 1 .. G.T2 loop
         if not Is_Best_Response_For_Type_2 (G, P, T, Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Bayesian_Nash;

   --------------------------------------------------------------------------
   -- Classic constructors
   --------------------------------------------------------------------------

   --  Sheriff payoffs: Suspect=P1 (Criminal/Civilian), Sheriff=P2.
   --  Criminal: Shoot dominates Not. Civilian: Not dominates Shoot.
   --  Against Criminal→Shoot / Civilian→Not:
   --    EU_Sheriff(Shoot) = p·0 + (1−p)·(−1) = p−1
   --    EU_Sheriff(Not)   = p·(−2) + (1−p)·0 = −2p
   --  Shoot better iff p > 1/3.

   function Sheriffs_Dilemma (P_Criminal : Probability := 0.5)
     return Bayesian_Game
   is
      G : Bayesian_Game (2, 1, 2, 2);
   begin
      Check_Prob_Unit (P_Criminal);
      G.U1 := Zero_Tensor (2, 1, 2, 2);
      G.U2 := Zero_Tensor (2, 1, 2, 2);
      G.Prior := Zero_Prior (2, 1);

      --  Criminal (t1=1), Sheriff type t2=1
      --  (a1,a2): Shoot=1, Not=2
      G.U1 (1, 1, 1, 1) := -1.0;  G.U2 (1, 1, 1, 1) := 0.0;
      G.U1 (1, 1, 1, 2) := 1.0;   G.U2 (1, 1, 1, 2) := -2.0;
      G.U1 (1, 2, 1, 1) := -2.0;  G.U2 (1, 2, 1, 1) := 1.0;
      G.U1 (1, 2, 1, 2) := -1.0;  G.U2 (1, 2, 1, 2) := 0.0;

      --  Civilian (t1=2)
      G.U1 (2, 1, 1, 1) := -2.0;  G.U2 (2, 1, 1, 1) := -1.0;
      G.U1 (2, 1, 1, 2) := -1.0;  G.U2 (2, 1, 1, 2) := 1.0;
      G.U1 (2, 2, 1, 1) := -1.0;  G.U2 (2, 2, 1, 1) := -1.0;
      G.U1 (2, 2, 1, 2) := 0.0;   G.U2 (2, 2, 1, 2) := 0.0;

      G.Prior (1, 1) := P_Criminal;
      G.Prior (2, 1) := 1.0 - P_Criminal;
      return G;
   end Sheriffs_Dilemma;

   function Sheriffs_BNE (P_Criminal : Probability := 0.5)
     return Strategy_Profile
   is
      G : constant Bayesian_Game := Sheriffs_Dilemma (P_Criminal);
      P : Strategy_Profile (2, 1, 2, 2);
   begin
      P.S1 := Zero_Mix (2, 2);
      P.S2 := Zero_Mix (1, 2);
      --  Criminal → Shoot, Civilian → Not
      P.S1 (1, 1) := 1.0;
      P.S1 (2, 2) := 1.0;
      if Near (P_Criminal, 1.0 / 3.0, 1.0E-12) then
         P.S2 (1, 1) := 0.5;
         P.S2 (1, 2) := 0.5;
      elsif P_Criminal > 1.0 / 3.0 then
         P.S2 (1, 1) := 1.0;
      else
         P.S2 (1, 2) := 1.0;
      end if;
      pragma Unreferenced (G);
      return P;
   end Sheriffs_BNE;

   --  Entry game: Entrant P1 (1 type), Incumbent P2 (Tough/Weak).
   --  Payoffs:
   --    Out: Entrant 0; Incumbent 2 (either type, either action ignored).
   --    Enter+Fight: Tough (−1,2) — fight pays for tough; Weak (−1,−1).
   --    Enter+Accommodate: (1,1) for both types.
   --  BNE: Tough→Fight, Weak→Accommodate.
   --    EU_Enter = P_Tough·(−1) + (1−P_Tough)·1 = 1 − 2 P_Tough
   --    EU_Out = 0 → Enter iff P_Tough < 1/2.

   function Entry_Game (P_Tough : Probability := 0.5) return Bayesian_Game is
      G : Bayesian_Game (1, 2, 2, 2);
   begin
      Check_Prob_Unit (P_Tough);
      G.U1 := Zero_Tensor (1, 2, 2, 2);
      G.U2 := Zero_Tensor (1, 2, 2, 2);
      G.Prior := Zero_Prior (1, 2);

      for T2 in Type_Id range 1 .. 2 loop
         for A2 in Action_Id range 1 .. 2 loop
            --  Out (a1=2): (0, 2)
            G.U1 (1, 2, T2, A2) := 0.0;
            G.U2 (1, 2, T2, A2) := 2.0;
         end loop;
      end loop;

      --  Enter + Fight (a1=1, a2=1)
      G.U1 (1, 1, 1, 1) := -1.0;  G.U2 (1, 1, 1, 1) := 2.0;   -- Tough
      G.U1 (1, 1, 2, 1) := -1.0;  G.U2 (1, 1, 2, 1) := -1.0;  -- Weak

      --  Enter + Accommodate (a1=1, a2=2)
      G.U1 (1, 1, 1, 2) := 1.0;   G.U2 (1, 1, 1, 2) := 1.0;
      G.U1 (1, 1, 2, 2) := 1.0;   G.U2 (1, 1, 2, 2) := 1.0;

      G.Prior (1, 1) := P_Tough;
      G.Prior (1, 2) := 1.0 - P_Tough;
      return G;
   end Entry_Game;

   function Entry_BNE (P_Tough : Probability := 0.5) return Strategy_Profile is
      P : Strategy_Profile (1, 2, 2, 2);
   begin
      Check_Prob_Unit (P_Tough);
      P.S1 := Zero_Mix (1, 2);
      P.S2 := Zero_Mix (2, 2);
      --  Tough → Fight, Weak → Accommodate
      P.S2 (1, 1) := 1.0;
      P.S2 (2, 2) := 1.0;
      if P_Tough < 0.5 then
         P.S1 (1, 1) := 1.0;  -- Enter
      else
         P.S1 (1, 2) := 1.0;  -- Out (also at equality)
      end if;
      return P;
   end Entry_BNE;

   --  Auction toy (second-price / Vickrey): independent uniform types
   --  Low/High with values 1 and 2; bids Low=1, High=2. Winner pays the
   --  rival's bid; ties split 1/2. Truthful bidding (bid = value) is a BNE.

   function Auction_Payoff
     (Own_Value, Own_Bid, Other_Bid : Payoff) return Payoff
   is
   begin
      if Own_Bid > Other_Bid then
         return Own_Value - Other_Bid;
      elsif Own_Bid < Other_Bid then
         return 0.0;
      else
         return 0.5 * (Own_Value - Other_Bid);
      end if;
   end Auction_Payoff;

   function Auction_Toy return Bayesian_Game is
      G      : Bayesian_Game (2, 2, 2, 2);
      V1, V2 : Payoff;
      B1, B2 : Payoff;
   begin
      G.U1 := Zero_Tensor (2, 2, 2, 2);
      G.U2 := Zero_Tensor (2, 2, 2, 2);
      G.Prior := Zero_Prior (2, 2);
      for T1 in Type_Id range 1 .. 2 loop
         for T2 in Type_Id range 1 .. 2 loop
            G.Prior (T1, T2) := 0.25;
            V1 := Payoff (Integer (T1));  -- 1 or 2
            V2 := Payoff (Integer (T2));
            for A1 in Action_Id range 1 .. 2 loop
               for A2 in Action_Id range 1 .. 2 loop
                  B1 := Payoff (Integer (A1));
                  B2 := Payoff (Integer (A2));
                  G.U1 (T1, A1, T2, A2) := Auction_Payoff (V1, B1, B2);
                  G.U2 (T1, A1, T2, A2) := Auction_Payoff (V2, B2, B1);
               end loop;
            end loop;
         end loop;
      end loop;
      return G;
   end Auction_Toy;

   function Auction_Toy_BNE return Strategy_Profile is
      P : Strategy_Profile (2, 2, 2, 2);
   begin
      P.S1 := Zero_Mix (2, 2);
      P.S2 := Zero_Mix (2, 2);
      --  Bid own value: type t plays action t
      P.S1 (1, 1) := 1.0;
      P.S1 (2, 2) := 1.0;
      P.S2 (1, 1) := 1.0;
      P.S2 (2, 2) := 1.0;
      return P;
   end Auction_Toy_BNE;

   --  Battle with private info: P1 types Opera-lover / Fight-lover;
   --  P2 one type. Coordination payoffs biased by P1's type.
   --  Opera-lover: prefers (Opera,Opera)=(3,2); Fight-lover: (Fight,Fight)=(3,2)
   --  Mismatch: 0. P2 gets 2 on match of either kind, 0 on mismatch.
   --  BNE: P1 type1→Opera, type2→Fight; P2 mixes 1/2 (indifferent: EU=1 either).

   function Battle_Private_Info return Bayesian_Game is
      G : Bayesian_Game (2, 1, 2, 2);
   begin
      G.U1 := Zero_Tensor (2, 1, 2, 2);
      G.U2 := Zero_Tensor (2, 1, 2, 2);
      G.Prior := Zero_Prior (2, 1);

      --  Opera-lover (t1=1): likes Opera=1
      G.U1 (1, 1, 1, 1) := 3.0;  G.U2 (1, 1, 1, 1) := 2.0;  -- both Opera
      G.U1 (1, 1, 1, 2) := 0.0;  G.U2 (1, 1, 1, 2) := 0.0;
      G.U1 (1, 2, 1, 1) := 0.0;  G.U2 (1, 2, 1, 1) := 0.0;
      G.U1 (1, 2, 1, 2) := 1.0;  G.U2 (1, 2, 1, 2) := 2.0;  -- both Fight

      --  Fight-lover (t1=2): likes Fight=2
      G.U1 (2, 1, 1, 1) := 1.0;  G.U2 (2, 1, 1, 1) := 2.0;
      G.U1 (2, 1, 1, 2) := 0.0;  G.U2 (2, 1, 1, 2) := 0.0;
      G.U1 (2, 2, 1, 1) := 0.0;  G.U2 (2, 2, 1, 1) := 0.0;
      G.U1 (2, 2, 1, 2) := 3.0;  G.U2 (2, 2, 1, 2) := 2.0;

      G.Prior (1, 1) := 0.5;
      G.Prior (2, 1) := 0.5;
      return G;
   end Battle_Private_Info;

   function Battle_Private_Info_BNE return Strategy_Profile is
      P : Strategy_Profile (2, 1, 2, 2);
   begin
      P.S1 := Zero_Mix (2, 2);
      P.S2 := Zero_Mix (1, 2);
      P.S1 (1, 1) := 1.0;  -- Opera-lover → Opera
      P.S1 (2, 2) := 1.0;  -- Fight-lover → Fight
      P.S2 (1, 1) := 0.5;
      P.S2 (1, 2) := 0.5;
      return P;
   end Battle_Private_Info_BNE;

   function Matching_Pennies_Complete return Bayesian_Game is
      G : Bayesian_Game (1, 1, 2, 2);
   begin
      G.U1 := Zero_Tensor (1, 1, 2, 2);
      G.U2 := Zero_Tensor (1, 1, 2, 2);
      G.Prior := Zero_Prior (1, 1);
      G.Prior (1, 1) := 1.0;
      --  Heads=1, Tails=2
      G.U1 (1, 1, 1, 1) := 1.0;   G.U2 (1, 1, 1, 1) := -1.0;
      G.U1 (1, 1, 1, 2) := -1.0;  G.U2 (1, 1, 1, 2) := 1.0;
      G.U1 (1, 2, 1, 1) := -1.0;  G.U2 (1, 2, 1, 1) := 1.0;
      G.U1 (1, 2, 1, 2) := 1.0;   G.U2 (1, 2, 1, 2) := -1.0;
      return G;
   end Matching_Pennies_Complete;

   function Matching_Pennies_Mixed_BNE return Strategy_Profile is
      P : Strategy_Profile (1, 1, 2, 2);
   begin
      P.S1 := Zero_Mix (1, 2);
      P.S2 := Zero_Mix (1, 2);
      P.S1 (1, 1) := 0.5;
      P.S1 (1, 2) := 0.5;
      P.S2 (1, 1) := 0.5;
      P.S2 (1, 2) := 0.5;
      return P;
   end Matching_Pennies_Mixed_BNE;

   function Prisoners_Dilemma_Complete return Bayesian_Game is
      G : Bayesian_Game (1, 1, 2, 2);
   begin
      G.U1 := Zero_Tensor (1, 1, 2, 2);
      G.U2 := Zero_Tensor (1, 1, 2, 2);
      G.Prior := Zero_Prior (1, 1);
      G.Prior (1, 1) := 1.0;
      G.U1 (1, 1, 1, 1) := 3.0;  G.U2 (1, 1, 1, 1) := 3.0;
      G.U1 (1, 1, 1, 2) := 0.0;  G.U2 (1, 1, 1, 2) := 5.0;
      G.U1 (1, 2, 1, 1) := 5.0;  G.U2 (1, 2, 1, 1) := 0.0;
      G.U1 (1, 2, 1, 2) := 1.0;  G.U2 (1, 2, 1, 2) := 1.0;
      return G;
   end Prisoners_Dilemma_Complete;

   function Prisoners_Dilemma_BNE return Strategy_Profile is
   begin
      return Pure_Actions_Profile
        (Prisoners_Dilemma_Complete, 2, 2);
   end Prisoners_Dilemma_BNE;

   function Chicken_Complete return Bayesian_Game is
      G : Bayesian_Game (1, 1, 2, 2);
   begin
      G.U1 := Zero_Tensor (1, 1, 2, 2);
      G.U2 := Zero_Tensor (1, 1, 2, 2);
      G.Prior := Zero_Prior (1, 1);
      G.Prior (1, 1) := 1.0;
      G.U1 (1, 1, 1, 1) := 0.0;  G.U2 (1, 1, 1, 1) := 0.0;
      G.U1 (1, 1, 1, 2) := 7.0;  G.U2 (1, 1, 1, 2) := 2.0;
      G.U1 (1, 2, 1, 1) := 2.0;  G.U2 (1, 2, 1, 1) := 7.0;
      G.U1 (1, 2, 1, 2) := 6.0;  G.U2 (1, 2, 1, 2) := 6.0;
      return G;
   end Chicken_Complete;

   function Chicken_Pure_DC_BNE return Strategy_Profile is
   begin
      return Pure_Actions_Profile (Chicken_Complete, 1, 2);
   end Chicken_Pure_DC_BNE;

   function Chicken_Pure_CD_BNE return Strategy_Profile is
   begin
      return Pure_Actions_Profile (Chicken_Complete, 2, 1);
   end Chicken_Pure_CD_BNE;

   function Chicken_Mixed_BNE return Strategy_Profile is
      P : Strategy_Profile (1, 1, 2, 2);
   begin
      P.S1 := Zero_Mix (1, 2);
      P.S2 := Zero_Mix (1, 2);
      --  Dare with 1/3, Chicken-out with 2/3
      P.S1 (1, 1) := 1.0 / 3.0;
      P.S1 (1, 2) := 2.0 / 3.0;
      P.S2 (1, 1) := 1.0 / 3.0;
      P.S2 (1, 2) := 2.0 / 3.0;
      return P;
   end Chicken_Mixed_BNE;

end Bayesian_Nash_Equilibrium;
