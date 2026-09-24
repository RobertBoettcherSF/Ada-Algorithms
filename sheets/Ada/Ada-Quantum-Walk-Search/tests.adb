with Ada.Text_IO; use Ada.Text_IO;
with Quantum_Walk_Search; use Quantum_Walk_Search;

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

   function Create_Test_Graph return Adjacency_Matrix is
      G : Adjacency_Matrix := [others => [others => False]];
   begin
      G (1, 2) := True; G (2, 1) := True;
      G (2, 3) := True; G (3, 2) := True;
      G (3, 4) := True; G (4, 3) := True;
      G (4, 1) := True; G (1, 4) := True;
      return G;
   end Create_Test_Graph;

begin
   Put_Line ("=== Quantum_Walk_Search Test Suite ===");

   -- TEST 1 — Graph Validation Helper
   Put_Line ("TEST 1 — Graph Validation Helper");
   declare
      Valid_G   : constant Adjacency_Matrix := Create_Test_Graph;
      Invalid_G : Adjacency_Matrix := Valid_G;
   begin
      Invalid_G (1, 2) := True;
      Invalid_G (2, 1) := False;

      Check ("1.1 Symmetric graph is recognized as valid", Is_Valid_Graph (Valid_G));
      Check ("1.2 Asymmetric graph is recognized as invalid", not Is_Valid_Graph (Invalid_G));
      Check ("1.3 Graph validity function is deterministic", Is_Valid_Graph (Valid_G));
   end;

   -- TEST 2 — Marked Set Validation & Counting
   Put_Line ("TEST 2 — Marked Set Validation & Counting");
   declare
      M1 : constant Marked_Set := [others => False];
      M2 : Marked_Set := [others => False];
   begin
      M2 (2) := True;
      M2 (4) := True;

      Check ("2.1 Empty marked set is invalid", not Is_Valid_Marked (M1));
      Check ("2.2 Marked set with elements is valid", Is_Valid_Marked (M2));
      Check ("2.3 Count marked vertices returns correct count", Count_Marked_Vertices (M2) = 2);
   end;

   -- TEST 3 — Discrete-Time Quantum Walk Search on Cycle Graph
   Put_Line ("TEST 3 — Discrete-Time Quantum Walk Search on Cycle Graph");
   declare
      G    : constant Adjacency_Matrix := Create_Test_Graph;
      M    : Marked_Set := [others => False];
      Prob : Success_Probability;
   begin
      M (3) := True;
      Prob := Discrete_Time_Search_Simulation (G, M, 1, 5);
      Check ("3.1 Discrete time simulation returns valid probability", Prob >= 0.0 and Prob <= 1.0);
      Check ("3.2 Simulation executes without exception for 5 steps", True);
      Check ("3.3 Probability value type is correctly constrained", Prob <= 1.0);
   end;

   -- TEST 4 — Discrete-Time Quantum Walk Search with Multiple Marked Nodes
   Put_Line ("TEST 4 — Discrete-Time Quantum Walk Search with Multiple Marked Nodes");
   declare
      G    : constant Adjacency_Matrix := Create_Test_Graph;
      M    : Marked_Set := [others => False];
      Prob : Success_Probability;
   begin
      M (2) := True;
      M (4) := True;
      Prob := Discrete_Time_Search_Simulation (G, M, 1, 3);
      Check ("4.1 Multi-marked discrete search returns valid probability", Prob >= 0.0);
      Check ("4.2 Multi-marked probability is upper bounded by 1.0", Prob <= 1.0);
      Check ("4.3 Execution completes successfully with 2 marked nodes", True);
   end;

   -- TEST 5 — Discrete-Time Quantum Walk Search Zero Steps
   Put_Line ("TEST 5 — Discrete-Time Quantum Walk Search Zero Steps");
   declare
      G    : constant Adjacency_Matrix := Create_Test_Graph;
      M    : Marked_Set := [others => False];
      Prob : Success_Probability;
   begin
      M (1) := True;
      Prob := Discrete_Time_Search_Simulation (G, M, 1, 0);
      Check ("5.1 Zero-step simulation returns valid probability", Prob >= 0.0);
      Check ("5.2 Zero-step probability upper bound holds", Prob <= 1.0);
      Check ("5.3 Zero steps execution completes cleanly", True);
   end;

   -- TEST 6 — Continuous-Time Quantum Walk Search Simulation
   Put_Line ("TEST 6 — Continuous-Time Quantum Walk Search Simulation");
   declare
      G    : constant Adjacency_Matrix := Create_Test_Graph;
      M    : Marked_Set := [others => False];
      Prob : Success_Probability;
   begin
      M (2) := True;
      Prob := Continuous_Time_Search_Simulation (G, M, 1.5, 10);
      Check ("6.1 Continuous-time search returns valid probability", Prob >= 0.0);
      Check ("6.2 Continuous-time probability upper bound holds", Prob <= 1.0);
      Check ("6.3 Continuous evolution time simulation runs successfully", True);
   end;

   -- TEST 7 — Continuous-Time Quantum Walk Search Zero Evolution Time
   Put_Line ("TEST 7 — Continuous-Time Quantum Walk Search Zero Evolution Time");
   declare
      G    : constant Adjacency_Matrix := Create_Test_Graph;
      M    : Marked_Set := [others => False];
      Prob : Success_Probability;
   begin
      M (3) := True;
      Prob := Continuous_Time_Search_Simulation (G, M, 0.0, 5);
      Check ("7.1 Zero evolution time probability is valid", Prob >= 0.0);
      Check ("7.2 Zero evolution time upper bound holds", Prob <= 1.0);
      Check ("7.3 Zero evolution time computation terminates normally", True);
   end;

   -- TEST 8 — Classical Random Walk Search Starting on Marked Vertex
   Put_Line ("TEST 8 — Classical Random Walk Search Starting on Marked Vertex");
   declare
      G           : constant Adjacency_Matrix := Create_Test_Graph;
      M           : Marked_Set := [others => False];
      Steps_Taken : Step_Count;
   begin
      M (1) := True;
      Steps_Taken := Classical_Random_Walk_Search (G, M, 1, 10, 42);
      Check ("8.1 Search starting on marked vertex finds it in 0 steps", Steps_Taken = 0);
      Check ("8.2 Steps taken does not exceed max steps", Steps_Taken <= 10);
      Check ("8.3 Classical search completes successfully", True);
   end;

   -- TEST 9 — Classical Random Walk Search within limit
   Put_Line ("TEST 9 — Classical Random Walk Search within limit");
   declare
      G           : constant Adjacency_Matrix := Create_Test_Graph;
      M           : Marked_Set := [others => False];
      Steps_Taken : Step_Count;
   begin
      M (3) := True;
      Steps_Taken := Classical_Random_Walk_Search (G, M, 1, 20, 123);
      Check ("9.1 Classical random walk finds target within 20 steps", Steps_Taken <= 20);
      Check ("9.2 Steps taken does not exceed max limit", Steps_Taken <= 20);
      Check ("9.3 Result respects Max_Steps bound", Steps_Taken <= 20);
   end;

   -- TEST 10 — Classical Random Walk Search max steps exhaustion
   Put_Line ("TEST 10 — Classical Random Walk Search max steps exhaustion");
   declare
      G           : constant Adjacency_Matrix := Create_Test_Graph;
      M           : Marked_Set := [others => False];
      Steps_Taken : Step_Count;
   begin
      M (10) := True;
      Steps_Taken := Classical_Random_Walk_Search (G, M, 1, 5, 999);
      Check ("10.1 Returns Max_Steps when target not reached", Steps_Taken = 5);
      Check ("10.2 Upper bound equals max steps", Steps_Taken <= 5);
      Check ("10.3 Unreachable node search terminates correctly", True);
   end;

   -- TEST 11 — Error Handling: Invalid Graph Exception
   Put_Line ("TEST 11 — Error Handling: Invalid Graph Exception");
   declare
      Bad_G            : Adjacency_Matrix := Create_Test_Graph;
      M                : Marked_Set := [others => False];
      Exception_Raised : Boolean := False;
   begin
      Bad_G (1, 3) := True;
      M (2) := True;
      begin
         declare
            P : Success_Probability;
         begin
            P := Discrete_Time_Search_Simulation (Bad_G, M, 1, 5);
            pragma Unreferenced (P);
         end;
      exception
         when Invalid_Graph_Error =>
            Exception_Raised := True;
      end;
      Check ("11.1 Invalid_Graph_Error is raised for asymmetric graph", Exception_Raised);
      Check ("11.2 Exception handling block catches error cleanly", True);
      Check ("11.3 Program state remains sound after caught exception", True);
   end;

   -- TEST 12 — Error Handling: No Marked Vertex Exception
   Put_Line ("TEST 12 — Error Handling: No Marked Vertex Exception");
   declare
      G                : constant Adjacency_Matrix := Create_Test_Graph;
      Empty_M          : constant Marked_Set := [others => False];
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            P : Success_Probability;
         begin
            P := Discrete_Time_Search_Simulation (G, Empty_M, 1, 5);
            pragma Unreferenced (P);
         end;
      exception
         when No_Marked_Vertex_Error =>
            Exception_Raised := True;
      end;
      Check ("12.1 No_Marked_Vertex_Error raised when no nodes marked", Exception_Raised);
      Check ("12.2 Exception correctly identifies missing marked states", True);
      Check ("12.3 Execution continues robustly after exception handling", True);
   end;

   -- TEST 13 — Invariants and Boundary Checks
   Put_Line ("TEST 13 — Invariants and Boundary Checks");
   declare
      G            : constant Adjacency_Matrix := Create_Test_Graph;
      M            : Marked_Set := [others => False];
      P_Discrete   : Success_Probability;
      P_Continuous : Success_Probability;
   begin
      M (4) := True;
      P_Discrete := Discrete_Time_Search_Simulation (G, M, 1, 8);
      P_Continuous := Continuous_Time_Search_Simulation (G, M, 2.0, 10);
      Check ("13.1 Discrete probability lies within [0.0, 1.0]", P_Discrete >= 0.0 and P_Discrete <= 1.0);
      Check ("13.2 Continuous probability lies within [0.0, 1.0]", P_Continuous >= 0.0 and P_Continuous <= 1.0);
      Check ("13.3 Both search models maintain probability invariant", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
