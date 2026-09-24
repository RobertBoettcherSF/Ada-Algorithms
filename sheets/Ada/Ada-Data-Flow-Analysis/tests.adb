with Ada.Text_IO; use Ada.Text_IO;
with Data_Flow_Analysis; use Data_Flow_Analysis;

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

   -- Variables for reuse in tests
   In_Mat  : Fact_Matrix (1 .. 3, 1 .. 2);
   Out_Mat : Fact_Matrix (1 .. 3, 1 .. 2);

   procedure Reset_Matrices is
   begin
      In_Mat  := [others => [others => False]];
      Out_Mat := [others => [others => False]];
   end Reset_Matrices;

begin
   Put_Line ("--- Starting Data-Flow Analysis Test Suite ---");

   -- TEST 1: Reaching Definitions - Linear Graph
   Put_Line ("TEST 1 — Reaching Definitions (Linear)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 2);
   begin
      Reset_Matrices;
      Add_Edge (CFG, 1, 2);
      Add_Edge (CFG, 2, 3);
      Add_Gen (CFG, 1, 1);
      Add_Gen (CFG, 2, 2);
      Add_Kill (CFG, 2, 1);

      Solve_Reaching_Definitions (CFG, In_Mat, Out_Mat);

      Check ("1.1 Fact 1 reaches Node 2 In", In_Mat (2, 1) = True);
      Check ("1.2 Fact 1 killed, does not reach Node 3 In", In_Mat (3, 1) = False);
      Check ("1.3 Fact 2 reaches Node 3 In", In_Mat (3, 2) = True);
   end;

   -- TEST 2: Reaching Definitions - Branching Graph
   Put_Line ("TEST 2 — Reaching Definitions (Branch)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 2);
   begin
      Reset_Matrices;
      Add_Edge (CFG, 1, 2);
      Add_Edge (CFG, 1, 3);
      Add_Gen (CFG, 1, 1);

      Solve_Reaching_Definitions (CFG, In_Mat, Out_Mat);

      Check ("2.1 Fact 1 reaches Node 2 In via branch", In_Mat (2, 1) = True);
      Check ("2.2 Fact 1 reaches Node 3 In via branch", In_Mat (3, 1) = True);
      Check ("2.3 Fact 2 is never generated", Out_Mat (3, 2) = False);
   end;

   -- TEST 3: Reaching Definitions - Loop Graph
   Put_Line ("TEST 3 — Reaching Definitions (Loop)");
   declare
      CFG : Control_Flow_Graph (Nodes => 2, Facts => 1);
      Loop_In  : Fact_Matrix (1 .. 2, 1 .. 1);
      Loop_Out : Fact_Matrix (1 .. 2, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 2);
      Add_Edge (CFG, 2, 1);
      Add_Gen (CFG, 2, 1);

      Solve_Reaching_Definitions (CFG, Loop_In, Loop_Out);

      Check ("3.1 Fact 1 reaches Node 1 In (loop back)", Loop_In (1, 1) = True);
      Check ("3.2 Fact 1 reaches Node 1 Out", Loop_Out (1, 1) = True);
      Check ("3.3 Fact 1 reaches Node 2 In", Loop_In (2, 1) = True);
   end;

   -- TEST 4: Live Variables - Linear
   Put_Line ("TEST 4 — Live Variables (Linear)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 2);
   begin
      Reset_Matrices;
      Add_Edge (CFG, 1, 2);
      Add_Edge (CFG, 2, 3);
      Add_Gen (CFG, 3, 1); -- Node 3 uses Fact 1
      Add_Kill (CFG, 2, 1); -- Node 2 defines Fact 1

      Solve_Live_Variables (CFG, In_Mat, Out_Mat);

      Check ("4.1 Fact 1 is live at Node 3 In", In_Mat (3, 1) = True);
      Check ("4.2 Fact 1 is live at Node 2 Out", Out_Mat (2, 1) = True);
      Check ("4.3 Fact 1 is dead at Node 1 Out (killed at 2)", Out_Mat (1, 1) = False);
   end;

   -- TEST 5: Live Variables - Dead Code / Unused
   Put_Line ("TEST 5 — Live Variables (Dead Code)");
   declare
      CFG : Control_Flow_Graph (Nodes => 2, Facts => 1);
      In_1 : Fact_Matrix (1 .. 2, 1 .. 1);
      Out_1 : Fact_Matrix (1 .. 2, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 2);
      Add_Kill (CFG, 1, 1); -- defined but never used

      Solve_Live_Variables (CFG, In_1, Out_1);

      Check ("5.1 Fact 1 is dead at Node 2 In", In_1 (2, 1) = False);
      Check ("5.2 Fact 1 is dead at Node 1 Out", Out_1 (1, 1) = False);
      Check ("5.3 Fact 1 is dead at Node 1 In", In_1 (1, 1) = False);
   end;

   -- TEST 6: Available Expressions - Branch (Must Analysis)
   Put_Line ("TEST 6 — Available Expressions (Branch)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 1);
      In_A : Fact_Matrix (1 .. 3, 1 .. 1);
      Out_A : Fact_Matrix (1 .. 3, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 3);
      Add_Edge (CFG, 2, 3);
      Add_Gen (CFG, 1, 1);
      -- Node 2 does NOT generate Fact 1.

      Solve_Available_Expressions (CFG, In_A, Out_A);

      Check ("6.1 Expr 1 available at Node 1 Out", Out_A (1, 1) = True);
      Check ("6.2 Expr 1 NOT available at Node 2 Out", Out_A (2, 1) = False);
      Check ("6.3 Expr 1 NOT available at Node 3 In (must analysis intersection)", In_A (3, 1) = False);
   end;

   -- TEST 7: Available Expressions - All Paths Generate
   Put_Line ("TEST 7 — Available Expressions (All Paths Generate)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 1);
      In_A : Fact_Matrix (1 .. 3, 1 .. 1);
      Out_A : Fact_Matrix (1 .. 3, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 3);
      Add_Edge (CFG, 2, 3);
      Add_Gen (CFG, 1, 1);
      Add_Gen (CFG, 2, 1);

      Solve_Available_Expressions (CFG, In_A, Out_A);

      Check ("7.1 Expr 1 available at Node 1 Out", Out_A (1, 1) = True);
      Check ("7.2 Expr 1 available at Node 2 Out", Out_A (2, 1) = True);
      Check ("7.3 Expr 1 IS available at Node 3 In (true on all paths)", In_A (3, 1) = True);
   end;

   -- TEST 8: Very Busy Expressions - Branch (Must Analysis)
   Put_Line ("TEST 8 — Very Busy Expressions (Branch)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 1);
      In_V : Fact_Matrix (1 .. 3, 1 .. 1);
      Out_V : Fact_Matrix (1 .. 3, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 2);
      Add_Edge (CFG, 1, 3);
      Add_Gen (CFG, 2, 1);
      Add_Gen (CFG, 3, 1);

      Solve_Very_Busy_Expressions (CFG, In_V, Out_V);

      Check ("8.1 Expr 1 busy at Node 2 In", In_V (2, 1) = True);
      Check ("8.2 Expr 1 busy at Node 3 In", In_V (3, 1) = True);
      Check ("8.3 Expr 1 IS busy at Node 1 Out (needed by all successors)", Out_V (1, 1) = True);
   end;

   -- TEST 9: Very Busy Expressions - Killed Before Use
   Put_Line ("TEST 9 — Very Busy Expressions (Killed Before Use)");
   declare
      CFG : Control_Flow_Graph (Nodes => 3, Facts => 1);
      In_V : Fact_Matrix (1 .. 3, 1 .. 1);
      Out_V : Fact_Matrix (1 .. 3, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 2);
      Add_Edge (CFG, 2, 3);
      Add_Gen (CFG, 3, 1);
      Add_Kill (CFG, 2, 1);

      Solve_Very_Busy_Expressions (CFG, In_V, Out_V);

      Check ("9.1 Expr 1 busy at Node 2 Out", Out_V (2, 1) = True);
      Check ("9.2 Expr 1 NOT busy at Node 2 In (killed)", In_V (2, 1) = False);
      Check ("9.3 Expr 1 NOT busy at Node 1 Out (killed before use)", Out_V (1, 1) = False);
   end;

   -- TEST 10: Single Node Graph
   Put_Line ("TEST 10 — Single Node Graph");
   declare
      CFG : Control_Flow_Graph (Nodes => 1, Facts => 1);
      In_1 : Fact_Matrix (1 .. 1, 1 .. 1);
      Out_1 : Fact_Matrix (1 .. 1, 1 .. 1);
   begin
      Add_Gen (CFG, 1, 1);
      Solve_Reaching_Definitions (CFG, In_1, Out_1);
      Check ("10.1 Reaching Defs: No In", In_1 (1, 1) = False);
      Check ("10.2 Reaching Defs: Gen Out", Out_1 (1, 1) = True);

      Solve_Very_Busy_Expressions (CFG, In_1, Out_1);
      Check ("10.3 Very Busy: Gen In", In_1 (1, 1) = True);
   end;

   -- TEST 11: Graph Exception Handling (Conflict Error)
   Put_Line ("TEST 11 — Graph Exception Handling");
   declare
      CFG : Control_Flow_Graph (Nodes => 1, Facts => 1);
      Caught : Boolean := False;
   begin
      Add_Gen (CFG, 1, 1);
      Add_Kill (CFG, 1, 1);
      begin
         Validate_Graph (CFG);
      exception
         when Graph_Conflict_Error =>
            Caught := True;
      end;
      Check ("11.1 Caught Graph_Conflict_Error as expected", Caught);
      Check ("11.2 Valid Gen retained", CFG.Gen (1, 1) = True);
      Check ("11.3 Valid Kill retained", CFG.Kill (1, 1) = True);
   end;

   -- TEST 12: All Kill No Gen
   Put_Line ("TEST 12 — All Kill No Gen");
   declare
      CFG : Control_Flow_Graph (Nodes => 2, Facts => 1);
      In_1 : Fact_Matrix (1 .. 2, 1 .. 1);
      Out_1 : Fact_Matrix (1 .. 2, 1 .. 1);
   begin
      Add_Edge (CFG, 1, 2);
      Add_Kill (CFG, 1, 1);
      Add_Kill (CFG, 2, 1);
      Solve_Live_Variables (CFG, In_1, Out_1);
      Check ("12.1 No variables live at node 2 out", Out_1 (2, 1) = False);
      Check ("12.2 No variables live at node 1 out", Out_1 (1, 1) = False);
      Check ("12.3 No variables live anywhere", In_1 (1, 1) = False);
   end;

   -- TEST 13: Disconnected Graph
   Put_Line ("TEST 13 — Disconnected Graph");
   declare
      CFG : Control_Flow_Graph (Nodes => 2, Facts => 1);
      In_1 : Fact_Matrix (1 .. 2, 1 .. 1);
      Out_1 : Fact_Matrix (1 .. 2, 1 .. 1);
   begin
      -- No edges added
      Add_Gen (CFG, 1, 1);
      Add_Gen (CFG, 2, 1);
      Solve_Available_Expressions (CFG, In_1, Out_1);
      
      Check ("13.1 Node 1 is an entry (no preds), In is empty", In_1 (1, 1) = False);
      Check ("13.2 Node 2 is an entry (no preds), In is empty", In_1 (2, 1) = False);
      Check ("13.3 Output holds generated expressions", Out_1 (1, 1) = True and Out_1 (2, 1) = True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
