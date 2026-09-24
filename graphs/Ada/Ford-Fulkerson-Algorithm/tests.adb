--  Standalone test suite for Ford_Fulkerson_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ford_Fulkerson_Algorithm; use Ford_Fulkerson_Algorithm;

procedure Tests is

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

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; From, To : Vertex_Id; Cap : Integer) return Boolean
   is
   begin
      Add_Edge (G, From, To, Cap);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Flow_Raises
     (G : in out Graph; Source, Sink : Vertex_Id) return Boolean
   is
      F : Flow_Value;
   begin
      F := Max_Flow (G, Source, Sink);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Flow_Raises;

   function Flow_BFS_Raises
     (G : in out Graph; Source, Sink : Vertex_Id) return Boolean
   is
      F : Flow_Value;
   begin
      F := Max_Flow_BFS (G, Source, Sink);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Flow_BFS_Raises;

   function Cut_Raises
     (G : Graph; Source : Vertex_Id; Last : Positive) return Boolean
   is
      In_S : Reachability_Array (1 .. Vertex_Id (Last));
   begin
      Min_Cut_Partition (G, Source, In_S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cut_Raises;

   function Edge_Query_Raises (G : Graph; Index : Positive) return Boolean is
      V1, V2 : Vertex_Id;
      C      : Capacity_Type;
      F      : Flow_Value;
   begin
      V1 := Edge_From (G, Index);
      V2 := Edge_To (G, Index);
      C := Edge_Capacity (G, Index);
      F := Edge_Flow (G, Index);
      pragma Unreferenced (V1, V2, C, F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Edge_Query_Raises;

   G, G2 : Graph;
   F, F2, Cut : Flow_Value;
   In_S : Reachability_Array (1 .. Vertex_Id (Max_Vertices));
   Sum_Out, Sum_In : Flow_Value;

begin
   ------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty N=0");
   Check (Edge_Count (G) = 0, "empty M=0");
   Check (Clear_Raises (Max_Vertices + 1), "Clear overflow");

   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "N=4");
   Check (Edge_Count (G) = 0, "M=0 after Clear");
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 3);
   Add_Edge (G, 1, 2, 2);  -- parallel
   Check (Edge_Count (G) = 3, "three edges with parallel");
   Check (Edge_From (G, 1) = 1, "edge1 from");
   Check (Edge_To (G, 1) = 2, "edge1 to");
   Check (Edge_Capacity (G, 1) = 5, "edge1 cap");
   Check (Edge_Flow (G, 1) = 0, "edge1 flow before Max_Flow");
   Check (Add_Raises (G, 1, 2, Int (-1)), "neg capacity rejected");
   Check (Add_Raises (G, 5, 1, 1), "From out of range");
   Check (Add_Raises (G, 1, 5, 1), "To out of range");
   Check (Add_Raises (G, 1, 2, Int (-100)), "neg capacity large");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument on flow APIs");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Flow_Raises (G, 1, 1), "Max_Flow N=0");
   Check (Flow_BFS_Raises (G, 1, 1), "Max_Flow_BFS N=0");
   Check (Cut_Raises (G, 1, 1), "Min_Cut N=0");

   Clear (G, 3);
   Check (Flow_Raises (G, 4, 1), "Source out of range");
   Check (Flow_Raises (G, 1, 4), "Sink out of range");
   Check (Flow_BFS_Raises (G, 4, 2), "BFS Source OOR");
   Check (Flow_BFS_Raises (G, 2, 4), "BFS Sink OOR");
   Check (Edge_Query_Raises (G, 1), "edge query M=0");
   Add_Edge (G, 1, 2, 1);
   Check (Edge_Query_Raises (G, 2), "edge query Index>M");
   Check (not Edge_Query_Raises (G, 1), "edge query Index=1 ok");

   F := Max_Flow (G, 1, 2);
   Check (Cut_Raises (G, 1, Nat (2)), "Min_Cut array too small");
   Check (not Cut_Raises (G, 1, Nat (3)), "Min_Cut array size N ok");

   ------------------------------------------------------------------
   Section ("3. Trivial / disconnected");
   ------------------------------------------------------------------
   Clear (G, 1);
   F := Max_Flow (G, 1, 1);
   Check (F = 0, "Source=Sink N=1 flow=0");
   F := Max_Flow_BFS (G, 1, 1);
   Check (F = 0, "BFS Source=Sink N=1 flow=0");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 3, 4, 10);
   F := Max_Flow (G, 1, 4);
   Check (F = 0, "disconnected s-t flow=0");
   F2 := Max_Flow_BFS (G, 1, 4);
   Check (F2 = 0, "BFS disconnected=0");
   F := Max_Flow (G, 1, 2);
   Check (F = 10, "connected component flow=10");

   Clear (G, 3);
   F := Max_Flow (G, 1, 3);
   Check (F = 0, "edgeless flow=0");
   F := Max_Flow (G, 2, 2);
   Check (F = 0, "Source=Sink mid flow=0");

   ------------------------------------------------------------------
   Section ("4. Classic diamond / textbook tiny");
   ------------------------------------------------------------------
   --  1→2:3, 1→3:2, 2→3:5, 2→4:2, 3→4:3  ⇒ max flow 5
   Clear (G, 4);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 2, 4, 2);
   Add_Edge (G, 3, 4, 3);
   F := Max_Flow (G, 1, 4);
   Check (F = 5, "diamond DFS flow=5");
   Min_Cut_Partition (G, 1, In_S);
   Cut := Cut_Capacity (G, In_S);
   Check (Cut = 5, "diamond min-cut=5");
   Check (In_S (1), "diamond S contains source");
   Check (not In_S (4), "diamond S excludes sink");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 2, 4, 2);
   Add_Edge (G, 3, 4, 3);
   F2 := Max_Flow_BFS (G, 1, 4);
   Check (F2 = 5, "diamond BFS flow=5");

   ------------------------------------------------------------------
   Section ("5. CLRS Figure 26.1 / 26.6 style (flow=23)");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 16);
   Add_Edge (G, 1, 3, 13);
   Add_Edge (G, 2, 3, 10);
   Add_Edge (G, 2, 4, 12);
   Add_Edge (G, 3, 2, 4);
   Add_Edge (G, 3, 5, 14);
   Add_Edge (G, 4, 3, 9);
   Add_Edge (G, 4, 6, 20);
   Add_Edge (G, 5, 4, 7);
   Add_Edge (G, 5, 6, 4);
   F := Max_Flow (G, 1, 6);
   Check (F = 23, "CLRS DFS flow=23");
   Min_Cut_Partition (G, 1, In_S);
   Check (Cut_Capacity (G, In_S) = 23, "CLRS min-cut=23");
   Check (In_S (1), "CLRS S has s");
   Check (not In_S (6), "CLRS S lacks t");

   Clear (G2, 6);
   Add_Edge (G2, 1, 2, 16);
   Add_Edge (G2, 1, 3, 13);
   Add_Edge (G2, 2, 3, 10);
   Add_Edge (G2, 2, 4, 12);
   Add_Edge (G2, 3, 2, 4);
   Add_Edge (G2, 3, 5, 14);
   Add_Edge (G2, 4, 3, 9);
   Add_Edge (G2, 4, 6, 20);
   Add_Edge (G2, 5, 4, 7);
   Add_Edge (G2, 5, 6, 4);
   F2 := Max_Flow_BFS (G2, 1, 6);
   Check (F2 = 23, "CLRS BFS flow=23");
   Check (F = F2, "CLRS DFS=BFS");

   ------------------------------------------------------------------
   Section ("6. Single edge / path / bottleneck");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 7);
   Check (Max_Flow (G, 1, 2) = 7, "single edge 7");
   Check (Edge_Flow (G, 1) = 7, "single edge full flow");
   Check (Edge_Capacity (G, 1) = 7, "single edge cap");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 3, 4, 10);
   Add_Edge (G, 4, 5, 10);
   F := Max_Flow (G, 1, 5);
   Check (F = 4, "path bottleneck=4");
   F2 := Max_Flow_BFS (G, 1, 5);
   Check (F2 = 4, "path BFS bottleneck=4");

   ------------------------------------------------------------------
   Section ("7. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 2, 2);
   F := Max_Flow (G, 1, 2);
   Check (F = 10, "parallel sum=10");
   Check (Edge_Flow (G, 1) + Edge_Flow (G, 2) + Edge_Flow (G, 3) = 10,
          "parallel flows sum");

   ------------------------------------------------------------------
   Section ("8. Capacity zero / self-loop");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 5);
   F := Max_Flow (G, 1, 3);
   Check (F = 0, "zero-cap blocks");
   Add_Edge (G, 1, 1, 100);
   F := Max_Flow (G, 1, 3);
   Check (F = 0, "self-loop does not help");
   Add_Edge (G, 1, 3, 4);
   F := Max_Flow (G, 1, 3);
   Check (F = 4, "direct after self-loop");

   ------------------------------------------------------------------
   Section ("9. Max-flow = min-cut battery");
   ------------------------------------------------------------------
   for Cap in 1 .. 8 loop
      Clear (G, 3);
      Add_Edge (G, 1, 2, Cap);
      Add_Edge (G, 2, 3, Cap + 1);
      F := Max_Flow (G, 1, 3);
      Min_Cut_Partition (G, 1, In_S);
      Cut := Cut_Capacity (G, In_S);
      Check (F = Flow_Value (Cap),
             "chain flow cap=" & Integer'Image (Cap));
      Check (Cut = F, "chain cut=flow cap=" & Integer'Image (Cap));
   end loop;

   for Cap in 1 .. 6 loop
      Clear (G, 4);
      Add_Edge (G, 1, 2, Cap);
      Add_Edge (G, 1, 3, Cap);
      Add_Edge (G, 2, 4, Cap);
      Add_Edge (G, 3, 4, Cap);
      F := Max_Flow (G, 1, 4);
      Min_Cut_Partition (G, 1, In_S);
      Check (F = Flow_Value (2 * Cap),
             "parallel paths flow=" & Integer'Image (2 * Cap));
      Check (Cut_Capacity (G, In_S) = F,
             "parallel paths cut=flow");
   end loop;

   ------------------------------------------------------------------
   Section ("10. DFS vs BFS agree on integers");
   ------------------------------------------------------------------
   for N in 3 .. 10 loop
      Clear (G, N);
      Clear (G2, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
         Add_Edge (G2, Vertex_Id (I), Vertex_Id (I + 1), I);
         if I + 2 <= N then
            Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 2), 1);
            Add_Edge (G2, Vertex_Id (I), Vertex_Id (I + 2), 1);
         end if;
      end loop;
      F := Max_Flow (G, 1, Vertex_Id (N));
      F2 := Max_Flow_BFS (G2, 1, Vertex_Id (N));
      Check (F = F2, "DFS=BFS pathish n=" & Integer'Image (N));
   end loop;

   for Seed in 1 .. 12 loop
      Clear (G, 8);
      Clear (G2, 8);
      --  Deterministic “random-ish” edges from Seed.
      for I in 1 .. 8 loop
         for J in 1 .. 8 loop
            if I /= J and then ((I * 17 + J * 13 + Seed) mod 5) = 0 then
               declare
                  C : constant Integer :=
                    1 + (I * J + Seed) mod 9;
               begin
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J), C);
                  Add_Edge (G2, Vertex_Id (I), Vertex_Id (J), C);
               end;
            end if;
         end loop;
      end loop;
      F := Max_Flow (G, 1, 8);
      F2 := Max_Flow_BFS (G2, 1, 8);
      Check (F = F2, "DFS=BFS rnd seed=" & Integer'Image (Seed));
      Min_Cut_Partition (G, 1, In_S);
      Check (Cut_Capacity (G, In_S) = F,
             "cut=flow rnd seed=" & Integer'Image (Seed));
   end loop;

   ------------------------------------------------------------------
   Section ("11. Flow conservation at intermediates");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 10);
   Add_Edge (G, 2, 4, 6);
   Add_Edge (G, 3, 4, 7);
   Add_Edge (G, 2, 5, 5);
   Add_Edge (G, 3, 5, 5);
   Add_Edge (G, 4, 5, 8);
   F := Max_Flow (G, 1, 5);
   Check (F > 0, "conservation net flow>0");
   --  Vertex 2: inflow = outflow
   Sum_In := 0;
   Sum_Out := 0;
   for I in 1 .. Edge_Count (G) loop
      if Edge_To (G, I) = 2 then
         Sum_In := Sum_In + Edge_Flow (G, I);
      end if;
      if Edge_From (G, I) = 2 then
         Sum_Out := Sum_Out + Edge_Flow (G, I);
      end if;
   end loop;
   Check (Sum_In = Sum_Out, "conservation at v2");
   Sum_In := 0;
   Sum_Out := 0;
   for I in 1 .. Edge_Count (G) loop
      if Edge_To (G, I) = 3 then
         Sum_In := Sum_In + Edge_Flow (G, I);
      end if;
      if Edge_From (G, I) = 3 then
         Sum_Out := Sum_Out + Edge_Flow (G, I);
      end if;
   end loop;
   Check (Sum_In = Sum_Out, "conservation at v3");
   Sum_In := 0;
   Sum_Out := 0;
   for I in 1 .. Edge_Count (G) loop
      if Edge_To (G, I) = 4 then
         Sum_In := Sum_In + Edge_Flow (G, I);
      end if;
      if Edge_From (G, I) = 4 then
         Sum_Out := Sum_Out + Edge_Flow (G, I);
      end if;
   end loop;
   Check (Sum_In = Sum_Out, "conservation at v4");
   --  Source outflow = sink inflow = F
   Sum_Out := 0;
   Sum_In := 0;
   for I in 1 .. Edge_Count (G) loop
      if Edge_From (G, I) = 1 then
         Sum_Out := Sum_Out + Edge_Flow (G, I);
      end if;
      if Edge_To (G, I) = 5 then
         Sum_In := Sum_In + Edge_Flow (G, I);
      end if;
   end loop;
   Check (Sum_Out = F, "source outflow = F");
   Check (Sum_In = F, "sink inflow = F");

   ------------------------------------------------------------------
   Section ("12. Bidirectional capacities");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 1, 3);
   Add_Edge (G, 2, 3, 4);
   F := Max_Flow (G, 1, 3);
   Check (F = 4, "bidir net flow=4");
   F2 := Max_Flow_BFS (G, 1, 3);
   Check (F2 = 4, "bidir BFS=4");

   ------------------------------------------------------------------
   Section ("13. Re-run Max_Flow resets");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   F := Max_Flow (G, 1, 3);
   Check (F = 5, "first run=5");
   F2 := Max_Flow (G, 1, 3);
   Check (F2 = 5, "second run resets=5");
   F := Max_Flow_BFS (G, 1, 3);
   Check (F = 5, "BFS after DFS resets=5");

   ------------------------------------------------------------------
   Section ("14. Complete bipartite-ish / star");
   ------------------------------------------------------------------
   Clear (G, 7);
   --  Star: 1 center to leaves 2..6, leaves to sink 7
   for I in 2 .. 6 loop
      Add_Edge (G, 1, Vertex_Id (I), 3);
      Add_Edge (G, Vertex_Id (I), 7, 2);
   end loop;
   F := Max_Flow (G, 1, 7);
   Check (F = 10, "star flow=10");  -- 5*2
   Min_Cut_Partition (G, 1, In_S);
   Check (Cut_Capacity (G, In_S) = 10, "star cut=10");

   ------------------------------------------------------------------
   Section ("15. Wikipedia-style small network");
   ------------------------------------------------------------------
   --  s=1,t=4; edges 1-2:10? common example flow=5? use known:
   --  A=1,B=2,C=3,D=4: A→B 3, A→C 2, B→C 5? wait already diamond.
   --  Another: s→a:10, s→b:5, a→b:15, a→t:5, b→t:10 ⇒ flow 15? 
   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, 15);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 10);
   F := Max_Flow (G, 1, 4);
   Check (F = 15, "wiki-ish flow=15");
   Check (Max_Flow_BFS (G, 1, 4) = 15, "wiki-ish BFS=15");

   ------------------------------------------------------------------
   Section ("16. Volume battery small n");
   ------------------------------------------------------------------
   for N in 2 .. 12 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 100);
      end loop;
      F := Max_Flow (G, 1, Vertex_Id (N));
      Check (F = 100, "line100 n=" & Integer'Image (N));
   end loop;

   for N in 2 .. 8 loop
      Clear (G, N);
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I /= J then
               Add_Edge (G, Vertex_Id (I), Vertex_Id (J), 1);
            end if;
         end loop;
      end loop;
      F := Max_Flow (G, 1, Vertex_Id (N));
      --  Complete digraph: n-1 unit edges out of source (and plenty).
      Check (F = Flow_Value (N - 1),
             "tournament-ish flow n=" & Integer'Image (N));
      Min_Cut_Partition (G, 1, In_S);
      Check (Cut_Capacity (G, In_S) = F,
             "tournament cut n=" & Integer'Image (N));
   end loop;

   ------------------------------------------------------------------
   Section ("17. Edge capacity bounds / Clear Max_Vertices");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear Max_Vertices ok");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 42);
   Check (Edge_Count (G) = 1, "edge across max ids");
   F := Max_Flow (G, 1, Vertex_Id (Max_Vertices));
   Check (F = 42, "max-id endpoints flow=42");
   F := Max_Flow_BFS (G, 1, Vertex_Id (Max_Vertices));
   Check (F = 42, "max-id BFS=42");

   Clear (G, 2);
   Add_Edge (G, 1, 2, Integer (Capacity_Type'Last));
   F := Max_Flow (G, 1, 2);
   Check (F = Flow_Value (Capacity_Type'Last), "max capacity edge");

   ------------------------------------------------------------------
   Section ("18. Clear resets edges");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 9);
   Add_Edge (G, 2, 3, 9);
   Clear (G, 4);
   Check (Edge_Count (G) = 0, "Clear empties edges");
   Check (Max_Flow (G, 1, 4) = 0, "cleared flow=0");

   ------------------------------------------------------------------
   Section ("19. Flow never exceeds capacity");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 7);
   Add_Edge (G, 1, 3, 8);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 2, 5, 4);
   Add_Edge (G, 3, 5, 5);
   Add_Edge (G, 3, 4, 6);
   Add_Edge (G, 4, 6, 9);
   Add_Edge (G, 5, 6, 9);
   F := Max_Flow (G, 1, 6);
   for I in 1 .. Edge_Count (G) loop
      Check (Edge_Flow (G, I) <= Flow_Value (Edge_Capacity (G, I)),
             "cap respect edge " & Integer'Image (I));
   end loop;
   Check (F = Max_Flow_BFS (G, 1, 6), "cap-net DFS=BFS");

   ------------------------------------------------------------------
   Section ("20. Min-cut source/sink membership patterns");
   ------------------------------------------------------------------
   for Cap in 1 .. 5 loop
      Clear (G, 4);
      Add_Edge (G, 1, 2, Cap);
      Add_Edge (G, 2, 3, 100);
      Add_Edge (G, 3, 4, Cap);
      F := Max_Flow (G, 1, 4);
      Min_Cut_Partition (G, 1, In_S);
      Check (F = Flow_Value (Cap), "s-cut pattern flow");
      Check (In_S (1), "s in S");
      Check (not In_S (4), "t not in S");
      --  After saturating 1→2, residual may leave only {1} in S
      --  or more if middle residual remains; cut capacity must match.
      Check (Cut_Capacity (G, In_S) = F, "s-cut pattern cut=F");
   end loop;

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
