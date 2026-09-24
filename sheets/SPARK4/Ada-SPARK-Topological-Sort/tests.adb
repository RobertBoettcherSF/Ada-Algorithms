--  Standalone test suite for Topological_Sorting (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Nodes are 1 .. N with N <= Max_Nodes. SPARK proves Success ⇒
--  Is_Valid_Sort; this suite checks that DAGs actually succeed, that
--  cycles fail, and that Is_Valid_Sort rejects bad permutations.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Topological_Sorting; use Topological_Sorting;

procedure Tests
  with SPARK_Mode => Off
is

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
   function Int (X : Integer) return Integer is (X);
   function Boo (X : Boolean) return Boolean is (X);

   procedure Expect_DAG (G : Graph; Label : String) is
      Result  : Node_Array (1 .. G.Num_Nodes);
      Success : Boolean;
   begin
      Kahn_Sort (G, Result, Success);
      Check (Boo (Success), Label & " Success");
      Check (Boo (Is_Valid_Sort (G, Result)), Label & " Is_Valid_Sort");
      Check (Nat (Result'Length) = Nat (G.Num_Nodes), Label & " length");
   end Expect_DAG;

   procedure Expect_Cycle (G : Graph; Label : String) is
      Result  : Node_Array (1 .. G.Num_Nodes);
      Success : Boolean;
   begin
      Kahn_Sort (G, Result, Success);
      Check (not Boo (Success), Label & " rejected");
   end Expect_Cycle;

begin
   Put_Line ("Topological_Sorting (SPARK) tests");
   Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Empty and singleton");
   ---------------------------------------------------------------------
   declare
      G0      : Graph (0);
      Empty   : Node_Array (1 .. 0);
      Success : Boolean;
   begin
      Check (Nat (G0.Num_Nodes) = 0, "empty Num_Nodes");
      Check (Boo (In_Bounds (Empty)), "empty In_Bounds");
      Check (Boo (Result_Shape (G0, Empty)), "empty Result_Shape");
      Kahn_Sort (G0, Empty, Success);
      Check (Boo (Success), "empty Success");
      Check (Boo (Is_Valid_Sort (G0, Empty)), "empty Is_Valid_Sort");
   end;
   declare
      G1      : Graph (1);
      Result  : Node_Array (1 .. 1) := [1 => 1];
      Success : Boolean;
   begin
      Check (Boo (In_Bounds (Result)), "singleton In_Bounds");
      Check (not Boo (Has_Edge (G1, 1, 1)), "singleton no loop");
      Kahn_Sort (G1, Result, Success);
      Check (Boo (Success), "singleton Success");
      Check (Int (Integer (Result (1))) = 1, "singleton value");
      Check (Boo (Is_Valid_Sort (G1, Result)), "singleton Is_Valid_Sort");
   end;

   ---------------------------------------------------------------------
   Section ("2. Linear chain 1 → 2 → 3");
   ---------------------------------------------------------------------
   declare
      G : Graph (3);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Check (Boo (Has_Edge (G, 1, 2)), "chain 1→2");
      Check (Boo (Has_Edge (G, 2, 3)), "chain 2→3");
      Check (not Boo (Has_Edge (G, 3, 1)), "chain no 3→1");
      Expect_DAG (G, "linear 3");
      declare
         Result  : Node_Array (1 .. 3);
         Success : Boolean;
      begin
         Kahn_Sort (G, Result, Success);
         Check (Int (Integer (Result (1))) = 1, "chain first is 1");
         Check (Int (Integer (Result (2))) = 2, "chain mid is 2");
         Check (Int (Integer (Result (3))) = 3, "chain last is 3");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Disconnected components");
   ---------------------------------------------------------------------
   declare
      G : Graph (4);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 3, 4);
      Expect_DAG (G, "disconnected");
   end;
   declare
      G : Graph (5);
   begin
      --  Three isolated nodes plus 2 → 5.
      Add_Edge (G, 2, 5);
      Expect_DAG (G, "mostly isolated");
   end;

   ---------------------------------------------------------------------
   Section ("4. Cycle detection");
   ---------------------------------------------------------------------
   declare
      G : Graph (3);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Expect_Cycle (G, "triangle");
   end;
   declare
      G : Graph (2);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Expect_Cycle (G, "two-cycle");
   end;
   declare
      G : Graph (4);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 2);
      Expect_Cycle (G, "cycle in tail");
   end;
   declare
      G : Graph (1);
   begin
      Add_Edge (G, 1, 1);
      Check (Boo (Has_Edge (G, 1, 1)), "self-loop stored");
      Expect_Cycle (G, "self-loop n=1");
   end;
   declare
      G : Graph (2);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 2);
      Expect_Cycle (G, "self-loop n=2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Diamond and branching DAGs");
   ---------------------------------------------------------------------
   declare
      G : Graph (4);
   begin
      --  1 → 2 → 4 and 1 → 3 → 4
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Expect_DAG (G, "diamond");
      declare
         Result  : Node_Array (1 .. 4);
         Success : Boolean;
      begin
         Kahn_Sort (G, Result, Success);
         Check (Int (Integer (Result (1))) = 1, "diamond starts at 1");
         Check (Int (Integer (Result (4))) = 4, "diamond ends at 4");
      end;
   end;
   declare
      G : Graph (3);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Expect_DAG (G, "star out");
   end;
   declare
      G : Graph (3);
   begin
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 3);
      Expect_DAG (G, "star in");
   end;

   ---------------------------------------------------------------------
   Section ("6. Complex DAG (sibling Wikipedia-style)");
   ---------------------------------------------------------------------
   declare
      G : Graph (6);
   begin
      --  Same edges as Ada-Topological-Sort TEST 7.
      Add_Edge (G, 6, 3);
      Add_Edge (G, 6, 1);
      Add_Edge (G, 5, 1);
      Add_Edge (G, 5, 2);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 2);
      Expect_DAG (G, "complex 6");
      declare
         Result  : Node_Array (1 .. 6);
         Success : Boolean;
      begin
         Kahn_Sort (G, Result, Success);
         --  5 and 6 have indegree 0; 2 is a sink.
         Check
           (Int (Integer (Result (1))) = 5
            or else Int (Integer (Result (1))) = 6,
            "complex starts at a source");
         Check (Int (Integer (Result (6))) = 2, "complex sink is 2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Wikipedia-style 8-node DAG");
   ---------------------------------------------------------------------
   declare
      G : Graph (8);
   begin
      --  Remap of the common Wikipedia figure
      --  (5,7,3,11,8,2,9,10) → (1,2,3,4,5,6,7,8):
      --    1→4, 2→4, 2→5, 3→5, 3→8, 4→6, 4→7, 5→7, 4→8
      Add_Edge (G, 1, 4);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 2, 5);
      Add_Edge (G, 3, 5);
      Add_Edge (G, 3, 8);
      Add_Edge (G, 4, 6);
      Add_Edge (G, 4, 7);
      Add_Edge (G, 5, 7);
      Add_Edge (G, 4, 8);
      Expect_DAG (G, "wikipedia 8");
   end;

   ---------------------------------------------------------------------
   Section ("8. Is_Valid_Sort rejects bad orders");
   ---------------------------------------------------------------------
   declare
      G : Graph (3);
      Reverse_Order : constant Node_Array := [3, 2, 1];
      Dup           : constant Node_Array := [1, 1, 2];
      Missing       : constant Node_Array := [1, 2, 2];
      Good          : constant Node_Array := [1, 2, 3];
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Check (Boo (Is_Valid_Sort (G, Good)), "good order accepted");
      Check (not Boo (Is_Valid_Sort (G, Reverse_Order)), "reverse rejected");
      Check (not Boo (Is_Valid_Sort (G, Dup)), "duplicate rejected");
      Check (not Boo (Is_Valid_Sort (G, Missing)), "missing 3 rejected");
   end;
   declare
      G : Graph (4);
      Swap_Sinks : constant Node_Array := [1, 4, 2, 3];
      --  1→2, 1→3, 2→4, 3→4 so 4 cannot precede 2 or 3.
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Check (not Boo (Is_Valid_Sort (G, Swap_Sinks)), "early sink rejected");
      Check (Boo (Is_Valid_Sort (G, [1, 2, 3, 4])), "1,2,3,4 ok");
      Check (Boo (Is_Valid_Sort (G, [1, 3, 2, 4])), "1,3,2,4 ok");
   end;

   ---------------------------------------------------------------------
   Section ("9. Clear, Add_Edge idempotence");
   ---------------------------------------------------------------------
   declare
      G : Graph (3);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Check (Boo (Has_Edge (G, 1, 2)), "idempotent add");
      Add_Edge (G, 2, 3);
      Clear (G);
      Check (not Boo (Has_Edge (G, 1, 2)), "cleared 1→2");
      Check (not Boo (Has_Edge (G, 2, 3)), "cleared 2→3");
      Check (Nat (G.Num_Nodes) = 3, "Clear keeps N");
      Expect_DAG (G, "cleared edgeless");
      Add_Edge (G, 3, 1);
      Expect_DAG (G, "after re-add");
   end;

   ---------------------------------------------------------------------
   Section ("10. Two-node and reverse chain");
   ---------------------------------------------------------------------
   declare
      G : Graph (2);
      Result  : Node_Array (1 .. 2);
      Success : Boolean;
   begin
      Add_Edge (G, 2, 1);
      Kahn_Sort (G, Result, Success);
      Check (Boo (Success), "reverse pair Success");
      Check (Int (Integer (Result (1))) = 2, "reverse pair first 2");
      Check (Int (Integer (Result (2))) = 1, "reverse pair last 1");
      Check (Boo (Is_Valid_Sort (G, Result)), "reverse pair valid");
   end;
   declare
      G : Graph (2);
   begin
      Expect_DAG (G, "edgeless pair");
   end;

   ---------------------------------------------------------------------
   Section ("11. Long chain and Max_Nodes");
   ---------------------------------------------------------------------
   declare
      G : Graph (Max_Nodes);
   begin
      for I in Node_Id range 1 .. Max_Nodes - 1 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Expect_DAG (G, "chain 32");
      declare
         Result  : Node_Array (1 .. Max_Nodes);
         Success : Boolean;
      begin
         Kahn_Sort (G, Result, Success);
         Check (Int (Integer (Result (1))) = 1, "chain32 starts at 1");
         Check
           (Int (Integer (Result (Max_Nodes))) = Max_Nodes,
            "chain32 ends at N");
         for I in 1 .. Max_Nodes loop
            if Integer (Result (I)) /= I then
               Check (False, "chain32 identity");
               exit;
            elsif I = Max_Nodes then
               Check (True, "chain32 identity");
            end if;
         end loop;
      end;
   end;
   declare
      G : Graph (Max_Nodes);
   begin
      --  Complete acyclic tournament: i → j iff i < j.
      for I in Node_Id loop
         for J in Node_Id range I + 1 .. Max_Nodes loop
            Add_Edge (G, I, J);
         end loop;
      end loop;
      Expect_DAG (G, "tournament 32");
   end;
   declare
      G : Graph (Max_Nodes);
   begin
      Add_Edge (G, 1, Max_Nodes);
      Add_Edge (G, Max_Nodes, 1);
      Expect_Cycle (G, "cycle at capacity");
   end;

   ---------------------------------------------------------------------
   Section ("12. Isolated Max_Nodes and single edge");
   ---------------------------------------------------------------------
   declare
      G : Graph (Max_Nodes);
   begin
      Expect_DAG (G, "edgeless 32");
   end;
   declare
      G : Graph (7);
   begin
      Add_Edge (G, 7, 1);
      Expect_DAG (G, "single edge 7→1");
   end;
   declare
      G : Graph (4);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 1, 4);
      Expect_DAG (G, "transitive + extra");
   end;

   ---------------------------------------------------------------------
   Section ("13. Cycle plus extra sources");
   ---------------------------------------------------------------------
   declare
      G : Graph (5);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 2);
      Add_Edge (G, 4, 1);
      Expect_Cycle (G, "cycle with source");
   end;
   declare
      G : Graph (3);
   begin
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 3);
      Expect_Cycle (G, "self-loop at sink");
   end;

   ---------------------------------------------------------------------
   Section ("14. Contract helpers");
   ---------------------------------------------------------------------
   declare
      G  : Graph (4);
      R0 : Node_Array (1 .. 0);
      R4 : constant Node_Array (1 .. 4) := [others => 1];
   begin
      Check (Boo (In_Bounds (R4)), "n=4 In_Bounds");
      Check (Boo (In_Bounds (R0)), "empty buffer In_Bounds");
      Check (Boo (Result_Shape (G, R4)), "n=4 Result_Shape");
      Check (not Boo (Result_Shape (G, R0)), "wrong length shape");
      Check (not Boo (Has_Edge (G, 1, 4)), "no phantom edge");
      Check (Nat (Max_Nodes) = 32, "Max_Nodes is 32");
   end;

   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "Topological_Sorting tests failed";
   end if;
end Tests;
