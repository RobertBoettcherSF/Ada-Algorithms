-- tests.adb
-- Executable test suite ensuring Code Verification and Validation.
-- Proves functional requirements by contradicting pessimistic failure assumptions.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Topological_Sorting; use Topological_Sorting;

procedure Tests is

   -- Helper to print pass state
   procedure Pass(Desc : String) is
   begin
      Put_Line("     PASS: " & Desc);
   end Pass;

   -- Helper logic for empty graphs
   procedure Test_Empty_Graph is
      G : Graph(0);
      Res : Node_Array(1 .. 0);
      Success : Boolean;
   begin
      Put_Line("TEST 1 - Empty Graph Validation");
      
      Put_Line("  1.1 [Assertion: Kahn handles 0 nodes gracefully]");
      Kahn_Sort(G, Res, Success);
      Assert(Success, "Empty graph should succeed");
      Pass("Kahn Empty");

      Put_Line("  1.2 [Assertion: DFS handles 0 nodes gracefully]");
      DFS_Sort(G, Res, Success);
      Assert(Success, "Empty graph should succeed");
      Pass("DFS Empty");
   end Test_Empty_Graph;

   procedure Test_Single_Node is
      G : Graph(1);
      Res : Node_Array(1 .. 1);
      Success : Boolean;
   begin
      Put_Line("TEST 2 - Single Node Integrity");
      
      Put_Line("  2.1 [Assertion: Kahn sorts 1 node]");
      Kahn_Sort(G, Res, Success);
      Assert(Success and Res(1) = 1, "Single node Kahn failed");
      Pass("Kahn Single Node");

      Put_Line("  2.2 [Assertion: DFS sorts 1 node]");
      DFS_Sort(G, Res, Success);
      Assert(Success and Res(1) = 1, "Single node DFS failed");
      Pass("DFS Single Node");
   end Test_Single_Node;

   procedure Test_Linear_Chain is
      G : Graph(3);
      Res : Node_Array(1 .. 3);
      Success : Boolean;
   begin
      Add_Edge(G, 1, 2);
      Add_Edge(G, 2, 3);
      
      Put_Line("TEST 3 - Linear Chain Sorting (1->2->3)");
      Put_Line("  3.1 [Assertion: Kahn sorts linear dependency]");
      Kahn_Sort(G, Res, Success);
      Assert(Success and Is_Valid_Sort(G, Res), "Kahn Linear failed");
      Pass("Kahn Linear Chain");

      Put_Line("  3.2 [Assertion: DFS sorts linear dependency]");
      DFS_Sort(G, Res, Success);
      Assert(Success and Is_Valid_Sort(G, Res), "DFS Linear failed");
      Pass("DFS Linear Chain");
   end Test_Linear_Chain;

   procedure Test_Disconnected is
      G : Graph(4);
      Res : Node_Array(1 .. 4);
      Success : Boolean;
   begin
      -- 1->2 and 3->4 (Disconnected components)
      Add_Edge(G, 1, 2);
      Add_Edge(G, 3, 4);
      
      Put_Line("TEST 4 - Disconnected Components");
      Put_Line("  4.1 [Assertion: Kahn sorts disconnected graphs]");
      Kahn_Sort(G, Res, Success);
      Assert(Success and Is_Valid_Sort(G, Res), "Kahn Disconnected failed");
      Pass("Kahn Disconnected");

      Put_Line("  4.2 [Assertion: DFS sorts disconnected graphs]");
      DFS_Sort(G, Res, Success);
      Assert(Success and Is_Valid_Sort(G, Res), "DFS Disconnected failed");
      Pass("DFS Disconnected");
   end Test_Disconnected;

   procedure Test_Cycle_Detection is
      G : Graph(3);
      Res : Node_Array(1 .. 3);
      Success : Boolean;
   begin
      Add_Edge(G, 1, 2);
      Add_Edge(G, 2, 3);
      Add_Edge(G, 3, 1); -- Cycle
      
      Put_Line("TEST 5 - Simple Cycle Detection");
      Put_Line("  5.1 [Assertion: Kahn flags cycles]");
      Kahn_Sort(G, Res, Success);
      Assert(not Success, "Kahn missed cycle");
      Pass("Kahn Cycle Caught");

      Put_Line("  5.2 [Assertion: DFS flags cycles]");
      DFS_Sort(G, Res, Success);
      Assert(not Success, "DFS missed cycle");
      Pass("DFS Cycle Caught");
   end Test_Cycle_Detection;

   procedure Test_Self_Loop is
      G : Graph(2);
      Res : Node_Array(1 .. 2);
      Success : Boolean;
   begin
      Add_Edge(G, 1, 2);
      Add_Edge(G, 2, 2); -- Self Loop
      
      Put_Line("TEST 6 - Self-Loop Cycle Check");
      Put_Line("  6.1 [Assertion: Kahn rejects self-loop]");
      Kahn_Sort(G, Res, Success);
      Assert(not Success, "Kahn missed self-loop");
      Pass("Kahn Self-Loop");

      Put_Line("  6.2 [Assertion: DFS rejects self-loop]");
      DFS_Sort(G, Res, Success);
      Assert(not Success, "DFS missed self-loop");
      Pass("DFS Self-Loop");
   end Test_Self_Loop;

   procedure Test_Complex_DAG is
      G : Graph(6);
      Res : Node_Array(1 .. 6);
      Success : Boolean;
   begin
      Add_Edge(G, 6, 3);
      Add_Edge(G, 6, 1);
      Add_Edge(G, 5, 1);
      Add_Edge(G, 5, 2);
      Add_Edge(G, 3, 4);
      Add_Edge(G, 4, 2);

      Put_Line("TEST 7 - Complex valid DAG");
      Put_Line("  7.1 [Assertion: Kahn handles complex overlapping branches]");
      Kahn_Sort(G, Res, Success);
      Assert(Success and Is_Valid_Sort(G, Res), "Kahn Complex failed");
      Pass("Kahn Complex DAG Valid");

      Put_Line("  7.2 [Assertion: DFS handles complex overlapping branches]");
      DFS_Sort(G, Res, Success);
      Assert(Success and Is_Valid_Sort(G, Res), "DFS Complex failed");
      Pass("DFS Complex DAG Valid");
   end Test_Complex_DAG;

   -- TEST 8 (checker scan of the Is_Valid_* judges): Is_Valid_Sort against
   -- an own definition. A topological order of G lists every node 1 ..
   -- Num_Nodes exactly once, and for every edge U -> V, U comes before V.
   -- Every graph on 3 nodes (6 possible edges besides self-loops, plus a
   -- self-loop on node 1: 128 graphs) x every array of 3 values in 1 .. 4
   -- (64), at origins 1 and 5; values outside 1 .. Num_Nodes are not an
   -- order (the judge must say False, not raise).
   procedure Test_Judge is
      Wrong, Seen, Raised : Natural := 0;
      type Edge is record U, V : Node_ID; end record;
      Edges : constant array (1 .. 7) of Edge :=
        ((1, 2), (2, 1), (1, 3), (3, 1), (2, 3), (3, 2), (1, 1));
      function Own (G : Graph; Mask : Natural; R : Node_Array) return Boolean is
         Pos  : array (Node_ID range 1 .. 3) of Natural := (others => 0);
         M    : Natural := Mask;
      begin
         if R'Length /= G.Num_Nodes then
            return False;
         end if;
         for I in R'Range loop
            if R (I) > 3 or else Pos (R (I)) /= 0 then
               return False;
            end if;
            Pos (R (I)) := I - R'First + 1;
         end loop;
         for E of Edges loop
            if M mod 2 = 1 and then Pos (E.U) >= Pos (E.V) then
               return False;
            end if;
            M := M / 2;
         end loop;
         return True;
      end Own;
   begin
      Put_Line("TEST 8 - Is_Valid_Sort against an own definition (3 nodes)");
      for Mask in 0 .. 127 loop
         declare
            G : Graph (3);
            M : Natural := Mask;
         begin
            for E of Edges loop
               if M mod 2 = 1 then
                  Add_Edge (G, E.U, E.V);
               end if;
               M := M / 2;
            end loop;
            for Origin in 1 .. 2 loop
               for A in Node_ID range 1 .. 4 loop
                  for B in Node_ID range 1 .. 4 loop
                     for C in Node_ID range 1 .. 4 loop
                        declare
                           F : constant Positive := (if Origin = 1 then 1 else 5);
                           R : constant Node_Array (F .. F + 2) := (A, B, C);
                           Got : Boolean;
                        begin
                           Seen := Seen + 1;
                           begin
                              Got := Is_Valid_Sort (G, R);
                              if Got /= Own (G, Mask, R) then
                                 Wrong := Wrong + 1;
                              end if;
                           exception
                              when others => Raised := Raised + 1;
                           end;
                        end;
                     end loop;
                  end loop;
               end loop;
            end loop;
         end;
      end loop;
      Put_Line("  8.1 [Assertion: all" & Natural'Image (Seen)
               & " graph / array pairs judged as defined, none raises]");
      Assert (Wrong = 0 and Raised = 0,
              Natural'Image (Wrong) & " misjudged," & Natural'Image (Raised) & " raised");
      Pass("Is_Valid_Sort matches the definition");
   end Test_Judge;

begin
   Put_Line("===========================================");
   Put_Line("Starting Topological Sorting Validation Suite");
   Put_Line("===========================================");
   
   Test_Empty_Graph;
   Test_Single_Node;
   Test_Linear_Chain;
   Test_Disconnected;
   Test_Cycle_Detection;
   Test_Self_Loop;
   Test_Complex_DAG;
   Test_Judge;
   
   Put_Line("===========================================");
   Put_Line("ALL 15 ASSUMPTIONS DISPROVEN. CODE IS CORRECT.");
   Put_Line("TEST SUITE: PASS");
end Tests;
