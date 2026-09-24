--  Standalone test suite for Vickrey_Clarke_Groves_Mechanism.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Vickrey_Clarke_Groves_Mechanism; use Vickrey_Clarke_Groves_Mechanism;

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
   function Ag (X : Positive) return Agent_Id is (Agent_Id (X));
   function Oc (X : Positive) return Outcome_Id is (Outcome_Id (X));
   function Mo (X : Money) return Money is (X);

   function Img (X : Integer) return String is
      S : constant String := Integer'Image (X);
   begin
      if S'Length > 0 and then S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      end if;
      return S;
   end Img;

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   function M22
     (A11, A12, A21, A22 : Money) return Valuation_Matrix
   is
      V : Valuation_Matrix (1 .. 2, 1 .. 2);
   begin
      V (1, 1) := A11;
      V (1, 2) := A12;
      V (2, 1) := A21;
      V (2, 2) := A22;
      return V;
   end M22;

   function M23
     (A11, A12, A13, A21, A22, A23 : Money) return Valuation_Matrix
   is
      V : Valuation_Matrix (1 .. 2, 1 .. 3);
   begin
      V (1, 1) := A11;
      V (1, 2) := A12;
      V (1, 3) := A13;
      V (2, 1) := A21;
      V (2, 2) := A22;
      V (2, 3) := A23;
      return V;
   end M23;

   function M32
     (A11, A12, A21, A22, A31, A32 : Money) return Valuation_Matrix
   is
      V : Valuation_Matrix (1 .. 3, 1 .. 2);
   begin
      V (1, 1) := A11;
      V (1, 2) := A12;
      V (2, 1) := A21;
      V (2, 2) := A22;
      V (3, 1) := A31;
      V (3, 2) := A32;
      return V;
   end M32;

   function Row2 (A, B : Money) return Money_Vector is
   begin
      return [1 => A, 2 => B];
   end Row2;

   function Row3 (A, B, C : Money) return Money_Vector is
   begin
      return [1 => A, 2 => B, 3 => C];
   end Row3;

   function True_U
     (True_V : Valuation_Matrix;
      Rep    : Valuation_Matrix;
      I      : Agent_Id) return Money
   is
      Star : constant Outcome_Id := Efficient_Outcome (Rep);
   begin
      return True_V (I, Star) - Clarke_Payment (Rep, I);
   end True_U;

   function True_U_C
     (True_V : Valuation_Matrix;
      Rep    : Valuation_Matrix;
      Costs  : Money_Vector;
      I      : Agent_Id) return Money
   is
      Star : constant Outcome_Id := Efficient_Outcome (Rep, Costs);
   begin
      return True_V (I, Star) - Clarke_Payment (Rep, I, Costs);
   end True_U_C;

   ---------------------------------------------------------------------------
   -- Exception helpers
   ---------------------------------------------------------------------------

   function Near_Raises (Tol : Money) return Boolean is
      Unused : Boolean;
   begin
      Unused := Near (0.0, 0.0, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Near_Raises;

   function NV_Raises (Tol : Money) return Boolean is
      Unused : Boolean;
      A      : constant Money_Vector := [1 => 0.0];
   begin
      Unused := Near_Vector (A, A, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end NV_Raises;

   function Welfare_O_Raises
     (V : Valuation_Matrix; O : Outcome_Id) return Boolean
   is
      Unused : Money;
   begin
      Unused := Social_Welfare (V, O);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Welfare_O_Raises;

   function Clarke_I_Raises
     (V : Valuation_Matrix; I : Agent_Id) return Boolean
   is
      Unused : Money;
   begin
      Unused := Clarke_Payment (V, I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clarke_I_Raises;

   function Eff_Costs_Raises
     (V : Valuation_Matrix; C : Money_Vector) return Boolean
   is
      Unused : Outcome_Id;
   begin
      Unused := Efficient_Outcome (V, C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Eff_Costs_Raises;

   function Weights_Raises
     (V : Valuation_Matrix; W : Money_Vector) return Boolean
   is
      Unused : Outcome_Id;
   begin
      Unused := Weighted_Efficient_Outcome (V, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Weights_Raises;

   function Bids_Raises (B : Money_Vector) return Boolean is
      Unused : Money;
   begin
      Unused := Highest_Bid (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Bids_Raises;

   function Reserve_Raises
     (B : Money_Vector; R : Money) return Boolean
   is
      Unused : Natural;
   begin
      Unused := Vickrey_Winner (B, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reserve_Raises;

   function Binary_Raises (P : Money_Vector) return Boolean is
   begin
      declare
         V : constant Valuation_Matrix := Make_Binary_Choice (P);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Binary_Raises;

   function Two_Item_Count_Raises (N : Positive) return Boolean is
      Unused : Positive;
   begin
      Unused := Two_Item_Outcome_Count (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Two_Item_Count_Raises;

   function Clear_Raises (A, O : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, A, O);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function As_Matrix_Raises (A, O : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, A, O);
      declare
         V : constant Valuation_Matrix := As_Matrix (Inst);
         pragma Unreferenced (V);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end As_Matrix_Raises;

   function Set_Value_Raises
     (A, O : Natural; I : Agent_Id; K : Outcome_Id) return Boolean
   is
      Inst : Instance;
   begin
      Clear (Inst, A, O);
      Set_Value (Inst, I, K, 1.0);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Value_Raises;

   function Report_Row_Raises
     (V : Valuation_Matrix; I : Agent_Id; Row : Money_Vector) return Boolean
   is
   begin
      declare
         R : constant Valuation_Matrix := With_Agent_Report (V, I, Row);
         pragma Unreferenced (R);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Report_Row_Raises;

   function Revenue_Raises return Boolean is
      Empty : Money_Vector (1 .. 0);
      Unused : Money;
   begin
      Unused := Total_Revenue (Empty);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Revenue_Raises;

   function IR_Raises (Tol : Money) return Boolean is
      U      : constant Money_Vector := [1 => 0.0];
      Unused : Boolean;
   begin
      Unused := Is_Individually_Rational (U, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end IR_Raises;

   function Offset_Matrix_Raises return Boolean is
      V : constant Valuation_Matrix (2 .. 3, 1 .. 2) :=
        [others => [others => 0.0]];
      Unused : Positive;
   begin
      Unused := N_Agents (V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Offset_Matrix_Raises;

   function Offset_Bids_Raises return Boolean is
      B : constant Money_Vector (2 .. 3) := [2 => 1.0, 3 => 2.0];
      Unused : Money;
   begin
      Unused := Highest_Bid (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Offset_Bids_Raises;

   ---------------------------------------------------------------------------
   -- 1. Near
   ---------------------------------------------------------------------------

begin
   Section ("1. Near / tolerances");

   Check (Near (Mo (0.0), Mo (0.0)), "Near 0 0");
   Check (Near (Mo (1.0), Mo (1.0)), "Near 1 1");
   Check (Near (Mo (1.0), Mo (1.0 + 1.0E-12)), "Near tiny delta");
   Check (not Near (Mo (1.0), Mo (2.0)), "not Near 1 2");
   Check (Near (Mo (-3.5), Mo (-3.5)), "Near negatives");
   Check (Near (Mo (5.0), Mo (5.2), Mo (0.25)), "Near custom tol");
   Check (not Near (Mo (5.0), Mo (5.2), Mo (0.1)), "not Near tight tol");
   Check (Near_Raises (Mo (-1.0)), "Near negative tol raises");
   Check (NV_Raises (Mo (-0.5)), "Near_Vector negative tol raises");
   declare
      A : constant Money_Vector := Row3 (1.0, 2.0, 3.0);
      B : constant Money_Vector := Row3 (1.0, 2.0, 3.0);
      C : constant Money_Vector := Row3 (1.0, 2.0, 9.0);
      D : constant Money_Vector := Row2 (1.0, 2.0);
   begin
      Check (Near_Vector (A, B), "Near_Vector equal");
      Check (not Near_Vector (A, C), "Near_Vector differs");
      Check (not Near_Vector (A, D), "Near_Vector length mismatch");
   end;

   ---------------------------------------------------------------------------
   -- 2. Validation
   ---------------------------------------------------------------------------

   Section ("2. Invalid_Argument");

   declare
      V : constant Valuation_Matrix := M22 (1.0, 0.0, 0.0, 1.0);
   begin
      Check (Welfare_O_Raises (V, Oc (3)), "welfare bad outcome");
      Check (Clarke_I_Raises (V, Ag (3)), "clarke bad agent");
      Check (Eff_Costs_Raises (V, Row3 (0.0, 0.0, 0.0)), "costs wrong len");
      Check (Eff_Costs_Raises (V, [2 => 0.0, 3 => 0.0]), "costs not 1-based");
      Check (Weights_Raises (V, Row3 (1.0, 1.0, 1.0)), "weights wrong len");
      Check (Weights_Raises (V, Row2 (1.0, 0.0)), "weight zero");
      Check (Weights_Raises (V, Row2 (1.0, -2.0)), "weight negative");
      Check (Report_Row_Raises (V, Ag (1), Row3 (0.0, 0.0, 0.0)),
             "report row wrong len");
      Check (Report_Row_Raises (V, Ag (3), Row2 (0.0, 0.0)),
             "report row bad agent");
   end;

   Check (Bids_Raises ([1 .. 0 => 0.0]), "empty bids");
   Check (Offset_Bids_Raises, "offset bids");
   Check (Reserve_Raises (Row2 (1.0, 2.0), Mo (-0.1)), "negative reserve");
   Check (Binary_Raises ([1 .. 0 => 0.0]), "empty binary");
   Check (Binary_Raises ([2 => 1.0, 3 => 2.0]), "offset binary");
   Check (Two_Item_Count_Raises (Pos (4)), "two-item N=4 too many outcomes");
   Check (Two_Item_Count_Raises (Pos (12)), "two-item N=12 too many");
   Check (Clear_Raises (Nat (13), Nat (2)), "Clear too many agents");
   Check (Clear_Raises (Nat (2), Nat (25)), "Clear too many outcomes");
   Check (As_Matrix_Raises (Nat (0), Nat (0)), "As_Matrix empty");
   Check (Set_Value_Raises (Nat (0), Nat (0), Ag (1), Oc (1)),
          "Set_Value empty");
   Check (Set_Value_Raises (Nat (2), Nat (2), Ag (3), Oc (1)),
          "Set_Value bad agent");
   Check (Set_Value_Raises (Nat (2), Nat (2), Ag (1), Oc (3)),
          "Set_Value bad outcome");
   Check (Revenue_Raises, "Total_Revenue empty");
   Check (IR_Raises (Mo (-1.0)), "IR negative tol");
   Check (Offset_Matrix_Raises, "non-1-based matrix");

   ---------------------------------------------------------------------------
   -- 3. Social welfare / efficient outcome
   ---------------------------------------------------------------------------

   Section ("3. Social welfare and efficient outcome");

   declare
      V : constant Valuation_Matrix := M22 (3.0, 1.0, 1.0, 4.0);
   begin
      Check (N_Agents (V) = Pos (2), "N_Agents 2");
      Check (N_Outcomes (V) = Pos (2), "N_Outcomes 2");
      Check (Near (Social_Welfare (V, Oc (1)), Mo (4.0)), "SW o1 = 4");
      Check (Near (Social_Welfare (V, Oc (2)), Mo (5.0)), "SW o2 = 5");
      Check (Efficient_Outcome (V) = Oc (2), "o* = 2");
      Check (Near (Efficient_Welfare (V), Mo (5.0)), "W* = 5");
      Check (Is_Welfare_Maximizing (V, Oc (2)), "o2 maximising");
      Check (not Is_Welfare_Maximizing (V, Oc (1)), "o1 not maximising");
      Check (Near (Others_Welfare (V, Oc (2), Ag (1)), Mo (4.0)),
             "others@o2 without 1");
      Check (Near (Others_Welfare (V, Oc (2), Ag (2)), Mo (1.0)),
             "others@o2 without 2");
      Check (Near (Report (V, Ag (1), Oc (1)), Mo (3.0)), "Report 1,1");
      Check (Near (Net_Welfare (V, Oc (2), Mo (1.5)), Mo (3.5)),
             "Net_Welfare minus 1.5");
   end;

   declare
      --  Tie: both outcomes SW = 5; lowest index wins.
      V : constant Valuation_Matrix := M22 (2.0, 4.0, 3.0, 1.0);
   begin
      Check (Near (Social_Welfare (V, Oc (1)), Mo (5.0)), "tie SW o1");
      Check (Near (Social_Welfare (V, Oc (2)), Mo (5.0)), "tie SW o2");
      Check (Efficient_Outcome (V) = Oc (1), "tie -> lowest index");
      Check (Is_Welfare_Maximizing (V, Oc (1)), "tie o1 max");
      Check (Is_Welfare_Maximizing (V, Oc (2)), "tie o2 also max");
   end;

   declare
      V : constant Valuation_Matrix :=
        M23 (1.0, 0.0, 5.0, 2.0, 4.0, 0.0);
      --  SW: 3, 4, 5 -> o* = 3
   begin
      Check (Efficient_Outcome (V) = Oc (3), "3-outcome o* = 3");
      Check (Near (Social_Welfare (V, Oc (1)), Mo (3.0)), "SW 3");
      Check (Near (Social_Welfare (V, Oc (2)), Mo (4.0)), "SW 4");
      Check (Near (Social_Welfare (V, Oc (3)), Mo (5.0)), "SW 5");
      Check (Efficient_Outcome_Without (V, Ag (1)) = Oc (2),
             "without 1 -> o2 (4 > 2 > 0)");
      Check (Efficient_Outcome_Without (V, Ag (2)) = Oc (3),
             "without 2 -> o3 (5 > 1 > 0)");
   end;

   --  Single agent, two outcomes
   declare
      V : Valuation_Matrix (1 .. 1, 1 .. 2);
   begin
      V (1, 1) := 2.0;
      V (1, 2) := 9.0;
      Check (Efficient_Outcome (V) = Oc (2), "single agent picks 2");
      Check (Near (Efficient_Welfare (V), Mo (9.0)), "single W* = 9");
      Check (Efficient_Outcome_Without (V, Ag (1)) = Oc (1),
             "single without self: lowest empty-welfare index");
   end;

   ---------------------------------------------------------------------------
   -- 4. Clarke payments (textbook 2x2)
   ---------------------------------------------------------------------------

   Section ("4. Clarke payments");

   declare
      --  v1 = (3,1), v2 = (1,4); o* = 2; p1 = 0; p2 = 2
      V : constant Valuation_Matrix := M22 (3.0, 1.0, 1.0, 4.0);
   begin
      Check (Near (Clarke_H (V, Ag (1)), Mo (4.0)), "h1 = 4");
      Check (Near (Clarke_H (V, Ag (2)), Mo (3.0)), "h2 = 3");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (0.0)), "p1 = 0");
      Check (Near (Clarke_Payment (V, Ag (2)), Mo (2.0)), "p2 = 2");
      Check (Near (VCG_Utility (V, Ag (1)), Mo (1.0)), "u1 = 1");
      Check (Near (VCG_Utility (V, Ag (2)), Mo (2.0)), "u2 = 2");
      Check (not Is_Pivotal (V, Ag (1)), "agent 1 not pivotal");
      Check (Is_Pivotal (V, Ag (2)), "agent 2 pivotal");
      Check (not Changes_Outcome (V, Ag (1)), "agent 1 same o*");
      Check (Changes_Outcome (V, Ag (2)), "agent 2 flips o*");
      declare
         P : constant Money_Vector := VCG_Payments (V);
         U : constant Money_Vector := VCG_Utilities (V);
      begin
         Check (Near_Vector (P, Row2 (0.0, 2.0)), "VCG_Payments (0,2)");
         Check (Near_Vector (U, Row2 (1.0, 2.0)), "VCG_Utilities (1,2)");
         Check (Near (Total_Revenue (P), Mo (2.0)), "revenue 2");
         Check (Payments_Nonnegative (P), "p >= 0");
         Check (Is_Individually_Rational (U), "IR");
      end;
   end;

   declare
      --  Symmetric: each wants a different outcome equally
      V : constant Valuation_Matrix := M22 (5.0, 0.0, 0.0, 5.0);
   begin
      Check (Efficient_Outcome (V) = Oc (1), "sym tie -> 1");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (5.0)), "p1 = 5 (flip)");
      Check (Near (Clarke_Payment (V, Ag (2)), Mo (0.0)), "p2 = 0");
      Check (Near (VCG_Utility (V, Ag (1)), Mo (0.0)), "u1 = 0");
      Check (Near (VCG_Utility (V, Ag (2)), Mo (0.0)), "u2 = 0");
   end;

   declare
      --  Three agents, two outcomes
      V : constant Valuation_Matrix :=
        M32 (4.0, 0.0, 3.0, 1.0, 1.0, 5.0);
      --  SW o1=8, o2=6 -> o*=1
      --  without 1: (3,6) -> o2, h1=6; others@o*=4; p1=2
      --  without 2: (5,5) -> o1, h2=5; others@o*=5; p2=0
      --  without 3: (7,1) -> o1, h3=7; others@o*=7; p3=0
   begin
      Check (Efficient_Outcome (V) = Oc (1), "3-agent o* = 1");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (2.0)), "3-agent p1=2");
      Check (Near (Clarke_Payment (V, Ag (2)), Mo (0.0)), "3-agent p2=0");
      Check (Near (Clarke_Payment (V, Ag (3)), Mo (0.0)), "3-agent p3=0");
      Check (Is_Pivotal (V, Ag (1)), "3-agent 1 pivotal");
      Check (not Is_Pivotal (V, Ag (2)), "3-agent 2 not");
      Check (not Is_Pivotal (V, Ag (3)), "3-agent 3 not");
   end;

   ---------------------------------------------------------------------------
   -- 5. Run consistency
   ---------------------------------------------------------------------------

   Section ("5. Run consistency");

   declare
      V : constant Valuation_Matrix := M22 (3.0, 1.0, 1.0, 4.0);
      R : constant Mechanism_Result := Run (V);
   begin
      Check (R.N = 2, "Run N=2");
      Check (R.Chosen = Oc (2), "Run chosen 2");
      Check (Near (R.Welfare, Mo (5.0)), "Run welfare 5");
      Check (Near (R.Payments (1), Mo (0.0)), "Run p1");
      Check (Near (R.Payments (2), Mo (2.0)), "Run p2");
      Check (Near (R.Utilities (1), Mo (1.0)), "Run u1");
      Check (Near (R.Utilities (2), Mo (2.0)), "Run u2");
      Check (Near (R.Utilities (1) + R.Utilities (2) +
                    Total_Revenue (R.Payments),
                   R.Welfare),
             "u + revenue = welfare");
   end;

   declare
      V : constant Valuation_Matrix :=
        M23 (2.0, 2.0, 2.0, 1.0, 3.0, 0.0);
      C : constant Money_Vector := Row3 (0.0, 1.0, 0.0);
      --  net: 3, 4, 2 -> o*=2
      R : constant Mechanism_Result := Run (V, C);
   begin
      Check (R.Chosen = Oc (2), "Run+cost chosen 2");
      Check (Near (R.Welfare, Mo (4.0)), "Run+cost net 4");
      Check (Near (Efficient_Welfare (V, C), Mo (4.0)), "Efficient_Welfare+C");
   end;

   ---------------------------------------------------------------------------
   -- 6. Vickrey auction
   ---------------------------------------------------------------------------

   Section ("6. Vickrey auction");

   declare
      B : constant Money_Vector := Row3 (10.0, 7.0, 3.0);
      R : constant Mechanism_Result := Vickrey_Auction (B);
      V : constant Valuation_Matrix := Make_Single_Item_Valuations (B);
      G : constant Mechanism_Result := Run (V);
   begin
      Check (Near (Highest_Bid (B), Mo (10.0)), "highest 10");
      Check (Near (Second_Highest_Bid (B), Mo (7.0)), "second 7");
      Check (Arg_Highest_Bid (B) = Pos (1), "arg max = 1");
      Check (Vickrey_Winner (B) = Nat (1), "winner 1");
      Check (Near (Vickrey_Price (B), Mo (7.0)), "price 7");
      Check (R.Chosen = Oc (1), "auction chosen 1");
      Check (Near (R.Payments (1), Mo (7.0)), "winner pays 7");
      Check (Near (R.Payments (2), Mo (0.0)), "loser 2 pays 0");
      Check (Near (R.Payments (3), Mo (0.0)), "loser 3 pays 0");
      Check (Near (R.Utilities (1), Mo (3.0)), "winner u=3");
      Check (Near (R.Utilities (2), Mo (0.0)), "loser u=0");
      Check (G.Chosen = R.Chosen, "generic VCG same winner");
      Check (Near_Vector (G.Payments, R.Payments), "generic VCG same prices");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (7.0)), "clarke = second");
      Check (Near (Clarke_Payment (V, Ag (2)), Mo (0.0)), "loser clarke 0");
   end;

   declare
      B : constant Money_Vector := [1 => 4.0];
      R : constant Mechanism_Result := Vickrey_Auction (B);
   begin
      Check (Vickrey_Winner (B) = Nat (1), "solo winner");
      Check (Near (Vickrey_Price (B), Mo (0.0)), "solo price 0");
      Check (Near (Second_Highest_Bid (B), Mo (0.0)), "solo second 0");
      Check (Near (R.Payments (1), Mo (0.0)), "solo pays 0");
      Check (Near (R.Utilities (1), Mo (4.0)), "solo u = bid");
   end;

   declare
      B : constant Money_Vector := Row2 (5.0, 5.0);
   begin
      Check (Vickrey_Winner (B) = Nat (1), "tie winner lowest index");
      Check (Near (Vickrey_Price (B), Mo (5.0)), "tie price = other bid");
   end;

   declare
      B : constant Money_Vector := Row3 (1.0, 8.0, 8.0);
   begin
      Check (Vickrey_Winner (B) = Nat (2), "first of two 8s");
      Check (Near (Vickrey_Price (B), Mo (8.0)), "price other 8");
   end;

   declare
      B : constant Money_Vector := Row3 (3.0, 6.0, 2.0);
      R : constant Mechanism_Result := Vickrey_Auction (B, Mo (10.0));
   begin
      Check (Vickrey_Winner (B, Mo (10.0)) = Nat (0), "reserve not met");
      Check (Near (Vickrey_Price (B, Mo (10.0)), Mo (0.0)), "unsold price 0");
      Check (R.Chosen = Oc (4), "unsold outcome N+1");
      Check (Near (R.Payments (1), Mo (0.0)), "unsold p1");
      Check (Near (R.Payments (2), Mo (0.0)), "unsold p2");
      Check (Near (R.Payments (3), Mo (0.0)), "unsold p3");
   end;

   declare
      B : constant Money_Vector := Row3 (3.0, 12.0, 7.0);
      R : constant Mechanism_Result := Vickrey_Auction (B, Mo (8.0));
      V : constant Valuation_Matrix :=
        Make_Single_Item_Valuations (B, Mo (8.0));
      G : constant Mechanism_Result := Run (V);
   begin
      Check (Vickrey_Winner (B, Mo (8.0)) = Nat (2), "reserve winner 2");
      Check (Near (Vickrey_Price (B, Mo (8.0)), Mo (8.0)),
             "price max(7,8)=8");
      Check (Near (R.Payments (2), Mo (8.0)), "winner pays reserve");
      Check (N_Agents (V) = Pos (4), "seller is agent 4");
      Check (N_Outcomes (V) = Pos (4), "unsold is outcome 4");
      Check (G.Chosen = Oc (2), "generic+reserve sells to 2");
      Check (Near (Clarke_Payment (V, Ag (2)), Mo (8.0)),
             "generic winner pays 8");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (0.0)),
             "generic loser 1 pays 0");
      Check (Near (Clarke_Payment (V, Ag (3)), Mo (0.0)),
             "generic loser 3 pays 0");
   end;

   declare
      B : constant Money_Vector := Row2 (0.0, 0.0);
   begin
      Check (Vickrey_Winner (B) = Nat (1), "zero bids -> 1");
      Check (Near (Vickrey_Price (B), Mo (0.0)), "zero bids price 0");
   end;

   ---------------------------------------------------------------------------
   -- 7. Vickrey truthfulness
   ---------------------------------------------------------------------------

   Section ("7. Vickrey truthfulness");

   declare
      True_Bids : constant Money_Vector := Row3 (10.0, 7.0, 3.0);
      Values    : constant Money_Vector := True_Bids;
   begin
      for Mis in 0 .. 8 loop
         declare
            Bid : constant Money := Money (Mis);
            Reported : Money_Vector := True_Bids;
            Truth    : constant Mechanism_Result :=
              Vickrey_Auction (True_Bids);
            Lie      : Mechanism_Result;
            U_True, U_Lie : Money;
         begin
            Reported (1) := Bid;
            Lie := Vickrey_Auction (Reported);
            --  True utility of agent 1: value 10 if wins, else 0, minus pay
            if Truth.Chosen = 1 then
               U_True := Values (1) - Truth.Payments (1);
            else
               U_True := 0.0;
            end if;
            if Lie.Chosen = 1 then
               U_Lie := Values (1) - Lie.Payments (1);
            else
               U_Lie := 0.0;
            end if;
            Check (U_Lie <= U_True + 1.0E-9,
                   "agent1 bid " & Img (Mis) & " not profitable");
         end;
      end loop;

      for Mis in 0 .. 8 loop
         declare
            Reported : Money_Vector := True_Bids;
            Truth    : constant Mechanism_Result :=
              Vickrey_Auction (True_Bids);
            Lie      : Mechanism_Result;
            U_True, U_Lie : Money;
         begin
            Reported (2) := Money (Mis);
            Lie := Vickrey_Auction (Reported);
            if Truth.Chosen = 2 then
               U_True := Values (2) - Truth.Payments (2);
            else
               U_True := 0.0;
            end if;
            if Lie.Chosen = 2 then
               U_Lie := Values (2) - Lie.Payments (2);
            else
               U_Lie := 0.0;
            end if;
            Check (U_Lie <= U_True + 1.0E-9,
                   "agent2 bid " & Img (Mis) & " not profitable");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------------
   -- 8. Public project
   ---------------------------------------------------------------------------

   Section ("8. Public project");

   declare
      --  C=10, values 6,5,4; sum=15>10 build; only 1 pivotal, tax=1
      Vals : constant Money_Vector := Row3 (6.0, 5.0, 4.0);
      R    : constant Mechanism_Result := Public_Project (Vals, Mo (10.0));
   begin
      Check (Should_Build (Vals, Mo (10.0)), "15>10 build");
      Check (not Should_Build (Vals, Mo (15.0)), "15=15 no (tie -> No)");
      Check (not Should_Build (Vals, Mo (16.0)), "15<16 no");
      Check (R.Chosen = Oc (2), "project built");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (1)), Mo (1.0)),
             "tax1 = 1");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (2)), Mo (0.0)),
             "tax2 = 0");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (3)), Mo (0.0)),
             "tax3 = 0");
      Check (Near (R.Payments (1), Mo (1.0)), "Run tax1");
      Check (Near (Total_Revenue (R.Payments), Mo (1.0)), "tax << cost");
      Check (Is_Pivotal
               (Make_Public_Project (Vals), Ag (1),
                [1 => 0.0, 2 => 10.0]),
             "citizen 1 pivotal");
      Check (not Is_Pivotal
               (Make_Public_Project (Vals), Ag (2),
                [1 => 0.0, 2 => 10.0]),
             "citizen 2 not pivotal");
      Check (Payments_Nonnegative (R.Payments), "taxes >= 0");
      Check (Is_Individually_Rational (R.Utilities), "project IR");
      Check (Near (R.Utilities (1), Mo (5.0)), "u1 = 6-1");
      Check (Near (R.Utilities (2), Mo (5.0)), "u2 = 5-0");
      Check (Near (R.Utilities (3), Mo (4.0)), "u3 = 4-0");
   end;

   declare
      --  All pivotal: 6,3,2 cost 10; sum=11; taxes 5,2,1
      Vals : constant Money_Vector := Row3 (6.0, 3.0, 2.0);
      R    : constant Mechanism_Result := Public_Project (Vals, Mo (10.0));
   begin
      Check (Should_Build (Vals, Mo (10.0)), "11>10 build");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (1)), Mo (5.0)),
             "all-piv tax1=5");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (2)), Mo (2.0)),
             "all-piv tax2=2");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (3)), Mo (1.0)),
             "all-piv tax3=1");
      Check (Near (Total_Revenue (R.Payments), Mo (8.0)), "rev 8 < 10");
      Check (R.Chosen = Oc (2), "all-piv built");
   end;

   declare
      Vals : constant Money_Vector := Row3 (3.0, 3.0, 3.0);
      R    : constant Mechanism_Result := Public_Project (Vals, Mo (10.0));
   begin
      Check (not Should_Build (Vals, Mo (10.0)), "9<10 no build");
      Check (R.Chosen = Oc (1), "status quo");
      Check (Near (R.Payments (1), Mo (0.0)), "no-build tax1");
      Check (Near (R.Payments (2), Mo (0.0)), "no-build tax2");
      Check (Near (R.Payments (3), Mo (0.0)), "no-build tax3");
      Check (Near (R.Welfare, Mo (0.0)), "no-build welfare 0");
   end;

   declare
      Vals : constant Money_Vector := Row2 (12.0, 1.0);
      R    : constant Mechanism_Result := Public_Project (Vals, Mo (10.0));
   begin
      Check (Should_Build (Vals, Mo (10.0)), "13>10 build");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (1)), Mo (9.0)),
             "big pivot tax=9");
      Check (Near (Public_Project_Tax (Vals, Mo (10.0), Ag (2)), Mo (0.0)),
             "small not pivot");
      Check (Near (R.Utilities (1), Mo (3.0)), "u1=12-9");
   end;

   ---------------------------------------------------------------------------
   -- 9. Public-project truthfulness
   ---------------------------------------------------------------------------

   Section ("9. Public-project truthfulness");

   declare
      True_V : constant Money_Vector := Row3 (6.0, 5.0, 4.0);
      Cost   : constant Money := 10.0;
      Mat    : constant Valuation_Matrix := Make_Public_Project (True_V);
      Costs  : constant Money_Vector := [1 => 0.0, 2 => Cost];
   begin
      for Who in 1 .. 3 loop
         for K in 0 .. 4 loop
            declare
               Mis : constant Integer := K * 3;
               Row : constant Money_Vector := Row2 (0.0, Money (Mis));
               Rep : constant Valuation_Matrix :=
                 With_Agent_Report (Mat, Ag (Who), Row);
               U_T : constant Money :=
                 True_U_C (Mat, Mat, Costs, Ag (Who));
               U_L : constant Money :=
                 True_U_C (Mat, Rep, Costs, Ag (Who));
            begin
               Check (U_L <= U_T + 1.0E-9,
                      "citizen " & Img (Who) &
                      " report " & Img (Mis) & " not profitable");
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------------
   -- 10. Binary choice
   ---------------------------------------------------------------------------

   Section ("10. Binary choice");

   declare
      Pref : constant Money_Vector := Row3 (2.0, -1.0, 2.0);
      V    : constant Valuation_Matrix := Make_Binary_Choice (Pref);
      R    : constant Mechanism_Result := Run (V);
   begin
      Check (N_Outcomes (V) = Pos (2), "binary 2 outcomes");
      Check (Near (Social_Welfare (V, Oc (1)), Mo (0.0)), "SQ welfare 0");
      Check (Near (Social_Welfare (V, Oc (2)), Mo (3.0)), "alt welfare 3");
      Check (R.Chosen = Oc (2), "alt chosen");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (0.0)),
             "without 1: still +1 > 0, not pivot");
      Check (Near (Clarke_Payment (V, Ag (3)), Mo (0.0)),
             "without 3: still +1");
      Check (Near (Clarke_Payment (V, Ag (2)), Mo (0.0)),
             "negative voter not charged (outcome unchanged)");
   end;

   declare
      Pref : constant Money_Vector := Row2 (5.0, -4.0);
      V    : constant Valuation_Matrix := Make_Binary_Choice (Pref);
   begin
      Check (Efficient_Outcome (V) = Oc (2), "5-4>0 alt");
      Check (Is_Pivotal (V, Ag (1)), "supporter pivotal");
      Check (Near (Clarke_Payment (V, Ag (1)), Mo (4.0)),
             "p1 = 0 - (-4) = 4");
      Check (not Is_Pivotal (V, Ag (2)), "opposer not pivot when alt wins");
   end;

   ---------------------------------------------------------------------------
   -- 11. Combinatorial two-item
   ---------------------------------------------------------------------------

   Section ("11. Two-item combinatorial");

   Check (Two_Item_Outcome_Count (Pos (1)) = Pos (4), "(1+1)^2 = 4");
   Check (Two_Item_Outcome_Count (Pos (2)) = Pos (9), "(2+1)^2 = 9");
   Check (Two_Item_Outcome_Count (Pos (3)) = Pos (16), "(3+1)^2 = 16");
   Check (Two_Item_Outcome (0, 0, Pos (2)) = Oc (1), "unsold,unsold -> 1");
   Check (Two_Item_Outcome (0, 1, Pos (2)) = Oc (2), "0,1 -> 2");
   Check (Two_Item_Outcome (1, 0, Pos (2)) = Oc (4), "1,0 -> 4");
   declare
      OA, OB : Natural := 99;
   begin
      Decode_Two_Item_Outcome (Oc (5), Pos (2), OA, OB);
      --  idx 4: 4/3=1, 4 mod 3=1
      Check (OA = Nat (1) and then OB = Nat (1), "decode 5 -> (1,1)");
   end;

   declare
      --  Additive 1: A=3,B=3,Both=6; 2: A=2,B=2,Both=5
      R1 : constant Bundle_Values :=
        [Empty => 0.0, A_Only => 3.0, B_Only => 3.0, Both => 6.0];
      R2 : constant Bundle_Values :=
        [Empty => 0.0, A_Only => 2.0, B_Only => 2.0, Both => 5.0];
      Rep : constant Agent_Bundles := [1 => R1, 2 => R2];
      V   : constant Valuation_Matrix := Make_Two_Item_Valuations (Rep);
      R   : constant Mechanism_Result := Two_Item_Allocation (Rep);
      OA, OB : Natural := 0;
   begin
      Check (N_Agents (V) = Pos (2), "combo N=2");
      Check (N_Outcomes (V) = Pos (9), "combo M=9");
      Decode_Two_Item_Outcome (R.Chosen, 2, OA, OB);
      Check (OA = Nat (1) and then OB = Nat (1), "both items to 1");
      Check (Near (R.Payments (1), Mo (5.0)), "winner pays other's Both");
      Check (Near (R.Payments (2), Mo (0.0)), "loser pays 0");
      Check (Near (R.Utilities (1), Mo (1.0)), "u1 = 6-5");
   end;

   declare
      --  Split is efficient: 1 wants A, 2 wants B
      R1 : constant Bundle_Values :=
        [Empty => 0.0, A_Only => 10.0, B_Only => 1.0, Both => 11.0];
      R2 : constant Bundle_Values :=
        [Empty => 0.0, A_Only => 1.0, B_Only => 10.0, Both => 11.0];
      Rep : constant Agent_Bundles := [1 => R1, 2 => R2];
      R   : constant Mechanism_Result := Two_Item_Allocation (Rep);
      OA, OB : Natural := 0;
   begin
      Decode_Two_Item_Outcome (R.Chosen, 2, OA, OB);
      Check (OA = Nat (1) and then OB = Nat (2), "split A->1 B->2");
      Check (Near (R.Welfare, Mo (20.0)), "split SW=20");
      Check (Near (R.Payments (1), Mo (1.0)), "p1 = 1");
      Check (Near (R.Payments (2), Mo (1.0)), "p2 = 1");
      Check (Near (R.Utilities (1), Mo (9.0)), "u1 = 10-1");
      Check (Near (R.Utilities (2), Mo (9.0)), "u2 = 10-1");
   end;

   declare
      --  Complementarity: 1 values the pair more than the sum of parts
      R1 : constant Bundle_Values :=
        [Empty => 0.0, A_Only => 1.0, B_Only => 1.0, Both => 10.0];
      R2 : constant Bundle_Values :=
        [Empty => 0.0, A_Only => 4.0, B_Only => 4.0, Both => 5.0];
      Rep : constant Agent_Bundles := [1 => R1, 2 => R2];
      R   : constant Mechanism_Result := Two_Item_Allocation (Rep);
      OA, OB : Natural := 0;
   begin
      Decode_Two_Item_Outcome (R.Chosen, 2, OA, OB);
      Check (OA = Nat (1) and then OB = Nat (1), "complements stay together");
      Check (Near (R.Welfare, Mo (10.0)), "pair SW=10 > split 5");
      Check (Near (R.Payments (1), Mo (5.0)), "pays 2's Both");
   end;

   ---------------------------------------------------------------------------
   -- 12. Weighted VCG
   ---------------------------------------------------------------------------

   Section ("12. Weighted VCG");

   declare
      V : constant Valuation_Matrix := M22 (3.0, 1.0, 1.0, 4.0);
      W : constant Money_Vector := Row2 (2.0, 1.0);
      --  weighted SW: o1=7, o2=6 -> o*=1
      --  p1 = (1/2)*(4-1)=1.5; p2 = 1*(6-6)=0
   begin
      Check (Near (Weighted_Social_Welfare (V, Oc (1), W), Mo (7.0)),
             "wSW o1=7");
      Check (Near (Weighted_Social_Welfare (V, Oc (2), W), Mo (6.0)),
             "wSW o2=6");
      Check (Weighted_Efficient_Outcome (V, W) = Oc (1), "weighted o*=1");
      Check (Near (Weighted_Clarke_Payment (V, W, Ag (1)), Mo (1.5)),
             "wp1=1.5");
      Check (Near (Weighted_Clarke_Payment (V, W, Ag (2)), Mo (0.0)),
             "wp2=0");
      declare
         R : constant Mechanism_Result := Weighted_Run (V, W);
      begin
         Check (R.Chosen = Oc (1), "W-Run chosen 1");
         Check (Near (R.Payments (1), Mo (1.5)), "W-Run p1");
         Check (Near (R.Utilities (1), Mo (1.5)), "W-Run u1=3-1.5");
         Check (Near (R.Utilities (2), Mo (1.0)), "W-Run u2=1-0");
      end;
      --  Unit weights recover ordinary VCG
      declare
         U : constant Money_Vector := Row2 (1.0, 1.0);
         P : constant Money_Vector := Weighted_VCG_Payments (V, U);
      begin
         Check (Weighted_Efficient_Outcome (V, U) = Efficient_Outcome (V),
                "unit weights same o*");
         Check (Near_Vector (P, VCG_Payments (V)), "unit weights same p");
      end;
   end;

   ---------------------------------------------------------------------------
   -- 13. Instance builder
   ---------------------------------------------------------------------------

   Section ("13. Instance builder");

   declare
      Inst : Instance;
      R    : Mechanism_Result;
   begin
      Clear (Inst, Nat (2), Nat (2));
      Check (Size_Agents (Inst) = 2, "size agents 2");
      Check (Size_Outcomes (Inst) = 2, "size outcomes 2");
      Check (Near (Get_Value (Inst, Ag (1), Oc (1)), Mo (0.0)), "zero init");
      Set_Value (Inst, Ag (1), Oc (1), 3.0);
      Set_Value (Inst, Ag (1), Oc (2), 1.0);
      Set_Value (Inst, Ag (2), Oc (1), 1.0);
      Set_Value (Inst, Ag (2), Oc (2), 4.0);
      Check (Near (Get_Value (Inst, Ag (1), Oc (1)), Mo (3.0)), "get 3");
      Check (Near (Get_Cost (Inst, Oc (1)), Mo (0.0)), "default cost 0");
      R := Run (Inst);
      Check (R.Chosen = Oc (2), "instance Run o*=2");
      Check (Near (R.Payments (2), Mo (2.0)), "instance p2=2");
      Set_Cost (Inst, Oc (2), 10.0);
      Check (Near (Get_Cost (Inst, Oc (2)), Mo (10.0)), "set cost 10");
      R := Run (Inst);
      --  net: o1=4, o2=5-10=-5 -> o*=1
      Check (R.Chosen = Oc (1), "cost flips to o1");
      declare
         Mat : constant Valuation_Matrix := As_Matrix (Inst);
         Cs  : constant Money_Vector := Costs_Of (Inst);
      begin
         Check (N_Agents (Mat) = Pos (2), "As_Matrix N");
         Check (Near (Cs (2), Mo (10.0)), "Costs_Of");
      end;
      Clear (Inst, Nat (0), Nat (0));
      Check (Size_Agents (Inst) = 0, "cleared empty N");
      Check (Size_Outcomes (Inst) = 0, "cleared empty M");
   end;

   ---------------------------------------------------------------------------
   -- 14. Identity: u_i = SW(o*) - h_i
   ---------------------------------------------------------------------------

   Section ("14. Utility identity");

   declare
      procedure Identity_Check (K : Positive; V : Valuation_Matrix) is
         SW : constant Money := Efficient_Welfare (V);
         R  : constant Mechanism_Result := Run (V);
      begin
         for I in 1 .. N_Agents (V) loop
            Check
              (Near
                 (VCG_Utility (V, Ag (I)),
                  SW - Clarke_H (V, Ag (I))),
               "u=SW-h profile " & Img (K) & " i=" & Img (I));
         end loop;
         Check
           (Near
              (R.Utilities (1) + R.Utilities (2)
               + Total_Revenue (R.Payments (1 .. Positive (R.N))),
               R.Welfare),
            "budget identity profile " & Img (K));
      end Identity_Check;
   begin
      Identity_Check (1, M22 (3.0, 1.0, 1.0, 4.0));
      Identity_Check (2, M22 (5.0, 0.0, 0.0, 5.0));
      Identity_Check (3, M22 (1.0, 1.0, 1.0, 1.0));
      Identity_Check (4, M22 (0.0, 8.0, 7.0, 0.0));
      Identity_Check (5, M22 (2.5, 2.5, 2.5, 2.4));
   end;

   ---------------------------------------------------------------------------
   -- 15. Generic truthfulness grid (2 agents, 2 outcomes)
   ---------------------------------------------------------------------------

   Section ("15. Generic truthfulness spot-checks");

   declare
      procedure Dsic_Check
        (Label : String; True_V : Valuation_Matrix; I : Agent_Id; X, Y : Money)
      is
         U : constant Money := VCG_Utility (True_V, I);
         R : constant Valuation_Matrix :=
           With_Agent_Report (True_V, I, Row2 (X, Y));
      begin
         Check (True_U (True_V, R, I) <= U + 1.0E-9,
                "DSIC " & Label);
      end Dsic_Check;
      T1 : constant Valuation_Matrix := M22 (3.0, 1.0, 1.0, 4.0);
      T2 : constant Valuation_Matrix := M22 (5.0, 0.0, 0.0, 5.0);
      T3 : constant Valuation_Matrix := M22 (0.0, 8.0, 7.0, 0.0);
      T4 : constant Valuation_Matrix := M22 (2.0, 2.0, 2.0, 2.0);
   begin
      Dsic_Check ("T1 i1 -> (0,0)", T1, Ag (1), 0.0, 0.0);
      Dsic_Check ("T1 i1 -> (9,9)", T1, Ag (1), 9.0, 9.0);
      Dsic_Check ("T1 i1 -> (1,3)", T1, Ag (1), 1.0, 3.0);
      Dsic_Check ("T1 i2 -> (0,0)", T1, Ag (2), 0.0, 0.0);
      Dsic_Check ("T1 i2 -> (9,0)", T1, Ag (2), 9.0, 0.0);
      Dsic_Check ("T2 i1 -> (0,5)", T2, Ag (1), 0.0, 5.0);
      Dsic_Check ("T2 i2 -> (5,0)", T2, Ag (2), 5.0, 0.0);
      Dsic_Check ("T3 i1 shade", T3, Ag (1), 0.0, 4.0);
      Dsic_Check ("T3 i2 shade", T3, Ag (2), 4.0, 0.0);
      Dsic_Check ("T4 i1 over", T4, Ag (1), 10.0, 0.0);
      Dsic_Check ("T4 i2 over", T4, Ag (2), 0.0, 10.0);
      Dsic_Check ("T4 i1 under", T4, Ag (1), 0.0, 0.0);
   end;

   ---------------------------------------------------------------------------
   -- 16. Nonnegative valuations => IR and p >= 0
   ---------------------------------------------------------------------------

   Section ("16. IR and no-subsidy on nonnegative v");

   for A in 0 .. 2 loop
      for B in 0 .. 2 loop
         declare
            V : constant Valuation_Matrix :=
              M22 (Money (A), Money (B), Money (B), Money (A + 1));
            R : constant Mechanism_Result := Run (V);
         begin
            Check (Payments_Nonnegative (R.Payments),
                   "p>=0 a=" & Img (A) & " b=" & Img (B));
            Check (Is_Individually_Rational (R.Utilities),
                   "IR a=" & Img (A) & " b=" & Img (B));
         end;
      end loop;
   end loop;

   ---------------------------------------------------------------------------
   -- 17. Vickrey batch
   ---------------------------------------------------------------------------

   Section ("17. Vickrey batch");

   for X in 1 .. 3 loop
      for Y in 1 .. 3 loop
         declare
            B : constant Money_Vector :=
              [1 => Money (X), 2 => Money (Y)];
            R : constant Mechanism_Result := Vickrey_Auction (B);
            V : constant Valuation_Matrix := Make_Single_Item_Valuations (B);
            G : constant Mechanism_Result := Run (V);
            W : constant Natural :=
              (if X >= Y then 1 else 2);
            P : constant Money := Money (if X >= Y then Y else X);
         begin
            Check (Vickrey_Winner (B) = W,
                   "winner x=" & Img (X) & " y=" & Img (Y));
            Check (Near (Vickrey_Price (B), P),
                   "price x=" & Img (X) & " y=" & Img (Y));
            Check (G.Chosen = R.Chosen,
                   "VCG winner x=" & Img (X) & " y=" & Img (Y));
            Check (Near_Vector (G.Payments, R.Payments),
                   "VCG price x=" & Img (X) & " y=" & Img (Y));
         end;
      end loop;
   end loop;

   ---------------------------------------------------------------------------
   -- 18. More Clarke / welfare micro-checks
   ---------------------------------------------------------------------------

   Section ("18. Micro-checks");

   --  Identical agents, three outcomes
   declare
      V : Valuation_Matrix (1 .. 3, 1 .. 3) := [others => [others => 1.0]];
   begin
      V (1, 2) := 3.0;
      V (2, 2) := 3.0;
      V (3, 2) := 3.0;
      Check (Efficient_Outcome (V) = Oc (2), "unanimous o2");
      Check (Near (Social_Welfare (V, Oc (2)), Mo (9.0)), "unanimous SW 9");
      for I in 1 .. 3 loop
         Check (Near (Clarke_Payment (V, Ag (I)), Mo (0.0)),
                "unanimous p" & Img (I) & " = 0");
         Check (not Is_Pivotal (V, Ag (I)),
                "unanimous not pivotal " & Img (I));
      end loop;
   end;

   --  Negative valuations allowed
   declare
      V : constant Valuation_Matrix := M22 (-1.0, -4.0, -2.0, -1.0);
      --  SW: -3, -5 -> o*=1
   begin
      Check (Efficient_Outcome (V) = Oc (1), "negatives pick lesser harm");
      Check (Near (Efficient_Welfare (V), Mo (-3.0)), "SW=-3");
   end;

   --  With_Agent_Report identity
   declare
      V : constant Valuation_Matrix := M22 (3.0, 1.0, 1.0, 4.0);
      R : constant Valuation_Matrix :=
        With_Agent_Report (V, Ag (1), Row2 (3.0, 1.0));
   begin
      Check (Near (Report (R, Ag (1), Oc (1)), Mo (3.0)), "copy row");
      Check (Near (Report (R, Ag (2), Oc (2)), Mo (4.0)), "other row kept");
      Check (Efficient_Outcome (R) = Efficient_Outcome (V), "same o*");
   end;

   --  Four bidders Vickrey
   declare
      B : constant Money_Vector :=
        [1 => 2.0, 2 => 9.0, 3 => 4.0, 4 => 6.0];
   begin
      Check (Arg_Highest_Bid (B) = Pos (2), "4-bid arg");
      Check (Near (Highest_Bid (B), Mo (9.0)), "4-bid high");
      Check (Near (Second_Highest_Bid (B), Mo (6.0)), "4-bid second");
      Check (Near (Vickrey_Price (B), Mo (6.0)), "4-bid price");
      Check (Vickrey_Winner (B, Mo (10.0)) = Nat (0), "4-bid reserve miss");
      Check (Vickrey_Winner (B, Mo (6.0)) = Nat (2), "4-bid reserve hit");
      Check (Near (Vickrey_Price (B, Mo (7.0)), Mo (7.0)),
             "4-bid price vs reserve 7");
   end;

   --  Public project single citizen
   declare
      Vals : constant Money_Vector := [1 => 8.0];
      R    : constant Mechanism_Result := Public_Project (Vals, Mo (5.0));
   begin
      Check (Should_Build (Vals, Mo (5.0)), "solo 8>5");
      Check (Near (R.Payments (1), Mo (5.0)), "solo tax = cost");
      Check (Near (R.Utilities (1), Mo (3.0)), "solo u=3");
      Check (not Should_Build (Vals, Mo (8.0)), "solo 8=8 no");
      Check (not Should_Build (Vals, Mo (9.0)), "solo 8<9 no");
   end;

   --  Zero vector payments helper
   declare
      P : constant Money_Vector := Row3 (0.0, 0.0, 0.0);
      U : constant Money_Vector := Row3 (1.0, 0.0, 2.0);
   begin
      Check (Near (Total_Revenue (P), Mo (0.0)), "zero revenue");
      Check (Payments_Nonnegative (P), "zero p nonnegative");
      Check (Is_Individually_Rational (U), "mixed IR ok");
      Check (not Is_Individually_Rational (Row2 (1.0, -0.5)), "neg u not IR");
      Check (not Payments_Nonnegative (Row2 (1.0, -0.5)), "neg p subsidy");
   end;

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------

   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
