--  Vickrey_Clarke_Groves_Mechanism body — efficient outcome, Clarke
--  pivot payments, Vickrey / public-project / two-item specialisations.

pragma Ada_2022;

package body Vickrey_Clarke_Groves_Mechanism
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Validation helpers
   ---------------------------------------------------------------------------

   procedure Check_Tol (Tol : Money) is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_Tol;

   procedure Check_Matrix (V : Valuation_Matrix) is
   begin
      if V'Length (1) = 0 or else V'Length (2) = 0 then
         raise Invalid_Argument;
      end if;
      if V'First (1) /= 1 or else V'First (2) /= 1 then
         raise Invalid_Argument;
      end if;
      if V'Length (1) > Max_Agents or else V'Length (2) > Max_Outcomes then
         raise Invalid_Argument;
      end if;
   end Check_Matrix;

   procedure Check_Agent (V : Valuation_Matrix; I : Agent_Id) is
   begin
      Check_Matrix (V);
      if Natural (I) > V'Length (1) then
         raise Invalid_Argument;
      end if;
   end Check_Agent;

   procedure Check_Outcome (V : Valuation_Matrix; O : Outcome_Id) is
   begin
      Check_Matrix (V);
      if Natural (O) > V'Length (2) then
         raise Invalid_Argument;
      end if;
   end Check_Outcome;

   procedure Check_Vector_1 (X : Money_Vector) is
   begin
      if X'Length = 0 or else X'First /= 1 then
         raise Invalid_Argument;
      end if;
   end Check_Vector_1;

   procedure Check_Costs (V : Valuation_Matrix; Costs : Money_Vector) is
   begin
      Check_Matrix (V);
      if Costs'Length /= V'Length (2) or else Costs'First /= 1 then
         raise Invalid_Argument;
      end if;
   end Check_Costs;

   procedure Check_Weights (V : Valuation_Matrix; Weights : Money_Vector) is
   begin
      Check_Matrix (V);
      if Weights'Length /= V'Length (1) or else Weights'First /= 1 then
         raise Invalid_Argument;
      end if;
      for W of Weights loop
         if W <= 0.0 then
            raise Invalid_Argument;
         end if;
      end loop;
   end Check_Weights;

   function Cost_At
     (Costs : Money_Vector; O : Outcome_Id) return Money
   is
   begin
      if Costs'Length = 0 then
         return 0.0;
      end if;
      return Costs (Positive (O));
   end Cost_At;

   function Weight_At
     (Weights : Money_Vector; I : Agent_Id) return Money
   is
   begin
      if Weights'Length = 0 then
         return 1.0;
      end if;
      return Weights (Positive (I));
   end Weight_At;

   ---------------------------------------------------------------------------
   -- Core welfare / argmax (Skip = 0 means nobody omitted)
   ---------------------------------------------------------------------------

   function Welfare_At
     (V       : Valuation_Matrix;
      O       : Outcome_Id;
      Skip    : Natural;
      Weights : Money_Vector;
      Cost    : Money) return Money
   is
      S : Money := -Cost;
   begin
      for I in V'Range (1) loop
         if Natural (I) /= Skip then
            S := S + Weight_At (Weights, I) * V (I, O);
         end if;
      end loop;
      return S;
   end Welfare_At;

   function Best_Outcome
     (V       : Valuation_Matrix;
      Skip    : Natural;
      Weights : Money_Vector;
      Costs   : Money_Vector) return Outcome_Id
   is
      Best   : Outcome_Id := V'First (2);
      Best_W : Money;
   begin
      Best_W :=
        Welfare_At (V, Best, Skip, Weights, Cost_At (Costs, Best));
      for O in Outcome_Id'Succ (V'First (2)) .. V'Last (2) loop
         declare
            W : constant Money :=
              Welfare_At (V, O, Skip, Weights, Cost_At (Costs, O));
         begin
            if W > Best_W then
               Best   := O;
               Best_W := W;
            end if;
         end;
      end loop;
      return Best;
   end Best_Outcome;

   Empty_Weights : constant Money_Vector (1 .. 0) := [];
   Empty_Costs   : constant Money_Vector (1 .. 0) := [];

   ---------------------------------------------------------------------------
   -- Near
   ---------------------------------------------------------------------------

   function Near
     (A, B : Money; Tol : Money := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      return abs (A - B) <= Tol;
   end Near;

   function Near_Vector
     (A, B : Money_Vector; Tol : Money := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if A'First /= B'First or else A'Last /= B'Last then
         return False;
      end if;
      for I in A'Range loop
         if abs (A (I) - B (I)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Near_Vector;

   ---------------------------------------------------------------------------
   -- Matrix shape
   ---------------------------------------------------------------------------

   function N_Agents (V : Valuation_Matrix) return Positive is
   begin
      Check_Matrix (V);
      return V'Length (1);
   end N_Agents;

   function N_Outcomes (V : Valuation_Matrix) return Positive is
   begin
      Check_Matrix (V);
      return V'Length (2);
   end N_Outcomes;

   function Report
     (V : Valuation_Matrix; I : Agent_Id; O : Outcome_Id) return Money
   is
   begin
      Check_Agent (V, I);
      Check_Outcome (V, O);
      return V (I, O);
   end Report;

   ---------------------------------------------------------------------------
   -- Welfare
   ---------------------------------------------------------------------------

   function Social_Welfare
     (V : Valuation_Matrix; O : Outcome_Id) return Money
   is
   begin
      Check_Outcome (V, O);
      return Welfare_At (V, O, 0, Empty_Weights, 0.0);
   end Social_Welfare;

   function Others_Welfare
     (V : Valuation_Matrix; O : Outcome_Id; I : Agent_Id) return Money
   is
   begin
      Check_Agent (V, I);
      Check_Outcome (V, O);
      return Welfare_At (V, O, Natural (I), Empty_Weights, 0.0);
   end Others_Welfare;

   function Net_Welfare
     (V : Valuation_Matrix; O : Outcome_Id; Cost : Money) return Money
   is
   begin
      Check_Outcome (V, O);
      return Welfare_At (V, O, 0, Empty_Weights, Cost);
   end Net_Welfare;

   function Efficient_Outcome (V : Valuation_Matrix) return Outcome_Id is
   begin
      Check_Matrix (V);
      return Best_Outcome (V, 0, Empty_Weights, Empty_Costs);
   end Efficient_Outcome;

   function Efficient_Outcome
     (V : Valuation_Matrix; Costs : Money_Vector) return Outcome_Id
   is
   begin
      Check_Costs (V, Costs);
      return Best_Outcome (V, 0, Empty_Weights, Costs);
   end Efficient_Outcome;

   function Efficient_Outcome_Without
     (V : Valuation_Matrix; I : Agent_Id) return Outcome_Id
   is
   begin
      Check_Agent (V, I);
      return Best_Outcome (V, Natural (I), Empty_Weights, Empty_Costs);
   end Efficient_Outcome_Without;

   function Efficient_Outcome_Without
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Outcome_Id
   is
   begin
      Check_Agent (V, I);
      Check_Costs (V, Costs);
      return Best_Outcome (V, Natural (I), Empty_Weights, Costs);
   end Efficient_Outcome_Without;

   function Efficient_Welfare (V : Valuation_Matrix) return Money is
   begin
      return Social_Welfare (V, Efficient_Outcome (V));
   end Efficient_Welfare;

   function Efficient_Welfare
     (V : Valuation_Matrix; Costs : Money_Vector) return Money
   is
      O : constant Outcome_Id := Efficient_Outcome (V, Costs);
   begin
      return Social_Welfare (V, O) - Costs (Positive (O));
   end Efficient_Welfare;

   function Is_Welfare_Maximizing
     (V   : Valuation_Matrix;
      O   : Outcome_Id;
      Tol : Money := Default_Tol) return Boolean
   is
   begin
      return Near (Social_Welfare (V, O), Efficient_Welfare (V), Tol);
   end Is_Welfare_Maximizing;

   ---------------------------------------------------------------------------
   -- Clarke / VCG
   ---------------------------------------------------------------------------

   function Clarke_H
     (V : Valuation_Matrix; I : Agent_Id) return Money
   is
      O : Outcome_Id;
   begin
      Check_Agent (V, I);
      O := Best_Outcome (V, Natural (I), Empty_Weights, Empty_Costs);
      return Welfare_At (V, O, Natural (I), Empty_Weights, 0.0);
   end Clarke_H;

   function Clarke_H
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Money
   is
      O : Outcome_Id;
   begin
      Check_Agent (V, I);
      Check_Costs (V, Costs);
      O := Best_Outcome (V, Natural (I), Empty_Weights, Costs);
      return Welfare_At (V, O, Natural (I), Empty_Weights, Cost_At (Costs, O));
   end Clarke_H;

   function Clarke_Payment
     (V : Valuation_Matrix; I : Agent_Id) return Money
   is
      Star : Outcome_Id;
   begin
      Check_Agent (V, I);
      Star := Best_Outcome (V, 0, Empty_Weights, Empty_Costs);
      return Clarke_H (V, I)
        - Welfare_At (V, Star, Natural (I), Empty_Weights, 0.0);
   end Clarke_Payment;

   function Clarke_Payment
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Money
   is
      Star : Outcome_Id;
   begin
      Check_Agent (V, I);
      Check_Costs (V, Costs);
      Star := Best_Outcome (V, 0, Empty_Weights, Costs);
      return Clarke_H (V, I, Costs)
        - Welfare_At
            (V, Star, Natural (I), Empty_Weights, Cost_At (Costs, Star));
   end Clarke_Payment;

   function VCG_Payments (V : Valuation_Matrix) return Money_Vector is
      N : constant Positive := N_Agents (V);
      P : Money_Vector (1 .. N);
   begin
      for I in 1 .. N loop
         P (I) := Clarke_Payment (V, Agent_Id (I));
      end loop;
      return P;
   end VCG_Payments;

   function VCG_Payments
     (V : Valuation_Matrix; Costs : Money_Vector) return Money_Vector
   is
      N : constant Positive := N_Agents (V);
      P : Money_Vector (1 .. N);
   begin
      Check_Costs (V, Costs);
      for I in 1 .. N loop
         P (I) := Clarke_Payment (V, Agent_Id (I), Costs);
      end loop;
      return P;
   end VCG_Payments;

   function VCG_Utility
     (V : Valuation_Matrix; I : Agent_Id) return Money
   is
      Star : constant Outcome_Id := Efficient_Outcome (V);
   begin
      Check_Agent (V, I);
      return V (I, Star) - Clarke_Payment (V, I);
   end VCG_Utility;

   function VCG_Utility
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Money
   is
      Star : constant Outcome_Id := Efficient_Outcome (V, Costs);
   begin
      Check_Agent (V, I);
      return V (I, Star) - Clarke_Payment (V, I, Costs);
   end VCG_Utility;

   function VCG_Utilities (V : Valuation_Matrix) return Money_Vector is
      N : constant Positive := N_Agents (V);
      U : Money_Vector (1 .. N);
   begin
      for I in 1 .. N loop
         U (I) := VCG_Utility (V, Agent_Id (I));
      end loop;
      return U;
   end VCG_Utilities;

   function VCG_Utilities
     (V : Valuation_Matrix; Costs : Money_Vector) return Money_Vector
   is
      N : constant Positive := N_Agents (V);
      U : Money_Vector (1 .. N);
   begin
      for I in 1 .. N loop
         U (I) := VCG_Utility (V, Agent_Id (I), Costs);
      end loop;
      return U;
   end VCG_Utilities;

   function Changes_Outcome
     (V : Valuation_Matrix; I : Agent_Id) return Boolean
   is
   begin
      return Efficient_Outcome (V) /= Efficient_Outcome_Without (V, I);
   end Changes_Outcome;

   function Changes_Outcome
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector) return Boolean
   is
   begin
      return Efficient_Outcome (V, Costs)
        /= Efficient_Outcome_Without (V, I, Costs);
   end Changes_Outcome;

   function Is_Pivotal
     (V   : Valuation_Matrix;
      I   : Agent_Id;
      Tol : Money := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      return abs (Clarke_Payment (V, I)) > Tol;
   end Is_Pivotal;

   function Is_Pivotal
     (V     : Valuation_Matrix;
      I     : Agent_Id;
      Costs : Money_Vector;
      Tol   : Money := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      return abs (Clarke_Payment (V, I, Costs)) > Tol;
   end Is_Pivotal;

   ---------------------------------------------------------------------------
   -- Run
   ---------------------------------------------------------------------------

   function Fill_Result
     (V     : Valuation_Matrix;
      Star  : Outcome_Id;
      Pays  : Money_Vector;
      Wel   : Money) return Mechanism_Result
   is
      N : constant Natural := V'Length (1);
      R : Mechanism_Result;
   begin
      R.N       := Agent_Count (N);
      R.Chosen  := Star;
      R.Welfare := Wel;
      for I in 1 .. N loop
         R.Payments (I)  := Pays (I);
         R.Utilities (I) := V (Agent_Id (I), Star) - Pays (I);
      end loop;
      return R;
   end Fill_Result;

   function Run (V : Valuation_Matrix) return Mechanism_Result is
      Star : constant Outcome_Id := Efficient_Outcome (V);
   begin
      return Fill_Result
        (V, Star, VCG_Payments (V), Social_Welfare (V, Star));
   end Run;

   function Run
     (V : Valuation_Matrix; Costs : Money_Vector) return Mechanism_Result
   is
      Star : constant Outcome_Id := Efficient_Outcome (V, Costs);
   begin
      return Fill_Result
        (V, Star, VCG_Payments (V, Costs),
         Social_Welfare (V, Star) - Costs (Positive (Star)));
   end Run;

   function Total_Revenue (Payments : Money_Vector) return Money is
      S : Money := 0.0;
   begin
      if Payments'Length = 0 then
         raise Invalid_Argument;
      end if;
      for P of Payments loop
         S := S + P;
      end loop;
      return S;
   end Total_Revenue;

   function Payments_Nonnegative
     (Payments : Money_Vector; Tol : Money := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if Payments'Length = 0 then
         raise Invalid_Argument;
      end if;
      for P of Payments loop
         if P < -Tol then
            return False;
         end if;
      end loop;
      return True;
   end Payments_Nonnegative;

   function Is_Individually_Rational
     (Utilities : Money_Vector; Tol : Money := Default_Tol) return Boolean
   is
   begin
      Check_Tol (Tol);
      if Utilities'Length = 0 then
         raise Invalid_Argument;
      end if;
      for U of Utilities loop
         if U < -Tol then
            return False;
         end if;
      end loop;
      return True;
   end Is_Individually_Rational;

   ---------------------------------------------------------------------------
   -- Weighted VCG
   ---------------------------------------------------------------------------

   function Weighted_Social_Welfare
     (V       : Valuation_Matrix;
      O       : Outcome_Id;
      Weights : Money_Vector) return Money
   is
   begin
      Check_Outcome (V, O);
      Check_Weights (V, Weights);
      return Welfare_At (V, O, 0, Weights, 0.0);
   end Weighted_Social_Welfare;

   function Weighted_Efficient_Outcome
     (V       : Valuation_Matrix;
      Weights : Money_Vector) return Outcome_Id
   is
   begin
      Check_Weights (V, Weights);
      return Best_Outcome (V, 0, Weights, Empty_Costs);
   end Weighted_Efficient_Outcome;

   function Weighted_Clarke_Payment
     (V       : Valuation_Matrix;
      Weights : Money_Vector;
      I       : Agent_Id) return Money
   is
      Star     : Outcome_Id;
      H, Other : Money;
      W_I      : Money;
   begin
      Check_Agent (V, I);
      Check_Weights (V, Weights);
      W_I  := Weights (Positive (I));
      Star := Best_Outcome (V, 0, Weights, Empty_Costs);
      H    := Welfare_At
        (V,
         Best_Outcome (V, Natural (I), Weights, Empty_Costs),
         Natural (I), Weights, 0.0);
      Other := Welfare_At (V, Star, Natural (I), Weights, 0.0);
      return (H - Other) / W_I;
   end Weighted_Clarke_Payment;

   function Weighted_VCG_Payments
     (V : Valuation_Matrix; Weights : Money_Vector) return Money_Vector
   is
      N : constant Positive := N_Agents (V);
      P : Money_Vector (1 .. N);
   begin
      Check_Weights (V, Weights);
      for I in 1 .. N loop
         P (I) := Weighted_Clarke_Payment (V, Weights, Agent_Id (I));
      end loop;
      return P;
   end Weighted_VCG_Payments;

   function Weighted_Run
     (V : Valuation_Matrix; Weights : Money_Vector) return Mechanism_Result
   is
      Star : constant Outcome_Id := Weighted_Efficient_Outcome (V, Weights);
      Pays : constant Money_Vector := Weighted_VCG_Payments (V, Weights);
   begin
      return Fill_Result
        (V, Star, Pays, Social_Welfare (V, Star));
   end Weighted_Run;

   ---------------------------------------------------------------------------
   -- Report surgery
   ---------------------------------------------------------------------------

   function With_Agent_Report
     (V        : Valuation_Matrix;
      I        : Agent_Id;
      New_Vals : Money_Vector) return Valuation_Matrix
   is
      N : Positive;
      M : Positive;
   begin
      Check_Agent (V, I);
      N := V'Length (1);
      M := V'Length (2);
      if New_Vals'Length /= M or else New_Vals'First /= 1 then
         raise Invalid_Argument;
      end if;
      declare
         R : Valuation_Matrix (1 .. Agent_Id (N), 1 .. Outcome_Id (M)) := V;
      begin
         for O in 1 .. M loop
            R (I, Outcome_Id (O)) := New_Vals (O);
         end loop;
         return R;
      end;
   end With_Agent_Report;

   ---------------------------------------------------------------------------
   -- Vickrey auction helpers
   ---------------------------------------------------------------------------

   procedure Check_Bids (Bids : Money_Vector) is
   begin
      if Bids'Length = 0 or else Bids'First /= 1 then
         raise Invalid_Argument;
      end if;
      if Bids'Length > Max_Agents then
         raise Invalid_Argument;
      end if;
   end Check_Bids;

   function Highest_Bid (Bids : Money_Vector) return Money is
      H : Money;
   begin
      Check_Bids (Bids);
      H := Bids (1);
      for I in 2 .. Bids'Last loop
         if Bids (I) > H then
            H := Bids (I);
         end if;
      end loop;
      return H;
   end Highest_Bid;

   function Arg_Highest_Bid (Bids : Money_Vector) return Positive is
      K : Positive := 1;
   begin
      Check_Bids (Bids);
      for I in 2 .. Bids'Last loop
         if Bids (I) > Bids (K) then
            K := I;
         end if;
      end loop;
      return K;
   end Arg_Highest_Bid;

   function Second_Highest_Bid (Bids : Money_Vector) return Money is
      Win : Positive;
      S   : Money;
   begin
      Check_Bids (Bids);
      if Bids'Length = 1 then
         return 0.0;
      end if;
      Win := Arg_Highest_Bid (Bids);
      S   := Money'First;
      for I in Bids'Range loop
         if I /= Win and then Bids (I) > S then
            S := Bids (I);
         end if;
      end loop;
      return S;
   end Second_Highest_Bid;

   function Make_Single_Item_Valuations
     (Bids : Money_Vector) return Valuation_Matrix
   is
      N : Natural;
   begin
      Check_Bids (Bids);
      N := Bids'Length;
      declare
         V : Valuation_Matrix
           (1 .. Agent_Id (N), 1 .. Outcome_Id (N)) :=
           [others => [others => 0.0]];
      begin
         for I in 1 .. N loop
            V (Agent_Id (I), Outcome_Id (I)) := Bids (I);
         end loop;
         return V;
      end;
   end Make_Single_Item_Valuations;

   function Make_Single_Item_Valuations
     (Bids : Money_Vector; Reserve : Money) return Valuation_Matrix
   is
      N : Natural;
   begin
      Check_Bids (Bids);
      if Reserve < 0.0 then
         raise Invalid_Argument;
      end if;
      N := Bids'Length;
      if N + 1 > Max_Agents or else N + 1 > Max_Outcomes then
         raise Invalid_Argument;
      end if;
      declare
         V : Valuation_Matrix
           (1 .. Agent_Id (N + 1), 1 .. Outcome_Id (N + 1)) :=
           [others => [others => 0.0]];
      begin
         for I in 1 .. N loop
            V (Agent_Id (I), Outcome_Id (I)) := Bids (I);
         end loop;
         V (Agent_Id (N + 1), Outcome_Id (N + 1)) := Reserve;
         return V;
      end;
   end Make_Single_Item_Valuations;

   function Vickrey_Winner
     (Bids : Money_Vector; Reserve : Money := 0.0) return Natural
   is
      K : Positive;
   begin
      Check_Bids (Bids);
      if Reserve < 0.0 then
         raise Invalid_Argument;
      end if;
      K := Arg_Highest_Bid (Bids);
      if Bids (K) < Reserve then
         return 0;
      end if;
      return K;
   end Vickrey_Winner;

   function Vickrey_Price
     (Bids : Money_Vector; Reserve : Money := 0.0) return Money
   is
      W : Natural;
      S : Money;
   begin
      W := Vickrey_Winner (Bids, Reserve);
      if W = 0 then
         return 0.0;
      end if;
      if Bids'Length = 1 then
         return Reserve;
      end if;
      S := 0.0;
      for I in Bids'Range loop
         if I /= W and then Bids (I) > S then
            S := Bids (I);
         end if;
      end loop;
      if S < Reserve then
         return Reserve;
      end if;
      return S;
   end Vickrey_Price;

   function Vickrey_Auction
     (Bids : Money_Vector; Reserve : Money := 0.0) return Mechanism_Result
   is
      N      : Natural;
      Winner : Natural;
      Price  : Money;
   begin
      Check_Bids (Bids);
      if Reserve < 0.0 then
         raise Invalid_Argument;
      end if;
      N      := Bids'Length;
      Winner := Vickrey_Winner (Bids, Reserve);
      Price  := Vickrey_Price (Bids, Reserve);
      declare
         R : Mechanism_Result;
      begin
         R.N := Agent_Count (N);
         if Winner = 0 then
            R.Chosen  := Outcome_Id (N + 1);
            R.Welfare := Reserve;
         else
            R.Chosen  := Outcome_Id (Winner);
            R.Welfare := Bids (Winner);
         end if;
         for I in 1 .. N loop
            if Winner /= 0 and then I = Winner then
               R.Payments (I)  := Price;
               R.Utilities (I) := Bids (I) - Price;
            else
               R.Payments (I)  := 0.0;
               R.Utilities (I) := 0.0;
            end if;
         end loop;
         return R;
      end;
   end Vickrey_Auction;

   ---------------------------------------------------------------------------
   -- Binary choice / public project
   ---------------------------------------------------------------------------

   function Make_Binary_Choice
     (Pref_Alt : Money_Vector) return Valuation_Matrix
   is
      N : Natural;
   begin
      Check_Vector_1 (Pref_Alt);
      if Pref_Alt'Length > Max_Agents then
         raise Invalid_Argument;
      end if;
      N := Pref_Alt'Length;
      declare
         V : Valuation_Matrix
           (1 .. Agent_Id (N), 1 .. 2) := [others => [others => 0.0]];
      begin
         for I in 1 .. N loop
            V (Agent_Id (I), 2) := Pref_Alt (I);
         end loop;
         return V;
      end;
   end Make_Binary_Choice;

   function Make_Public_Project
     (Values : Money_Vector) return Valuation_Matrix
   is
   begin
      return Make_Binary_Choice (Values);
   end Make_Public_Project;

   function Project_Costs (Cost : Money) return Money_Vector is
   begin
      return [1 => 0.0, 2 => Cost];
   end Project_Costs;

   function Should_Build
     (Values : Money_Vector; Cost : Money) return Boolean
   is
      V : constant Valuation_Matrix := Make_Public_Project (Values);
      C : constant Money_Vector := Project_Costs (Cost);
   begin
      return Efficient_Outcome (V, C) = 2;
   end Should_Build;

   function Public_Project_Tax
     (Values : Money_Vector;
      Cost   : Money;
      I      : Agent_Id) return Money
   is
      V : constant Valuation_Matrix := Make_Public_Project (Values);
   begin
      return Clarke_Payment (V, I, Project_Costs (Cost));
   end Public_Project_Tax;

   function Public_Project
     (Values : Money_Vector; Cost : Money) return Mechanism_Result
   is
      V : constant Valuation_Matrix := Make_Public_Project (Values);
   begin
      return Run (V, Project_Costs (Cost));
   end Public_Project;

   ---------------------------------------------------------------------------
   -- Two-item combinatorial toy
   ---------------------------------------------------------------------------

   function Two_Item_Outcome_Count (N : Positive) return Positive is
      C : Natural;
   begin
      if N > Max_Agents then
         raise Invalid_Argument;
      end if;
      C := (N + 1) * (N + 1);
      if C = 0 or else C > Max_Outcomes then
         raise Invalid_Argument;
      end if;
      return C;
   end Two_Item_Outcome_Count;

   function Two_Item_Outcome
     (Owner_A, Owner_B : Natural; N : Positive) return Outcome_Id
   is
   begin
      if Owner_A > N or else Owner_B > N then
         raise Invalid_Argument;
      end if;
      declare
         Unused : constant Positive := Two_Item_Outcome_Count (N);
         pragma Unreferenced (Unused);
      begin
         return Outcome_Id (Owner_A * (N + 1) + Owner_B + 1);
      end;
   end Two_Item_Outcome;

   procedure Decode_Two_Item_Outcome
     (O                : Outcome_Id;
      N                : Positive;
      Owner_A, Owner_B : out Natural)
   is
      Idx : Natural;
      Modulus : Positive;
   begin
      declare
         Unused : constant Positive := Two_Item_Outcome_Count (N);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
      if Natural (O) > (N + 1) * (N + 1) then
         raise Invalid_Argument;
      end if;
      Idx     := Natural (O) - 1;
      Modulus := N + 1;
      Owner_A := Idx / Modulus;
      Owner_B := Idx mod Modulus;
   end Decode_Two_Item_Outcome;

   function Bundle_Of (Owner_A, Owner_B, I : Natural) return Bundle is
      Has_A : constant Boolean := Owner_A = I;
      Has_B : constant Boolean := Owner_B = I;
   begin
      if Has_A and Has_B then
         return Both;
      elsif Has_A then
         return A_Only;
      elsif Has_B then
         return B_Only;
      else
         return Empty;
      end if;
   end Bundle_Of;

   function Make_Two_Item_Valuations
     (Reports : Agent_Bundles) return Valuation_Matrix
   is
      N : Natural;
      M : Positive;
   begin
      if Reports'Length = 0 or else Reports'First /= 1 then
         raise Invalid_Argument;
      end if;
      N := Reports'Length;
      M := Two_Item_Outcome_Count (Positive (N));
      declare
         V : Valuation_Matrix
           (1 .. Agent_Id (N), 1 .. Outcome_Id (M)) :=
           [others => [others => 0.0]];
         OA, OB : Natural;
      begin
         for O in 1 .. M loop
            Decode_Two_Item_Outcome (Outcome_Id (O), N, OA, OB);
            for I in 1 .. N loop
               V (Agent_Id (I), Outcome_Id (O)) :=
                 Reports (I) (Bundle_Of (OA, OB, I));
            end loop;
         end loop;
         return V;
      end;
   end Make_Two_Item_Valuations;

   function Two_Item_Allocation
     (Reports : Agent_Bundles) return Mechanism_Result
   is
   begin
      return Run (Make_Two_Item_Valuations (Reports));
   end Two_Item_Allocation;

   ---------------------------------------------------------------------------
   -- Instance builder
   ---------------------------------------------------------------------------

   procedure Clear
     (Inst : in out Instance; Agents, Outcomes : Natural)
   is
   begin
      if Agents > Max_Agents or else Outcomes > Max_Outcomes then
         raise Invalid_Argument;
      end if;
      Inst.N := Agent_Count (Agents);
      Inst.M := Outcome_Count (Outcomes);
      Inst.V := [others => [others => 0.0]];
      Inst.C := [others => 0.0];
   end Clear;

   function Size_Agents (Inst : Instance) return Agent_Count is
   begin
      return Inst.N;
   end Size_Agents;

   function Size_Outcomes (Inst : Instance) return Outcome_Count is
   begin
      return Inst.M;
   end Size_Outcomes;

   procedure Check_Inst_Agent (Inst : Instance; I : Agent_Id) is
   begin
      if Inst.N = 0 or else Natural (I) > Natural (Inst.N) then
         raise Invalid_Argument;
      end if;
   end Check_Inst_Agent;

   procedure Check_Inst_Outcome (Inst : Instance; O : Outcome_Id) is
   begin
      if Inst.M = 0 or else Natural (O) > Natural (Inst.M) then
         raise Invalid_Argument;
      end if;
   end Check_Inst_Outcome;

   procedure Set_Value
     (Inst : in out Instance;
      I    : Agent_Id;
      O    : Outcome_Id;
      X    : Money)
   is
   begin
      Check_Inst_Agent (Inst, I);
      Check_Inst_Outcome (Inst, O);
      Inst.V (I, O) := X;
   end Set_Value;

   function Get_Value
     (Inst : Instance; I : Agent_Id; O : Outcome_Id) return Money
   is
   begin
      Check_Inst_Agent (Inst, I);
      Check_Inst_Outcome (Inst, O);
      return Inst.V (I, O);
   end Get_Value;

   procedure Set_Cost
     (Inst : in out Instance; O : Outcome_Id; C : Money)
   is
   begin
      Check_Inst_Outcome (Inst, O);
      Inst.C (Positive (O)) := C;
   end Set_Cost;

   function Get_Cost (Inst : Instance; O : Outcome_Id) return Money is
   begin
      Check_Inst_Outcome (Inst, O);
      return Inst.C (Positive (O));
   end Get_Cost;

   function As_Matrix (Inst : Instance) return Valuation_Matrix is
   begin
      if Inst.N = 0 or else Inst.M = 0 then
         raise Invalid_Argument;
      end if;
      declare
         R : Valuation_Matrix
           (1 .. Agent_Id (Inst.N), 1 .. Outcome_Id (Inst.M));
      begin
         for I in R'Range (1) loop
            for O in R'Range (2) loop
               R (I, O) := Inst.V (I, O);
            end loop;
         end loop;
         return R;
      end;
   end As_Matrix;

   function Costs_Of (Inst : Instance) return Money_Vector is
   begin
      if Inst.M = 0 then
         raise Invalid_Argument;
      end if;
      return Inst.C (1 .. Positive (Inst.M));
   end Costs_Of;

   function Run (Inst : Instance) return Mechanism_Result is
   begin
      return Run (As_Matrix (Inst), Costs_Of (Inst));
   end Run;

end Vickrey_Clarke_Groves_Mechanism;
