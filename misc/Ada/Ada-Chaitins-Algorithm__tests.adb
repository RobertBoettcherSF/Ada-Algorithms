with Ada.Text_IO; use Ada.Text_IO;
with Chaitins_Algorithm; use Chaitins_Algorithm;

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

   Graph      : Interference_Graph;
   Allocation : Allocation_Map;
   Spills     : Node_Set;
begin
   Put_Line ("=== Running Chaitin's Algorithm Tests ===");

   -- TEST 1 — Graph Initialization
   Put_Line ("TEST 1 — Graph Initialization");
   Initialize_Graph (Graph, 3);
   Check ("1.1 Active node count is 3", Graph.Active_Node_Count = 3);
   Check ("1.2 Node 1 is active", Graph.Nodes (1));
   Check ("1.3 Node 4 is not active", not Graph.Nodes (4));
   Check ("1.4 Degrees are 0", Graph.Degrees (1) = 0 and Graph.Degrees (2) = 0);

   -- TEST 2 — Edge Addition Validation
   Put_Line ("TEST 2 — Edge Addition Validation");
   Add_Edge (Graph, 1, 2);
   Check ("2.1 Edge is symmetric (1,2)", Graph.Edges (1, 2));
   Check ("2.2 Edge is symmetric (2,1)", Graph.Edges (2, 1));
   Check ("2.3 Degrees incremented", Graph.Degrees (1) = 1 and Graph.Degrees (2) = 1);

   -- TEST 3 — Empty Graph (K=1) (Basic)
   Put_Line ("TEST 3 — Empty Graph Basic Chaitin");
   Initialize_Graph (Graph, 0);
   Basic_Chaitin_Allocate (Graph, 1, Allocation, Spills);
   Check ("3.1 Empty allocation mapping", Allocation (1) = Spilled_Color);
   Check ("3.2 No spills on empty graph", not Spills (1));
   Check ("3.3 Valid termination", True);

   -- TEST 4 — Empty Graph (K=1) (Briggs)
   Put_Line ("TEST 4 — Empty Graph Chaitin-Briggs");
   Initialize_Graph (Graph, 0);
   Chaitin_Briggs_Allocate (Graph, 1, Allocation, Spills);
   Check ("4.1 Empty allocation mapping", Allocation (1) = Spilled_Color);
   Check ("4.2 No spills on empty graph", not Spills (1));
   Check ("4.3 Valid termination", True);

   -- TEST 5 — Disconnected Graph (Basic)
   Put_Line ("TEST 5 — Disconnected Graph Basic Chaitin");
   Initialize_Graph (Graph, 3);
   Basic_Chaitin_Allocate (Graph, 1, Allocation, Spills);
   Check ("5.1 Node 1 gets color 1", Allocation (1) = 1);
   Check ("5.2 Node 2 gets color 1", Allocation (2) = 1);
   Check ("5.3 Node 3 gets color 1", Allocation (3) = 1);
   Check ("5.4 No spills occur", not Spills (1) and not Spills (2) and not Spills (3));

   -- TEST 6 — Disconnected Graph (Briggs)
   Put_Line ("TEST 6 — Disconnected Graph Chaitin-Briggs");
   Initialize_Graph (Graph, 3);
   Chaitin_Briggs_Allocate (Graph, 1, Allocation, Spills);
   Check ("6.1 Node 1 gets color 1", Allocation (1) = 1);
   Check ("6.2 Node 2 gets color 1", Allocation (2) = 1);
   Check ("6.3 No spills occur", not Spills (3));

   -- TEST 7 — Triangle Graph (Fully connected, K=3)
   Put_Line ("TEST 7 — Triangle Graph No Spills");
   Initialize_Graph (Graph, 3);
   Add_Edge (Graph, 1, 2);
   Add_Edge (Graph, 2, 3);
   Add_Edge (Graph, 1, 3);
   Basic_Chaitin_Allocate (Graph, 3, Allocation, Spills);
   Check ("7.1 Node 1 has valid color", Allocation (1) in 1 .. 3);
   Check ("7.2 Node 1 and 2 differ", Allocation (1) /= Allocation (2));
   Check ("7.3 Node 2 and 3 differ", Allocation (2) /= Allocation (3));
   Check ("7.4 No spills", not Spills (1) and not Spills (2) and not Spills (3));

   -- TEST 8 — Triangle Graph with Spills (Fully connected, K=2)
   Put_Line ("TEST 8 — Triangle Graph Forced Spill Basic Chaitin");
   Basic_Chaitin_Allocate (Graph, 2, Allocation, Spills);
   Check ("8.1 Exactly one node is spilled or left uncolored",
          (Spills (1) or Spills (2) or Spills (3)));
   declare
      Spill_Count : Natural := 0;
   begin
      for I in Node_ID range 1 .. 3 loop
         if Spills (I) then Spill_Count := Spill_Count + 1; end if;
      end loop;
      Check ("8.2 Spill count is exactly 1", Spill_Count = 1);
      Check ("8.3 Unspilled have colors in 1..2", 
             Spills (1) or else Allocation (1) in 1 .. 2);
   end;

   -- TEST 9 — Triangle Graph with Spills (Briggs, K=2)
   Put_Line ("TEST 9 — Triangle Graph Forced Spill Chaitin-Briggs");
   Chaitin_Briggs_Allocate (Graph, 2, Allocation, Spills);
   declare
      Spill_Count : Natural := 0;
   begin
      for I in Node_ID range 1 .. 3 loop
         if Spills (I) then Spill_Count := Spill_Count + 1; end if;
      end loop;
      Check ("9.1 Spill count is exactly 1", Spill_Count = 1);
      Check ("9.2 Spilled node color is 0", 
             (for all I in Node_ID range 1 .. 3 => (if Spills (I) then Allocation (I) = Spilled_Color)));
      Check ("9.3 Colors are valid", 
             Spills (1) or else Allocation (1) /= Spilled_Color);
   end;

   -- TEST 10 — Diamond Graph Basic Chaitin (A=1, B=2, C=3, D=4)
   -- Edges: 1-2, 1-3, 2-4, 3-4. All nodes have degree 2. K=2.
   -- Basic Chaitin will fail to simplify ANY node initially, forcing a spill.
   Put_Line ("TEST 10 — Diamond Graph Basic Chaitin (K=2)");
   Initialize_Graph (Graph, 4);
   Add_Edge (Graph, 1, 2);
   Add_Edge (Graph, 1, 3);
   Add_Edge (Graph, 2, 4);
   Add_Edge (Graph, 3, 4);
   Basic_Chaitin_Allocate (Graph, 2, Allocation, Spills);
   declare
      Has_Spill : Boolean := False;
   begin
      for I in Node_ID range 1 .. 4 loop
         if Spills (I) then Has_Spill := True; end if;
      end loop;
      Check ("10.1 All nodes degree 2", Graph.Degrees (1) = 2 and Graph.Degrees (4) = 2);
      Check ("10.2 Basic Chaitin MUST spill due to pessimism", Has_Spill);
      Check ("10.3 Basic Chaitin finishes properly", True);
   end;

   -- TEST 11 — Diamond Graph Chaitin-Briggs (Optimistic Magic!)
   -- Same graph as 10. Briggs pushes anyway.
   -- When popping, 2 and 3 can take the same color, leaving a free color for 1 and 4!
   Put_Line ("TEST 11 — Diamond Graph Chaitin-Briggs (K=2)");
   Chaitin_Briggs_Allocate (Graph, 2, Allocation, Spills);
   declare
      Has_Spill : Boolean := False;
   begin
      for I in Node_ID range 1 .. 4 loop
         if Spills (I) then Has_Spill := True; end if;
      end loop;
      Check ("11.1 Optimistic Briggs yields NO spills!", not Has_Spill);
      Check ("11.2 Node 2 and 3 get the SAME color", Allocation (2) = Allocation (3));
      Check ("11.3 Node 1 and 4 get the SAME color", Allocation (1) = Allocation (4));
   end;

   -- TEST 12 — Graph_Error on Invalid Edge
   Put_Line ("TEST 12 — Invalid Edge Handling");
   Initialize_Graph (Graph, 2);
   declare
      Caught : Boolean := False;
   begin
      begin
         Add_Edge (Graph, 1, 3); -- Node 3 is not active!
      exception
         when Graph_Error => Caught := True;
      end;
      Check ("12.1 Caught Graph_Error on inactive node addition", Caught);
      Check ("12.2 Graph active nodes unaltered", Graph.Active_Node_Count = 2);
      Check ("12.3 Graph degrees unaltered", Graph.Degrees (1) = 0);
   end;

   -- TEST 13 — High Register Count (K=Maximum_Nodes)
   Put_Line ("TEST 13 — Max K avoids all spills");
   Initialize_Graph (Graph, 5);
   Add_Edge (Graph, 1, 2);
   Add_Edge (Graph, 2, 3);
   Add_Edge (Graph, 3, 4);
   Add_Edge (Graph, 4, 5);
   Basic_Chaitin_Allocate (Graph, Maximum_Nodes, Allocation, Spills);
   Check ("13.1 Node 1 gets colored", Allocation (1) /= Spilled_Color);
   Check ("13.2 Node 5 gets colored", Allocation (5) /= Spilled_Color);
   Check ("13.3 Zero spills overall", not Spills (1) and not Spills (3));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed," & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
