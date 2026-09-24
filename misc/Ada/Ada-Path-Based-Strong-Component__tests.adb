--  Standalone test suite for Path_Based_Strong_Component (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Path_Based_Strong_Component; use Path_Based_Strong_Component;

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

   function All_Labeled (Comp : Component_Array; N : Natural) return Boolean is
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Comp (V) = 0 then
            return False;
         end if;
      end loop;
      return True;
   end All_Labeled;

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
      Check (All_Labeled (Comp, 3), "3 isolated all labeled");
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

      Clear (G, 4);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "star in → 4 SCCs");
      Check (All_Singleton (Comp, 4), "star in singletons");
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

      --  1→2→3→1, 3→4→5→4, 5→6→7→8→6
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

      --  Wikipedia intuition: a→b→c→a, b→d, d→e→d
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
      Check (Comp (4) < Comp (1), "wiki pair finished before triangle");
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

      --  A={1,2} → B={3}: finishes B before A, so Id_B < Id_A
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
      pragma Unreferenced (Count);
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

      Clear (G, 20);
      for I in Vertex_Id range 1 .. 19 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Add_Edge (G, 20, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "20-cycle → 1 SCC");
      Check (Same_SCC (Comp, 1, 20), "20-cycle ends");
      Check (Same_SCC (Comp, 7, 15), "20-cycle middle");

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
   -- 12. Systematic small graphs
   -------------------------------------------------------------------------

   procedure Test_Systematic is
      G     : Graph;
      Comp  : Component_Array (1 .. 6);
      Count : Natural;
   begin
      Section ("12. Systematic small cases");

      Clear (G, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "n2 none → 2");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "n2 forward → 2");
      Check (not Same_SCC (Comp, 1, 2), "n2 forward distinct");

      Clear (G, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "n2 backward → 2");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "n2 both → 1");

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

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "path+back → 2");
      Check (not Same_SCC (Comp, 1, 2), "1 alone");
      Check (Same_SCC (Comp, 2, 3), "{2,3}");

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

   -------------------------------------------------------------------------
   -- 14. Cross / forward / back edges (Gabow P-stack contraction)
   -------------------------------------------------------------------------

   procedure Test_Path_Contraction is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("14. Cross / forward / back (P-stack contraction)");

      --  Diamond DAG 1→2→4, 1→3→4: all singletons; cross/forward must
      --  not merge (target already assigned).
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "diamond DAG → 4 SCCs");
      Check (All_Singleton (Comp, 4), "diamond DAG singletons");

      --  Same diamond plus 4→1: one SCC (all mutually reachable).
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "diamond + return → 1 SCC");
      Check (Same_SCC (Comp, 2, 3), "diamond branches merge");

      --  Forward edge over a 3-cycle: 1→2→3→1 and 1→3. Still one SCC.
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "cycle + forward → 1 SCC");
      Check (Block_Is_SCC (Comp, 3, 1, 3), "cycle+forward one block");

      --  Cross edge 3→2 in tree 1→2, 1→3 with 2 unassigned? After 2
      --  finishes it is assigned; 3→2 is into a completed SCC.
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 3, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "tree + cross to finished → 3");
      Check (All_Singleton (Comp, 3), "tree+cross singletons");

      --  Back edge from a side branch into an ancestor: 1→2→3, 1→4→2
      --  does not create a cycle through 1 unless 2 can reach 1.
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 1, 4);
      Add_Edge (G, 4, 2);
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "side branch into descendant → 4");
      Check (All_Singleton (Comp, 4), "no return path, all singletons");

      --  Side branch back to ancestor: 1→2→3, 1→4, 4→1 ⇒ {1,4},{2},{3}
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 1, 4);
      Add_Edge (G, 4, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "side back to root → 3 SCCs");
      Check (Same_SCC (Comp, 1, 4), "root pair {1,4}");
      Check (not Same_SCC (Comp, 1, 2), "chain stays split");
      Check (not Same_SCC (Comp, 2, 3), "2 ≠ 3");
   end Test_Path_Contraction;

   -------------------------------------------------------------------------
   -- 15. Nested / hierarchical SCCs and figure-8
   -------------------------------------------------------------------------

   procedure Test_Nested is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("15. Nested / hierarchical SCCs");

      --  Figure-8: cycles 1→2→1 and 1→3→1 share vertex 1 ⇒ one SCC.
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 3, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "figure-8 → 1 SCC");
      Check (Same_SCC (Comp, 2, 3), "figure-8 2 and 3 via 1");

      --  Two triangles sharing a vertex.
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "two triangles sharing vertex → 1");
      Check (Same_SCC (Comp, 2, 4), "triangles merge");

      --  Barbell: K3 on {1,2,3} —bridge→ K3 on {4,5,6}.
      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 4);
      Add_Edge (G, 3, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "barbell → 2 SCCs");
      Check (Same_SCC (Comp, 1, 3), "barbell left K3");
      Check (Same_SCC (Comp, 4, 6), "barbell right K3");
      Check (not Same_SCC (Comp, 3, 4), "barbell bridge does not merge");
      Check (Comp (4) < Comp (1), "barbell right finished first");

      --  Chain of three 2-cycles with bridges: {1,2}→{3,4}→{5,6}
      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 3);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 5);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 4, 5);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "three linked pairs → 3");
      Check (Same_SCC (Comp, 1, 2), "chain pair A");
      Check (Same_SCC (Comp, 3, 4), "chain pair B");
      Check (Same_SCC (Comp, 5, 6), "chain pair C");
      Check (Comp (5) < Comp (3) and then Comp (3) < Comp (1),
             "linked pairs reverse topo");
   end Test_Nested;

   -------------------------------------------------------------------------
   -- 16. DFS forest / multiple roots
   -------------------------------------------------------------------------

   procedure Test_Forest is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("16. DFS forest / multiple roots");

      --  Later vertices form a cycle; earlier are isolated. DFS starts at 1.
      Clear (G, 5);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "forest isolates + pair → 4");
      Check (Same_SCC (Comp, 4, 5), "forest pair {4,5}");
      Check (not Same_SCC (Comp, 1, 2), "forest 1≠2");
      Check (not Same_SCC (Comp, 1, 4), "forest 1≠4");

      --  Two disjoint cycles discovered as separate DFS trees.
      Clear (G, 6);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 4);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "two DFS-tree cycles → 2");
      Check (Same_SCC (Comp, 1, 3), "forest cycle A");
      Check (Same_SCC (Comp, 4, 6), "forest cycle B");
      Check (not Same_SCC (Comp, 3, 4), "forest cycles distinct");

      --  Reverse-id discovery: edges only among high vertices, then low cycle.
      Clear (G, 6);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 4, "low pair + high pair + isolates → 4");
      Check (Same_SCC (Comp, 1, 2), "low pair");
      Check (Same_SCC (Comp, 5, 6), "high pair");
      Check (not Same_SCC (Comp, 1, 5), "pairs in distinct trees");
   end Test_Forest;

   -------------------------------------------------------------------------
   -- 17. k-cycle sweep and bidirectional path
   -------------------------------------------------------------------------

   procedure Test_K_Cycles is
      G     : Graph;
      Comp  : Component_Array (1 .. 16);
      Count : Natural;
   begin
      Section ("17. k-cycles / bidirectional path");

      for N in Vertex_Id range 2 .. 12 loop
         Clear (G, Natural (N));
         for I in Vertex_Id range 1 .. N - 1 loop
            Add_Edge (G, I, I + 1);
         end loop;
         Add_Edge (G, N, 1);
         Compute_SCC (G, Comp, Count);
         Check (Count = 1, "k-cycle" & Vertex_Id'Image (N) & " → 1");
      end loop;

      --  Bidirectional path of 6: every consecutive pair is mutual, so
      --  the whole path is one SCC.
      Clear (G, 6);
      for I in Vertex_Id range 1 .. 5 loop
         Add_Edge (G, I, I + 1);
         Add_Edge (G, I + 1, I);
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "bidirectional path → 1 SCC");
      Check (Same_SCC (Comp, 1, 6), "bidir ends");

      --  One missing return edge splits the path: 1↔2↔3→4↔5↔6
      Clear (G, 6);
      for I in Vertex_Id range 1 .. 5 loop
         Add_Edge (G, I, I + 1);
         if I /= 3 then
            Add_Edge (G, I + 1, I);
         end if;
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "bidir path gap → 2");
      Check (Same_SCC (Comp, 1, 3), "left of gap");
      Check (Same_SCC (Comp, 4, 6), "right of gap");
      Check (not Same_SCC (Comp, 3, 4), "gap splits");
   end Test_K_Cycles;

   -------------------------------------------------------------------------
   -- 18. Source / sink around a cycle; wheel; tournament
   -------------------------------------------------------------------------

   procedure Test_Source_Sink is
      G     : Graph;
      Comp  : Component_Array (1 .. 20);
      Count : Natural;
   begin
      Section ("18. Source-cycle-sink / wheel / tournament");

      --  1 → {2,3,4 cycle} → 5
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 2);
      Add_Edge (G, 4, 5);
      Compute_SCC (G, Comp, Count);
      Check (Count = 3, "source-cycle-sink → 3");
      Check (not Same_SCC (Comp, 1, 2), "source alone");
      Check (Same_SCC (Comp, 2, 4), "middle cycle");
      Check (not Same_SCC (Comp, 4, 5), "sink alone");
      Check (Comp (5) < Comp (2) and then Comp (2) < Comp (1),
             "source-cycle-sink reverse topo");

      --  In-wheel: hub 1, rim 2-5 cycle, each rim → hub. Rim cycle is
      --  one SCC; hub is reachable from the rim but cannot return ⇒ 2 SCCs.
      Clear (G, 5);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 2);
      for I in Vertex_Id range 2 .. 5 loop
         Add_Edge (G, I, 1);
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "in-wheel → 2 SCCs");
      Check (Same_SCC (Comp, 2, 5), "in-wheel rim");
      Check (not Same_SCC (Comp, 1, 2), "hub not in rim");

      --  Out-wheel: hub → each rim, rim cycle. Hub can reach rim but
      --  rim cannot reach hub ⇒ 2 SCCs.
      Clear (G, 5);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 2);
      for I in Vertex_Id range 2 .. 5 loop
         Add_Edge (G, 1, I);
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "out-wheel → 2 SCCs");
      Check (Same_SCC (Comp, 2, 5), "out-wheel rim");
      Check (not Same_SCC (Comp, 1, 3), "out-hub distinct");

      --  Two-way wheel: hub ↔ every rim + rim cycle ⇒ one SCC.
      Clear (G, 5);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 2);
      for I in Vertex_Id range 2 .. 5 loop
         Add_Edge (G, 1, I);
         Add_Edge (G, I, 1);
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "two-way wheel → 1 SCC");
      Check (Same_SCC (Comp, 1, 4), "two-way hub in rim");
   end Test_Source_Sink;

   -------------------------------------------------------------------------
   -- 19. Oversized Component_Of, Same_SCC zeros, Max_Vertices isolates
   -------------------------------------------------------------------------

   procedure Test_Bounds_And_Capacity is
      G     : Graph;
      Comp  : Component_Array (1 .. 200);
      Big   : Component_Array (1 .. Vertex_Id'Last);
      Count : Natural;
      Zeros : Component_Array (1 .. 4);
   begin
      Section ("19. Bounds, Same_SCC zeros, capacity");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "oversized array still 2 SCCs");
      Check (Same_SCC (Comp, 1, 2), "oversized {1,2}");
      Check (Comp (4) = 0, "slot beyond N stays 0");
      Check (not Same_SCC (Comp, 1, 4), "Same_SCC with zero is false");
      Check (not Same_SCC (Comp, 4, 5), "two zeros not Same_SCC");

      Zeros := [others => 0];
      Check (not Same_SCC (Zeros, 1, 1), "unset array 1,1 is false");

      Clear (G, 200);
      Compute_SCC (G, Comp, Count);
      Check (Count = 200, "200 isolated → 200 SCCs");
      Check (All_Singleton (Comp, 200), "200 isolated singletons");

      Clear (G, Max_Vertices);
      Compute_SCC (G, Big, Count);
      Check (Count = Max_Vertices, "Max_Vertices isolates → N SCCs");
      Check (Big (1) /= 0 and then Big (Vertex_Id (Max_Vertices)) /= 0,
             "max isolates endpoints labeled");
   end Test_Bounds_And_Capacity;

   -------------------------------------------------------------------------
   -- 20. Mixed dense / sparse patterns
   -------------------------------------------------------------------------

   procedure Test_Mixed is
      G     : Graph;
      Comp  : Component_Array (1 .. 30);
      Count : Natural;
      Ok    : Boolean;
   begin
      Section ("20. Mixed dense / sparse patterns");

      --  Complete bipartite one-way A={1,2,3} → B={4,5}: all singletons.
      Clear (G, 5);
      for I in Vertex_Id range 1 .. 3 loop
         for J in Vertex_Id range 4 .. 5 loop
            Add_Edge (G, I, J);
         end loop;
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 5, "one-way bipartite → 5");
      Check (All_Singleton (Comp, 5), "one-way bipartite singletons");

      --  Both directions: two partitions become two SCCs? No: from A you
      --  reach B and back to every vertex of A, so it is one SCC.
      Clear (G, 5);
      for I in Vertex_Id range 1 .. 3 loop
         for J in Vertex_Id range 4 .. 5 loop
            Add_Edge (G, I, J);
            Add_Edge (G, J, I);
         end loop;
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "two-way bipartite → 1 SCC");
      Check (Same_SCC (Comp, 1, 5), "bipartite ends");

      --  8-vertex: cycle 1-4, cycle 5-8, edges 4→5 and 8→3 (merges all).
      Clear (G, 8);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 7);
      Add_Edge (G, 7, 8);
      Add_Edge (G, 8, 5);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 8, 3);
      Compute_SCC (G, Comp, Count);
      Check (Count = 1, "two cycles + cross returns → 1");
      Check (Same_SCC (Comp, 1, 8), "merged cycles 1 and 8");

      --  Same without 8→3: two SCCs.
      Clear (G, 8);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Add_Edge (G, 5, 6);
      Add_Edge (G, 6, 7);
      Add_Edge (G, 7, 8);
      Add_Edge (G, 8, 5);
      Add_Edge (G, 4, 5);
      Compute_SCC (G, Comp, Count);
      Check (Count = 2, "two cycles + one bridge → 2");
      Check (Same_SCC (Comp, 1, 4), "left cycle");
      Check (Same_SCC (Comp, 5, 8), "right cycle");
      Check (not Same_SCC (Comp, 4, 5), "bridge does not merge");

      --  Self-loop on every vertex of a chain: still singletons.
      Clear (G, 7);
      for I in Vertex_Id range 1 .. 7 loop
         Add_Edge (G, I, I);
      end loop;
      for I in Vertex_Id range 1 .. 6 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Compute_SCC (G, Comp, Count);
      Check (Count = 7, "looped chain → 7 SCCs");
      Check (All_Singleton (Comp, 7), "looped chain singletons");

      --  Component_Of Last = N exactly (tight bounds).
      declare
         Tight : Component_Array (1 .. 4);
      begin
         Clear (G, 4);
         Add_Edge (G, 1, 2);
         Add_Edge (G, 2, 1);
         Add_Edge (G, 3, 4);
         Add_Edge (G, 4, 3);
         Compute_SCC (G, Tight, Count);
         Check (Count = 2, "tight array two pairs → 2");
         Check (Same_SCC (Tight, 1, 2), "tight left");
         Check (Same_SCC (Tight, 3, 4), "tight right");
      end;

      --  Repeated Compute_SCC is deterministic on the same graph.
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 4);
      declare
         Comp2 : Component_Array (1 .. 5);
         C2    : Natural;
      begin
         Compute_SCC (G, Comp, Count);
         Compute_SCC (G, Comp2, C2);
         Check (Count = C2, "repeat Compute_SCC same count");
         Ok := True;
         for V in Vertex_Id range 1 .. 5 loop
            if Comp (V) /= Comp2 (V) then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "repeat Compute_SCC same labelling");
      end;
   end Test_Mixed;

begin
   Put_Line ("Path_Based_Strong_Component test suite");
   Put_Line ("======================================");

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
   Test_Path_Contraction;
   Test_Nested;
   Test_Forest;
   Test_K_Cycles;
   Test_Source_Sink;
   Test_Bounds_And_Capacity;
   Test_Mixed;

   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
