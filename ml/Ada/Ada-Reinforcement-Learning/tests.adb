with Ada.Text_IO; use Ada.Text_IO;
with Reinforcement_Learning; use Reinforcement_Learning;

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

   -- Environmental test variables mapped to custom types
   T : Q_Table (1 .. 5, 1 .. 3);

begin
   Put_Line ("TEST 1 — Initialization");
   Initialize (T);
   Check ("1.1 Table(1,1) is zero", Almost_Equal (T(1,1), 0.0));
   Check ("1.2 Table(5,3) is zero", Almost_Equal (T(5,3), 0.0));
   Check ("1.3 Table(3,2) is zero", Almost_Equal (T(3,2), 0.0));

   Put_Line ("TEST 2 — Get_Max_Q (All Zeros)");
   Check ("2.1 Max Q for State 1 is 0.0", Almost_Equal (Get_Max_Q (T, 1), 0.0));
   Check ("2.2 Max Q for State 5 is 0.0", Almost_Equal (Get_Max_Q (T, 5), 0.0));
   Check ("2.3 Best Action for State 3 is 1 (first available)", Get_Best_Action (T, 3) = 1);

   Put_Line ("TEST 3 — Get_Max_Q (Mixed Positive and Negative Values)");
   T(1,1) := -5.0; T(1,2) := 2.5; T(1,3) := 1.0;
   T(2,1) := -10.0; T(2,2) := -2.0; T(2,3) := -5.0;
   Check ("3.1 Max Q for State 1 is 2.5", Almost_Equal (Get_Max_Q (T, 1), 2.5));
   Check ("3.2 Max Q for State 2 is -2.0", Almost_Equal (Get_Max_Q (T, 2), -2.0));
   Check ("3.3 Max Q for State 3 is 0.0 (untouched)", Almost_Equal (Get_Max_Q (T, 3), 0.0));

   Put_Line ("TEST 4 — Get_Best_Action (Mixed Values & Tie-Breaking)");
   Check ("4.1 Best action for State 1 is 2", Get_Best_Action (T, 1) = 2);
   Check ("4.2 Best action for State 2 is 2", Get_Best_Action (T, 2) = 2);
   T(4,1) := 10.0; T(4,2) := 10.0; T(4,3) := 5.0;
   Check ("4.3 Best action with tie returns first encountered (1)", Get_Best_Action (T, 4) = 1);

   Put_Line ("TEST 5 — Q-Learning Basic Update (Zero Future State)");
   Initialize (T);
   -- Current_Q = 0.0, Target = 10.0 + 0.9 * 0.0 = 10.0. Update = 0 + 0.5 * 10 = 5.0
   Update_Q_Learning (T, 1, 1, 10.0, 2, 0.5, 0.9);
   Check ("5.1 T(1,1) updated to 5.0", Almost_Equal (T(1,1), 5.0));
   Check ("5.2 T(1,2) remains 0.0", Almost_Equal (T(1,2), 0.0));
   Check ("5.3 Future state T(2,1) remains 0.0", Almost_Equal (T(2,1), 0.0));

   Put_Line ("TEST 6 — Q-Learning with Future Reward Bootstrapping");
   T(2,1) := 10.0; -- Establish maximum future Q = 10.0
   -- R=5.0. Target = 5 + 0.9*10 = 14. Current Q = 5.0. Update = 5 + 0.5*(14 - 5) = 9.5
   Update_Q_Learning (T, 1, 1, 5.0, 2, 0.5, 0.9);
   Check ("6.1 T(1,1) updated to 9.5", Almost_Equal (T(1,1), 9.5));
   Check ("6.2 Future Q remains untouched", Almost_Equal (T(2,1), 10.0));
   Check ("6.3 Unrelated action Q remains 0.0", Almost_Equal (T(1,3), 0.0));

   Put_Line ("TEST 7 — SARSA Basic Update (On-Policy)");
   Initialize (T);
   T(2,2) := 4.0;
   -- R=10.0, Next Action=2 -> Next Q=4.0
   -- Target = 10 + 0.9*4 = 13.6. Update = 0 + 0.5*13.6 = 6.8
   Update_SARSA (T, 1, 1, 10.0, 2, 2, 0.5, 0.9);
   Check ("7.1 T(1,1) updated to 6.8", Almost_Equal (T(1,1), 6.8));
   Check ("7.2 Target action Q unaffected", Almost_Equal (T(2,2), 4.0));
   Check ("7.3 Next action being checked does not affect other states", Almost_Equal (Get_Max_Q (T, 2), 4.0));

   Put_Line ("TEST 8 — Algorithm Difference: SARSA vs Q-Learning");
   Initialize (T);
   T(2,1) := 10.0; -- Max Q in Next State
   T(2,2) := 2.0;  -- Specific action chosen
   Update_SARSA (T, 1, 1, 0.0, 2, 2, 1.0, 1.0);       -- Target = 2.0  -> T(1,1) = 2.0
   Update_Q_Learning (T, 1, 2, 0.0, 2, 1.0, 1.0);     -- Target = 10.0 -> T(1,2) = 10.0
   Check ("8.1 SARSA uses specific selected action Q", Almost_Equal (T(1,1), 2.0));
   Check ("8.2 Q-Learning greedily uses max Q", Almost_Equal (T(1,2), 10.0));
   Check ("8.3 Different targets achieved based on policy", not Almost_Equal (T(1,1), T(1,2)));

   Put_Line ("TEST 9 — Edge Case: Alpha = 0.0 (No Learning)");
   Initialize (T);
   T(1,1) := 5.0;
   Update_Q_Learning (T, 1, 1, 100.0, 2, 0.0, 1.0);
   Update_SARSA (T, 1, 1, 100.0, 2, 2, 0.0, 1.0);
   Check ("9.1 Q-Learning respects Alpha=0.0", Almost_Equal (T(1,1), 5.0));
   Check ("9.2 SARSA respects Alpha=0.0", Almost_Equal (T(1,1), 5.0));
   Check ("9.3 Nothing changed structurally", Almost_Equal (Get_Max_Q (T, 1), 5.0));

   Put_Line ("TEST 10 — Edge Case: Gamma = 0.0 (Myopic Agent)");
   Initialize (T);
   T(2,1) := 100.0;
   Update_Q_Learning (T, 1, 1, 5.0, 2, 1.0, 0.0);
   Check ("10.1 Q-Learning ignores future with Gamma=0.0", Almost_Equal (T(1,1), 5.0));
   Update_SARSA (T, 1, 2, 5.0, 2, 1, 1.0, 0.0);
   Check ("10.2 SARSA ignores future with Gamma=0.0", Almost_Equal (T(1,2), 5.0));
   Check ("10.3 Future state unchanged", Almost_Equal (T(2,1), 100.0));

   Put_Line ("TEST 11 — Exceptions in Observation Methods");
   declare
      Caught_Max : Boolean := False;
      Caught_Act : Boolean := False;
   begin
      begin
         if Almost_Equal (Get_Max_Q (T, 99), 0.0) then null; end if;
      exception
         when Invalid_State => Caught_Max := True;
      end;
      begin
         if Get_Best_Action (T, 10) = 1 then null; end if;
      exception
         when Invalid_State => Caught_Act := True;
      end;
      Check ("11.1 Get_Max_Q correctly raises Invalid_State", Caught_Max);
      Check ("11.2 Get_Best_Action correctly raises Invalid_State", Caught_Act);
      Check ("11.3 Original table is unaltered", Almost_Equal (T(1,1), 5.0));
   end;

   Put_Line ("TEST 12 — Exceptions in Q-Learning Contract Checking");
   declare
      Caught_State, Caught_Next, Caught_Action : Boolean := False;
   begin
      begin
         Update_Q_Learning (T, 99, 1, 1.0, 2, 0.5, 0.9);
      exception when Invalid_State => Caught_State := True; end;
      begin
         Update_Q_Learning (T, 1, 1, 1.0, 99, 0.5, 0.9);
      exception when Invalid_State => Caught_Next := True; end;
      begin
         Update_Q_Learning (T, 1, 99, 1.0, 2, 0.5, 0.9);
      exception when Invalid_Action => Caught_Action := True; end;

      Check ("12.1 Raises Invalid_State for current state out of bounds", Caught_State);
      Check ("12.2 Raises Invalid_State for next state out of bounds", Caught_Next);
      Check ("12.3 Raises Invalid_Action for action out of bounds", Caught_Action);
   end;

   Put_Line ("TEST 13 — Exceptions in SARSA Contract Checking");
   declare
      Caught_State, Caught_Next_Action, Caught_Action : Boolean := False;
   begin
      begin
         Update_SARSA (T, 99, 1, 1.0, 2, 2, 0.5, 0.9);
      exception when Invalid_State => Caught_State := True; end;
      begin
         Update_SARSA (T, 1, 1, 1.0, 2, 99, 0.5, 0.9);
      exception when Invalid_Action => Caught_Next_Action := True; end;
      begin
         Update_SARSA (T, 1, 99, 1.0, 2, 2, 0.5, 0.9);
      exception when Invalid_Action => Caught_Action := True; end;

      Check ("13.1 Raises Invalid_State for current state out of bounds", Caught_State);
      Check ("13.2 Raises Invalid_Action for next action out of bounds", Caught_Next_Action);
      Check ("13.3 Raises Invalid_Action for current action out of bounds", Caught_Action);
   end;

   Put_Line ("TEST 14 — Empty Table Edge Cases");
   declare
      Empty_T : Q_Table (1 .. 0, 1 .. 0);
      Caught_State : Boolean := False;
      Caught_Action : Boolean := False;
   begin
      Initialize (Empty_T); -- Should execute without exception and do nothing

      begin
         if Almost_Equal (Get_Max_Q (Empty_T, 1), 0.0) then null; end if;
      exception
         when Invalid_State => Caught_State := True;
      end;

      declare
         Half_Empty : Q_Table (1 .. 1, 1 .. 0);
      begin
         Update_Q_Learning (Half_Empty, 1, 1, 1.0, 1, 0.5, 0.9);
      exception
         when Invalid_Action => Caught_Action := True;
      end;

      Check ("14.1 Get_Max_Q on fully empty table raises Invalid_State", Caught_State);
      Check ("14.2 Q-Learning with empty actions raises Invalid_Action", Caught_Action);
      Check ("14.3 Empty initialization safely does nothing", Caught_State and Caught_Action);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
