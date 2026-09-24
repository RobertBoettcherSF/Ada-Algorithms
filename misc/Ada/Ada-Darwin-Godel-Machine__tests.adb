with Ada.Text_IO; use Ada.Text_IO;
with Darwin_Godel_Machine; use Darwin_Godel_Machine;

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

   -- Helper to force a constraint error dynamically bypassing static checks
   function Get_OOB return Float is
   begin
      return 15_000.0;
   end Get_OOB;

begin
   Put_Line ("Starting Darwin-Gödel Machine Tests...");
   Put_Line ("");

   -- TEST 1
   Put_Line ("TEST 1 — Agent Creation");
   declare
      A : constant Agent_State := Create_Agent (42, 75.5, 100);
   begin
      Check ("1.1 Correct ID", A.Id = 42);
      Check ("1.2 Correct Fitness", A.Fitness = 75.5);
      Check ("1.3 Correct Complexity", A.Complexity = 100);
   end;

   -- TEST 2
   Put_Line ("TEST 2 — Static Environment Evaluation");
   declare
      A : constant Agent_State := Create_Agent (1, 50.0, 50);
      E : constant Fitness_Value := Evaluate (A, Static_Env);
   begin
      Check ("2.1 Eval static matches exactly", E = 50.0);
      Check ("2.2 Eval static greater than 0", E > 0.0);
      Check ("2.3 Eval static under bounds", E < 100.0);
   end;

   -- TEST 3
   Put_Line ("TEST 3 — Dynamic Environment Evaluation");
   declare
      A_Low  : constant Agent_State := Create_Agent (1, 50.0, 50);
      A_High : constant Agent_State := Create_Agent (2, 50.0, 200);
   begin
      Check ("3.1 No penalty for low complexity", Evaluate (A_Low, Dynamic_Env) = 50.0);
      Check ("3.2 Penalty applied for high complexity", Evaluate (A_High, Dynamic_Env) < 50.0);
      Check ("3.3 Exact penalty calculated correctly (200-100)*0.1=10", Evaluate (A_High, Dynamic_Env) = 40.0);
   end;

   -- TEST 4
   Put_Line ("TEST 4 — Strict Verification (Success)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Cand : constant Agent_State := Create_Agent (2, 60.0, 110);
   begin
      Check ("4.1 strict passes with higher fitness & bounded complexity", Verify_Strict (Base, Cand, Static_Env));
      Check ("4.2 heuristic also passes", Verify_Heuristic (Base, Cand, Static_Env));
      Check ("4.3 Valid transition", Is_Valid_Transition (Base, Cand));
   end;

   -- TEST 5
   Put_Line ("TEST 5 — Strict Verification (Fail via Complexity)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Cand : constant Agent_State := Create_Agent (2, 60.0, 200);
   begin
      Check ("5.1 strict fails due to complexity > base+50", not Verify_Strict (Base, Cand, Static_Env));
      Check ("5.2 heuristic still passes", Verify_Heuristic (Base, Cand, Static_Env));
      Check ("5.3 transition logically valid", Is_Valid_Transition (Base, Cand));
   end;

   -- TEST 6
   Put_Line ("TEST 6 — Strict Verification (Fail via Fitness)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Cand : constant Agent_State := Create_Agent (2, 40.0, 100);
   begin
      Check ("6.1 strict fails due to lower fitness", not Verify_Strict (Base, Cand, Static_Env));
      Check ("6.2 heuristic also fails", not Verify_Heuristic (Base, Cand, Static_Env));
      Check ("6.3 candidate evaluates exactly", Evaluate (Cand, Static_Env) = 40.0);
   end;

   -- TEST 7
   Put_Line ("TEST 7 — Exhaustive Evolution (Improvement Found)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Pop  : constant Agent_Array (1 .. 3) :=
        [1 => Create_Agent (2, 55.0, 100),
         2 => Create_Agent (3, 70.0, 100),
         3 => Create_Agent (4, 60.0, 100)];
      Result : constant Agent_State := Evolve_Exhaustive (Base, Pop, Static_Env);
   begin
      Check ("7.1 picks the highest verified fitness", Result.Id = 3);
      Check ("7.2 sets level to Strict_Proof", Result.Level = Strict_Proof);
      Check ("7.3 improves fitness materially", Result.Fitness = 70.0);
   end;

   -- TEST 8
   Put_Line ("TEST 8 — Exhaustive Evolution (No Improvement)");
   declare
      Base : constant Agent_State := Create_Agent (1, 80.0, 100);
      Pop  : constant Agent_Array (1 .. 2) :=
        [1 => Create_Agent (2, 55.0, 100),
         2 => Create_Agent (3, 70.0, 100)];
      Result : constant Agent_State := Evolve_Exhaustive (Base, Pop, Static_Env);
   begin
      Check ("8.1 picks base agent when candidates fail verification", Result.Id = 1);
      Check ("8.2 verification level remains None", Result.Level = None);
      Check ("8.3 fitness remains unchanged", Result.Fitness = 80.0);
   end;

   -- TEST 9
   Put_Line ("TEST 9 — Preemptive Evolution (Early Stop)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Pop  : constant Agent_Array (1 .. 3) :=
        [1 => Create_Agent (2, 55.0, 100),
         2 => Create_Agent (3, 65.0, 200),
         3 => Create_Agent (4, 80.0, 100)];
      Result : constant Agent_State := Evolve_Preemptive (Base, Pop, Static_Env, 10.0);
   begin
      -- Threshold is 60.0. Cand 1=55(fail), Cand 2=65(passes preemptive heuristic!)
      Check ("9.1 Preemptive stops early at cand 2", Result.Id = 3);
      Check ("9.2 level mapped to Heuristic", Result.Level = Heuristic);
      Check ("9.3 Result fitness is correct", Result.Fitness = 65.0);
   end;

   -- TEST 10
   Put_Line ("TEST 10 — Preemptive Evolution (None Meet Threshold)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Pop  : constant Agent_Array (1 .. 2) :=
        [1 => Create_Agent (2, 55.0, 100),
         2 => Create_Agent (3, 58.0, 100)];
      Result : constant Agent_State := Evolve_Preemptive (Base, Pop, Static_Env, 10.0);
   begin
      Check ("10.1 returns base if target threshold is not achieved", Result.Id = 1);
      Check ("10.2 fitness aligns with base", Result.Fitness = 50.0);
      Check ("10.3 level retains None", Result.Level = None);
   end;

   -- TEST 11
   Put_Line ("TEST 11 — Dynamic Environment Interactions (Preemptive Search)");
   declare
      Base : constant Agent_State := Create_Agent (1, 50.0, 100);
      Pop  : constant Agent_Array (1 .. 2) :=
        [1 => Create_Agent (2, 70.0, 400),
         2 => Create_Agent (3, 60.0, 100)];
      Result : constant Agent_State := Evolve_Preemptive (Base, Pop, Dynamic_Env, 5.0);
   begin
      -- Target=55.0. Cand 1 penalty=(400-100)*.1=30, eval=40(fail). Cand 2 penalty=0, eval=60(pass).
      Check ("11.1 Dynamic env penalizes cand 1, discovers cand 2", Result.Id = 3);
      Check ("11.2 Result fitness matches expected selected node", Result.Fitness = 60.0);
      Check ("11.3 Level operates under Heuristic rules", Result.Level = Heuristic);
   end;

   -- TEST 12
   Put_Line ("TEST 12 — Empty Population Edge Case");
   declare
      Base : constant Agent_State := Create_Agent (1, 10.0, 10);
      Empty_Pop : constant Agent_Array (1 .. 0) := [others => Base];
      Ex_Caught : Boolean := False;
      Pr_Caught : Boolean := False;
   begin
      begin
         declare
            Dummy : Agent_State;
         begin
            Dummy := Evolve_Exhaustive (Base, Empty_Pop, Static_Env);
            Check ("Should not reach here", Dummy.Id = Positive'Last);
         exception
            when Population_Empty_Error => Ex_Caught := True;
         end;
      end;
      Check ("12.1 Exhaustive safely catches empty population", Ex_Caught);

      begin
         declare
            Dummy : Agent_State;
         begin
            Dummy := Evolve_Preemptive (Base, Empty_Pop, Static_Env, 5.0);
            Check ("Should not reach here", Dummy.Id = Positive'Last);
         exception
            when Population_Empty_Error => Pr_Caught := True;
         end;
      end;
      Check ("12.2 Preemptive safely catches empty population", Pr_Caught);
      Check ("12.3 Complete architectural safety on 0-bound inputs", Ex_Caught and Pr_Caught);
   end;

   -- TEST 13
   Put_Line ("TEST 13 — Exceptions & Constraints");
   declare
      Base : constant Agent_State := Create_Agent (1, 10.0, 10);
      Pop  : constant Agent_Array (1 .. 1) := [1 => Create_Agent (2, 20.0, 10)];
      Thresh_Caught : Boolean := False;
      CE_Caught : Boolean := False;
   begin
      begin
         declare
            Dummy : Agent_State;
         begin
            Dummy := Evolve_Preemptive (Base, Pop, Static_Env, 0.0);
            Check ("Should not reach here", Dummy.Id = Positive'Last);
         exception
            when Invalid_Threshold => Thresh_Caught := True;
         end;
      end;
      Check ("13.1 Preemptive search intercepts invalid threshold inputs", Thresh_Caught);

      begin
         declare
            Bad_Fit : Fitness_Value;
         begin
            Bad_Fit := Fitness_Value (Get_OOB);
            Check ("Should not reach here", Bad_Fit = Fitness_Value'Last);
         exception
            when Constraint_Error => CE_Caught := True;
         end;
      end;
      Check ("13.2 Type engine Constraint_Error thrown on invalid data", CE_Caught);

      Check ("13.3 Is_Valid_Transition evaluates correctly on healthy data", Is_Valid_Transition (Base, Pop (1)));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");

end Tests;
