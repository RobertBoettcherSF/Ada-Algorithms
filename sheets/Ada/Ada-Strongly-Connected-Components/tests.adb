--  Standalone test suite for Strongly_Connected_Components (survey).
--  Verifies Tarjan, Kosaraju, and Path_Based agree on partitions
--  (up to component-id renumbering) on shared fixtures.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Strongly_Connected_Components; use Strongly_Connected_Components;

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
     (G : in out Graph; From, To : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, From, To);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Compute_Raises
     (G : Graph; Algo : Method; First, Last : Vertex_Id) return Boolean
   is
      Comp  : Component_Array (First .. Last);
      Count : Natural;
   begin
      Compute_SCC (G, Algo, Comp, Count);
      pragma Unreferenced (Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Raises;

   function Same_Raises
     (Comp : Component_Array; U, V : Vertex_Id) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Same_SCC (Comp, U, V);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Same_Raises;

   --  True iff A and B induce the same partition of 1 .. N
   --  (component ids may be renumbered).
   function Partitions_Agree
     (A, B : Component_Array; N : Natural) return Boolean
   is
   begin
      if N = 0 then
         return True;
      end if;
      for U in Vertex_Id range 1 .. Vertex_Id (N) loop
         if A (U) = 0 or else B (U) = 0 then
            return False;
         end if;
         for V in Vertex_Id range U .. Vertex_Id (N) loop
            if (A (U) = A (V)) /= (B (U) = B (V)) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Partitions_Agree;

   function All_Singleton (Comp : Component_Array; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_Vertices) of Boolean := [others => False];
      Id   : Natural;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Id := Natural (Comp (V));
         if Id = 0 or else Id > N then
            return False;
         end if;
         if Seen (Id) then
            return False;
         end if;
         Seen (Id) := True;
      end loop;
      return True;
   end All_Singleton;

   function All_Labeled (Comp : Component_Array; N : Natural) return Boolean is
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Comp (V) = 0 then
            return False;
         end if;
      end loop;
      return True;
   end All_Labeled;

   function Distinct_Count (Comp : Component_Array; N : Natural) return Natural
   is
      Seen  : array (1 .. Max_Vertices) of Boolean := [others => False];
      Count : Natural := 0;
      Id    : Natural;
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Id := Natural (Comp (V));
         if Id = 0 or else Id > Max_Vertices then
            return 0;
         end if;
         if not Seen (Id) then
            Seen (Id) := True;
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Distinct_Count;

   --  Run all three methods; check counts, labels, and pairwise agreement.
   procedure Check_Triple
     (G           : Graph;
      Expect_Count : Natural;
      Tag         : String)
   is
      N : constant Natural := Vertex_Count (G);
      CT, CK, CP : Component_Array (1 .. Vertex_Id'Last);
      NT, NK, NP : Natural;
   begin
      Compute_SCC (G, Tarjan, CT, NT);
      Compute_SCC (G, Kosaraju, CK, NK);
      Compute_SCC (G, Path_Based, CP, NP);

      Check (NT = Expect_Count, Tag & " Tarjan count");
      Check (NK = Expect_Count, Tag & " Kosaraju count");
      Check (NP = Expect_Count, Tag & " Path_Based count");
      Check (NT = NK and then NK = NP, Tag & " counts equal");

      if N > 0 then
         Check (All_Labeled (CT, N), Tag & " Tarjan labeled");
         Check (All_Labeled (CK, N), Tag & " Kosaraju labeled");
         Check (All_Labeled (CP, N), Tag & " Path_Based labeled");
         Check (Distinct_Count (CT, N) = Expect_Count,
                Tag & " Tarjan distinct");
         Check (Distinct_Count (CK, N) = Expect_Count,
                Tag & " Kosaraju distinct");
         Check (Distinct_Count (CP, N) = Expect_Count,
                Tag & " Path_Based distinct");
      end if;

      Check (Partitions_Agree (CT, CK, N), Tag & " Tarjan≡Kosaraju");
      Check (Partitions_Agree (CT, CP, N), Tag & " Tarjan≡Path_Based");
      Check (Partitions_Agree (CK, CP, N), Tag & " Kosaraju≡Path_Based");
   end Check_Triple;

   procedure Check_Triple_Same
     (G : Graph; U, V : Vertex_Id; Expect_Same : Boolean; Tag : String)
   is
      Comp : Component_Array (1 .. Vertex_Id'Last);
      Count : Natural;
   begin
      for Algo in Method loop
         Compute_SCC (G, Algo, Comp, Count);
         Check (Count > 0 or else Vertex_Count (G) = 0,
                Tag & " count ok " & Method'Image (Algo));
         if Expect_Same then
            Check (Same_SCC (Comp, U, V),
                   Tag & " Same_SCC " & Method'Image (Algo));
         else
            Check (not Same_SCC (Comp, U, V),
                   Tag & " not Same_SCC " & Method'Image (Algo));
         end if;
      end loop;
   end Check_Triple_Same;


   -------------------------------------------------------------------------
   -- 1. Empty / single / trivial
   -------------------------------------------------------------------------

   procedure Test_Trivial is
      G : Graph;
   begin
      Section ("1. Empty / single / no edges");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "empty Vertex_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Check_Triple (G, 0, "empty");

      Clear (G, 1);
      Check (Vertex_Count (G) = 1, "single Vertex_Count = 1");
      Check_Triple (G, 1, "single");
      Check_Triple_Same (G, 1, 1, True, "single self");

      Clear (G, 1);
      Add_Edge (G, 1, 1);
      Check (Edge_Count (G) = 1, "self-loop Edge_Count = 1");
      Check_Triple (G, 1, "self-loop");

      Clear (G, 3);
      Check_Triple (G, 3, "3 isolated");
      Check_Triple_Same (G, 1, 2, False, "isolated 1≠2");
      Check_Triple_Same (G, 2, 3, False, "isolated 2≠3");

      Clear (G, 5);
      Check_Triple (G, 5, "5 isolated");
   end Test_Trivial;

   -------------------------------------------------------------------------
   -- 2. Chains and DAGs
   -------------------------------------------------------------------------

   procedure Test_Chains is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("2. Chains / DAGs (acyclic ⇒ singletons)");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Check_Triple (G, 4, "chain4");
      Compute_SCC (G, Tarjan, Comp, Count);
      Check (All_Singleton (Comp, 4), "chain4 all singletons Tarjan");
      Compute_SCC (G, Kosaraju, Comp, Count);
      Check (All_Singleton (Comp, 4), "chain4 all singletons Kosaraju");
      Compute_SCC (G, Path_Based, Comp, Count);
      Check (All_Singleton (Comp, 4), "chain4 all singletons Path_Based");

      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Check_Triple (G, 5, "diamond-DAG");

      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Check_Triple (G, 6, "long-chain");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Check_Triple (G, 3, "star-out");

      Clear (G, 3);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 1);
      Check_Triple (G, 3, "star-in");
   end Test_Chains;

   -------------------------------------------------------------------------
   -- 3. Cycles
   -------------------------------------------------------------------------

   procedure Test_Cycles is
      G : Graph;
   begin
      Section ("3. Cycles");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Check_Triple (G, 1, "2-cycle");
      Check_Triple_Same (G, 1, 2, True, "2-cycle members");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Check_Triple (G, 1, "3-cycle");
      Check_Triple_Same (G, 1, 3, True, "3-cycle 1~3");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Check_Triple (G, 1, "4-cycle");

      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 1);
      Check_Triple (G, 1, "5-cycle");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Check_Triple (G, 2, "two-2-cycles");
      Check_Triple_Same (G, 1, 2, True, "pairA");
      Check_Triple_Same (G, 3, 4, True, "pairB");
      Check_Triple_Same (G, 1, 3, False, "pairA≠pairB");

      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 4);
      Check_Triple (G, 2, "two-3-cycles");
      Check_Triple_Same (G, 1, 3, True, "triA");
      Check_Triple_Same (G, 4, 6, True, "triB");
      Check_Triple_Same (G, 2, 5, False, "triA≠triB");
   end Test_Cycles;

   -------------------------------------------------------------------------
   -- 4. Classic textbook graph
   -------------------------------------------------------------------------

   procedure Test_Classic is
      G : Graph;
   begin
      Section ("4. Classic multi-SCC graphs");

      --  {1,2,3} cycle, bridge 2→4, {4,5} mutual, sink 5→6 optional
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Check_Triple (G, 2, "classic5");
      Check_Triple_Same (G, 1, 3, True, "classic5 triangle");
      Check_Triple_Same (G, 4, 5, True, "classic5 pair");
      Check_Triple_Same (G, 2, 4, False, "classic5 bridge");

      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Add_Edge (G, 5, 6);
      Check_Triple (G, 3, "classic6");
      Check_Triple_Same (G, 1, 2, True, "classic6 tri");
      Check_Triple_Same (G, 4, 5, True, "classic6 mid");
      Check_Triple_Same (G, 6, 6, True, "classic6 sink self");
      Check_Triple_Same (G, 5, 6, False, "classic6 mid≠sink");

      --  Wikipedia-ish: a→b→c→a, b→d→e→d, b→f, f→g→f, e→g
      Clear (G, 7);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Add_Edge (G, 2, 6);
      Add_Edge (G, 6, 7);
      Add_Edge (G, 7, 6);
      Add_Edge (G, 5, 7);
      Check_Triple (G, 3, "wiki7");
      Check_Triple_Same (G, 1, 3, True, "wiki7 A");
      Check_Triple_Same (G, 4, 5, True, "wiki7 B");
      Check_Triple_Same (G, 6, 7, True, "wiki7 C");
      Check_Triple_Same (G, 1, 4, False, "wiki7 A≠B");
      Check_Triple_Same (G, 4, 6, False, "wiki7 B≠C");
   end Test_Classic;

   -------------------------------------------------------------------------
   -- 5. Complete digraphs
   -------------------------------------------------------------------------

   procedure Test_Complete is
      G : Graph;
   begin
      Section ("5. Complete digraphs");

      Clear (G, 3);
      for U in Vertex_Id range 1 .. 3 loop
         for V in Vertex_Id range 1 .. 3 loop
            if U /= V then
               Add_Edge (G, U, V);
            end if;
         end loop;
      end loop;
      Check_Triple (G, 1, "K3");

      Clear (G, 4);
      for U in Vertex_Id range 1 .. 4 loop
         for V in Vertex_Id range 1 .. 4 loop
            if U /= V then
               Add_Edge (G, U, V);
            end if;
         end loop;
      end loop;
      Check_Triple (G, 1, "K4");

      Clear (G, 5);
      for U in Vertex_Id range 1 .. 5 loop
         for V in Vertex_Id range 1 .. 5 loop
            if U /= V then
               Add_Edge (G, U, V);
            end if;
         end loop;
      end loop;
      Check_Triple (G, 1, "K5");
      Check_Triple_Same (G, 1, 5, True, "K5 all together");
   end Test_Complete;

   -------------------------------------------------------------------------
   -- 6. Disconnected
   -------------------------------------------------------------------------

   procedure Test_Disconnected is
      G : Graph;
   begin
      Section ("6. Disconnected unions");

      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      --  3,4,5 isolated
      Check_Triple (G, 4, "pair+3iso");
      Check_Triple_Same (G, 1, 2, True, "disc pair");
      Check_Triple_Same (G, 3, 4, False, "disc iso");

      Clear (G, 8);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 5);
      Add_Edge (G, 7, 8);
      Add_Edge (G, 8, 7);
      Check_Triple (G, 4, "four-pairs");

      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      --  4→5→6 chain
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Check_Triple (G, 4, "cycle+chain");
   end Test_Disconnected;

   -------------------------------------------------------------------------
   -- 7. Condensation / bridging
   -------------------------------------------------------------------------

   procedure Test_Condensation is
      G    : Graph;
      Comp : Component_Array (1 .. 20);
      Count : Natural;
      Id_A, Id_B, Id_C : Component_Id;
   begin
      Section ("7. Condensation DAG properties");

      --  Source SCC → mid SCC → sink SCC
      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 5);
      Check_Triple (G, 3, "src-mid-snk");
      Check_Triple_Same (G, 1, 2, True, "src pair");
      Check_Triple_Same (G, 3, 4, True, "mid pair");
      Check_Triple_Same (G, 5, 6, True, "snk pair");
      Check_Triple_Same (G, 1, 3, False, "src≠mid");
      Check_Triple_Same (G, 3, 5, False, "mid≠snk");

      --  Kosaraju: topological ids (source < mid < sink)
      Compute_SCC (G, Kosaraju, Comp, Count);
      Id_A := Comp (1);
      Id_B := Comp (3);
      Id_C := Comp (5);
      Check (Id_A < Id_B and then Id_B < Id_C,
             "Kosaraju topo order sources before sinks");

      --  Tarjan / Path_Based: reverse topo (sink finished first ⇒ smaller id)
      Compute_SCC (G, Tarjan, Comp, Count);
      Id_A := Comp (1);
      Id_B := Comp (3);
      Id_C := Comp (5);
      Check (Id_C < Id_B and then Id_B < Id_A,
             "Tarjan reverse topo sinks before sources");
      Compute_SCC (G, Path_Based, Comp, Count);
      Id_A := Comp (1);
      Id_B := Comp (3);
      Id_C := Comp (5);
      Check (Id_C < Id_B and then Id_B < Id_A,
             "Path_Based reverse topo sinks before sources");
      pragma Unreferenced (Count);
   end Test_Condensation;

   -------------------------------------------------------------------------
   -- 8. Multiedges / self-loops
   -------------------------------------------------------------------------

   procedure Test_Multiedges is
      G : Graph;
   begin
      Section ("8. Parallel edges / self-loops");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 2, 1);
      Check (Edge_Count (G) = 4, "parallel Edge_Count = 4");
      Check_Triple (G, 2, "parallels+iso");
      Check_Triple_Same (G, 1, 2, True, "parallel pair");

      Clear (G, 2);
      Add_Edge (G, 1, 1);
      Add_Edge (G, 2, 2);
      Check_Triple (G, 2, "two self-loops");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 1);
      Add_Edge (G, 2, 2);
      Check_Triple (G, 1, "cycle+selfloops");
   end Test_Multiedges;

   -------------------------------------------------------------------------
   -- 9. Invalid arguments
   -------------------------------------------------------------------------

   procedure Test_Invalid is
      G    : Graph;
      Comp : Component_Array (1 .. 5);
      Count : Natural;
   begin
      Section ("9. Invalid_Argument");

      Check (Clear_Raises (Nat (Max_Vertices) + 1),
             "Clear N > Max_Vertices");
      Check (not Clear_Raises (0), "Clear 0 ok");
      Check (not Clear_Raises (Max_Vertices), "Clear Max_Vertices ok");

      Clear (G, 3);
      Check (Add_Raises (G, 1, 4), "Add_Edge To out of range");
      Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");

      Clear (G, 0);
      Check (Add_Raises (G, 1, 1), "Add_Edge on empty graph");

      Clear (G, 2);
      for Algo in Method loop
         Check (Compute_Raises (G, Algo, 2, 2),
                "Compute First≠1 " & Method'Image (Algo));
         Check (Compute_Raises (G, Algo, 1, 1),
                "Compute Last < N " & Method'Image (Algo));
      end loop;

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Compute_SCC (G, Tarjan, Comp, Count);
      Check (Same_Raises (Comp, 1, 6), "Same_SCC V out of range");
      Check (Same_Raises (Comp, 6, 1), "Same_SCC U out of range");
      pragma Unreferenced (Count);
   end Test_Invalid;

   -------------------------------------------------------------------------
   -- 10. Clear / reset / counters
   -------------------------------------------------------------------------

   procedure Test_Clear_Reset is
      G : Graph;
   begin
      Section ("10. Clear / reset / counters");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Check (Vertex_Count (G) = 4, "VC=4");
      Check (Edge_Count (G) = 2, "EC=2");
      Clear (G, 2);
      Check (Vertex_Count (G) = 2, "after Clear VC=2");
      Check (Edge_Count (G) = 0, "after Clear EC=0");
      Check_Triple (G, 2, "cleared isolates");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Check_Triple (G, 1, "rebuild cycle");
      Clear (G, 3);
      Check_Triple (G, 3, "rebuild isolates");
   end Test_Clear_Reset;

   -------------------------------------------------------------------------
   -- 11. Larger patterns
   -------------------------------------------------------------------------

   procedure Test_Larger is
      G : Graph;
      N : Natural;
   begin
      Section ("11. Larger patterns");

      --  Five disjoint 2-cycles
      Clear (G, 10);
      for I in 0 .. 4 loop
         Add_Edge (G, Vertex_Id (2 * I + 1), Vertex_Id (2 * I + 2));
         Add_Edge (G, Vertex_Id (2 * I + 2), Vertex_Id (2 * I + 1));
      end loop;
      Check_Triple (G, 5, "five-2-cycles");

      --  20-cycle
      Clear (G, 20);
      for I in 1 .. 19 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, 20, 1);
      Check_Triple (G, 1, "20-cycle");
      Check_Triple_Same (G, 1, 20, True, "20-cycle ends");

      --  50 isolates
      Clear (G, 50);
      Check_Triple (G, 50, "50 isolates");

      --  Chain of 30
      Clear (G, 30);
      for I in 1 .. 29 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Check_Triple (G, 30, "chain30");

      --  Ten triangles linked by bridges (10 SCCs if bridges one-way)
      Clear (G, 30);
      for T in 0 .. 9 loop
         declare
            A : constant Vertex_Id := Vertex_Id (3 * T + 1);
            B : constant Vertex_Id := Vertex_Id (3 * T + 2);
            C : constant Vertex_Id := Vertex_Id (3 * T + 3);
         begin
            Add_Edge (G, A, B);
            Add_Edge (G, B, C);
            Add_Edge (G, C, A);
            if T < 9 then
               Add_Edge (G, C, Vertex_Id (3 * (T + 1) + 1));
            end if;
         end;
      end loop;
      Check_Triple (G, 10, "ten-triangles");

      N := 100;
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
         Add_Edge (G, Vertex_Id (I + 1), Vertex_Id (I));
      end loop;
      Check_Triple (G, 1, "path-bidir-100");
   end Test_Larger;

   -------------------------------------------------------------------------
   -- 12. Nested / hierarchical
   -------------------------------------------------------------------------

   procedure Test_Nested is
      G : Graph;
   begin
      Section ("12. Nested / hierarchical SCCs");

      --  Outer: 1↔2↔3 cycle; from 3 → 4; 4↔5; from 5 → 6 sink
      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Add_Edge (G, 5, 6);
      Check_Triple (G, 3, "nested3");
      Check_Triple_Same (G, 1, 2, True, "nested outer");
      Check_Triple_Same (G, 4, 5, True, "nested mid");
      Check_Triple_Same (G, 6, 1, False, "nested sink≠outer");

      --  Two sources into one sink cycle
      Clear (G, 5);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 3);
      Check_Triple (G, 3, "two-src-sink-cycle");
      Check_Triple_Same (G, 3, 5, True, "sink cycle");
      Check_Triple_Same (G, 1, 2, False, "two sources distinct");
   end Test_Nested;

   -------------------------------------------------------------------------
   -- 13. Forest / multiple DFS trees
   -------------------------------------------------------------------------

   procedure Test_Forest is
      G : Graph;
   begin
      Section ("13. DFS forests");

      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Add_Edge (G, 5, 6);
      Check_Triple (G, 4, "forest");
      --  5→6 is a chain ⇒ two singletons + two pairs = 4

      Clear (G, 9);
      for K in 0 .. 2 loop
         declare
            A : constant Vertex_Id := Vertex_Id (3 * K + 1);
            B : constant Vertex_Id := Vertex_Id (3 * K + 2);
            C : constant Vertex_Id := Vertex_Id (3 * K + 3);
         begin
            Add_Edge (G, A, B);
            Add_Edge (G, B, C);
            Add_Edge (G, C, A);
         end;
      end loop;
      Check_Triple (G, 3, "three-disjoint-triangles");
   end Test_Forest;

   -------------------------------------------------------------------------
   -- 14. Method enum / API smoke
   -------------------------------------------------------------------------

   procedure Test_Method_API is
      G : Graph;
      Comp : Component_Array (1 .. 10);
      Count : Natural;
      First : Boolean := True;
      Prev  : Natural := 0;
   begin
      Section ("14. Method enum / API smoke");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);

      for Algo in Method loop
         Compute_SCC (G, Algo, Comp, Count);
         Check (Count = 2, "API count " & Method'Image (Algo));
         Check (Same_SCC (Comp, 1, 2), "API pair1 " & Method'Image (Algo));
         Check (Same_SCC (Comp, 3, 4), "API pair2 " & Method'Image (Algo));
         Check (not Same_SCC (Comp, 1, 3), "API cross " & Method'Image (Algo));
         if First then
            Prev := Count;
            First := False;
         else
            Check (Count = Prev, "API stable count " & Method'Image (Algo));
         end if;
      end loop;

      Check (Method'Pos (Tarjan) = 0, "Method'Pos Tarjan=0");
      Check (Method'Pos (Kosaraju) = 1, "Method'Pos Kosaraju=1");
      Check (Method'Pos (Path_Based) = 2, "Method'Pos Path_Based=2");
      Check (Method'Pred (Kosaraju) = Tarjan, "Method'Pred");
      Check (Method'Succ (Kosaraju) = Path_Based, "Method'Succ");
   end Test_Method_API;

   -------------------------------------------------------------------------
   -- 15. Mixed / stress fixtures
   -------------------------------------------------------------------------

   procedure Test_Mixed is
      G : Graph;
   begin
      Section ("15. Mixed fixtures");

      --  Self-loop plus outgoing
      Clear (G, 3);
      Add_Edge (G, 1, 1);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 2);
      Check_Triple (G, 2, "loop+pair");
      Check_Triple_Same (G, 2, 3, True, "mixed pair");
      Check_Triple_Same (G, 1, 2, False, "mixed loop≠pair");

      --  Bidirectional star: center connected both ways to leaves
      Clear (G, 5);
      for L in Vertex_Id range 2 .. 5 loop
         Add_Edge (G, 1, L);
         Add_Edge (G, L, 1);
      end loop;
      Check_Triple (G, 1, "bidir-star");

      --  Tournament-ish: i→j for i<j plus one back edge closing a cycle
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 1, 4);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 2);  -- closes {2,3,4}? 4→2→3→4 needs 3→4 and 2→3
      Check_Triple (G, 2, "tournament+back");
      Check_Triple_Same (G, 2, 4, True, "tourn cycle");
      Check_Triple_Same (G, 1, 2, False, "tourn source alone");

      --  Empty after edges? rebuild
      Clear (G, 1);
      Check_Triple (G, 1, "tiny again");

      Clear (G, 8);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 4);
      Add_Edge (G, 6, 7);
      Add_Edge (G, 7, 8);
      Add_Edge (G, 8, 7);
      Check_Triple (G, 3, "cascade3");
      Check_Triple_Same (G, 1, 3, True, "casc A");
      Check_Triple_Same (G, 4, 6, True, "casc B");
      Check_Triple_Same (G, 7, 8, True, "casc C");
   end Test_Mixed;

   -------------------------------------------------------------------------
   -- 16. Bounds / capacity smoke
   -------------------------------------------------------------------------

   procedure Test_Bounds is
      G : Graph;
      Comp : Component_Array (1 .. Vertex_Id'Last);
      Count : Natural;
   begin
      Section ("16. Bounds / Max_Vertices smoke");

      Clear (G, Max_Vertices);
      Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices VC");
      Compute_SCC (G, Tarjan, Comp, Count);
      Check (Count = Max_Vertices, "Max_Vertices all isolates Tarjan");
      Compute_SCC (G, Kosaraju, Comp, Count);
      Check (Count = Max_Vertices, "Max_Vertices all isolates Kosaraju");
      Compute_SCC (G, Path_Based, Comp, Count);
      Check (Count = Max_Vertices, "Max_Vertices all isolates Path_Based");
      Check (Partitions_Agree (Comp, Comp, Max_Vertices), "agree self");

      --  Component_Of oversized last is OK
      declare
         Wide : Component_Array (1 .. Vertex_Id'Last);
      begin
         Clear (G, 3);
         Add_Edge (G, 1, 2);
         Add_Edge (G, 2, 1);
         Compute_SCC (G, Tarjan, Wide, Count);
         Check (Count = 2, "wide array Tarjan");
         Compute_SCC (G, Kosaraju, Wide, Count);
         Check (Count = 2, "wide array Kosaraju");
         Compute_SCC (G, Path_Based, Wide, Count);
         Check (Count = 2, "wide array Path_Based");
      end;
   end Test_Bounds;

   -------------------------------------------------------------------------
   -- 17. Systematic small graphs
   -------------------------------------------------------------------------

   procedure Test_Systematic is
      G : Graph;
   begin
      Section ("17. Systematic small graphs");

      --  Single edge
      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Check_Triple (G, 2, "single-edge");

      --  Mutual + pendant
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 2, 3);
      Check_Triple (G, 2, "mutual+pendant");
      Check_Triple_Same (G, 1, 2, True, "mp pair");
      Check_Triple_Same (G, 2, 3, False, "mp pendant");

      --  Figure-8: two cycles sharing a vertex
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 1);
      Check_Triple (G, 1, "figure-8");
      Check_Triple_Same (G, 2, 5, True, "figure-8 all");

      --  Chordal cycle
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Add_Edge (G, 1, 3);
      Check_Triple (G, 1, "chordal-4");

      --  Only back edges forming no cycle across components
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 3, 2);  -- 2↔3
      Check_Triple (G, 3, "chain-with-mid-cycle");
      Check_Triple_Same (G, 2, 3, True, "mid cycle");
      Check_Triple_Same (G, 1, 2, False, "src alone");
      Check_Triple_Same (G, 3, 4, False, "snk alone");
   end Test_Systematic;

begin
   Put_Line ("Strongly_Connected_Components test suite");
   Put_Line ("========================================");

   Test_Trivial;
   Test_Chains;
   Test_Cycles;
   Test_Classic;
   Test_Complete;
   Test_Disconnected;
   Test_Condensation;
   Test_Multiedges;
   Test_Invalid;
   Test_Clear_Reset;
   Test_Larger;
   Test_Nested;
   Test_Forest;
   Test_Method_API;
   Test_Mixed;
   Test_Bounds;
   Test_Systematic;

   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
