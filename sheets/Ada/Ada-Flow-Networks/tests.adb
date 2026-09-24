--  Standalone test suite for Flow_Networks (survey; main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Flow_Networks; use Flow_Networks;

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
      N : Network;
   begin
      Clear (N, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (N : in out Network; From, To : Vertex_Id; Cap : Integer) return Boolean
   is
   begin
      Add_Edge (N, From, To, Cap);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Flow_Raises
     (N : in out Network; Source, Sink : Vertex_Id) return Boolean
   is
      F : Flow_Value;
   begin
      F := Max_Flow (N, Source, Sink, Edmonds_Karp);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Flow_Raises;

   function Flow_Stored_Raises
     (N : in out Network; Algo : Method) return Boolean
   is
      F : Flow_Value;
   begin
      F := Max_Flow (N, Algo);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Flow_Stored_Raises;

   function Set_Source_Raises
     (N : in out Network; S : Vertex_Id) return Boolean
   is
   begin
      Set_Source (N, S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Source_Raises;

   function Set_Sink_Raises
     (N : in out Network; T : Vertex_Id) return Boolean
   is
   begin
      Set_Sink (N, T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Sink_Raises;

   function Source_Raises (N : Network) return Boolean is
      S : Vertex_Id;
   begin
      S := Source (N);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Source_Raises;

   function Sink_Raises (N : Network) return Boolean is
      T : Vertex_Id;
   begin
      T := Sink (N);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sink_Raises;

   function Cut_Raises
     (N : Network; Source : Vertex_Id; Last : Positive) return Boolean
   is
      In_S : Reachability_Array (1 .. Vertex_Id (Last));
   begin
      Min_Cut_Partition (N, Source, In_S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cut_Raises;

   function Cut_Cap_Raises (N : Network; Last : Positive) return Boolean is
      In_S : Reachability_Array (1 .. Vertex_Id (Last));
      C    : Flow_Value;
   begin
      for I in In_S'Range loop
         In_S (I) := False;
      end loop;
      C := Cut_Capacity (N, In_S);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cut_Cap_Raises;

   function Edge_Query_Raises (N : Network; Index : Positive) return Boolean is
      V1, V2 : Vertex_Id;
      C      : Capacity_Type;
      F      : Flow_Value;
   begin
      V1 := Edge_From (N, Index);
      V2 := Edge_To (N, Index);
      C := Edge_Capacity (N, Index);
      F := Edge_Flow (N, Index);
      pragma Unreferenced (V1, V2, C, F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Edge_Query_Raises;

   N : Network;
   F, F2, Cut : Flow_Value;
   In_S : Reachability_Array (1 .. Vertex_Id (Max_Vertices));
   Sum_Out, Sum_In : Flow_Value;
   Algo : Method;

begin
   ------------------------------------------------------------------
   Section ("1. Clear / Add_Edge / counts");
   ------------------------------------------------------------------
   Clear (N, 0);
   Check (Vertex_Count (N) = 0, "empty N=0");
   Check (Edge_Count (N) = 0, "empty M=0");
   Check (not Has_Source (N), "no source after Clear");
   Check (not Has_Sink (N), "no sink after Clear");
   Check (Clear_Raises (Max_Vertices + 1), "Clear overflow");

   Clear (N, 4);
   Check (Vertex_Count (N) = 4, "N=4");
   Check (Edge_Count (N) = 0, "M=0 after Clear");
   Add_Edge (N, 1, 2, 5);
   Add_Edge (N, 2, 3, 3);
   Add_Edge (N, 1, 2, 2);  -- parallel
   Check (Edge_Count (N) = 3, "three edges with parallel");
   Check (Edge_From (N, 1) = 1, "edge1 from");
   Check (Edge_To (N, 1) = 2, "edge1 to");
   Check (Edge_Capacity (N, 1) = 5, "edge1 cap");
   Check (Edge_Flow (N, 1) = 0, "edge1 flow before Max_Flow");
   Check (Add_Raises (N, 1, 2, Int (-1)), "neg capacity rejected");
   Check (Add_Raises (N, 5, 1, 1), "From out of range");
   Check (Add_Raises (N, 1, 5, 1), "To out of range");
   Check (Add_Raises (N, 1, 2, Int (-100)), "neg capacity large");
   Check (not Add_Raises (N, 1, 1, 0), "self-loop cap 0 ok");
   Check (Edge_Count (N) = 4, "self-loop counted");

   ------------------------------------------------------------------
   Section ("2. Source / Sink helpers");
   ------------------------------------------------------------------
   Clear (N, 0);
   Check (Set_Source_Raises (N, 1), "Set_Source on empty");
   Check (Set_Sink_Raises (N, 1), "Set_Sink on empty");
   Check (Source_Raises (N), "Source unset raises");
   Check (Sink_Raises (N), "Sink unset raises");
   Check (Flow_Stored_Raises (N, Edmonds_Karp), "Max_Flow stored unset");

   Clear (N, 3);
   Check (not Has_Source (N), "Has_Source false after Clear");
   Check (not Has_Sink (N), "Has_Sink false after Clear");
   Check (Set_Source_Raises (N, 4), "Set_Source OOR");
   Check (Set_Sink_Raises (N, 4), "Set_Sink OOR");
   Set_Source (N, 1);
   Set_Sink (N, 3);
   Check (Has_Source (N), "Has_Source true");
   Check (Has_Sink (N), "Has_Sink true");
   Check (Source (N) = 1, "Source=1");
   Check (Sink (N) = 3, "Sink=3");
   Add_Edge (N, 1, 2, 4);
   Add_Edge (N, 2, 3, 4);
   F := Max_Flow (N, Edmonds_Karp);
   Check (F = 4, "stored terminals Max_Flow EK=4");
   F2 := Max_Flow (N, Dinic);
   Check (F2 = 4, "stored terminals Max_Flow Dinic=4");
   Clear (N, 3);
   Check (not Has_Source (N), "Clear clears Source");
   Check (not Has_Sink (N), "Clear clears Sink");

   ------------------------------------------------------------------
   Section ("3. Invalid_Argument on flow APIs");
   ------------------------------------------------------------------
   Clear (N, 0);
   Check (Flow_Raises (N, 1, 1), "Max_Flow N=0");
   Check (Cut_Raises (N, 1, 1), "Min_Cut N=0");
   Check (Cut_Cap_Raises (N, 1), "Cut_Capacity N=0");

   Clear (N, 3);
   Check (Flow_Raises (N, 4, 1), "Source out of range");
   Check (Flow_Raises (N, 1, 4), "Sink out of range");
   Check (Edge_Query_Raises (N, 1), "edge query M=0");
   Add_Edge (N, 1, 2, 1);
   Check (Edge_Query_Raises (N, 2), "edge query Index>M");
   Check (not Edge_Query_Raises (N, 1), "edge query Index=1 ok");

   F := Max_Flow (N, 1, 2, Edmonds_Karp);
   Check (F = 1, "tiny 1->2 flow=1");
   Check (Has_Source (N) and then Source (N) = 1, "Max_Flow stores Source");
   Check (Has_Sink (N) and then Sink (N) = 2, "Max_Flow stores Sink");
   Check (Cut_Raises (N, 1, Nat (2)), "Min_Cut array too small");
   Check (not Cut_Raises (N, 1, Nat (3)), "Min_Cut array size N ok");
   Check (Cut_Cap_Raises (N, Nat (2)), "Cut_Capacity array too small");
   Check (Cut_Raises (N, 4, Nat (3)), "Min_Cut Source OOR");

   ------------------------------------------------------------------
   Section ("4. Trivial / disconnected");
   ------------------------------------------------------------------
   Clear (N, 1);
   F := Max_Flow (N, 1, 1, Edmonds_Karp);
   Check (F = 0, "Source=Sink N=1 flow=0 EK");
   F := Max_Flow (N, 1, 1, Dinic);
   Check (F = 0, "Source=Sink N=1 flow=0 Dinic");

   Clear (N, 4);
   Add_Edge (N, 1, 2, 10);
   Add_Edge (N, 3, 4, 10);
   F := Max_Flow (N, 1, 4, Edmonds_Karp);
   Check (F = 0, "disconnected s-t flow=0");
   F := Max_Flow (N, 1, 2, Dinic);
   Check (F = 10, "connected component flow=10");

   Clear (N, 3);
   F := Max_Flow (N, 1, 3, Edmonds_Karp);
   Check (F = 0, "edgeless flow=0");
   F := Max_Flow (N, 2, 2, Dinic);
   Check (F = 0, "Source=Sink mid flow=0");
   F := Max_Flow (N, 3, 1, Edmonds_Karp);
   Check (F = 0, "reverse direction edgeless=0");

   ------------------------------------------------------------------
   Section ("5. Classic diamond / EK≡Dinic");
   ------------------------------------------------------------------
   --  1→2:3, 1→3:2, 2→3:5, 2→4:2, 3→4:3  ⇒ max flow 5
   Clear (N, 4);
   Add_Edge (N, 1, 2, 3);
   Add_Edge (N, 1, 3, 2);
   Add_Edge (N, 2, 3, 5);
   Add_Edge (N, 2, 4, 2);
   Add_Edge (N, 3, 4, 3);
   F := Max_Flow (N, 1, 4, Edmonds_Karp);
   Check (F = 5, "diamond flow=5 EK");
   Min_Cut_Partition (N, 1, In_S);
   Cut := Cut_Capacity (N, In_S);
   Check (Cut = 5, "diamond min-cut=5 EK");
   Check (In_S (1), "diamond S contains source");
   Check (not In_S (4), "diamond S excludes sink");
   Check (Edge_Flow (N, 1) + Edge_Flow (N, 2) = 5, "diamond source outflow");
   Check (Edge_Flow (N, 4) + Edge_Flow (N, 5) = 5, "diamond sink inflow");
   F2 := Max_Flow (N, 1, 4, Dinic);
   Check (F2 = 5, "diamond flow=5 Dinic");
   Check (F = F2, "diamond EK≡Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 5, "diamond min-cut=5 Dinic");

   ------------------------------------------------------------------
   Section ("6. CLRS Figure 26.1 / 26.6 style (flow=23)");
   ------------------------------------------------------------------
   Clear (N, 6);
   Add_Edge (N, 1, 2, 16);
   Add_Edge (N, 1, 3, 13);
   Add_Edge (N, 2, 3, 10);
   Add_Edge (N, 2, 4, 12);
   Add_Edge (N, 3, 2, 4);
   Add_Edge (N, 3, 5, 14);
   Add_Edge (N, 4, 3, 9);
   Add_Edge (N, 4, 6, 20);
   Add_Edge (N, 5, 4, 7);
   Add_Edge (N, 5, 6, 4);
   F := Max_Flow (N, 1, 6, Edmonds_Karp);
   Check (F = 23, "CLRS flow=23 EK");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 23, "CLRS min-cut=23 EK");
   F2 := Max_Flow (N, 1, 6, Dinic);
   Check (F2 = 23, "CLRS flow=23 Dinic");
   Check (F = F2, "CLRS EK≡Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 23, "CLRS min-cut=23 Dinic");
   Check (In_S (1), "CLRS S has s");
   Check (not In_S (6), "CLRS S lacks t");
   F2 := Max_Flow (N, 1, 6, Edmonds_Karp);
   Check (F2 = 23, "CLRS rerun=23");

   ------------------------------------------------------------------
   Section ("7. Wikipedia seven-node example");
   ------------------------------------------------------------------
   --  A=1 B=2 C=3 D=4 E=5 F=6 G=7; max flow 5; min-cut {A,B,C,E}/{D,F,G}
   Clear (N, 7);
   Add_Edge (N, 1, 2, 3);  -- A→B
   Add_Edge (N, 1, 4, 3);  -- A→D
   Add_Edge (N, 2, 3, 4);  -- B→C
   Add_Edge (N, 3, 4, 1);  -- C→D
   Add_Edge (N, 3, 5, 2);  -- C→E
   Add_Edge (N, 4, 5, 2);  -- D→E
   Add_Edge (N, 4, 6, 6);  -- D→F
   Add_Edge (N, 5, 7, 1);  -- E→G
   Add_Edge (N, 6, 7, 9);  -- F→G
   F := Max_Flow (N, 1, 7, Edmonds_Karp);
   Check (F = 5, "wiki seven-node flow=5 EK");
   F2 := Max_Flow (N, 1, 7, Dinic);
   Check (F2 = 5, "wiki seven-node flow=5 Dinic");
   Check (F = F2, "wiki EK≡Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 5, "wiki min-cut=5");
   Check (In_S (1), "wiki S has A");
   Check (In_S (2), "wiki S has B");
   Check (In_S (3), "wiki S has C");
   Check (not In_S (4), "wiki S lacks D");
   Check (In_S (5), "wiki S has E");
   Check (not In_S (6), "wiki S lacks F");
   Check (not In_S (7), "wiki S lacks G");
   Check (Edge_Capacity (N, 2) = 3, "wiki A-D cap");
   Check (Edge_Capacity (N, 4) = 1, "wiki C-D cap");
   Check (Edge_Capacity (N, 8) = 1, "wiki E-G cap");

   ------------------------------------------------------------------
   Section ("8. Single edge / path / bottleneck");
   ------------------------------------------------------------------
   Clear (N, 2);
   Add_Edge (N, 1, 2, 7);
   Check (Max_Flow (N, 1, 2, Edmonds_Karp) = 7, "single edge 7 EK");
   Check (Edge_Flow (N, 1) = 7, "single edge full flow");
   Check (Max_Flow (N, 1, 2, Dinic) = 7, "single edge 7 Dinic");

   Clear (N, 5);
   Add_Edge (N, 1, 2, 10);
   Add_Edge (N, 2, 3, 4);
   Add_Edge (N, 3, 4, 10);
   Add_Edge (N, 4, 5, 10);
   F := Max_Flow (N, 1, 5, Edmonds_Karp);
   Check (F = 4, "path bottleneck=4 EK");
   F2 := Max_Flow (N, 1, 5, Dinic);
   Check (F2 = 4, "path bottleneck=4 Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 4, "path cut=4");

   ------------------------------------------------------------------
   Section ("9. Parallel edges");
   ------------------------------------------------------------------
   Clear (N, 2);
   Add_Edge (N, 1, 2, 3);
   Add_Edge (N, 1, 2, 5);
   Add_Edge (N, 1, 2, 2);
   F := Max_Flow (N, 1, 2, Edmonds_Karp);
   Check (F = 10, "parallel sum=10 EK");
   F2 := Max_Flow (N, 1, 2, Dinic);
   Check (F2 = 10, "parallel sum=10 Dinic");
   Check (Edge_Flow (N, 1) + Edge_Flow (N, 2) + Edge_Flow (N, 3) = 10,
          "parallel flows sum");
   Check (Edge_Flow (N, 1) <= 3, "parallel e1 <= cap");
   Check (Edge_Flow (N, 2) <= 5, "parallel e2 <= cap");
   Check (Edge_Flow (N, 3) <= 2, "parallel e3 <= cap");

   ------------------------------------------------------------------
   Section ("10. Capacity zero / self-loop");
   ------------------------------------------------------------------
   Clear (N, 3);
   Add_Edge (N, 1, 2, 0);
   Add_Edge (N, 2, 3, 5);
   F := Max_Flow (N, 1, 3, Edmonds_Karp);
   Check (F = 0, "zero-cap blocks");
   Add_Edge (N, 1, 1, 100);
   F := Max_Flow (N, 1, 3, Dinic);
   Check (F = 0, "self-loop does not help");
   Add_Edge (N, 1, 3, 4);
   F := Max_Flow (N, 1, 3, Edmonds_Karp);
   Check (F = 4, "direct after self-loop");
   Check (Edge_Flow (N, 3) = 0, "self-loop flow stays 0");

   ------------------------------------------------------------------
   Section ("11. Max-flow = min-cut battery (both methods)");
   ------------------------------------------------------------------
   for Cap in 1 .. 10 loop
      Clear (N, 3);
      Add_Edge (N, 1, 2, Cap);
      Add_Edge (N, 2, 3, Cap + 1);
      for Algo in Method loop
         F := Max_Flow (N, 1, 3, Algo);
         Min_Cut_Partition (N, 1, In_S);
         Cut := Cut_Capacity (N, In_S);
         Check (F = Flow_Value (Cap),
                "chain flow cap=" & Integer'Image (Cap)
                & " " & Method'Image (Algo));
         Check (Cut = F,
                "chain cut=flow cap=" & Integer'Image (Cap)
                & " " & Method'Image (Algo));
      end loop;
   end loop;

   for Cap in 1 .. 8 loop
      Clear (N, 4);
      Add_Edge (N, 1, 2, Cap);
      Add_Edge (N, 1, 3, Cap);
      Add_Edge (N, 2, 4, Cap);
      Add_Edge (N, 3, 4, Cap);
      F := Max_Flow (N, 1, 4, Edmonds_Karp);
      F2 := Max_Flow (N, 1, 4, Dinic);
      Check (F = Flow_Value (2 * Cap),
             "parallel paths flow=" & Integer'Image (2 * Cap));
      Check (F = F2, "parallel paths EK≡Dinic");
      Min_Cut_Partition (N, 1, In_S);
      Check (Cut_Capacity (N, In_S) = F, "parallel paths cut=flow");
   end loop;

   ------------------------------------------------------------------
   Section ("12. Flow conservation at intermediates");
   ------------------------------------------------------------------
   Clear (N, 5);
   Add_Edge (N, 1, 2, 10);
   Add_Edge (N, 1, 3, 10);
   Add_Edge (N, 2, 4, 6);
   Add_Edge (N, 3, 4, 7);
   Add_Edge (N, 2, 5, 5);
   Add_Edge (N, 3, 5, 5);
   Add_Edge (N, 4, 5, 8);
   F := Max_Flow (N, 1, 5, Edmonds_Karp);
   Check (F > 0, "conservation net flow>0");
   Sum_In := 0;
   Sum_Out := 0;
   for I in 1 .. Edge_Count (N) loop
      if Edge_To (N, I) = 2 then
         Sum_In := Sum_In + Edge_Flow (N, I);
      end if;
      if Edge_From (N, I) = 2 then
         Sum_Out := Sum_Out + Edge_Flow (N, I);
      end if;
   end loop;
   Check (Sum_In = Sum_Out, "conservation at v2");
   Sum_In := 0;
   Sum_Out := 0;
   for I in 1 .. Edge_Count (N) loop
      if Edge_To (N, I) = 3 then
         Sum_In := Sum_In + Edge_Flow (N, I);
      end if;
      if Edge_From (N, I) = 3 then
         Sum_Out := Sum_Out + Edge_Flow (N, I);
      end if;
   end loop;
   Check (Sum_In = Sum_Out, "conservation at v3");
   Sum_In := 0;
   Sum_Out := 0;
   for I in 1 .. Edge_Count (N) loop
      if Edge_To (N, I) = 4 then
         Sum_In := Sum_In + Edge_Flow (N, I);
      end if;
      if Edge_From (N, I) = 4 then
         Sum_Out := Sum_Out + Edge_Flow (N, I);
      end if;
   end loop;
   Check (Sum_In = Sum_Out, "conservation at v4");
   Sum_Out := 0;
   Sum_In := 0;
   for I in 1 .. Edge_Count (N) loop
      if Edge_From (N, I) = 1 then
         Sum_Out := Sum_Out + Edge_Flow (N, I);
      end if;
      if Edge_To (N, I) = 5 then
         Sum_In := Sum_In + Edge_Flow (N, I);
      end if;
   end loop;
   Check (Sum_Out = F, "source outflow = F");
   Check (Sum_In = F, "sink inflow = F");
   F2 := Max_Flow (N, 1, 5, Dinic);
   Check (F2 = F, "conservation net EK≡Dinic");

   ------------------------------------------------------------------
   Section ("13. Bidirectional capacities / re-run");
   ------------------------------------------------------------------
   Clear (N, 3);
   Add_Edge (N, 1, 2, 5);
   Add_Edge (N, 2, 1, 3);
   Add_Edge (N, 2, 3, 4);
   F := Max_Flow (N, 1, 3, Edmonds_Karp);
   Check (F = 4, "bidir net flow=4 EK");
   F2 := Max_Flow (N, 1, 3, Dinic);
   Check (F2 = 4, "bidir net flow=4 Dinic");

   Clear (N, 3);
   Add_Edge (N, 1, 2, 5);
   Add_Edge (N, 2, 3, 5);
   F := Max_Flow (N, 1, 3, Edmonds_Karp);
   Check (F = 5, "first run=5");
   F2 := Max_Flow (N, 1, 3, Edmonds_Karp);
   Check (F2 = 5, "second run resets=5");
   Add_Edge (N, 1, 3, 2);
   F := Max_Flow (N, 1, 3, Dinic);
   Check (F = 7, "after extra edge flow=7");

   ------------------------------------------------------------------
   Section ("14. Star / wiki-ish flow=15");
   ------------------------------------------------------------------
   Clear (N, 7);
   for I in 2 .. 6 loop
      Add_Edge (N, 1, Vertex_Id (I), 3);
      Add_Edge (N, Vertex_Id (I), 7, 2);
   end loop;
   F := Max_Flow (N, 1, 7, Edmonds_Karp);
   Check (F = 10, "star flow=10 EK");
   F2 := Max_Flow (N, 1, 7, Dinic);
   Check (F2 = 10, "star flow=10 Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 10, "star cut=10");
   Check (In_S (1), "star S has source");
   Check (not In_S (7), "star S lacks sink");

   Clear (N, 4);
   Add_Edge (N, 1, 2, 10);
   Add_Edge (N, 1, 3, 5);
   Add_Edge (N, 2, 3, 15);
   Add_Edge (N, 2, 4, 5);
   Add_Edge (N, 3, 4, 10);
   F := Max_Flow (N, 1, 4, Edmonds_Karp);
   Check (F = 15, "wiki-ish flow=15 EK");
   F2 := Max_Flow (N, 1, 4, Dinic);
   Check (F2 = 15, "wiki-ish flow=15 Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 15, "wiki-ish cut=15");

   ------------------------------------------------------------------
   Section ("15. Volume battery small n (EK≡Dinic, MF=MC)");
   ------------------------------------------------------------------
   for Nx in 2 .. 16 loop
      Clear (N, Nx);
      for I in 1 .. Nx - 1 loop
         Add_Edge (N, Vertex_Id (I), Vertex_Id (I + 1), 100);
      end loop;
      F := Max_Flow (N, 1, Vertex_Id (Nx), Edmonds_Karp);
      F2 := Max_Flow (N, 1, Vertex_Id (Nx), Dinic);
      Check (F = 100, "line100 n=" & Integer'Image (Nx));
      Check (F = F2, "line100 EK≡Dinic n=" & Integer'Image (Nx));
   end loop;

   for Nx in 2 .. 8 loop
      Clear (N, Nx);
      for I in 1 .. Nx loop
         for J in 1 .. Nx loop
            if I /= J then
               Add_Edge (N, Vertex_Id (I), Vertex_Id (J), 1);
            end if;
         end loop;
      end loop;
      F := Max_Flow (N, 1, Vertex_Id (Nx), Edmonds_Karp);
      F2 := Max_Flow (N, 1, Vertex_Id (Nx), Dinic);
      Check (F = Flow_Value (Nx - 1),
             "tournament-ish flow n=" & Integer'Image (Nx));
      Check (F = F2, "tournament EK≡Dinic n=" & Integer'Image (Nx));
      Min_Cut_Partition (N, 1, In_S);
      Check (Cut_Capacity (N, In_S) = F,
             "tournament cut n=" & Integer'Image (Nx));
   end loop;

   ------------------------------------------------------------------
   Section ("16. Edge capacity bounds / Clear Max_Vertices");
   ------------------------------------------------------------------
   Clear (N, Max_Vertices);
   Check (Vertex_Count (N) = Max_Vertices, "Clear Max_Vertices ok");
   Add_Edge (N, 1, Vertex_Id (Max_Vertices), 42);
   Check (Edge_Count (N) = 1, "edge across max ids");
   F := Max_Flow (N, 1, Vertex_Id (Max_Vertices), Edmonds_Karp);
   Check (F = 42, "max-id endpoints flow=42 EK");
   F2 := Max_Flow (N, 1, Vertex_Id (Max_Vertices), Dinic);
   Check (F2 = 42, "max-id endpoints flow=42 Dinic");

   Clear (N, 2);
   Add_Edge (N, 1, 2, Integer (Capacity_Type'Last));
   F := Max_Flow (N, 1, 2, Edmonds_Karp);
   Check (F = Flow_Value (Capacity_Type'Last), "max capacity edge EK");
   F2 := Max_Flow (N, 1, 2, Dinic);
   Check (F2 = F, "max capacity EK≡Dinic");

   ------------------------------------------------------------------
   Section ("17. Clear resets edges / flow never exceeds capacity");
   ------------------------------------------------------------------
   Clear (N, 4);
   Add_Edge (N, 1, 2, 9);
   Add_Edge (N, 2, 3, 9);
   Clear (N, 4);
   Check (Edge_Count (N) = 0, "Clear empties edges");
   Check (Max_Flow (N, 1, 4, Edmonds_Karp) = 0, "cleared flow=0");
   Check (Vertex_Count (N) = 4, "Clear keeps N=4");

   Clear (N, 6);
   Add_Edge (N, 1, 2, 7);
   Add_Edge (N, 1, 3, 8);
   Add_Edge (N, 2, 4, 3);
   Add_Edge (N, 2, 5, 4);
   Add_Edge (N, 3, 5, 5);
   Add_Edge (N, 3, 4, 6);
   Add_Edge (N, 4, 6, 9);
   Add_Edge (N, 5, 6, 9);
   F := Max_Flow (N, 1, 6, Edmonds_Karp);
   for I in 1 .. Edge_Count (N) loop
      Check (Edge_Flow (N, I) <= Flow_Value (Edge_Capacity (N, I)),
             "cap respect edge " & Integer'Image (I));
   end loop;
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = F, "cap-net cut=F");
   F2 := Max_Flow (N, 1, 6, Dinic);
   Check (F2 = F, "cap-net EK≡Dinic");

   ------------------------------------------------------------------
   Section ("18. Min-cut membership / random digraphs");
   ------------------------------------------------------------------
   for Cap in 1 .. 6 loop
      Clear (N, 4);
      Add_Edge (N, 1, 2, Cap);
      Add_Edge (N, 2, 3, 100);
      Add_Edge (N, 3, 4, Cap);
      F := Max_Flow (N, 1, 4, Edmonds_Karp);
      F2 := Max_Flow (N, 1, 4, Dinic);
      Min_Cut_Partition (N, 1, In_S);
      Check (F = Flow_Value (Cap), "s-cut pattern flow");
      Check (F = F2, "s-cut EK≡Dinic");
      Check (In_S (1), "s in S");
      Check (not In_S (4), "t not in S");
      Check (Cut_Capacity (N, In_S) = F, "s-cut pattern cut=F");
   end loop;

   for Seed in 1 .. 16 loop
      Clear (N, 8);
      for I in 1 .. 8 loop
         for J in 1 .. 8 loop
            if I /= J and then ((I * 17 + J * 13 + Seed) mod 5) = 0 then
               declare
                  C : constant Integer :=
                    1 + (I * J + Seed) mod 9;
               begin
                  Add_Edge (N, Vertex_Id (I), Vertex_Id (J), C);
               end;
            end if;
         end loop;
      end loop;
      F := Max_Flow (N, 1, 8, Edmonds_Karp);
      F2 := Max_Flow (N, 1, 8, Dinic);
      Check (F = F2, "rnd EK≡Dinic seed=" & Integer'Image (Seed));
      Min_Cut_Partition (N, 1, In_S);
      Check (Cut_Capacity (N, In_S) = F,
             "cut=flow rnd seed=" & Integer'Image (Seed));
      Check (In_S (1), "rnd S has s seed=" & Integer'Image (Seed));
      Check (not In_S (8) or else F = 0,
             "rnd t not in S or F=0 seed=" & Integer'Image (Seed));
   end loop;

   ------------------------------------------------------------------
   Section ("19. Layered pathish / bipartite matching");
   ------------------------------------------------------------------
   for Nx in 3 .. 12 loop
      Clear (N, Nx);
      for I in 1 .. Nx - 1 loop
         Add_Edge (N, Vertex_Id (I), Vertex_Id (I + 1), I);
         if I + 2 <= Nx then
            Add_Edge (N, Vertex_Id (I), Vertex_Id (I + 2), 1);
         end if;
      end loop;
      F := Max_Flow (N, 1, Vertex_Id (Nx), Edmonds_Karp);
      F2 := Max_Flow (N, 1, Vertex_Id (Nx), Dinic);
      Check (F = F2, "pathish EK≡Dinic n=" & Integer'Image (Nx));
      Min_Cut_Partition (N, 1, In_S);
      Check (Cut_Capacity (N, In_S) = F,
             "pathish cut=flow n=" & Integer'Image (Nx));
      Check (F > 0, "pathish flow>0 n=" & Integer'Image (Nx));
   end loop;

   Clear (N, 8);
   Add_Edge (N, 1, 2, 1);
   Add_Edge (N, 1, 3, 1);
   Add_Edge (N, 1, 4, 1);
   Add_Edge (N, 2, 5, 1);
   Add_Edge (N, 2, 6, 1);
   Add_Edge (N, 3, 6, 1);
   Add_Edge (N, 3, 7, 1);
   Add_Edge (N, 4, 7, 1);
   Add_Edge (N, 5, 8, 1);
   Add_Edge (N, 6, 8, 1);
   Add_Edge (N, 7, 8, 1);
   F := Max_Flow (N, 1, 8, Edmonds_Karp);
   Check (F = 3, "bipartite matching=3 EK");
   F2 := Max_Flow (N, 1, 8, Dinic);
   Check (F2 = 3, "bipartite matching=3 Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 3, "bipartite cut=3");

   Clear (N, 5);
   Add_Edge (N, 1, 2, 1);
   Add_Edge (N, 1, 3, 1);
   Add_Edge (N, 2, 4, 1);
   Add_Edge (N, 3, 4, 1);
   Add_Edge (N, 4, 5, 1);
   F := Max_Flow (N, 1, 5, Edmonds_Karp);
   Check (F = 1, "unbalanced matching=1");
   Check (Max_Flow (N, 1, 5, Dinic) = 1, "unbalanced matching=1 Dinic");

   ------------------------------------------------------------------
   Section ("20. Backward residual / multi s-t / default Algo");
   ------------------------------------------------------------------
   Clear (N, 4);
   Add_Edge (N, 1, 2, 1);
   Add_Edge (N, 1, 3, 1);
   Add_Edge (N, 2, 3, 1);
   Add_Edge (N, 2, 4, 1);
   Add_Edge (N, 3, 4, 1);
   F := Max_Flow (N, 1, 4);  -- default Edmonds_Karp
   Check (F = 2, "cancel-net flow=2 default EK");
   F2 := Max_Flow (N, 1, 4, Dinic);
   Check (F2 = 2, "cancel-net flow=2 Dinic");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = 2, "cancel-net cut=2");
   Check (Edge_Flow (N, 1) = 1, "s→a saturated");
   Check (Edge_Flow (N, 2) = 1, "s→b saturated");

   Clear (N, 5);
   Add_Edge (N, 1, 2, 4);
   Add_Edge (N, 1, 3, 6);
   Add_Edge (N, 2, 4, 5);
   Add_Edge (N, 3, 4, 3);
   Add_Edge (N, 4, 5, 8);
   Add_Edge (N, 2, 5, 2);
   F := Max_Flow (N, 1, 5, Edmonds_Karp);
   Check (F = 7, "multi pair 1→5 =7");
   Check (Max_Flow (N, 1, 5, Dinic) = 7, "multi pair 1→5 Dinic=7");
   Min_Cut_Partition (N, 1, In_S);
   Check (Cut_Capacity (N, In_S) = F, "multi pair 1→5 cut=F");
   F := Max_Flow (N, 1, 4, Edmonds_Karp);
   Check (F = 7, "multi pair 1→4 =7");
   Check (Max_Flow (N, 1, 4, Dinic) = 7, "multi pair 1→4 Dinic");
   F := Max_Flow (N, 2, 5, Edmonds_Karp);
   Check (F = 7, "multi pair 2→5 =7");
   Min_Cut_Partition (N, 2, In_S);
   Check (Cut_Capacity (N, In_S) = F, "multi pair 2→5 cut=F");

   --  Stored-terminals overload after Set_Source/Set_Sink
   Clear (N, 3);
   Add_Edge (N, 1, 2, 9);
   Add_Edge (N, 2, 3, 5);
   Set_Source (N, 1);
   Set_Sink (N, 3);
   Check (Max_Flow (N) = 5, "stored default Algo flow=5");
   Check (Max_Flow (N, Dinic) = 5, "stored Dinic flow=5");
   Algo := Edmonds_Karp;
   Check (Max_Flow (N, Algo) = 5, "stored enum var flow=5");

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
