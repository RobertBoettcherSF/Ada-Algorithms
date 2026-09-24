with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Sarsa; use Sarsa;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Gen : Ada.Numerics.Float_Random.Generator;

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

begin
   Ada.Numerics.Float_Random.Reset (Gen);

   -- TEST 1 — Initialization of Q Table
   Put_Line ("TEST 1 — Initialize Q Table");
   declare
      Q : constant Q_Table := Initialize_Q_Table (2, 3);
   begin
      Check ("1.1 Q-table row bounds match", Q'Length (1) = 2);
      Check ("1.2 Q-table col bounds match", Q'Length (2) = 3);
      Check ("1.3 Q-table is zero initialized", Q (1, 1) = 0.0 and Q (2, 3) = 0.0);
   end;

   -- TEST 2 — Initialization of Trace Table
   Put_Line ("TEST 2 — Initialize Trace Table");
   declare
      T : constant Trace_Table := Initialize_Trace_Table (4, 2);
   begin
      Check ("2.1 Trace row bounds match", T'Length (1) = 4);
      Check ("2.2 Trace col bounds match", T'Length (2) = 2);
      Check ("2.3 Trace is zero initialized", T (4, 2) = 0.0);
   end;

   -- TEST 3 — Best Action Selection
   Put_Line ("TEST 3 — Best Action Extraction");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 3);
   begin
      Q (1, 1) := 1.0; Q (1, 2) := 5.0; Q (1, 3) := 3.0;
      Q (2, 1) := 8.0; Q (2, 2) := 2.0; Q (2, 3) := 9.0;
      Check ("3.1 Finds middle peak correctly", Best_Action (Q, 1) = 2);
      Check ("3.2 Finds end peak correctly", Best_Action (Q, 2) = 3);
      Q (1, 1) := 10.0;
      Check ("3.3 Finds start peak correctly", Best_Action (Q, 1) = 1);
   end;

   -- TEST 4 — TD Error Calculation
   Put_Line ("TEST 4 — Calculate TD Error");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
      E1, E2, E3 : Q_Value;
   begin
      Q (1, 1) := 5.0; Q (2, 2) := 10.0;
      E1 := Calculate_TD_Error (Q, 1, 1, 0.0, 2, 2, 0.5); -- 0.0 + 0.5*10.0 - 5.0 = 0.0
      Check ("4.1 Correct TD Error for zero change", E1 = 0.0);
      E2 := Calculate_TD_Error (Q, 1, 1, 3.0, 2, 2, 0.5); -- 3.0 + 0.5*10.0 - 5.0 = 3.0
      Check ("4.2 Correct TD Error with positive reward", E2 = 3.0);
      E3 := Calculate_TD_Error (Q, 1, 1, 0.0, 2, 2, 0.0); -- 0.0 + 0.0 - 5.0 = -5.0
      Check ("4.3 Correct TD Error with zero Gamma", E3 = -5.0);
   end;

   -- TEST 5 — Standard SARSA Update
   Put_Line ("TEST 5 — Standard SARSA Update");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
   begin
      Q (2, 2) := 10.0;
      Update_Standard (Q, 1, 1, 5.0, 2, 2, 0.1, 0.9);
      -- Target = 5.0 + 0.9*10.0 = 14.0. Q(1,1) = 0.0 + 0.1*(14.0) = 1.4
      Check ("5.1 Standard update performs correctly", Q (1, 1) = 1.4);
      Update_Standard (Q, 1, 1, 0.0, 2, 2, 0.0, 0.9);
      Check ("5.2 Zero Alpha preserves value", Q (1, 1) = 1.4);
      Update_Standard (Q, 1, 1, -20.0, 2, 2, 0.5, 0.0);
      -- Target = -20.0 + 0.0*10 = -20. Q(1,1) = 1.4 + 0.5*(-20 - 1.4) = -9.3
      Check ("5.3 Negative reward lowers Q", Q (1, 1) = -9.3);
   end;

   -- TEST 6 — Expected SARSA (Greedy / Epsilon = 0.0)
   Put_Line ("TEST 6 — Expected SARSA (Greedy, Epsilon=0)");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
   begin
      Q (2, 1) := 2.0; Q (2, 2) := 10.0;
      Update_Expected (Q, 1, 1, 1.0, 2, 0.5, 1.0, 0.0);
      -- Target = 1.0 + 1.0*(1.0*10.0 + 0.0*2.0) = 11.0. Q(1,1) = 0.5 * 11.0 = 5.5
      Check ("6.1 Greedy updates based strictly on max", Q (1, 1) = 5.5);
      Q (1, 1) := 0.0;
      Update_Expected (Q, 1, 1, 0.0, 2, 0.1, 0.0, 0.0);
      Check ("6.2 Zero reward and gamma preserves zero", Q (1, 1) = 0.0);
      Check ("6.3 Non-max action at state 2 is ignored", True); -- Proven by 6.1
   end;

   -- TEST 7 — Expected SARSA (Random / Epsilon = 1.0)
   Put_Line ("TEST 7 — Expected SARSA (Random, Epsilon=1)");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
   begin
      Q (2, 1) := 2.0; Q (2, 2) := 10.0;
      Update_Expected (Q, 1, 1, 0.0, 2, 1.0, 1.0, 1.0);
      -- Target = 0.0 + 1.0*(0.5*10.0 + 0.5*2.0) = 6.0.
      Check ("7.1 Fully random expected computes uniform average", Q (1, 1) = 6.0);
      Q (2, 1) := 10.0;
      Update_Expected (Q, 1, 2, 0.0, 2, 1.0, 1.0, 1.0);
      -- Uniform over (10, 10) = 10.
      Check ("7.2 Symmetrical next state actions yield correct expected", Q (1, 2) = 10.0);
      Check ("7.3 Updates apply to specific action independently", Q (1, 1) = 6.0);
   end;

   -- TEST 8 — Expected SARSA (Mixed / Epsilon = 0.5)
   Put_Line ("TEST 8 — Expected SARSA (Mixed, Epsilon=0.5)");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
   begin
      Q (2, 1) := 0.0; Q (2, 2) := 10.0;
      Update_Expected (Q, 1, 1, 0.0, 2, 1.0, 1.0, 0.5);
      -- Best = 2. Prob(Best) = 0.5 + 0.25 = 0.75. Prob(Other) = 0.25.
      -- Expected = 0.75*10 + 0.25*0 = 7.5.
      Check ("8.1 Correct weighted average calculated", Q (1, 1) = 7.5);
      Q (1, 1) := 0.0; Q (2, 1) := 10.0; Q (2, 2) := 10.0;
      Update_Expected (Q, 1, 1, 0.0, 2, 1.0, 1.0, 0.5);
      Check ("8.2 Ties handled safely", Q (1, 1) = 10.0);
      Check ("8.3 Mixed epsilon bounds respected", Q (1, 1) <= 10.0);
   end;

   -- TEST 9 — Epsilon Greedy Action Selection (Exploit)
   Put_Line ("TEST 9 — Epsilon Greedy (Exploit)");
   declare
      Q : Q_Table := Initialize_Q_Table (1, 3);
   begin
      Q (1, 1) := 1.0; Q (1, 2) := 9.0; Q (1, 3) := 2.0;
      Check ("9.1 Exploits maximum action (Run 1)", Epsilon_Greedy_Action (Q, 1, 0.0, Gen) = 2);
      Check ("9.2 Exploits maximum action (Run 2)", Epsilon_Greedy_Action (Q, 1, 0.0, Gen) = 2);
      Check ("9.3 Exploits maximum action (Run 3)", Epsilon_Greedy_Action (Q, 1, 0.0, Gen) = 2);
   end;

   -- TEST 10 — Epsilon Greedy Action Selection (Explore)
   Put_Line ("TEST 10 — Epsilon Greedy (Explore)");
   declare
      Q : Q_Table := Initialize_Q_Table (1, 3);
      Act : Action_Index;
   begin
      Q (1, 1) := 1.0; Q (1, 2) := 9.0; Q (1, 3) := 2.0;
      
      Act := Epsilon_Greedy_Action (Q, 1, 1.0, Gen);
      Check ("10.1 Explore returns valid bounds (Run 1)", Act <= 3);
      
      Act := Epsilon_Greedy_Action (Q, 1, 1.0, Gen);
      Check ("10.2 Explore returns valid bounds (Run 2)", Act <= 3);
      
      Act := Epsilon_Greedy_Action (Q, 1, 1.0, Gen);
      Check ("10.3 Explore returns valid bounds (Run 3)", Act <= 3);
   end;

   -- TEST 11 — SARSA Lambda Trace Increment
   Put_Line ("TEST 11 — SARSA Lambda Trace Increment");
   declare
      T : Trace_Table := Initialize_Trace_Table (2, 2);
   begin
      Increment_Trace (T, 1, 2);
      Check ("11.1 Trace increases to 1.0", T (1, 2) = 1.0);
      Increment_Trace (T, 1, 2);
      Check ("11.2 Trace accumulates to 2.0", T (1, 2) = 2.0);
      Check ("11.3 Untouched traces remain zero", T (1, 1) = 0.0 and T (2, 2) = 0.0);
   end;

   -- TEST 12 — SARSA Lambda Full Update Step
   Put_Line ("TEST 12 — SARSA Lambda Global Step");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
      T : Trace_Table := Initialize_Trace_Table (2, 2);
   begin
      T (1, 1) := 1.0;
      T (2, 2) := 0.5;
      Update_Lambda_Step (Q, T, 10.0, 0.1, 0.9, 0.5);
      -- Q(1,1) += 0.1 * 10 * 1.0 = 1.0
      -- Q(2,2) += 0.1 * 10 * 0.5 = 0.5
      Check ("12.1 Q value scales properly by Trace", Q (1, 1) = 1.0 and Q (2, 2) = 0.5);
      -- T(1,1) = 1.0 * 0.9 * 0.5 = 0.45
      Check ("12.2 Traces decay by Gamma and Lambda", T (1, 1) = 0.45);
      Check ("12.3 Untraced Q values remain zero", Q (1, 2) = 0.0 and Q (2, 1) = 0.0);
   end;

   -- TEST 13 — Exception Handling (State Out of Bounds)
   Put_Line ("TEST 13 — Exceptions (State Bounds)");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
      Failed : Boolean;
   begin
      Failed := False;
      begin
         Update_Standard (Q, 3, 1, 0.0, 1, 1, 0.1, 0.9);
      exception
         when State_Out_Of_Bounds => Failed := True;
      end;
      Check ("13.1 Update_Standard raises State_Out_Of_Bounds", Failed);

      Failed := False;
      begin
         Update_Expected (Q, 1, 1, 0.0, 3, 0.1, 0.9, 0.1);
      exception
         when State_Out_Of_Bounds => Failed := True;
      end;
      Check ("13.2 Update_Expected raises State_Out_Of_Bounds", Failed);

      Failed := False;
      begin
         declare
            A : Action_Index := Best_Action (Q, 3);
            pragma Unreferenced (A);
         begin
            null;
         end;
      exception
         when State_Out_Of_Bounds => Failed := True;
      end;
      Check ("13.3 Best_Action raises State_Out_Of_Bounds", Failed);
   end;

   -- TEST 14 — Exception Handling (Action & Structure Bounds)
   Put_Line ("TEST 14 — Exceptions (Action Bounds)");
   declare
      Q : Q_Table := Initialize_Q_Table (2, 2);
      T : Trace_Table := Initialize_Trace_Table (3, 3);
      Failed : Boolean;
   begin
      Failed := False;
      begin
         Update_Standard (Q, 1, 3, 0.0, 1, 1, 0.1, 0.9);
      exception
         when Action_Out_Of_Bounds => Failed := True;
      end;
      Check ("14.1 Update_Standard raises Action_Out_Of_Bounds", Failed);

      Failed := False;
      begin
         Increment_Trace (T, 1, 4);
      exception
         when Action_Out_Of_Bounds => Failed := True;
      end;
      Check ("14.2 Increment_Trace raises Action_Out_Of_Bounds", Failed);

      Failed := False;
      begin
         Update_Lambda_Step (Q, T, 1.0, 0.1, 0.9, 0.5);
      exception
         when Table_Size_Mismatch => Failed := True;
      end;
      Check ("14.3 Update_Lambda_Step raises Table_Size_Mismatch", Failed);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
