pragma Ada_2022;

package body Correlated_Equilibrium is

   --------------------------------------------------------------------------
   -- Local helpers
   --------------------------------------------------------------------------

   procedure Check_Tol (Tol : Payoff) is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_Tol;

   procedure Check_Size (Rows, Cols : Action_Count) is
   begin
      if Rows = 0 or else Cols = 0 then
         raise Invalid_Argument;
      end if;
   end Check_Size;

   procedure Check_Action
     (A : Action_Id; Bound : Action_Count) is
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

   function Is_Prob_Vector
     (P : Mixed_Strategy; Tol : Payoff) return Boolean
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
   end Is_Prob_Vector;

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
   -- Distribution helpers
   --------------------------------------------------------------------------

   function Total_Mass (D : Distribution) return Probability is
      S : Probability := 0.0;
   begin
      for R in 1 .. D.Rows loop
         for C in 1 .. D.Cols loop
            S := S + D.Mu (R, C);
         end loop;
      end loop;
      return S;
   end Total_Mass;

   function Is_Nonnegative
     (D : Distribution; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      for R in 1 .. D.Rows loop
         for C in 1 .. D.Cols loop
            if D.Mu (R, C) < -Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Nonnegative;

   function Is_Probability_Distribution
     (D : Distribution; Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if D.Rows = 0 or else D.Cols = 0 then
         return False;
      end if;
      return Is_Nonnegative (D, Tol)
        and then Abs_Val (Total_Mass (D) - 1.0) <= Tol;
   end Is_Probability_Distribution;

   function Normalize (D : Distribution) return Distribution is
      M      : constant Probability := Total_Mass (D);
      Result : Distribution (D.Rows, D.Cols);
   begin
      Check_Size (D.Rows, D.Cols);
      if M <= 0.0 then
         raise Invalid_Argument;
      end if;
      for R in 1 .. D.Rows loop
         for C in 1 .. D.Cols loop
            Result.Mu (R, C) := D.Mu (R, C) / M;
         end loop;
      end loop;
      return Result;
   end Normalize;

   function Pure_Distribution
     (Rows, Cols : Action_Count;
      Row_Action, Col_Action : Action_Id) return Distribution
   is
      Result : Distribution (Rows, Cols);
   begin
      Check_Size (Rows, Cols);
      Check_Action (Row_Action, Rows);
      Check_Action (Col_Action, Cols);
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            Result.Mu (R, C) := 0.0;
         end loop;
      end loop;
      Result.Mu (Row_Action, Col_Action) := 1.0;
      return Result;
   end Pure_Distribution;

   function Uniform_Distribution
     (Rows, Cols : Action_Count) return Distribution
   is
      Result : Distribution (Rows, Cols);
      N      : constant Probability :=
        Probability (Integer (Rows) * Integer (Cols));
      P      : Probability;
   begin
      Check_Size (Rows, Cols);
      P := 1.0 / N;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            Result.Mu (R, C) := P;
         end loop;
      end loop;
      return Result;
   end Uniform_Distribution;

   function Product_Distribution
     (P_Row : Mixed_Strategy; P_Col : Mixed_Strategy) return Distribution
   is
      Rows : constant Action_Count := Action_Count (P_Row'Length);
      Cols : constant Action_Count := Action_Count (P_Col'Length);
      Result : Distribution (Rows, Cols);
   begin
      if P_Row'Length = 0 or else P_Col'Length = 0 then
         raise Invalid_Argument;
      end if;
      if P_Row'First /= 1 or else P_Col'First /= 1 then
         raise Invalid_Argument;
      end if;
      if Integer (P_Row'Last) > Max_Actions
        or else Integer (P_Col'Last) > Max_Actions
      then
         raise Invalid_Argument;
      end if;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            Result.Mu (R, C) := P_Row (R) * P_Col (C);
         end loop;
      end loop;
      return Result;
   end Product_Distribution;

   function Row_Marginal
     (D : Distribution; R : Action_Id) return Probability
   is
      S : Probability := 0.0;
   begin
      Check_Size (D.Rows, D.Cols);
      Check_Action (R, D.Rows);
      for C in 1 .. D.Cols loop
         S := S + D.Mu (R, C);
      end loop;
      return S;
   end Row_Marginal;

   function Col_Marginal
     (D : Distribution; C : Action_Id) return Probability
   is
      S : Probability := 0.0;
   begin
      Check_Size (D.Rows, D.Cols);
      Check_Action (C, D.Cols);
      for R in 1 .. D.Rows loop
         S := S + D.Mu (R, C);
      end loop;
      return S;
   end Col_Marginal;

   function Is_Product_Distribution
     (D   : Distribution;
      Tol : Payoff := Default_Tol) return Boolean
   is
      Mass : Probability;
   begin
      Check_Tol (Tol);
      if not Is_Probability_Distribution (D, Tol) then
         return False;
      end if;
      Mass := Total_Mass (D);
      if Mass <= 0.0 then
         return False;
      end if;
      for R in 1 .. D.Rows loop
         for C in 1 .. D.Cols loop
            declare
               Pred : constant Probability :=
                 Row_Marginal (D, R) * Col_Marginal (D, C);
            begin
               if Abs_Val (D.Mu (R, C) - Pred) > Tol then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Is_Product_Distribution;

   --------------------------------------------------------------------------
   -- Compatibility / expected payoffs
   --------------------------------------------------------------------------

   procedure Require_Compatible (G : Game; D : Distribution) is
   begin
      Check_Size (G.Rows, G.Cols);
      if G.Rows /= D.Rows or else G.Cols /= D.Cols then
         raise Invalid_Argument;
      end if;
   end Require_Compatible;

   function Expected_Payoff_Row
     (G : Game; D : Distribution) return Payoff
   is
      S : Payoff := 0.0;
   begin
      Require_Compatible (G, D);
      for R in 1 .. G.Rows loop
         for C in 1 .. G.Cols loop
            S := S + D.Mu (R, C) * G.A (R, C);
         end loop;
      end loop;
      return S;
   end Expected_Payoff_Row;

   function Expected_Payoff_Col
     (G : Game; D : Distribution) return Payoff
   is
      S : Payoff := 0.0;
   begin
      Require_Compatible (G, D);
      for R in 1 .. G.Rows loop
         for C in 1 .. G.Cols loop
            S := S + D.Mu (R, C) * G.B (R, C);
         end loop;
      end loop;
      return S;
   end Expected_Payoff_Col;

   --------------------------------------------------------------------------
   -- Incentive gaps / CE
   --------------------------------------------------------------------------

   function Row_Incentive_Gap
     (G : Game; D : Distribution; R, R_Alt : Action_Id) return Payoff
   is
      Gap : Payoff := 0.0;
   begin
      Require_Compatible (G, D);
      Check_Action (R, G.Rows);
      Check_Action (R_Alt, G.Rows);
      for C in 1 .. G.Cols loop
         Gap := Gap
           + D.Mu (R, C) * (G.A (R, C) - G.A (R_Alt, C));
      end loop;
      return Gap;
   end Row_Incentive_Gap;

   function Col_Incentive_Gap
     (G : Game; D : Distribution; C, C_Alt : Action_Id) return Payoff
   is
      Gap : Payoff := 0.0;
   begin
      Require_Compatible (G, D);
      Check_Action (C, G.Cols);
      Check_Action (C_Alt, G.Cols);
      for R in 1 .. G.Rows loop
         Gap := Gap
           + D.Mu (R, C) * (G.B (R, C) - G.B (R, C_Alt));
      end loop;
      return Gap;
   end Col_Incentive_Gap;

   function Max_Row_Violation
     (G : Game; D : Distribution) return Payoff
   is
      Worst : Payoff := 0.0;
   begin
      Require_Compatible (G, D);
      for R in 1 .. G.Rows loop
         for R_Alt in 1 .. G.Rows loop
            declare
               Gap : constant Payoff :=
                 Row_Incentive_Gap (G, D, R, R_Alt);
            begin
               if -Gap > Worst then
                  Worst := -Gap;
               end if;
            end;
         end loop;
      end loop;
      return Worst;
   end Max_Row_Violation;

   function Max_Col_Violation
     (G : Game; D : Distribution) return Payoff
   is
      Worst : Payoff := 0.0;
   begin
      Require_Compatible (G, D);
      for C in 1 .. G.Cols loop
         for C_Alt in 1 .. G.Cols loop
            declare
               Gap : constant Payoff :=
                 Col_Incentive_Gap (G, D, C, C_Alt);
            begin
               if -Gap > Worst then
                  Worst := -Gap;
               end if;
            end;
         end loop;
      end loop;
      return Worst;
   end Max_Col_Violation;

   function Max_Incentive_Violation
     (G : Game; D : Distribution) return Payoff
   is
   begin
      return Max_Payoff
        (Max_Row_Violation (G, D), Max_Col_Violation (G, D));
   end Max_Incentive_Violation;

   function Is_Correlated_Equilibrium
     (G   : Game;
      D   : Distribution;
      Tol : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      Require_Compatible (G, D);
      if not Is_Probability_Distribution (D, Tol) then
         return False;
      end if;
      return Max_Incentive_Violation (G, D) <= Tol;
   end Is_Correlated_Equilibrium;

   --------------------------------------------------------------------------
   -- Nash product
   --------------------------------------------------------------------------

   function Pure_Row_Vs_Mixed
     (G : Game; R : Action_Id; P_Col : Mixed_Strategy) return Payoff
   is
      S : Payoff := 0.0;
   begin
      for C in 1 .. G.Cols loop
         S := S + P_Col (C) * G.A (R, C);
      end loop;
      return S;
   end Pure_Row_Vs_Mixed;

   function Pure_Col_Vs_Mixed
     (G : Game; C : Action_Id; P_Row : Mixed_Strategy) return Payoff
   is
      S : Payoff := 0.0;
   begin
      for R in 1 .. G.Rows loop
         S := S + P_Row (R) * G.B (R, C);
      end loop;
      return S;
   end Pure_Col_Vs_Mixed;

   function Is_Best_Response_Row
     (G     : Game;
      P_Col : Mixed_Strategy;
      P_Row : Mixed_Strategy;
      Tol   : Payoff := Default_Tol) return Boolean
   is
      Best : Payoff;
   begin
      Check_Tol (Tol);
      Check_Size (G.Rows, G.Cols);
      if P_Row'First /= 1 or else P_Col'First /= 1 then
         raise Invalid_Argument;
      end if;
      if P_Row'Length /= Natural (G.Rows)
        or else P_Col'Length /= Natural (G.Cols)
      then
         raise Invalid_Argument;
      end if;
      Best := Pure_Row_Vs_Mixed (G, 1, P_Col);
      for R in 2 .. G.Rows loop
         Best := Max_Payoff (Best, Pure_Row_Vs_Mixed (G, R, P_Col));
      end loop;
      for R in 1 .. G.Rows loop
         if P_Row (R) > Tol then
            if Pure_Row_Vs_Mixed (G, R, P_Col) + Tol < Best then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Best_Response_Row;

   function Is_Best_Response_Col
     (G     : Game;
      P_Row : Mixed_Strategy;
      P_Col : Mixed_Strategy;
      Tol   : Payoff := Default_Tol) return Boolean
   is
      Best : Payoff;
   begin
      Check_Tol (Tol);
      Check_Size (G.Rows, G.Cols);
      if P_Row'First /= 1 or else P_Col'First /= 1 then
         raise Invalid_Argument;
      end if;
      if P_Row'Length /= Natural (G.Rows)
        or else P_Col'Length /= Natural (G.Cols)
      then
         raise Invalid_Argument;
      end if;
      Best := Pure_Col_Vs_Mixed (G, 1, P_Row);
      for C in 2 .. G.Cols loop
         Best := Max_Payoff (Best, Pure_Col_Vs_Mixed (G, C, P_Row));
      end loop;
      for C in 1 .. G.Cols loop
         if P_Col (C) > Tol then
            if Pure_Col_Vs_Mixed (G, C, P_Row) + Tol < Best then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Best_Response_Col;

   function Is_Nash_Product
     (G     : Game;
      P_Row, P_Col : Mixed_Strategy;
      Tol   : Payoff := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if not Is_Prob_Vector (P_Row, Tol)
        or else not Is_Prob_Vector (P_Col, Tol)
      then
         return False;
      end if;
      return Is_Best_Response_Row (G, P_Col, P_Row, Tol)
        and then Is_Best_Response_Col (G, P_Row, P_Col, Tol);
   end Is_Nash_Product;

   function Is_Nash_Product
     (G   : Game;
      D   : Distribution;
      Tol : Payoff := Default_Tol) return Boolean
   is
      P_Row : Mixed_Strategy (1 .. G.Rows);
      P_Col : Mixed_Strategy (1 .. G.Cols);
   begin
      Check_Tol (Tol);
      Require_Compatible (G, D);
      if not Is_Product_Distribution (D, Tol) then
         return False;
      end if;
      for R in 1 .. G.Rows loop
         P_Row (R) := Row_Marginal (D, R);
      end loop;
      for C in 1 .. G.Cols loop
         P_Col (C) := Col_Marginal (D, C);
      end loop;
      return Is_Nash_Product (G, P_Row, P_Col, Tol);
   end Is_Nash_Product;

   --------------------------------------------------------------------------
   -- Uniform over support / grid search
   --------------------------------------------------------------------------

   function Uniform_Over_Pure_Profiles
     (Rows, Cols : Action_Count;
      Profiles   : Probability_Matrix) return Distribution
   is
      Raw : Distribution (Rows, Cols);
   begin
      Check_Size (Rows, Cols);
      if Profiles'First (1) /= 1
        or else Profiles'First (2) /= 1
        or else Profiles'Last (1) /= Action_Id (Rows)
        or else Profiles'Last (2) /= Action_Id (Cols)
      then
         raise Invalid_Argument;
      end if;
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            if Profiles (R, C) < 0.0 then
               raise Invalid_Argument;
            end if;
            Raw.Mu (R, C) := Profiles (R, C);
         end loop;
      end loop;
      return Normalize (Raw);
   end Uniform_Over_Pure_Profiles;

   function Find_CE_Grid_2x2
     (G     : Game;
      Steps : Positive := 8;
      Tol   : Payoff := 1.0E-6) return Grid_CE_Result
   is
      Result : Grid_CE_Result;
      --  Parameterize a 2×2 probability simplex by three free nonnegative
      --  masses p,q,r with p+q+r ≤ 1; the fourth is 1−p−q−r.
      H      : Probability;
      P, Q, R, S : Probability;
      Cand   : Distribution (2, 2);
   begin
      Check_Tol (Tol);
      if G.Rows /= 2 or else G.Cols /= 2 then
         raise Invalid_Argument;
      end if;
      if Steps > 40 then
         raise Invalid_Argument;
      end if;
      Result.Found := False;
      Result.D := Uniform_Distribution (2, 2);
      H := 1.0 / Probability (Steps);
      for I in 0 .. Steps loop
         for J in 0 .. Steps - I loop
            for K in 0 .. Steps - I - J loop
               P := Probability (I) * H;
               Q := Probability (J) * H;
               R := Probability (K) * H;
               S := 1.0 - P - Q - R;
               if S >= -Tol then
                  if S < 0.0 then
                     S := 0.0;
                  end if;
                  Cand.Mu (1, 1) := P;
                  Cand.Mu (1, 2) := Q;
                  Cand.Mu (2, 1) := R;
                  Cand.Mu (2, 2) := S;
                  if Is_Correlated_Equilibrium (G, Cand, Tol) then
                     Result.Found := True;
                     Result.D := Cand;
                     return Result;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
      return Result;
   end Find_CE_Grid_2x2;

   --------------------------------------------------------------------------
   -- Classic games
   --------------------------------------------------------------------------

   function Prisoners_Dilemma return Game is
      G : Game (2, 2);
   begin
      --  C=1, D=2
      G.A := [[3.0, 0.0], [5.0, 1.0]];
      G.B := [[3.0, 5.0], [0.0, 1.0]];
      return G;
   end Prisoners_Dilemma;

   function Chicken return Game is
      G : Game (2, 2);
   begin
      --  Dare=1, Chicken-out=2 (Wikipedia table)
      G.A := [[0.0, 7.0], [2.0, 6.0]];
      G.B := [[0.0, 2.0], [7.0, 6.0]];
      return G;
   end Chicken;

   function Matching_Pennies return Game is
      G : Game (2, 2);
   begin
      G.A := [[1.0, -1.0], [-1.0, 1.0]];
      G.B := [[-1.0, 1.0], [1.0, -1.0]];
      return G;
   end Matching_Pennies;

   function Battle_Of_Sexes return Game is
      G : Game (2, 2);
   begin
      --  Opera=1, Fight=2
      G.A := [[2.0, 0.0], [0.0, 1.0]];
      G.B := [[1.0, 0.0], [0.0, 2.0]];
      return G;
   end Battle_Of_Sexes;

   function Pure_Coordination return Game is
      G : Game (2, 2);
   begin
      G.A := [[1.0, 0.0], [0.0, 1.0]];
      G.B := [[1.0, 0.0], [0.0, 1.0]];
      return G;
   end Pure_Coordination;

   --------------------------------------------------------------------------
   -- Classic distributions
   --------------------------------------------------------------------------

   function PD_Defect_Defect return Distribution is
   begin
      return Pure_Distribution (2, 2, 2, 2);
   end PD_Defect_Defect;

   function Chicken_Traffic_Light_CE return Distribution is
      D : Distribution (2, 2);
   begin
      --  Dare=1, Chicken=2; mass on (C,C),(D,C),(C,D)
      D.Mu := [[0.0, 1.0 / 3.0], [1.0 / 3.0, 1.0 / 3.0]];
      return D;
   end Chicken_Traffic_Light_CE;

   function Chicken_Better_CE return Distribution is
      D : Distribution (2, 2);
   begin
      D.Mu := [[0.0, 0.25], [0.25, 0.5]];
      return D;
   end Chicken_Better_CE;

   function Chicken_Mixed_Nash_Product return Distribution is
      --  Each plays Chicken-out (action 2) with probability 2/3
      P : constant Mixed_Strategy (1 .. 2) :=
        [1.0 / 3.0, 2.0 / 3.0];
   begin
      return Product_Distribution (P, P);
   end Chicken_Mixed_Nash_Product;

   function Matching_Pennies_Mixed_Nash return Distribution is
      P : constant Mixed_Strategy (1 .. 2) := [0.5, 0.5];
   begin
      return Product_Distribution (P, P);
   end Matching_Pennies_Mixed_Nash;

   function BoS_Pure_Opera return Distribution is
   begin
      return Pure_Distribution (2, 2, 1, 1);
   end BoS_Pure_Opera;

   function BoS_Pure_Fight return Distribution is
   begin
      return Pure_Distribution (2, 2, 2, 2);
   end BoS_Pure_Fight;

   function Coordination_Diagonal_CE return Distribution is
      Mask : constant Probability_Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 0.0], [0.0, 1.0]];
   begin
      return Uniform_Over_Pure_Profiles (2, 2, Mask);
   end Coordination_Diagonal_CE;

end Correlated_Equilibrium;
