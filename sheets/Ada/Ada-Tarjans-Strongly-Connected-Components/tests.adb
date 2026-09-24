--  Standalone test suite for Tarjans_SCC (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Tarjans_SCC; use Tarjans_SCC;

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
     (G : Graph; First, Last : Vertex_Id) return Boolean
   is
      Comp  : Component_Array (First .. Last);
      Count : Natural;
   begin
      Compute_SCC (G, Comp, Count);
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

   --  Helper: all vertices in Lo .. Hi share one component id, and that
   --  id differs from every vertex outside that range (within 1 .. N).
   function Block_Is_SCC
     (Comp : Component_Array;
      N    : Natural;
      Lo, Hi : Vertex_Id) return Boolean
   is
      Id : constant Component_Id := Comp (Lo);
   begin
      if Id = 0 then
         return False;
      end if;
      for V in Lo .. Hi loop
         if Comp (V) /= Id then
            return False;
         end if;
      end loop;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if V < Lo or else V > Hi then
            if Comp (V) = Id then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Block_Is_SCC;

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

   -------------------------------------------------------------------------
   -- 1. Empty / single / trivial
   -------------------------------------------------------------------------

   procedure Test_Trivial is
      G     : Graph;
      Comp  : Component_Array (1 .. 10);
      Count : Natural;
   begin
      Section ("1. Empty / single / no edges");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "empty Vertex_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Compute_SCC (G, Comp, Count);
      Check (Count = 0, "empty graph → 0 SCCs");

      Clear (G, 1);
      Check (Vertex_Count (G) = 1, "single Vertex_Count = 1");
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "single vertex → 1 SCC");
      Check (Comp (1) = 1, "single vertex component id 1");
      Check (Same_SCC (Comp, 1, 1), "Same_SCC (1,1)");

      Clear (G, 1);
      Add_Edge (G, 1, 1);
      Check (Edge_Count (G) = 1, "self-loop Edge_Count = 1");
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "self-loop still 1 SCC");
      Check (Comp (1) = 1, "self-loop component id 1");

      Clear (G, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "3 isolated → 3 SCCs");
      Check (All_Singleton (Comp, 3), "3 isolated all singletons");
      Check (not Same_SCC (Comp, 1, 2), "isolated 1 ≠ 2");
      Check (not Same_SCC (Comp, 2, 3), "isolated 2 ≠ 3");
   end Test_Trivial;

   -------------------------------------------------------------------------
   -- 2. Chains and DAGs (all singletons)
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
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "chain 1→2→3→4 → 4 SCCs");
      Check (All_Singleton (Comp, 4), "chain all singletons");

      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Compute_SCC (G, Comp, Count);
      Check (Count = 5, "DAG diamond → 5 SCCs");
      Check (All_Singleton (Comp, 5), "DAG all singletons");
      Check (not Same_SCC (Comp, 1, 5), "DAG ends differ");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "star out → 3 SCCs");
      Check (All_Singleton (Comp, 3), "star out singletons");
   end Test_Chains;

   -------------------------------------------------------------------------
   -- 3. Simple cycles
   -------------------------------------------------------------------------

   procedure Test_Cycles is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("3. Simple cycles");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "2-cycle → 1 SCC");
      Check (Same_SCC (Comp, 1, 2), "2-cycle Same_SCC");
      Check (Comp (1) = Comp (2), "2-cycle same id");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "3-cycle → 1 SCC");
      Check (Same_SCC (Comp, 1, 2) and then Same_SCC (Comp, 2, 3),
             "3-cycle all same");

      Clear (G, 5);
      for I in Vertex_Id range 1 .. 4 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Add_Edge (G, 5, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "5-cycle → 1 SCC");
      Check (Block_Is_SCC (Comp, 5, 1, 5), "5-cycle one block");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "two 2-cycles linked → 2 SCCs");
      Check (Same_SCC (Comp, 1, 2), "pair {1,2}");
      Check (Same_SCC (Comp, 3, 4), "pair {3,4}");
      Check (not Same_SCC (Comp, 1, 3), "pairs distinct");
   end Test_Cycles;

   -------------------------------------------------------------------------
   -- 4. Classic textbook / Wikipedia-style examples
   -------------------------------------------------------------------------

   procedure Test_Classic is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("4. Classic multi-SCC examples");

      --  Vertices 1..8: two cycles sharing a bridge pattern
      --  SCC A = {1,2,3}, B = {4}, C = {5,6,7}, D = {8}
      --  Edges: 1→2→3→1, 3→4, 4→5, 5→6→7→5, 6→8, 4→3 (makes {1,2,3,4}? no)
      --  Simpler classic:
      --    1→2→3→1, 3→4→5→4, 5→6, 6→7→8→6, 6→5
      Clear (G, 8);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 7);
      Add_Edge (G, 7, 8);
      Add_Edge (G, 8, 6);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "classic 8-vertex → 3 SCCs");
      Check (Same_SCC (Comp, 1, 2) and then Same_SCC (Comp, 2, 3),
             "classic {1,2,3}");
      Check (Same_SCC (Comp, 4, 5), "classic {4,5}");
      Check (Same_SCC (Comp, 6, 7) and then Same_SCC (Comp, 7, 8),
             "classic {6,7,8}");
      Check (not Same_SCC (Comp, 1, 4), "classic A ≠ B");
      Check (not Same_SCC (Comp, 4, 6), "classic B ≠ C");
      Check (not Same_SCC (Comp, 1, 8), "classic A ≠ C");

      --  Wikipedia intuition: root of each SCC; nested reachability
      --  Graph: a→b→c→a, b→d, d→e→d  (map a=1,b=2,c=3,d=4,e=5)
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "wiki-like → 2 SCCs");
      Check (Block_Is_SCC (Comp, 5, 1, 3) or else
               (Same_SCC (Comp, 1, 2) and then Same_SCC (Comp, 2, 3)
                  and then Same_SCC (Comp, 4, 5)
                  and then not Same_SCC (Comp, 1, 4)),
             "wiki-like partitions {1,2,3}|{4,5}");
   end Test_Classic;

   -------------------------------------------------------------------------
   -- 5. Complete digraphs / dense
   -------------------------------------------------------------------------

   procedure Test_Complete is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("5. Complete digraphs");

      Clear (G, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "K1 → 1");

      Clear (G, 3);
      for I in Vertex_Id range 1 .. 3 loop
         for J in Vertex_Id range 1 .. 3 loop
            if I /= J then
               Add_Edge (G, I, J);
            end if;
         end loop;
      end loop;
      Check (Edge_Count (G) = 6, "K3 digraph 6 edges");
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "complete digraph K3 → 1 SCC");
      Check (Same_SCC (Comp, 1, 3), "K3 Same_SCC 1,3");

      Clear (G, 4);
      for I in Vertex_Id range 1 .. 4 loop
         for J in Vertex_Id range 1 .. 4 loop
            if I /= J then
               Add_Edge (G, I, J);
            end if;
         end loop;
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "complete digraph K4 → 1 SCC");
      Check (Block_Is_SCC (Comp, 4, 1, 4), "K4 one block");
   end Test_Complete;

   -------------------------------------------------------------------------
   -- 6. Disconnected components
   -------------------------------------------------------------------------

   procedure Test_Disconnected is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("6. Disconnected digraphs");

      Clear (G, 6);
      --  Component cycle {1,2}, isolated 3, cycle {4,5,6}
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "disconnected → 3 SCCs");
      Check (Same_SCC (Comp, 1, 2), "disc {1,2}");
      Check (Comp (3) /= 0, "disc isolated 3 assigned");
      Check (Same_SCC (Comp, 4, 5) and then Same_SCC (Comp, 5, 6),
             "disc {4,5,6}");
      Check (not Same_SCC (Comp, 1, 3), "disc 1 ≠ 3");
      Check (not Same_SCC (Comp, 1, 4), "disc 1 ≠ 4");
      Check (not Same_SCC (Comp, 3, 4), "disc 3 ≠ 4");

      Clear (G, 4);
      --  Two isolated edges (not cycles) ⇒ 4 SCCs
      Add_Edge (G, 1, 2);
      Add_Edge (G, 3, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "two arcs → 4 SCCs");
      Check (All_Singleton (Comp, 4), "two arcs singletons");
   end Test_Disconnected;

   -------------------------------------------------------------------------
   -- 7. Condensation / reverse topo property (ids)
   -------------------------------------------------------------------------

   procedure Test_Condensation_Order is
      G     : Graph;
      Comp  : Component_Array (1 .. 10);
      Count : Natural;
      Id_A, Id_B : Component_Id;
   begin
      Section ("7. Condensation reverse-topo order");

      --  A={1,2} → B={3}: Tarjan finishes B before A, so Id_B < Id_A
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 2, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "A→B condensation 2 SCCs");
      Id_A := Comp (1);
      Id_B := Comp (3);
      Check (Id_A /= Id_B, "A ≠ B ids");
      Check (Id_B < Id_A, "successor SCC finished first (smaller id)");

      --  Chain of three singleton SCCs 1→2→3: ids 3,2,1 respectively
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "chain condensation 3");
      Check (Comp (3) < Comp (2) and then Comp (2) < Comp (1),
             "chain reverse topo ids 3<2<1");
   end Test_Condensation_Order;

   -------------------------------------------------------------------------
   -- 8. Parallel edges, self-loops, mixed
   -------------------------------------------------------------------------

   procedure Test_Multiedges is
      G     : Graph;
      Comp  : Component_Array (1 .. 10);
      Count : Natural;
   begin
      Section ("8. Parallel edges / self-loops");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Check (Edge_Count (G) = 3, "parallel Edge_Count = 3");
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "parallel one-way → 2 SCCs");

      Clear (G, 3);
      Add_Edge (G, 1, 1);
      Add_Edge (G, 2, 2);
      Add_Edge (G, 3, 3);
      Add_Edge (G, 1, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "self-loops do not merge without return path");
      Check (All_Singleton (Comp, 3), "self-loop digraph singletons");

      Clear (G, 2);
      Add_Edge (G, 1, 1);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 2, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "mutual + self-loops → 1 SCC");
   end Test_Multiedges;

   -------------------------------------------------------------------------
   -- 9. Invalid_Argument contracts
   -------------------------------------------------------------------------

   procedure Test_Invalid is
      G     : Graph;
      Comp  : Component_Array (1 .. 5);
      Count : Natural;
      Ok    : Boolean;
   begin
      Section ("9. Invalid_Argument");

      Check (Clear_Raises (Nat (Max_Vertices + 1)),
             "Clear N > Max_Vertices");
      Check (not Clear_Raises (Nat (0)), "Clear 0 ok");
      Check (not Clear_Raises (Nat (Max_Vertices)), "Clear Max ok");

      Clear (G, 2);
      Check (Add_Raises (G, 1, 3), "Add_Edge To out of range");
      Clear (G, 2);
      Check (Add_Raises (G, 3, 1), "Add_Edge From out of range");
      Clear (G, 0);
      Check (Add_Raises (G, 1, 1), "Add_Edge on empty graph");

      Clear (G, 2);
      Check (Compute_Raises (G, 2, 5), "Compute_SCC First ≠ 1");
      Clear (G, 5);
      Check (Compute_Raises (G, 1, 3), "Compute_SCC Last < N");

      Clear (G, 2);
      Compute_SCC (G, Comp (1 .. 2), Count);
      Check (Same_Raises (Comp (1 .. 2), 1, 3), "Same_SCC V out of range");
      Check (Same_Raises (Comp (1 .. 2), 3, 1), "Same_SCC U out of range");

      --  Edge capacity exhaustion
      Clear (G, 2);
      Ok := True;
      begin
         for I in 1 .. Max_Edges loop
            Add_Edge (G, 1, 2);
         end loop;
         Check (Edge_Count (G) = Max_Edges, "filled to Max_Edges");
         Check (Add_Raises (G, 1, 2), "Add_Edge beyond Max_Edges");
      exception
         when others =>
            Ok := False;
      end;
      Check (Ok, "capacity test completed");
   end Test_Invalid;

   -------------------------------------------------------------------------
   -- 10. Larger random-ish structures / Same_SCC matrix
   -------------------------------------------------------------------------

   procedure Test_Larger is
      G     : Graph;
      Comp  : Component_Array (1 .. 50);
      Count : Natural;
      M     : Natural;
   begin
      Section ("10. Larger graphs / Same_SCC matrix");

      --  10 vertices: five disjoint 2-cycles
      Clear (G, 10);
      for I in 0 .. 4 loop
         Add_Edge (G, Vertex_Id (2 * I + 1), Vertex_Id (2 * I + 2));
         Add_Edge (G, Vertex_Id (2 * I + 2), Vertex_Id (2 * I + 1));
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 5, "five 2-cycles → 5 SCCs");
      for I in 0 .. 4 loop
         Check
           (Same_SCC
              (Comp, Vertex_Id (2 * I + 1), Vertex_Id (2 * I + 2)),
            "pair cycle" & Integer'Image (I));
      end loop;
      Check (not Same_SCC (Comp, 1, 3), "cross pair 1≠3");
      Check (not Same_SCC (Comp, 2, 10), "cross pair 2≠10");

      --  One big cycle of 20
      Clear (G, 20);
      for I in Vertex_Id range 1 .. 19 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Add_Edge (G, 20, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "20-cycle → 1 SCC");
      Check (Same_SCC (Comp, 1, 20), "20-cycle ends");
      Check (Same_SCC (Comp, 7, 15), "20-cycle middle");

      --  Tournament-like: i→j for i<j plus back edge 10→1 ⇒ one SCC?
      Clear (G, 10);
      for I in Vertex_Id range 1 .. 10 loop
         for J in Vertex_Id range 1 .. 10 loop
            if I < J then
               Add_Edge (G, I, J);
            end if;
         end loop;
      end loop;
      Add_Edge (G, 10, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "transitive + return → 1 SCC");

      --  Path with back edges creating nested SCCs:
      --  1→2→3→4→5, 3→1, 5→4  ⇒ {1,2,3}, {4,5}
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 5, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "nested back-edges → 2 SCCs");
      Check (Same_SCC (Comp, 1, 2) and then Same_SCC (Comp, 2, 3),
             "nested {1,2,3}");
      Check (Same_SCC (Comp, 4, 5), "nested {4,5}");
      Check (not Same_SCC (Comp, 3, 4), "nested split at 3|4");

      --  Count components equals N for edgeless N=50
      Clear (G, 50);
      Compute_SCC (G, Comp, Count);
      Check (Count = 50, "50 isolated → 50 SCCs");
      M := 0;
      for V in Vertex_Id range 1 .. 50 loop
         if Comp (V) /= 0 then
            M := M + 1;
         end if;
      end loop;
      Check (M = 50, "50 isolated all labeled");
   end Test_Larger;

   -------------------------------------------------------------------------
   -- 11. Clear resets edges; Vertex_Count / Edge_Count
   -------------------------------------------------------------------------

   procedure Test_Clear_Reset is
      G     : Graph;
      Comp  : Component_Array (1 .. 5);
      Count : Natural;
   begin
      Section ("11. Clear resets / API counters");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Check (Vertex_Count (G) = 4, "VC=4");
      Check (Edge_Count (G) = 2, "EC=2");
      Clear (G, 4);
      Check (Edge_Count (G) = 0, "Clear wipes edges");
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "after Clear, 4 singletons");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Clear (G, 3);
      Check (Vertex_Count (G) = 3, "Clear resize VC=3");
      Check (Edge_Count (G) = 0, "Clear resize EC=0");
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "resized empty → 3");
   end Test_Clear_Reset;

   -------------------------------------------------------------------------
   -- 12. Systematic small graphs enumeration-style checks
   -------------------------------------------------------------------------

   procedure Test_Systematic is
      G     : Graph;
      Comp  : Component_Array (1 .. 6);
      Count : Natural;
   begin
      Section ("12. Systematic small cases");

      --  n=2: no edges
      Clear (G, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "n2 none → 2");

      --  n=2: only 1→2
      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "n2 forward → 2");
      Check (not Same_SCC (Comp, 1, 2), "n2 forward distinct");

      --  n=2: only 2→1
      Clear (G, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "n2 backward → 2");

      --  n=2: both ways
      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "n2 both → 1");

      --  n=3: cycle both orientations
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "n3 CW cycle → 1");

      Clear (G, 3);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 3, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "n3 CCW cycle → 1");

      --  n=3: path 1→2→3 plus 3→2 ⇒ {1},{2,3}
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "path+back → 2");
      Check (not Same_SCC (Comp, 1, 2), "1 alone");
      Check (Same_SCC (Comp, 2, 3), "{2,3}");

      --  n=4: two independent mutual pairs + cross edge
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Add_Edge (G, 2, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "pairs + bridge → 2");
      Check (Same_SCC (Comp, 1, 2), "left pair");
      Check (Same_SCC (Comp, 3, 4), "right pair");
      Check (Comp (1) > Comp (3), "left finished after right");

      --  Bidirectional complete on 5
      Clear (G, 5);
      for I in Vertex_Id range 1 .. 5 loop
         for J in Vertex_Id range 1 .. 5 loop
            if I /= J then
               Add_Edge (G, I, J);
            end if;
         end loop;
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "K5 digraph → 1");
      for I in Vertex_Id range 1 .. 5 loop
         Check (Same_SCC (Comp, 1, I), "K5 with 1 and" & Vertex_Id'Image (I));
      end loop;
   end Test_Systematic;

   -------------------------------------------------------------------------
   -- 13. Component id range / coverage
   -------------------------------------------------------------------------

   procedure Test_Ids is
      G     : Graph;
      Comp  : Component_Array (1 .. 15);
      Count : Natural;
      Seen  : array (1 .. 15) of Boolean;
      Ok    : Boolean;
   begin
      Section ("13. Component id range 1 .. Count");

      Clear (G, 7);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 3);
      --  6,7 isolated
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "mixed → 4 SCCs");
      Seen := [others => False];
      Ok := True;
      for V in Vertex_Id range 1 .. 7 loop
         if Natural (Comp (V)) < 1 or else Natural (Comp (V)) > Count then
            Ok := False;
         else
            Seen (Natural (Comp (V))) := True;
         end if;
      end loop;
      Check (Ok, "all ids in 1 .. Count");
      for C in 1 .. Count loop
         Check (Seen (C), "id used:" & Integer'Image (C));
      end loop;

      Check (Same_SCC (Comp, 1, 2), "ids {1,2}");
      Check (Same_SCC (Comp, 3, 5), "ids {3,4,5}");
      Check (not Same_SCC (Comp, 6, 7), "ids 6≠7");
      Check (Comp (6) /= Comp (7), "isolated distinct ids");
   end Test_Ids;

begin
   Put_Line ("Tarjans_SCC test suite");
   Put_Line ("======================");

   Test_Trivial;
   Test_Chains;
   Test_Cycles;
   Test_Classic;
   Test_Complete;
   Test_Disconnected;
   Test_Condensation_Order;
   Test_Multiedges;
   Test_Invalid;
   Test_Larger;
   Test_Clear_Reset;
   Test_Systematic;
   Test_Ids;

   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
