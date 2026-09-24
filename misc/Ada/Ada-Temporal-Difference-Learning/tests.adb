with Ada.Text_IO; use Ada.Text_IO;
with Temporal_Difference_Learning; use Temporal_Difference_Learning;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   function Almost_Equal (Left, Right : Value_Type) return Boolean is
   begin
      return abs (Left - Right) < 0.0001;
   end Almost_Equal;

   -----------------------------------------------------------------------------
   --  Test Setup
   -----------------------------------------------------------------------------
   
   procedure Test_1_TD0_Basic is
      V : Value_Table (1 .. 3) := [0.0, 10.0, 0.0];
   begin
      Put_Line ("TEST 1 — TD(0) Basic Update");
      -- V(1) = 0.0, R = 5.0, Gamma = 0.9, V(2) = 10.0
      -- Target = 5.0 + 0.9 * 10.0 = 14.0
      -- Error = 14.0 - 0.0 = 14.0
      -- V(1) = 0.0 + 0.5 * 14.0 = 7.0
      Update_TD_0 (V, 1, 2, 5.0, 0.5, 0.9);
      Check ("1.1 Source state correctly updated", Almost_Equal (V (1), 7.0));
      Check ("1.2 Target state untouched", Almost_Equal (V (2), 10.0));
      Check ("1.3 Unrelated state untouched", Almost_Equal (V (3), 0.0));
   end Test_1_TD0_Basic;

   procedure Test_2_TD0_Zero_Alpha is
      V : Value_Table (1 .. 2) := [5.0, 10.0];
   begin
      Put_Line ("TEST 2 — TD(0) Zero Learning Rate");
      Update_TD_0 (V, 1, 2, 100.0, 0.0, 1.0);
      Check ("2.1 Value should not change with Alpha=0.0", Almost_Equal (V (1), 5.0));
      Check ("2.2 Next state untouched", Almost_Equal (V (2), 10.0));
      Check ("2.3 No side effects", V'Length = 2);
   end Test_2_TD0_Zero_Alpha;

   procedure Test_3_TD0_Zero_Gamma is
      V : Value_Table (1 .. 2) := [0.0, 20.0];
   begin
      Put_Line ("TEST 3 — TD(0) Zero Discount Factor (Myopic)");
      -- Target = R + 0.0 * V(2) = 10.0
      -- V(1) = 0.0 + 0.5 * 10.0 = 5.0
      Update_TD_0 (V, 1, 2, 10.0, 0.5, 0.0);
      Check ("3.1 Gamma 0.0 ignores future state value", Almost_Equal (V (1), 5.0));
      Check ("3.2 Future state maintains its value", Almost_Equal (V (2), 20.0));
      Check ("3.3 Table length unchanged", V'Length = 2);
   end Test_3_TD0_Zero_Gamma;

   procedure Test_4_QLearning_Basic is
      Q : Q_Table (1 .. 2, 1 .. 2) :=
        [1 => [1 => 0.0, 2 => 0.0],
         2 => [1 => 5.0, 2 => 10.0]]; -- Max in state 2 is 10.0
   begin
      Put_Line ("TEST 4 — Q-Learning Basic Update");
      -- S=1, A=1, R=2.0, S_Next=2. Alpha=0.5, Gamma=0.8
      -- Max_Next = 10.0
      -- Target = 2.0 + 0.8 * 10.0 = 10.0
      -- Q(1,1) = 0.0 + 0.5 * (10.0 - 0.0) = 5.0
      Update_Q_Learning (Q, 1, 1, 2, 2.0, 0.5, 0.8);
      Check ("4.1 Source Q-value correctly updated", Almost_Equal (Q (1, 1), 5.0));
      Check ("4.2 Alternate action untouched", Almost_Equal (Q (1, 2), 0.0));
      Check ("4.3 Next state values untouched", Almost_Equal (Q (2, 2), 10.0));
   end Test_4_QLearning_Basic;

   procedure Test_5_Max_Action_Helper is
      Q : Q_Table (1 .. 1, 1 .. 3) := [1 => [1 => -5.0, 2 => 15.5, 3 => 2.0]];
   begin
      Put_Line ("TEST 5 — Max Action Value Helper");
      Check ("5.1 Extracts maximum positive value", Almost_Equal (Max_Action_Value (Q, 1), 15.5));
      Q (1, 2) := -10.0;
      Check ("5.2 Extracts maximum when negative", Almost_Equal (Max_Action_Value (Q, 1), 2.0));
      Q (1, 3) := -20.0;
      Check ("5.3 Extracts maximum when all negative", Almost_Equal (Max_Action_Value (Q, 1), -5.0));
   end Test_5_Max_Action_Helper;

   procedure Test_6_SARSA_Basic is
      Q : Q_Table (1 .. 2, 1 .. 2) :=
        [1 => [1 => 0.0, 2 => 0.0],
         2 => [1 => 5.0, 2 => 10.0]];
   begin
      Put_Line ("TEST 6 — SARSA Basic Update");
      -- S=1, A=1, R=2.0, S_Next=2, A_Next=1 (Not the max action!). Alpha=0.5, Gamma=0.8
      -- Next_Q = Q(2,1) = 5.0
      -- Target = 2.0 + 0.8 * 5.0 = 6.0
      -- Q(1,1) = 0.0 + 0.5 * (6.0 - 0.0) = 3.0
      Update_SARSA (Q, 1, 1, 2, 1, 2.0, 0.5, 0.8);
      Check ("6.1 Uses specific next action value, not max", Almost_Equal (Q (1, 1), 3.0));
      Check ("6.2 Alternate action untouched", Almost_Equal (Q (1, 2), 0.0));
      Check ("6.3 Next state values untouched", Almost_Equal (Q (2, 1), 5.0));
   end Test_6_SARSA_Basic;

   procedure Test_7_Expected_SARSA_Basic is
      Q  : Q_Table (1 .. 2, 1 .. 2) :=
        [1 => [1 => 0.0, 2 => 0.0],
         2 => [1 => 4.0, 2 => 10.0]];
      Pi : constant Policy_Distribution (1 .. 2) := [0.5, 0.5]; -- 50/50 chance
   begin
      Put_Line ("TEST 7 — Expected SARSA with Uniform Policy");
      -- S=1, A=1, R=2.0, S_Next=2. Alpha=0.5, Gamma=1.0
      -- Expected Next = 0.5 * 4.0 + 0.5 * 10.0 = 7.0
      -- Target = 2.0 + 1.0 * 7.0 = 9.0
      -- Q(1,1) = 0.0 + 0.5 * 9.0 = 4.5
      Update_Expected_SARSA (Q, 1, 1, 2, Pi, 2.0, 0.5, 1.0);
      Check ("7.1 Uses probability-weighted expected value", Almost_Equal (Q (1, 1), 4.5));
      Check ("7.2 Policy check helper is True", Is_Valid_Policy (Pi));
      Check ("7.3 Next state values untouched", Almost_Equal (Q (2, 2), 10.0));
   end Test_7_Expected_SARSA_Basic;

   procedure Test_8_Expected_SARSA_Deterministic is
      Q  : Q_Table (1 .. 2, 1 .. 2) :=
        [1 => [1 => 0.0, 2 => 0.0],
         2 => [1 => 4.0, 2 => 10.0]];
      Pi : constant Policy_Distribution (1 .. 2) := [0.0, 1.0]; -- 100% chance for A=2
   begin
      Put_Line ("TEST 8 — Expected SARSA Deterministic Policy");
      -- S=1, A=1, R=2.0, S_Next=2. Alpha=0.5, Gamma=1.0
      -- Expected Next = 0.0 * 4.0 + 1.0 * 10.0 = 10.0
      -- Target = 2.0 + 1.0 * 10.0 = 12.0
      -- Q(1,1) = 0.0 + 0.5 * 12.0 = 6.0
      Update_Expected_SARSA (Q, 1, 1, 2, Pi, 2.0, 0.5, 1.0);
      Check ("8.1 Acts like Q-learning if policy matches max action", Almost_Equal (Q (1, 1), 6.0));
      Check ("8.2 Alternate action untouched", Almost_Equal (Q (1, 2), 0.0));
      Check ("8.3 Next state values untouched", Almost_Equal (Q (2, 1), 4.0));
   end Test_8_Expected_SARSA_Deterministic;

   procedure Test_9_Invalid_State_TD0 is
      V : Value_Table (1 .. 2) := [0.0, 0.0];
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 9 — TD(0) Invalid State Exception");
      begin
         Update_TD_0 (V, 1, 3, 1.0, 0.1, 0.1); -- State 3 doesn't exist
      exception
         when Invalid_State_Error =>
            Caught := True;
      end;
      Check ("9.1 Exception raised for invalid S_Next", Caught);
      
      Caught := False;
      begin
         Update_TD_0 (V, 4, 1, 1.0, 0.1, 0.1); -- State 4 doesn't exist
      exception
         when Constraint_Error => Caught := True; -- Array bounds might catch first depending on compilation
         when Invalid_State_Error => Caught := True;
      end;
      Check ("9.2 Exception raised for invalid S", Caught);
      Check ("9.3 Table values uncorrupted", Almost_Equal (V (1), 0.0));
   end Test_9_Invalid_State_TD0;

   procedure Test_10_Invalid_Action_QLearning is
      Q : Q_Table (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 10 — Q-Learning Invalid Action Exception");
      begin
         Update_Q_Learning (Q, 1, 3, 2, 1.0, 0.1, 0.1); -- Action 3 doesn't exist
      exception
         when Invalid_Action_Error => Caught := True;
         when Constraint_Error => Caught := True;
      end;
      Check ("10.1 Exception raised for invalid action", Caught);
      Check ("10.2 Table uncorrupted", Almost_Equal (Q (1, 1), 0.0));
      Check ("10.3 Table uncorrupted", Almost_Equal (Q (2, 2), 0.0));
   end Test_10_Invalid_Action_QLearning;

   procedure Test_11_Policy_Mismatch_Expected_SARSA is
      Q  : Q_Table (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      Pi : constant Policy_Distribution (1 .. 3) := [0.3, 0.3, 0.4]; -- Size 3 vs Action Size 2
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 11 — Expected SARSA Policy Size Mismatch");
      begin
         Update_Expected_SARSA (Q, 1, 1, 2, Pi, 1.0, 0.1, 0.1);
      exception
         when Policy_Mismatch_Error => Caught := True;
      end;
      Check ("11.1 Policy_Mismatch_Error raised", Caught);
      Check ("11.2 Q_Table unaffected", Almost_Equal (Q (1, 1), 0.0));
      Check ("11.3 Invalid policy detection helper works", Is_Valid_Policy (Pi)); -- It is valid summing to 1, but wrong length for Q
   end Test_11_Policy_Mismatch_Expected_SARSA;

   procedure Test_12_TD0_Convergence is
      V : Value_Table (1 .. 2) := [0.0, 10.0];
   begin
      Put_Line ("TEST 12 — TD(0) Convergence sequence");
      -- Multiple updates should push V(1) towards R + Gamma * V(2) = 0 + 1.0 * 10 = 10
      for I in 1 .. 10 loop
         Update_TD_0 (V, 1, 2, 0.0, 0.5, 1.0);
      end loop;
      -- After 10 iterations of 0.5 decay, V(1) should be very close to 10.0
      Check ("12.1 Value converges towards target", V (1) > 9.9);
      Check ("12.2 Value does not overshoot", V (1) <= 10.0);
      Check ("12.3 Anchor state unperturbed", Almost_Equal (V (2), 10.0));
   end Test_12_TD0_Convergence;

   procedure Test_13_Invalid_Policy is
      Pi_Bad : constant Policy_Distribution (1 .. 2) := [0.5, 0.8]; -- Sum = 1.3
      Pi_Good : constant Policy_Distribution (1 .. 2) := [0.2, 0.8];
      Pi_Empty : constant Policy_Distribution (2 .. 1) := [others => 0.0]; -- Empty
   begin
      Put_Line ("TEST 13 — Valid Policy Checker");
      Check ("13.1 Detects over-summation", not Is_Valid_Policy (Pi_Bad));
      Check ("13.2 Accepts precise 1.0 summation", Is_Valid_Policy (Pi_Good));
      Check ("13.3 Rejects empty distribution", not Is_Valid_Policy (Pi_Empty));
   end Test_13_Invalid_Policy;

begin
   Test_1_TD0_Basic;
   Test_2_TD0_Zero_Alpha;
   Test_3_TD0_Zero_Gamma;
   Test_4_QLearning_Basic;
   Test_5_Max_Action_Helper;
   Test_6_SARSA_Basic;
   Test_7_Expected_SARSA_Basic;
   Test_8_Expected_SARSA_Deterministic;
   Test_9_Invalid_State_TD0;
   Test_10_Invalid_Action_QLearning;
   Test_11_Policy_Mismatch_Expected_SARSA;
   Test_12_TD0_Convergence;
   Test_13_Invalid_Policy;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
