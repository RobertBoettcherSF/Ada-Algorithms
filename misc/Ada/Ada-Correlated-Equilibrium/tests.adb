--  Standalone test suite for Correlated_Equilibrium.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Correlated_Equilibrium; use Correlated_Equilibrium;

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
   function AC (X : Natural) return Action_Count is (Action_Count (X));
   function Aid (X : Positive) return Action_Id is (Action_Id (X));
   function Pf (X : Payoff) return Payoff is (X);

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

   function Normalize_Raises (D : Distribution) return Boolean is
      Unused : Distribution (D.Rows, D.Cols);
   begin
      Unused := Normalize (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Normalize_Raises;

   function Pure_Raises
     (Rows, Cols : Action_Count; R, C : Action_Id) return Boolean
   is
      Unused : Distribution (Rows, Cols);
   begin
      Unused := Pure_Distribution (Rows, Cols, R, C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Pure_Raises;

   function Uniform_Raises (Rows, Cols : Action_Count) return Boolean is
      Unused : Distribution (1, 1);
      pragma Unreferenced (Unused);
   begin
      declare
         U : constant Distribution := Uniform_Distribution (Rows, Cols);
         pragma Unreferenced (U);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Uniform_Raises;

   function Compatible_Raises (G : Game; D : Distribution) return Boolean is
   begin
      Require_Compatible (G, D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compatible_Raises;

   function Grid_Raises (G : Game; Steps : Positive) return Boolean is
      Unused : Grid_CE_Result;
      pragma Unreferenced (Unused);
   begin
      declare
         R : constant Grid_CE_Result :=
           Find_CE_Grid_2x2 (G, Steps => Steps);
         pragma Unreferenced (R);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Grid_Raises;

   function Product_Raises_Empty return Boolean is
      P : Mixed_Strategy (1 .. 0);
      Q : constant Mixed_Strategy (1 .. 2) := [0.5, 0.5];
      Unused : Distribution (1, 2);
      pragma Unreferenced (Unused);
   begin
      declare
         D : constant Distribution := Product_Distribution (P, Q);
         pragma Unreferenced (D);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Product_Raises_Empty;

begin
   Put_Line ("Correlated_Equilibrium Ada 2023 — test suite");

   ---------------------------------------------------------------------
   Section ("1. Near / tolerances");
   ---------------------------------------------------------------------
   Check (Near (Pf (1.0), Pf (1.0)), "Near equal");
   Check (Near (Pf (1.0), Pf (1.0 + 1.0E-12)), "Near tiny delta");
   Check (not Near (Pf (1.0), Pf (2.0), Pf (0.1)), "Near far apart");
   Check (Near_Raises (Pf (-1.0)), "Near negative tol raises");
   Check (not Near_Raises (Pf (0.0)), "Near zero tol ok");

   ---------------------------------------------------------------------
   Section ("2. Distribution mass / normalize / pure / uniform");
   ---------------------------------------------------------------------
   declare
      U : constant Distribution := Uniform_Distribution (AC (2), AC (3));
      P : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (2));
      Z : Distribution (2, 2);
   begin
      Check (U.Rows = AC (2) and then U.Cols = AC (3), "uniform 2x3 shape");
      Check (Near (Total_Mass (U), Pf (1.0)), "uniform mass 1");
      Check (Is_Probability_Distribution (U), "uniform is prob");
      Check (Near (U.Mu (1, 1), Pf (1.0 / 6.0)), "uniform entry 1/6");
      Check (Near (Total_Mass (P), Pf (1.0)), "pure mass 1");
      Check (Near (P.Mu (1, 2), Pf (1.0)), "pure mass location");
      Check (Near (P.Mu (2, 1), Pf (0.0)), "pure zero elsewhere");
      Z.Mu := [[0.0, 0.0], [0.0, 0.0]];
      Check (Normalize_Raises (Z), "normalize zero mass raises");
      Z.Mu := [[1.0, 3.0], [0.0, 0.0]];
      declare
         N : constant Distribution := Normalize (Z);
      begin
         Check (Near (Total_Mass (N), Pf (1.0)), "normalize mass 1");
         Check (Near (N.Mu (1, 1), Pf (0.25)), "normalize 1/4");
         Check (Near (N.Mu (1, 2), Pf (0.75)), "normalize 3/4");
      end;
      Check (Is_Nonnegative (P), "pure nonnegative");
      Z.Mu := [[1.0, -0.5], [0.0, 0.5]];
      Check (not Is_Nonnegative (Z, Pf (0.1)), "negative detected");
      Check (not Is_Probability_Distribution (Z), "not a prob dist");
   end;
   Check (Uniform_Raises (AC (0), AC (2)), "uniform rows=0 raises");
   Check (Uniform_Raises (AC (2), AC (0)), "uniform cols=0 raises");
   Check (Pure_Raises (AC (0), AC (2), Aid (1), Aid (1)),
          "pure rows=0 raises");
   Check (Pure_Raises (AC (2), AC (2), Aid (3), Aid (1)),
          "pure bad row index raises");
   Check (Pure_Raises (AC (2), AC (2), Aid (1), Aid (3)),
          "pure bad col index raises");

   ---------------------------------------------------------------------
   Section ("3. Product / marginals / Is_Product");
   ---------------------------------------------------------------------
   declare
      P : constant Mixed_Strategy (1 .. 2) := [0.25, 0.75];
      Q : constant Mixed_Strategy (1 .. 3) := [0.2, 0.3, 0.5];
      D : constant Distribution := Product_Distribution (P, Q);
      Bad : Distribution (2, 2);
   begin
      Check (D.Rows = AC (2) and then D.Cols = AC (3), "product shape");
      Check (Near (D.Mu (1, 1), Pf (0.05)), "product 0.25*0.2");
      Check (Near (D.Mu (2, 3), Pf (0.375)), "product 0.75*0.5");
      Check (Near (Total_Mass (D), Pf (1.0)), "product mass 1");
      Check (Is_Product_Distribution (D), "product is product");
      Check (Near (Row_Marginal (D, Aid (1)), Pf (0.25)), "row marg 1");
      Check (Near (Row_Marginal (D, Aid (2)), Pf (0.75)), "row marg 2");
      Check (Near (Col_Marginal (D, Aid (2)), Pf (0.3)), "col marg 2");
      Bad.Mu := [[0.5, 0.0], [0.0, 0.5]];
      Check (Is_Probability_Distribution (Bad), "corr diag is prob");
      Check (not Is_Product_Distribution (Bad), "corr diag not product");
   end;
   Check (Product_Raises_Empty, "empty mixed raises");

   ---------------------------------------------------------------------
   Section ("4. Prisoner's Dilemma — pure NE as CE");
   ---------------------------------------------------------------------
   declare
      G  : constant Game := Prisoners_Dilemma;
      DD : constant Distribution := PD_Defect_Defect;
      CC : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (1));
      CD : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (2));
   begin
      Check (G.Rows = AC (2) and then G.Cols = AC (2), "PD shape");
      Check (Near (G.A (1, 1), Pf (3.0)) and then Near (G.B (1, 1), Pf (3.0)),
             "PD CC payoffs");
      Check (Near (G.A (2, 1), Pf (5.0)) and then Near (G.B (2, 1), Pf (0.0)),
             "PD DC temptation");
      Check (Is_Correlated_Equilibrium (G, DD), "PD DD is CE");
      Check (Is_Nash_Product (G, DD), "PD DD is Nash product");
      Check (Near (Expected_Payoff_Row (G, DD), Pf (1.0)), "PD DD row pay");
      Check (Near (Expected_Payoff_Col (G, DD), Pf (1.0)), "PD DD col pay");
      Check (not Is_Correlated_Equilibrium (G, CC), "PD CC not CE");
      Check (not Is_Correlated_Equilibrium (G, CD), "PD CD not CE");
      Check (Near (Max_Incentive_Violation (G, DD), Pf (0.0)),
             "PD DD zero violation");
      Check (Max_Incentive_Violation (G, CC) > Pf (0.0),
             "PD CC positive violation");
   end;

   ---------------------------------------------------------------------
   Section ("5. Chicken — traffic light and better CE");
   ---------------------------------------------------------------------
   declare
      G  : constant Game := Chicken;
      TL : constant Distribution := Chicken_Traffic_Light_CE;
      BT : constant Distribution := Chicken_Better_CE;
      MX : constant Distribution := Chicken_Mixed_Nash_Product;
      DD : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (1));
      DC : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (2));
      CD : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (2), Aid (1));
   begin
      Check (Near (G.A (1, 2), Pf (7.0)) and then Near (G.B (1, 2), Pf (2.0)),
             "Chicken D,C payoffs");
      Check (Is_Probability_Distribution (TL), "TL mass ok");
      Check (Near (TL.Mu (1, 1), Pf (0.0)), "TL no (D,D)");
      Check (Near (TL.Mu (2, 2), Pf (1.0 / 3.0)), "TL (C,C)=1/3");
      Check (Is_Correlated_Equilibrium (G, TL), "traffic-light is CE");
      Check (not Is_Product_Distribution (TL), "TL not a product");
      Check (not Is_Nash_Product (G, TL), "TL not Nash product");
      Check (Near (Expected_Payoff_Row (G, TL), Pf (5.0)), "TL row E=5");
      Check (Near (Expected_Payoff_Col (G, TL), Pf (5.0)), "TL col E=5");
      Check (Is_Correlated_Equilibrium (G, BT), "better CE is CE");
      Check (Near (Expected_Payoff_Row (G, BT), Pf (5.25)), "better row 5.25");
      Check (Near (Expected_Payoff_Col (G, BT), Pf (5.25)), "better col 5.25");
      Check (Expected_Payoff_Row (G, BT) > Expected_Payoff_Row (G, MX),
             "better CE beats mixed Nash (row)");
      Check (Is_Correlated_Equilibrium (G, MX), "mixed Nash product is CE");
      Check (Is_Nash_Product (G, MX), "mixed Nash is Nash product");
      Check (Is_Correlated_Equilibrium (G, DC), "pure (D,C) is CE");
      Check (Is_Correlated_Equilibrium (G, CD), "pure (C,D) is CE");
      Check (Is_Nash_Product (G, DC), "pure (D,C) Nash product");
      Check (not Is_Correlated_Equilibrium (G, DD), "(D,D) not CE");
      --  When recommended C under TL: gap C vs D should be nonnegative
      Check (Row_Incentive_Gap (G, TL, Aid (2), Aid (1)) >= Pf (-1.0E-9),
             "TL row C vs D gap >= 0");
      Check (Col_Incentive_Gap (G, TL, Aid (2), Aid (1)) >= Pf (-1.0E-9),
             "TL col C vs D gap >= 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Matching Pennies");
   ---------------------------------------------------------------------
   declare
      G  : constant Game := Matching_Pennies;
      MX : constant Distribution := Matching_Pennies_Mixed_Nash;
      HH : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (1));
      P  : constant Mixed_Strategy (1 .. 2) := [0.5, 0.5];
      Bad : constant Mixed_Strategy (1 .. 2) := [1.0, 0.0];
   begin
      Check (Near (G.A (1, 1), Pf (1.0)) and then Near (G.B (1, 1), Pf (-1.0)),
             "MP zero-sum HH");
      Check (Is_Correlated_Equilibrium (G, MX), "MP mixed is CE");
      Check (Is_Nash_Product (G, P, P), "MP (1/2,1/2) Nash");
      Check (Is_Nash_Product (G, MX), "MP product Nash via D");
      Check (Near (Expected_Payoff_Row (G, MX), Pf (0.0)), "MP row value 0");
      Check (Near (Expected_Payoff_Col (G, MX), Pf (0.0)), "MP col value 0");
      Check (not Is_Correlated_Equilibrium (G, HH), "MP pure HH not CE");
      Check (not Is_Nash_Product (G, Bad, P), "MP pure vs mixed not Nash");
      Check (Is_Best_Response_Row (G, P, P), "MP row BR to 1/2");
      Check (Is_Best_Response_Col (G, P, P), "MP col BR to 1/2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Battle of Sexes / Coordination");
   ---------------------------------------------------------------------
   declare
      BoS : constant Game := Battle_Of_Sexes;
      Co  : constant Game := Pure_Coordination;
      Op  : constant Distribution := BoS_Pure_Opera;
      Fi  : constant Distribution := BoS_Pure_Fight;
      Di  : constant Distribution := Coordination_Diagonal_CE;
      Off : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (2));
   begin
      Check (Is_Correlated_Equilibrium (BoS, Op), "BoS Opera CE");
      Check (Is_Correlated_Equilibrium (BoS, Fi), "BoS Fight CE");
      Check (Is_Nash_Product (BoS, Op), "BoS Opera Nash product");
      Check (Near (Expected_Payoff_Row (BoS, Op), Pf (2.0)), "BoS Opera row 2");
      Check (Near (Expected_Payoff_Col (BoS, Op), Pf (1.0)), "BoS Opera col 1");
      Check (not Is_Correlated_Equilibrium (BoS, Off), "BoS off-diag not CE");
      Check (Is_Correlated_Equilibrium (Co, Di), "coord diagonal CE");
      Check (not Is_Product_Distribution (Di), "diag CE not product");
      Check (Near (Expected_Payoff_Row (Co, Di), Pf (1.0)), "coord diag pay 1");
      Check (Is_Correlated_Equilibrium
               (Co, Pure_Distribution (AC (2), AC (2), Aid (1), Aid (1))),
             "coord (A,A) CE");
      Check (not Is_Correlated_Equilibrium (Co, Off), "coord off-diag not CE");
   end;

   ---------------------------------------------------------------------
   Section ("8. Incentive gaps exhaustive on Chicken TL");
   ---------------------------------------------------------------------
   declare
      G  : constant Game := Chicken;
      TL : constant Distribution := Chicken_Traffic_Light_CE;
   begin
      for R in Action_Id range 1 .. 2 loop
         for R_Alt in Action_Id range 1 .. 2 loop
            Check
              (Row_Incentive_Gap (G, TL, R, R_Alt) >= Pf (-1.0E-9),
               "TL row gap (" & Action_Id'Image (R) & ","
               & Action_Id'Image (R_Alt) & ")");
         end loop;
      end loop;
      for C in Action_Id range 1 .. 2 loop
         for C_Alt in Action_Id range 1 .. 2 loop
            Check
              (Col_Incentive_Gap (G, TL, C, C_Alt) >= Pf (-1.0E-9),
               "TL col gap (" & Action_Id'Image (C) & ","
               & Action_Id'Image (C_Alt) & ")");
         end loop;
      end loop;
      Check (Near (Max_Row_Violation (G, TL), Pf (0.0), Pf (1.0E-9)),
             "TL max row viol ~ 0");
      Check (Near (Max_Col_Violation (G, TL), Pf (0.0), Pf (1.0E-9)),
             "TL max col viol ~ 0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Uniform_Over_Pure_Profiles");
   ---------------------------------------------------------------------
   declare
      Mask : constant Probability_Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 2.0], [2.0, 0.0]];
      D : constant Distribution :=
        Uniform_Over_Pure_Profiles (AC (2), AC (2), Mask);
      G : constant Game := Chicken;
   begin
      Check (Near (D.Mu (1, 2), Pf (0.5)), "uniform support (1,2)");
      Check (Near (D.Mu (2, 1), Pf (0.5)), "uniform support (2,1)");
      Check (Near (D.Mu (1, 1), Pf (0.0)), "uniform support zero (1,1)");
      Check (Is_Correlated_Equilibrium (G, D),
             "uniform on Chicken pure NE is CE");
      Check (not Is_Product_Distribution (D),
             "50-50 on anti-diag is correlated (not product)");
   end;

   ---------------------------------------------------------------------
   Section ("10. Find_CE_Grid_2x2");
   ---------------------------------------------------------------------
   declare
      G_PD : constant Game := Prisoners_Dilemma;
      G_MP : constant Game := Matching_Pennies;
      G_Ch : constant Game := Chicken;
      R1   : constant Grid_CE_Result := Find_CE_Grid_2x2 (G_PD, Steps => 6);
      R2   : constant Grid_CE_Result := Find_CE_Grid_2x2 (G_MP, Steps => 4);
      R3   : constant Grid_CE_Result := Find_CE_Grid_2x2 (G_Ch, Steps => 8);
      Big  : Game (3, 3);
   begin
      Check (R1.Found, "grid finds CE for PD");
      Check (Is_Correlated_Equilibrium (G_PD, R1.D, Pf (1.0E-6)),
             "grid PD result is CE");
      Check (R2.Found, "grid finds CE for MP");
      Check (Is_Correlated_Equilibrium (G_MP, R2.D, Pf (1.0E-6)),
             "grid MP result is CE");
      Check (R3.Found, "grid finds CE for Chicken");
      Check (Is_Correlated_Equilibrium (G_Ch, R3.D, Pf (1.0E-6)),
             "grid Chicken result is CE");
      Big.A := [others => [others => 0.0]];
      Big.B := [others => [others => 0.0]];
      Check (Grid_Raises (Big, 4), "grid non-2x2 raises");
      Check (Grid_Raises (G_PD, 50), "grid Steps>40 raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Compatibility / size errors");
   ---------------------------------------------------------------------
   declare
      G2 : constant Game := Chicken;
      G3 : Game (3, 2);
      D2 : constant Distribution := Chicken_Traffic_Light_CE;
      D3 : Distribution (3, 2);
   begin
      G3.A := [others => [others => 0.0]];
      G3.B := [others => [others => 0.0]];
      D3.Mu := [others => [others => 0.0]];
      D3.Mu (1, 1) := 1.0;
      Check (Compatible_Raises (G2, D3), "size mismatch raises");
      Check (Compatible_Raises (G3, D2), "size mismatch raises 2");
      Check (not Compatible_Raises (G2, D2), "matching sizes ok");
   end;

   ---------------------------------------------------------------------
   Section ("12. Larger 3x3 / 4x4 / 5x5 sanity");
   ---------------------------------------------------------------------
   declare
      G3 : Game (3, 3);
      G5 : Game (5, 4);
      U3 : constant Distribution := Uniform_Distribution (AC (3), AC (3));
      P5 : constant Distribution :=
        Pure_Distribution (AC (5), AC (4), Aid (3), Aid (2));
   begin
      --  Constant-sum friendly: identity-like coordination on diagonal
      for R in Action_Id range 1 .. 3 loop
         for C in Action_Id range 1 .. 3 loop
            if R = C then
               G3.A (R, C) := 1.0;
               G3.B (R, C) := 1.0;
            else
               G3.A (R, C) := 0.0;
               G3.B (R, C) := 0.0;
            end if;
         end loop;
      end loop;
      declare
         Mask : Probability_Matrix (1 .. 3, 1 .. 3) :=
           [others => [others => 0.0]];
         Diag : Distribution (3, 3);
      begin
         Mask (1, 1) := 1.0;
         Mask (2, 2) := 1.0;
         Mask (3, 3) := 1.0;
         Diag := Uniform_Over_Pure_Profiles (AC (3), AC (3), Mask);
         Check (Is_Correlated_Equilibrium (G3, Diag), "3x3 diag CE");
         Check (Near (Expected_Payoff_Row (G3, Diag), Pf (1.0)),
                "3x3 diag payoff 1");
         Check (Is_Correlated_Equilibrium (G3, U3),
                "3x3 uniform is CE for weak coord (gaps=0)");
         --  Contrast: put mass only on off-diagonal — not a CE
         declare
            Off : Distribution (3, 3);
         begin
            Off.Mu := [others => [others => 0.0]];
            Off.Mu (1, 2) := 1.0;
            Check (not Is_Correlated_Equilibrium (G3, Off),
                   "3x3 off-diagonal Dirac not CE");
         end;
      end;
      for R in 1 .. G5.Rows loop
         for C in 1 .. G5.Cols loop
            G5.A (R, C) := Payoff (Integer (R) + Integer (C));
            G5.B (R, C) := Payoff (Integer (R) * Integer (C));
         end loop;
      end loop;
      Check (P5.Rows = AC (5) and then P5.Cols = AC (4), "5x4 pure shape");
      Check (Near (Total_Mass (P5), Pf (1.0)), "5x4 pure mass");
      Check (Near (Expected_Payoff_Row (G5, P5),
                   Pf (Payoff (3 + 2))), "5x4 expected row");
      Check (Max_Actions = Nat (5), "Max_Actions = 5");
   end;

   ---------------------------------------------------------------------
   Section ("13. Nash product mixed Chicken explicitly");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Chicken;
      --  p(Dare)=1/3, p(Chicken)=2/3
      P : constant Mixed_Strategy (1 .. 2) := [1.0 / 3.0, 2.0 / 3.0];
      D : constant Distribution := Product_Distribution (P, P);
   begin
      Check (Is_Nash_Product (G, P, P), "Chicken mixed mutual BR");
      Check (Is_Correlated_Equilibrium (G, D), "Chicken mixed product CE");
      Check (Near (Expected_Payoff_Row (G, D),
                   Expected_Payoff_Row (G, Chicken_Mixed_Nash_Product)),
             "mixed constructor matches product");
      --  Expected payoff of mixed NE: each gets 14/3 ≈ 4.666...
      Check (Near (Expected_Payoff_Row (G, D), Pf (14.0 / 3.0), Pf (1.0E-9)),
             "Chicken mixed NE payoff 14/3");
   end;

   ---------------------------------------------------------------------
   Section ("14. Better CE incentive equality at C");
   ---------------------------------------------------------------------
   declare
      G  : constant Game := Chicken;
      BT : constant Distribution := Chicken_Better_CE;
      Gap : constant Payoff :=
        Row_Incentive_Gap (G, BT, Aid (2), Aid (1));
   begin
      --  Wikipedia: when recommended C, EU(C)=EU(D)=14/3
      Check (Near (Gap, Pf (0.0), Pf (1.0E-9)),
             "better CE row C vs D gap ~ 0");
      Check (Near (Col_Incentive_Gap (G, BT, Aid (2), Aid (1)),
                   Pf (0.0), Pf (1.0E-9)),
             "better CE col C vs D gap ~ 0");
      Check (Row_Incentive_Gap (G, BT, Aid (1), Aid (2)) >= Pf (-1.0E-9),
             "better CE dare recommendation obedient");
   end;

   ---------------------------------------------------------------------
   Section ("15. Batch pure-profile CE checks (PD)");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Prisoners_Dilemma;
   begin
      for R in Action_Id range 1 .. 2 loop
         for C in Action_Id range 1 .. 2 loop
            declare
               D : constant Distribution :=
                 Pure_Distribution (AC (2), AC (2), R, C);
               Ok : constant Boolean := Is_Correlated_Equilibrium (G, D);
               Expect : constant Boolean :=
                 (R = Aid (2) and then C = Aid (2));
            begin
               Check (Ok = Expect,
                      "PD pure (" & Action_Id'Image (R) & ","
                      & Action_Id'Image (C) & ") CE iff DD");
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("16. Batch pure-profile CE checks (Chicken)");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Chicken;
   begin
      for R in Action_Id range 1 .. 2 loop
         for C in Action_Id range 1 .. 2 loop
            declare
               D : constant Distribution :=
                 Pure_Distribution (AC (2), AC (2), R, C);
               Ok : constant Boolean := Is_Correlated_Equilibrium (G, D);
               --  Pure NE: (D,C)=(1,2) and (C,D)=(2,1)
               Expect : constant Boolean :=
                 (R = Aid (1) and then C = Aid (2))
                 or else (R = Aid (2) and then C = Aid (1));
            begin
               Check (Ok = Expect,
                      "Chicken pure (" & Action_Id'Image (R) & ","
                      & Action_Id'Image (C) & ") CE iff NE");
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("17. Batch pure-profile CE checks (Coordination)");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Pure_Coordination;
   begin
      for R in Action_Id range 1 .. 2 loop
         for C in Action_Id range 1 .. 2 loop
            declare
               D : constant Distribution :=
                 Pure_Distribution (AC (2), AC (2), R, C);
               Ok : constant Boolean := Is_Correlated_Equilibrium (G, D);
               Expect : constant Boolean := (R = C);
            begin
               Check (Ok = Expect,
                      "Coord pure (" & Action_Id'Image (R) & ","
                      & Action_Id'Image (C) & ") CE iff diagonal");
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("18. Mixed strategy BR edge cases");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Matching_Pennies;
      Half : constant Mixed_Strategy (1 .. 2) := [0.5, 0.5];
      Pure_H : constant Mixed_Strategy (1 .. 2) := [1.0, 0.0];
      Pure_T : constant Mixed_Strategy (1 .. 2) := [0.0, 1.0];
   begin
      Check (Is_Best_Response_Row (G, Half, Pure_H),
             "any pure is BR to 1/2 (row H)");
      Check (Is_Best_Response_Row (G, Half, Pure_T),
             "any pure is BR to 1/2 (row T)");
      Check (Is_Best_Response_Row (G, Pure_H, Pure_H),
             "row H is BR to col H (match)");
      Check (not Is_Best_Response_Row (G, Pure_H, Pure_T),
             "row T not BR to col H");
      Check (not Is_Nash_Product (G, Pure_H, Pure_H),
             "MP (H,H) not Nash");
      Check (Is_Nash_Product (G, Half, Half), "MP half-half Nash");
   end;

   ---------------------------------------------------------------------
   Section ("19. Violation magnitude ordering");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Prisoners_Dilemma;
      CC : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (1));
      CD : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (2));
      DD : constant Distribution := PD_Defect_Defect;
   begin
      Check (Max_Incentive_Violation (G, CC)
             > Max_Incentive_Violation (G, DD),
             "CC violates more than DD");
      Check (Max_Incentive_Violation (G, CD)
             > Max_Incentive_Violation (G, DD),
             "CD violates more than DD");
      Check (Near (Max_Incentive_Violation (G, DD), Pf (0.0)),
             "DD violation ~ 0");
   end;

   ---------------------------------------------------------------------
   Section ("20. Self-gap zero / alternate bookkeeping");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Battle_Of_Sexes;
      D : constant Distribution := BoS_Pure_Opera;
   begin
      Check (Near (Row_Incentive_Gap (G, D, Aid (1), Aid (1)), Pf (0.0)),
             "self row gap 0");
      Check (Near (Col_Incentive_Gap (G, D, Aid (1), Aid (1)), Pf (0.0)),
             "self col gap 0");
      Check (Near (Row_Marginal (D, Aid (1)), Pf (1.0)), "opera row marg");
      Check (Near (Col_Marginal (D, Aid (2)), Pf (0.0)), "opera col2 marg 0");
   end;

   ---------------------------------------------------------------------
   Section ("21. Probability tolerance boundaries");
   ---------------------------------------------------------------------
   declare
      D : Distribution (2, 2);
   begin
      D.Mu := [[0.5, 0.5], [0.0, 0.0]];
      Check (Is_Probability_Distribution (D, Pf (1.0E-12)),
             "exact half-half ok");
      D.Mu := [[0.5, 0.5 + 1.0E-4], [0.0, 0.0]];
      Check (not Is_Probability_Distribution (D, Pf (1.0E-9)),
             "mass drift fails tight tol");
      Check (Is_Probability_Distribution (D, Pf (1.0E-3)),
             "mass drift ok loose tol");
      D.Mu := [[-1.0E-12, 0.5], [0.0, 0.5]];
      Check (Is_Nonnegative (D, Pf (1.0E-9)),
             "tiny negative within tol");
      Check (not Is_Nonnegative (D, Pf (1.0E-15)),
             "tiny negative outside tiny tol");
   end;

   ---------------------------------------------------------------------
   Section ("22. Every classic game constructor shape / CE smoke");
   ---------------------------------------------------------------------
   declare
      procedure Smoke (G : Game; Label : String) is
         R : constant Grid_CE_Result :=
           Find_CE_Grid_2x2 (G, Steps => 4);
      begin
         Check (G.Rows = AC (2) and then G.Cols = AC (2),
                Label & " is 2x2");
         Check (R.Found, "grid CE exists for " & Label);
      end Smoke;
   begin
      Smoke (Prisoners_Dilemma, "PD");
      Smoke (Chicken, "Chicken");
      Smoke (Matching_Pennies, "MP");
      Smoke (Battle_Of_Sexes, "BoS");
      Smoke (Pure_Coordination, "Coordination");
   end;

   ---------------------------------------------------------------------
   Section ("23. Product of independent pure NE (BoS) vs correlated");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Battle_Of_Sexes;
      --  Mixed NE roughly (2/3,1/3) x (1/3,2/3) for this payoff scaling
      P : constant Mixed_Strategy (1 .. 2) := [2.0 / 3.0, 1.0 / 3.0];
      Q : constant Mixed_Strategy (1 .. 2) := [1.0 / 3.0, 2.0 / 3.0];
      D : constant Distribution := Product_Distribution (P, Q);
      Corr : Distribution (2, 2);
   begin
      Check (Is_Nash_Product (G, P, Q), "BoS mixed NE");
      Check (Is_Correlated_Equilibrium (G, D), "BoS mixed product CE");
      --  Correlated: 1/2 on each pure NE — also a CE (convex)
      Corr.Mu := [[0.5, 0.0], [0.0, 0.5]];
      Check (Is_Correlated_Equilibrium (G, Corr),
             "BoS 1/2-1/2 on pure NE is CE");
      Check (not Is_Product_Distribution (Corr),
             "BoS correlated not product");
      Check (Expected_Payoff_Row (G, Corr)
             > Expected_Payoff_Row (G, D) - Pf (1.0E-9),
             "BoS correlated weakly beats mixed NE row pay");
   end;

   ---------------------------------------------------------------------
   Section ("24. Require_Compatible does not mutate");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Chicken;
      D : constant Distribution := Chicken_Better_CE;
      E1 : constant Payoff := Expected_Payoff_Row (G, D);
   begin
      Require_Compatible (G, D);
      Check (Near (Expected_Payoff_Row (G, D), E1),
             "payoff stable after Require_Compatible");
   end;

   ---------------------------------------------------------------------
   Section ("25. Max_Actions boundary Pure_Distribution");
   ---------------------------------------------------------------------
   declare
      D : constant Distribution :=
        Pure_Distribution
          (AC (Max_Actions), AC (Max_Actions),
           Aid (Max_Actions), Aid (1));
   begin
      Check (D.Rows = AC (Max_Actions), "max rows");
      Check (Near (D.Mu (Aid (Max_Actions), Aid (1)), Pf (1.0)),
             "max corner mass");
      Check (Is_Probability_Distribution (D), "max pure is prob");
   end;

   ---------------------------------------------------------------------
   Section ("26. Gap identity: following vs switching on Dirac NE");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Chicken;
      D : constant Distribution :=
        Pure_Distribution (AC (2), AC (2), Aid (1), Aid (2)); -- (D,C)
   begin
      --  Row plays Dare: switching to Chicken lowers payoff 7 -> 6
      Check (Row_Incentive_Gap (G, D, Aid (1), Aid (2)) > Pf (0.0),
             "row prefers Dare when col Chickens");
      --  Col plays Chicken: switching to Dare lowers 2 -> 0
      Check (Col_Incentive_Gap (G, D, Aid (2), Aid (1)) > Pf (0.0),
             "col prefers Chicken when row Dares");
   end;

   ---------------------------------------------------------------------
   Section ("27. Is_Nash_Product rejects non-probability mixes");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Matching_Pennies;
      Bad : constant Mixed_Strategy (1 .. 2) := [0.7, 0.7];
      Half : constant Mixed_Strategy (1 .. 2) := [0.5, 0.5];
   begin
      Check (not Is_Nash_Product (G, Bad, Half),
             "non-prob mix rejected");
      Check (not Is_Nash_Product (G, Half, Bad),
             "non-prob mix rejected (col)");
   end;

   ---------------------------------------------------------------------
   Section ("28. Traffic-light vs better vs mixed payoff ranking");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Chicken;
      TL : constant Payoff :=
        Expected_Payoff_Row (G, Chicken_Traffic_Light_CE);
      BT : constant Payoff :=
        Expected_Payoff_Row (G, Chicken_Better_CE);
      MX : constant Payoff :=
        Expected_Payoff_Row (G, Chicken_Mixed_Nash_Product);
   begin
      Check (Near (TL, Pf (5.0)), "rank TL=5");
      Check (Near (BT, Pf (5.25)), "rank BT=5.25");
      Check (Near (MX, Pf (14.0 / 3.0)), "rank MX=14/3");
      Check (BT > TL and then TL > MX, "BT > TL > mixed Nash");
   end;

   ---------------------------------------------------------------------
   Section ("29. Zero-sum Matching Pennies payoff sum");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Matching_Pennies;
      MX : constant Distribution := Matching_Pennies_Mixed_Nash;
      U  : constant Distribution := Uniform_Distribution (AC (2), AC (2));
   begin
      Check (Near (Expected_Payoff_Row (G, MX)
                   + Expected_Payoff_Col (G, MX), Pf (0.0)),
             "MP mixed sum 0");
      Check (Near (Expected_Payoff_Row (G, U)
                   + Expected_Payoff_Col (G, U), Pf (0.0)),
             "MP uniform sum 0");
      --  Uniform equals mixed Nash product for MP
      Check (Is_Correlated_Equilibrium (G, U), "MP uniform is CE");
   end;

   ---------------------------------------------------------------------
   Section ("30. Extra product / CE cross checks");
   ---------------------------------------------------------------------
   declare
      G : constant Game := Pure_Coordination;
      P : constant Mixed_Strategy (1 .. 2) := [1.0, 0.0];
      Q : constant Mixed_Strategy (1 .. 2) := [0.0, 1.0];
      Off : constant Distribution := Product_Distribution (P, Q);
      On  : constant Distribution := Product_Distribution (P, P);
   begin
      Check (not Is_Correlated_Equilibrium (G, Off),
             "coord product off-diag not CE");
      Check (Is_Correlated_Equilibrium (G, On),
             "coord product (A,A) CE");
      Check (Is_Nash_Product (G, On), "coord (A,A) Nash product");
      Check (Is_Nash_Product (G, P, P), "coord pure A Nash");
      Check (not Is_Nash_Product (G, P, Q), "coord mismatched pure not Nash");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("RESULT: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   Put_Line ("========================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
