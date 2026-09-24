with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions; use Ada.Exceptions;
with Uniform_Cost_Search; use Uniform_Cost_Search;

procedure Tests is
   G : Graph;
   Result : Search_Result;

   -- Helper for resetting the graph between tests
   procedure Reset_Graph is
      Empty_Graph : Graph;
   begin
      -- Assigning a fresh, default-initialized Graph properly clears the private type
      G := Empty_Graph;
   end Reset_Graph;
   
begin
   Put_Line ("=================================================");
   Put_Line ("  Uniform-Cost Search (UCS) Validation & Tests");
   Put_Line ("=================================================");
   Put_Line ("Testing Hypothesis: 'The code is incorrect'.");
   Put_Line ("PASS implies the hypothesis is false (Code works!).");
   Put_Line ("");

   -- TEST 1
   Put_Line ("TEST 1 - Standard Path Finding (A -> B -> C)");
   Put_Line ("  1.1 Assert path A->C evaluates to optimal sum cost");
   Put_Line ("  1.2 Assert correct number of nodes in result path");
   Reset_Graph;
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 10);
   Result := UCS_Graph_Search (G, 1, 3);
   Assert (Result.Found = True, "Path not found");
   Assert (Result.Cost = 15, "Cost is incorrect");
   Assert (Integer(Result.Path.Length) = 3, "Path length incorrect");
   Put_Line ("    PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Indirect Cheaper Path Preference");
   Put_Line ("  2.1 Assert direct expensive path is bypassed for indirect cheaper path");
   Reset_Graph;
   Add_Edge (G, 1, 3, 50); -- Direct (Expensive)
   Add_Edge (G, 1, 2, 10); -- Indirect (Cheap)
   Add_Edge (G, 2, 3, 15);
   Result := UCS_Graph_Search (G, 1, 3);
   Assert (Result.Cost = 25, "Algorithm picked direct, expensive path");
   Put_Line ("    PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Disconnected Graph / Unreachable Goal");
   Put_Line ("  3.1 Assert algorithm properly evaluates unreachable states");
   Reset_Graph;
   Add_Node (G, 1);
   Add_Node (G, 2);
   Result := UCS_Graph_Search (G, 1, 2);
   Assert (Result.Found = False, "False path discovered");
   Put_Line ("    PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Start Equals Goal");
   Put_Line ("  4.1 Assert cost is 0");
   Put_Line ("  4.2 Assert length of path is 1 (Just the start node)");
   Reset_Graph;
   Add_Node (G, 1);
   Result := UCS_Graph_Search (G, 1, 1);
   Assert (Result.Cost = 0, "Cost of Start=Goal is not 0");
   Assert (Integer(Result.Path.Length) = 1, "Length is not 1");
   Put_Line ("    PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Graph Cycles (Graph Search Mode)");
   Put_Line ("  5.1 Assert Graph Search terminates gracefully on circular references");
   Reset_Graph;
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 2, 1, 10);
   Add_Node (G, 3); -- Goal
   Result := UCS_Graph_Search (G, 1, 3);
   Assert (Result.Found = False, "Failed to terminate properly on cycle");
   Put_Line ("    PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Multiple Same-Cost Paths");
   Put_Line ("  6.1 Assert one of the optimal paths is successfully chosen");
   Reset_Graph;
   Add_Edge (G, 1, 2, 10); Add_Edge (G, 2, 4, 10); -- Cost 20
   Add_Edge (G, 1, 3, 10); Add_Edge (G, 3, 4, 10); -- Cost 20
   Result := UCS_Graph_Search (G, 1, 4);
   Assert (Result.Cost = 20, "Optimal path evaluation failed for symmetrical routes");
   Put_Line ("    PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Goal is Dead End / Backtracking");
   Put_Line ("  7.1 Assert algorithm fully explores prior bounds before failing or succeeding");
   Reset_Graph;
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 100); -- Unnecessarily long path
   Add_Edge (G, 1, 4, 10);
   Add_Edge (G, 4, 3, 10);  -- Shorter alternative
   Result := UCS_Graph_Search (G, 1, 3);
   Assert (Result.Cost = 20, "Failed to backtrack and find shorter path");
   Put_Line ("    PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Invalid Start Node");
   Put_Line ("  8.1 Assert Graph_Error exception is raised for non-existent start node");
   begin
      Reset_Graph;
      Add_Node (G, 2);
      Result := UCS_Graph_Search (G, 1, 2);
      Assert (False, "Exception was not raised");
   exception
      when Graph_Error => Put_Line ("    PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Invalid Goal Node");
   Put_Line ("  9.1 Assert Graph_Error exception is raised for non-existent goal node");
   begin
      Reset_Graph;
      Add_Node (G, 1);
      Result := UCS_Graph_Search (G, 1, 2);
      Assert (False, "Exception was not raised");
   exception
      when Graph_Error => Put_Line ("    PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Tree Search Cycle Exhaustion");
   Put_Line ("  10.1 Assert Tree Search triggers Limit Exception in cyclic environment without explored set");
   begin
      Reset_Graph;
      Add_Edge (G, 1, 2, 5);
      Add_Edge (G, 2, 1, 5); -- Cycle
      Add_Node (G, 3);
      Result := UCS_Tree_Search (G, 1, 3, Max_Expansions => 100);
      Assert (False, "Exception was not raised for Infinite Loop Tree Search");
   exception
      when Search_Limit_Exceeded => Put_Line ("    PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Tree Search Normal Validation");
   Put_Line ("  11.1 Assert Tree Search effectively finds paths in Acyclic environments");
   Reset_Graph;
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 10);
   Result := UCS_Tree_Search (G, 1, 3);
   Assert (Result.Found = True and Result.Cost = 15, "Tree Search failed standard graph");
   Put_Line ("    PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Cost Updating (Frontier Re-evaluation)");
   Put_Line ("  12.1 Assert algorithm queues duplicate nodes correctly and drops suboptimal routes");
   Reset_Graph;
   Add_Edge (G, 1, 2, 50);
   Add_Edge (G, 1, 3, 10);
   Add_Edge (G, 3, 2, 10); -- Reaches 2 with cost 20 (Better than 50)
   Add_Edge (G, 2, 4, 10);
   Result := UCS_Graph_Search (G, 1, 4);
   Assert (Result.Cost = 30, "Frontier overriding logic failed");
   Put_Line ("    PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Stress Test / Large Graphs");
   Put_Line ("  13.1 Assert algorithm handles large linear configurations efficiently");
   Reset_Graph;
   for I in Node_Id range 1 .. 99 loop
      Add_Edge (G, I, I + 1, 1);
   end loop;
   Result := UCS_Graph_Search (G, 1, 100);
   Assert (Result.Found = True and Result.Cost = 99, "Failed to resolve deep chain");
   Put_Line ("    PASS");

   -- TEST 14
   Put_Line ("TEST 14 - Zero-Cost Cycles Simulation");
   Put_Line ("  14.1 Assert algorithm avoids spinning endlessly on zero-cost loops");
   Reset_Graph;
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 1, 0);
   Add_Edge (G, 2, 3, 5);
   Result := UCS_Graph_Search (G, 1, 3);
   Assert (Result.Cost = 5, "Fell into infinite zero-cost trap");
   Put_Line ("    PASS");
   
   Put_Line ("");
   Put_Line ("=================================================");
   Put_Line ("ALL TESTS PASSED. The assumption that the code");
   Put_Line ("was incorrect has been successfully DISPROVEN.");
   Put_Line ("=================================================");

exception
   when E : Assertion_Error =>
      Put_Line ("    FAIL: " & Ada.Exceptions.Exception_Message (E));
      raise;
   when E : others =>
      Put_Line ("    FATAL ERROR: Unexpected Exception Caught");
      raise;
end Tests;
