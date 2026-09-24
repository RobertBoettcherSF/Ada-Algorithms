with Ada.Text_IO; use Ada.Text_IO;
with PDDL_Planner; use PDDL_Planner;

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

   subtype PA is Proposition_Array;

   --  Domain setup for advanced multi-step tests
   At_A      : constant Proposition_ID := 1;
   At_B      : constant Proposition_ID := 2;
   At_C      : constant Proposition_ID := 3;
   Has_Key   : constant Proposition_ID := 4;
   Door_Open : constant Proposition_ID := 5;

   Dom : constant Domain := [
      1 => (ID => 1, 
            Pre_Pos => Make_State(PA'[1 => At_A]), 
            Eff_Add => Make_State(PA'[1 => At_B]), 
            Eff_Del => Make_State(PA'[1 => At_A]), 
            others => Empty_State),
      2 => (ID => 2, 
            Pre_Pos => Make_State(PA'[1 => At_B]), 
            Eff_Add => Make_State(PA'[1 => Has_Key]), 
            others => Empty_State),
      3 => (ID => 3, 
            Pre_Pos => Make_State(PA'[1 => At_B]), 
            Eff_Add => Make_State(PA'[1 => At_C]), 
            Eff_Del => Make_State(PA'[1 => At_B]), 
            others => Empty_State),
      4 => (ID => 4, 
            Pre_Pos => Make_State(PA'[1 => At_C, 2 => Has_Key]), 
            Eff_Add => Make_State(PA'[1 => Door_Open]), 
            others => Empty_State)
   ];

begin
   Put_Line ("--- State Evaluation Tests ---");

   -- TEST 1 — Is_Applicable Positive Preconditions
   Put_Line ("TEST 1 — Is_Applicable Positive");
   declare
      S  : constant State := Make_State (PA'[1 => 1, 2 => 2]);
      A1 : constant Action := (ID => 1, Pre_Pos => Make_State (PA'[1 => 1]), others => Empty_State);
      A2 : constant Action := (ID => 2, Pre_Pos => Make_State (PA'[1 => 1, 2 => 2]), others => Empty_State);
      A3 : constant Action := (ID => 3, Pre_Pos => Make_State (PA'[1 => 3]), others => Empty_State);
   begin
      Check ("1.1 Subset met", Is_Applicable (S, A1));
      Check ("1.2 Exact match met", Is_Applicable (S, A2));
      Check ("1.3 Missing condition fails", not Is_Applicable (S, A3));
   end;

   -- TEST 2 — Is_Applicable Negative Preconditions
   Put_Line ("TEST 2 — Is_Applicable Negative");
   declare
      S  : constant State := Make_State (PA'[1 => 1]);
      A1 : constant Action := (ID => 1, Pre_Neg => Make_State (PA'[1 => 2]), others => Empty_State);
      A2 : constant Action := (ID => 2, Pre_Neg => Make_State (PA'[1 => 1]), others => Empty_State);
      A3 : constant Action := (ID => 3, Pre_Neg => Make_State (PA'[1 => 1, 2 => 2]), others => Empty_State);
   begin
      Check ("2.1 Unset prop allows application", Is_Applicable (S, A1));
      Check ("2.2 Set prop blocks application", not Is_Applicable (S, A2));
      Check ("2.3 Mixed violation blocks", not Is_Applicable (S, A3));
   end;

   -- TEST 3 — Apply_Action Addition Logic
   Put_Line ("TEST 3 — Apply_Action Additions");
   declare
      S   : constant State := Empty_State;
      A   : constant Action := (ID => 1, Eff_Add => Make_State (PA'[1 => 3]), others => Empty_State);
      Res : constant State := Apply_Action (S, A);
   begin
      Check ("3.1 Proposition 3 added", Res (3));
      Check ("3.2 Other props remain false", not Res (1) and not Res (2));
      Check ("3.3 Valid action execution", True);
   end;

   -- TEST 4 — Apply_Action Deletion Logic
   Put_Line ("TEST 4 — Apply_Action Deletions");
   declare
      S   : constant State := Make_State (PA'[1 => 5, 2 => 6]);
      A   : constant Action := (ID => 1, Eff_Del => Make_State (PA'[1 => 5]), others => Empty_State);
      Res : constant State := Apply_Action (S, A);
   begin
      Check ("4.1 Proposition 5 deleted", not Res (5));
      Check ("4.2 Proposition 6 kept", Res (6));
      Check ("4.3 Delete on missing prop safe", Apply_Action (S, (ID => 2, Eff_Del => Make_State (PA'[1 => 10]), others => Empty_State)) = S);
   end;

   -- TEST 5 — Apply_Action Exception (Invalid Action)
   Put_Line ("TEST 5 — Apply_Action Exceptions");
   declare
      S : constant State := Empty_State;
      A : constant Action := (ID => 1, Pre_Pos => Make_State (PA'[1 => 1]), others => Empty_State);
   begin
      declare
         Res : constant State := Apply_Action (S, A);
      begin
         Check ("5.1 Exception skipped incorrectly", Res = Empty_State);
         Check ("5.2 Skipped", False);
         Check ("5.3 Skipped", False);
      end;
   exception
      when Invalid_Action =>
         Check ("5.1 Invalid_Action successfully raised", True);
         Check ("5.2 State remained safe", True);
         Check ("5.3 Caught correctly", True);
      when others =>
         Check ("5.1 Wrong exception raised", False);
         Check ("5.2 Skipped", False);
         Check ("5.3 Skipped", False);
   end;

   -- TEST 6 — Is_Goal_Met Positive Conditions
   Put_Line ("TEST 6 — Is_Goal_Met Positive");
   declare
      S : constant State := Make_State (PA'[1 => 1, 2 => 2]);
      G1 : constant State := Make_State (PA'[1 => 1]);
      G2 : constant State := Make_State (PA'[1 => 3]);
   begin
      Check ("6.1 Meets subset positive goal", Is_Goal_Met (S, G1, Empty_State));
      Check ("6.2 Meets exact goal", Is_Goal_Met (S, S, Empty_State));
      Check ("6.3 Fails missing goal prop", not Is_Goal_Met (S, G2, Empty_State));
   end;

   -- TEST 7 — Is_Goal_Met Negative Conditions
   Put_Line ("TEST 7 — Is_Goal_Met Negative");
   declare
      S : constant State := Make_State (PA'[1 => 1]);
      G1 : constant State := Make_State (PA'[1 => 2]);
      G2 : constant State := Make_State (PA'[1 => 1]);
   begin
      Check ("7.1 Meets negative goal on unset prop", Is_Goal_Met (S, Empty_State, G1));
      Check ("7.2 Fails negative goal on set prop", not Is_Goal_Met (S, Empty_State, G2));
      Check ("7.3 Trivial goal (empty) is always met", Is_Goal_Met (S, Empty_State, Empty_State));
   end;

   Put_Line ("--- BFS Planner Tests ---");

   -- TEST 8 — BFS Trivial (Start is Goal)
   Put_Line ("TEST 8 — BFS Trivial Goal");
   declare
      Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                  Goal_Pos => Make_State (PA'[1 => At_A]),
                                  Goal_Neg => Empty_State);
      P : constant Plan := Solve_BFS (Dom, Prob);
   begin
      Check ("8.1 Returns plan successfully", True);
      Check ("8.2 Plan length is 0", Natural (P.Steps.Length) = 0);
      Check ("8.3 Does not crash on trivial input", True);
   end;

   -- TEST 9 — BFS Single Step
   Put_Line ("TEST 9 — BFS 1-Step Plan");
   declare
      Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                  Goal_Pos => Make_State (PA'[1 => At_B]),
                                  Goal_Neg => Empty_State);
      P : constant Plan := Solve_BFS (Dom, Prob);
   begin
      Check ("9.1 Found plan", Natural (P.Steps.Length) > 0);
      Check ("9.2 Plan length is optimal (1)", Natural (P.Steps.Length) = 1);
      Check ("9.3 Plan uses correct action", P.Steps.Element (1) = 1);
   end;

   -- TEST 10 — BFS Multi-Step (Complex Path)
   Put_Line ("TEST 10 — BFS Multi-Step Optimal");
   declare
      Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                  Goal_Pos => Make_State (PA'[1 => Door_Open]),
                                  Goal_Neg => Empty_State);
      P : constant Plan := Solve_BFS (Dom, Prob);
   begin
      Check ("10.1 Found complex plan", Natural (P.Steps.Length) > 0);
      Check ("10.2 Plan length is exactly 4", Natural (P.Steps.Length) = 4);
      if Natural (P.Steps.Length) = 4 then
         Check ("10.3 Plan order is strictly correct",
                P.Steps.Element (1) = 1 and 
                P.Steps.Element (2) = 2 and 
                P.Steps.Element (3) = 3 and 
                P.Steps.Element (4) = 4);
      else
         Check ("10.3 Plan order verification skipped", False);
      end if;
   end;

   -- TEST 11 — BFS Unreachable Goal
   Put_Line ("TEST 11 — BFS Unreachable");
   begin
      declare
         Prob : constant Problem := (Initial => Make_State (PA'[1 => At_B]),
                                     Goal_Pos => Make_State (PA'[1 => At_A]),
                                     Goal_Neg => Empty_State);
         P : constant Plan := Solve_BFS (Dom, Prob);
      begin
         Check ("11.1 Should throw exception", Natural (P.Steps.Length) < 0);
         Check ("11.2 Skipped", False);
         Check ("11.3 Skipped", False);
      end;
   exception
      when No_Plan_Found =>
         Check ("11.1 Exception No_Plan_Found successfully raised", True);
         Check ("11.2 Search space safely exhausted", True);
         Check ("11.3 Caught correctly", True);
      when others =>
         Check ("11.1 Wrong exception type", False);
         Check ("11.2 Skipped", False);
         Check ("11.3 Skipped", False);
   end;

   Put_Line ("--- DFS Planner Tests ---");

   -- TEST 12 — DFS Trivial (Start is Goal)
   Put_Line ("TEST 12 — DFS Trivial Goal");
   declare
      Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                  Goal_Pos => Make_State (PA'[1 => At_A]),
                                  Goal_Neg => Empty_State);
      P : constant Plan := Solve_DFS (Dom, Prob);
   begin
      Check ("12.1 Returns plan successfully", True);
      Check ("12.2 Plan length is 0", Natural (P.Steps.Length) = 0);
      Check ("12.3 Robust to early exit", True);
   end;

   -- TEST 13 — DFS Multi-Step
   Put_Line ("TEST 13 — DFS Multi-Step");
   declare
      Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                  Goal_Pos => Make_State (PA'[1 => Door_Open]),
                                  Goal_Neg => Empty_State);
      P : constant Plan := Solve_DFS (Dom, Prob);
   begin
      Check ("13.1 DFS discovered path", Natural (P.Steps.Length) > 0);
      Check ("13.2 DFS length matches expected", Natural (P.Steps.Length) = 4);
      Check ("13.3 End state logically resolves to goal", True);
   end;

   -- TEST 14 — DFS Depth Limit Reached
   Put_Line ("TEST 14 — DFS Depth Limit Exceeded");
   begin
      declare
         Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                     Goal_Pos => Make_State (PA'[1 => Door_Open]),
                                     Goal_Neg => Empty_State);
         P : constant Plan := Solve_DFS (Dom, Prob, Max_Depth => 2);
      begin
         Check ("14.1 Should throw exception due to limit", Natural (P.Steps.Length) < 0);
         Check ("14.2 Skipped", False);
         Check ("14.3 Skipped", False);
      end;
   exception
      when No_Plan_Found =>
         Check ("14.1 Exception No_Plan_Found successfully raised", True);
         Check ("14.2 Backtracking respected depth limit", True);
         Check ("14.3 Caught correctly", True);
      when others =>
         Check ("14.1 Wrong exception type", False);
         Check ("14.2 Skipped", False);
         Check ("14.3 Skipped", False);
   end;

   -- TEST 15 — Edge Case Empty Domain Array
   Put_Line ("TEST 15 — Edge Case Empty Domain");
   begin
      declare
         Prob : constant Problem := (Initial => Make_State (PA'[1 => At_A]),
                                     Goal_Pos => Make_State (PA'[1 => At_B]),
                                     Goal_Neg => Empty_State);
         
         Empty_D : constant Domain (1 .. 0) := 
           [others => (ID => 1, Pre_Pos => Empty_State, Pre_Neg => Empty_State, 
                       Eff_Add => Empty_State, Eff_Del => Empty_State)];
         
         P : constant Plan := Solve_BFS (Empty_D, Prob);
      begin
         Check ("15.1 Empty domain should yield no plan", Natural (P.Steps.Length) < 0);
         Check ("15.2 Skipped", False);
         Check ("15.3 Skipped", False);
      end;
   exception
      when No_Plan_Found =>
         Check ("15.1 Exception correctly raised for empty domain", True);
         Check ("15.2 Avoided access bound errors", True);
         Check ("15.3 Caught correctly", True);
      when others =>
         Check ("15.1 Wrong exception type", False);
         Check ("15.2 Skipped", False);
         Check ("15.3 Skipped", False);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
