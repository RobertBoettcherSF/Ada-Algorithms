--  Standalone test suite for Lexicographic_Breadth_First_Search (main).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Lexicographic_Breadth_First_Search; use Lexicographic_Breadth_First_Search;

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

   function Is_Permutation (Order : Order_Array; N : Natural) return Boolean is
      Seen : array (1 .. Max_Vertices) of Boolean := [others => False];
      V    : Vertex_Id;
   begin
      if N = 0 then
         return True;
      end if;
      for I in 1 .. N loop
         V := Order (Vertex_Id (I));
         if Natural (V) > N or else Seen (Natural (V)) then
            return False;
         end if;
         Seen (Natural (V)) := True;
      end loop;
      return True;
   end Is_Permutation;

   function Reverse_Order (Order : Order_Array; N : Natural) return Order_Array is
      R : Order_Array (1 .. Vertex_Id (N));
   begin
      for I in 1 .. N loop
         R (Vertex_Id (I)) := Order (Vertex_Id (N - I + 1));
      end loop;
      return R;
   end Reverse_Order;

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
     (G : in out Graph; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Lex_Raises_Start
     (G : Graph; Start : Vertex_Id; Last : Vertex_Id) return Boolean
   is
      Order : Order_Array (1 .. Last);
   begin
      Lex_BFS (G, Start, Order);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Lex_Raises_Start;

   function Lex_Raises_Bounds
     (G : Graph; First, Last : Vertex_Id) return Boolean
   is
      Order : Order_Array (First .. Last);
   begin
      Lex_BFS (G, Order);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Lex_Raises_Bounds;

   function Adj_Raises (G : Graph; U, V : Vertex_Id) return Boolean is
   begin
      if Is_Adjacent (G, U, V) then
         return False;
      end if;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Adj_Raises;

   function PEO_Raises
     (G : Graph; First, Last : Vertex_Id) return Boolean
   is
      Order : constant Order_Array (First .. Last) := [others => 1];
   begin
      if Is_PEO (G, Order) then
         return False;
      end if;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end PEO_Raises;

   -------------------------------------------------------------------------
   -- 1. Empty / single / trivial
   -------------------------------------------------------------------------

   procedure Test_Trivial is
      G     : Graph;
      Order : Order_Array (1 .. 10);
   begin
      Section ("1. Empty / single / no edges");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "empty Vertex_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Lex_BFS (G, Order);
      Check (True, "empty Lex_BFS (no start) accepts");

      Check (Lex_Raises_Start (G, 1, 10), "empty Lex_BFS with Start raises");

      Clear (G, 1);
      Check (Vertex_Count (G) = 1, "single Vertex_Count = 1");
      Check (Edge_Count (G) = 0, "single Edge_Count = 0");
      Lex_BFS (G, Order);
      Check (Order (1) = 1, "single default order starts at 1");
      Check (Is_Permutation (Order, 1), "single is permutation");
      Check (Is_PEO (G, Order), "single is PEO");
      Check (Is_PEO (G, Reverse_Order (Order, 1)), "single reverse is PEO");

      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "single Start=1");

      Clear (G, 5);
      Check (Vertex_Count (G) = 5, "five isolates N=5");
      Check (Edge_Count (G) = 0, "five isolates E=0");
      Lex_BFS (G, Order);
      Check (Order (1) = 1, "isolates default start 1");
      Check (Is_Permutation (Order, 5), "isolates permutation");
      Check (Is_PEO (G, Reverse_Order (Order, 5)), "isolates reverse PEO");

      Lex_BFS (G, 3, Order);
      Check (Order (1) = 3, "isolates Start=3 first");
      Check (Is_Permutation (Order, 5), "isolates Start=3 permutation");
   end Test_Trivial;

   -------------------------------------------------------------------------
   -- 2. Paths
   -------------------------------------------------------------------------

   procedure Test_Paths is
      G     : Graph;
      Order : Order_Array (1 .. 20);
   begin
      Section ("2. Paths");

      --  P2: 1—2
      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Check (Edge_Count (G) = 1, "P2 edge count");
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1 and then Order (2) = 2, "P2 from 1 → 1,2");
      Lex_BFS (G, 2, Order);
      Check (Order (1) = 2 and then Order (2) = 1, "P2 from 2 → 2,1");
      Check (Is_PEO (G, Reverse_Order (Order, 2)), "P2 reverse PEO");

      --  P3: 1—2—3
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "P3 from 1 starts 1");
      Check (Order (2) = 2, "P3 from 1 second 2");
      Check (Order (3) = 3, "P3 from 1 third 3");
      Check (Is_Adjacent (G, 1, 2), "P3 adj 1-2");
      Check (Is_Adjacent (G, 2, 3), "P3 adj 2-3");
      Check (not Is_Adjacent (G, 1, 3), "P3 not adj 1-3");
      Check (Is_PEO (G, Reverse_Order (Order, 3)), "P3 reverse PEO (path chordal)");

      Lex_BFS (G, 2, Order);
      Check (Order (1) = 2, "P3 from 2 starts 2");
      Check (Is_Permutation (Order, 3), "P3 from 2 permutation");
      --  From middle: {1,3} tied after 2; either order OK for Lex-BFS
      Check (Order (2) = 1 or else Order (2) = 3, "P3 from 2 second is leaf");

      --  P5
      Clear (G, 5);
      for I in Vertex_Id range 1 .. 4 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "P5 from 1 starts 1");
      Check (Order (2) = 2, "P5 from 1 then 2");
      Check (Order (3) = 3, "P5 from 1 then 3");
      Check (Order (4) = 4, "P5 from 1 then 4");
      Check (Order (5) = 5, "P5 from 1 then 5");
      Check (Is_PEO (G, Reverse_Order (Order, 5)), "P5 reverse PEO");

      Lex_BFS (G, Order);
      Check (Order (1) = 1, "P5 default start 1");

      --  P10
      Clear (G, 10);
      for I in Vertex_Id range 1 .. 9 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Lex_BFS (G, 1, Order);
      Check (Is_Permutation (Order, 10), "P10 permutation");
      declare
         Ok : Boolean := True;
      begin
         for I in 1 .. 10 loop
            if Order (Vertex_Id (I)) /= Vertex_Id (I) then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "P10 from 1 is 1..10");
      end;
      Check (Is_PEO (G, Reverse_Order (Order, 10)), "P10 reverse PEO");
   end Test_Paths;

   -------------------------------------------------------------------------
   -- 3. Cycles
   -------------------------------------------------------------------------

   procedure Test_Cycles is
      G     : Graph;
      Order : Order_Array (1 .. 20);
      Rev   : Order_Array (1 .. 20);
   begin
      Section ("3. Cycles");

      --  C3 = K3 (chordal)
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "C3 starts at 1");
      Check (Is_Permutation (Order, 3), "C3 permutation");
      Rev (1 .. 3) := Reverse_Order (Order, 3);
      Check (Is_PEO (G, Rev (1 .. 3)), "C3 reverse is PEO");

      --  C4 (not chordal)
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "C4 starts at 1");
      Check (Is_Permutation (Order, 4), "C4 permutation");
      --  After 1, vertices 2 and 4 are tied; then 3.
      Check (Order (2) = 2 or else Order (2) = 4, "C4 second neighbour of 1");
      Check (Order (4) = 3 or else Order (3) = 3, "C4 contains 3");
      Rev (1 .. 4) := Reverse_Order (Order, 4);
      Check (not Is_PEO (G, Rev (1 .. 4)), "C4 reverse is not PEO");

      --  C5 (not chordal)
      Clear (G, 5);
      for I in Vertex_Id range 1 .. 4 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Add_Edge (G, 5, 1);
      Lex_BFS (G, 1, Order);
      Check (Is_Permutation (Order, 5), "C5 permutation");
      Rev (1 .. 5) := Reverse_Order (Order, 5);
      Check (not Is_PEO (G, Rev (1 .. 5)), "C5 reverse is not PEO");

      --  C6
      Clear (G, 6);
      for I in Vertex_Id range 1 .. 5 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Add_Edge (G, 6, 1);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "C6 start");
      Check (Is_Permutation (Order, 6), "C6 permutation");
      Rev (1 .. 6) := Reverse_Order (Order, 6);
      Check (not Is_PEO (G, Rev (1 .. 6)), "C6 reverse not PEO");
   end Test_Cycles;

   -------------------------------------------------------------------------
   -- 4. Complete graphs (chordal)
   -------------------------------------------------------------------------

   procedure Test_Complete is
      G     : Graph;
      Order : Order_Array (1 .. 20);
      Rev   : Order_Array (1 .. 20);
   begin
      Section ("4. Complete graphs");

      for N in 2 .. 8 loop
         Clear (G, N);
         for I in Vertex_Id range 1 .. Vertex_Id (N) loop
            for J in Vertex_Id range I + 1 .. Vertex_Id (N) loop
               Add_Edge (G, I, J);
            end loop;
         end loop;
         Check
           (Edge_Count (G) = N * (N - 1) / 2,
            "K" & Integer'Image (N) & " edge count");
         Lex_BFS (G, 1, Order);
         Check (Order (1) = 1, "K" & Integer'Image (N) & " start 1");
         Check
           (Is_Permutation (Order, N),
            "K" & Integer'Image (N) & " permutation");
         Rev (1 .. Vertex_Id (N)) := Reverse_Order (Order, N);
         Check
           (Is_PEO (G, Rev (1 .. Vertex_Id (N))),
            "K" & Integer'Image (N) & " reverse PEO");
      end loop;

      Clear (G, 4);
      for I in Vertex_Id range 1 .. 4 loop
         for J in Vertex_Id range I + 1 .. 4 loop
            Add_Edge (G, I, J);
         end loop;
      end loop;
      Lex_BFS (G, 3, Order);
      Check (Order (1) = 3, "K4 Start=3");
      Check (Is_Permutation (Order, 4), "K4 Start=3 permutation");
   end Test_Complete;

   -------------------------------------------------------------------------
   -- 5. Trees / stars (chordal)
   -------------------------------------------------------------------------

   procedure Test_Trees is
      G     : Graph;
      Order : Order_Array (1 .. 20);
      Rev   : Order_Array (1 .. 20);
   begin
      Section ("5. Trees and stars");

      --  Star K1,4: centre 1, leaves 2..5
      Clear (G, 5);
      for L in Vertex_Id range 2 .. 5 loop
         Add_Edge (G, 1, L);
      end loop;
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "star from centre starts 1");
      Check (Is_Permutation (Order, 5), "star permutation");
      Rev (1 .. 5) := Reverse_Order (Order, 5);
      Check (Is_PEO (G, Rev (1 .. 5)), "star reverse PEO");

      Lex_BFS (G, 5, Order);
      Check (Order (1) = 5, "star from leaf starts 5");
      Check (Order (2) = 1, "star from leaf then centre");
      Rev (1 .. 5) := Reverse_Order (Order, 5);
      Check (Is_PEO (G, Rev (1 .. 5)), "star from leaf reverse PEO");

      --  Binary-ish tree
      Clear (G, 7);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 2, 5);
      Add_Edge (G, 3, 6);
      Add_Edge (G, 3, 7);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "tree root first");
      Check (Is_Permutation (Order, 7), "tree permutation");
      Rev (1 .. 7) := Reverse_Order (Order, 7);
      Check (Is_PEO (G, Rev (1 .. 7)), "tree reverse PEO");
   end Test_Trees;

   -------------------------------------------------------------------------
   -- 6. Chordal examples / PEO
   -------------------------------------------------------------------------

   procedure Test_Chordal is
      G     : Graph;
      Order : Order_Array (1 .. 20);
      Rev   : Order_Array (1 .. 20);
      Bad   : Order_Array (1 .. 4);
   begin
      Section ("6. Chordal graphs and PEO");

      --  Diamond: K4 minus one edge (chordal)
      --  Vertices 1,2,3,4; edges all except 1—4
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Lex_BFS (G, 1, Order);
      Check (Is_Permutation (Order, 4), "diamond permutation");
      Rev (1 .. 4) := Reverse_Order (Order, 4);
      Check (Is_PEO (G, Rev (1 .. 4)), "diamond reverse PEO");

      --  Known PEO for diamond: e.g. 1,4,2,3 (eliminate 1 then 4)
      Bad := [1, 4, 2, 3];
      Check (Is_PEO (G, Bad), "diamond explicit PEO 1,4,2,3");

      --  Two triangles sharing an edge (chordal)
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Lex_BFS (G, 1, Order);
      Rev (1 .. 4) := Reverse_Order (Order, 4);
      Check (Is_PEO (G, Rev (1 .. 4)), "two triangles reverse PEO");

      --  Chordal: path with one chord making triangle + pendant
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 2, 4);  -- chord; still a tree? no — C3 with pendant 1
      Lex_BFS (G, 1, Order);
      Rev (1 .. 4) := Reverse_Order (Order, 4);
      Check (Is_PEO (G, Rev (1 .. 4)), "triangle+pendant reverse PEO");

      --  Non-PEO on C4
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1);
      Bad := [1, 2, 3, 4];
      Check (not Is_PEO (G, Bad), "C4 natural order not PEO");
      Bad := [1, 3, 2, 4];
      Check (not Is_PEO (G, Bad), "C4 crossing order not PEO");
   end Test_Chordal;

   -------------------------------------------------------------------------
   -- 7. Disconnected graphs
   -------------------------------------------------------------------------

   procedure Test_Disconnected is
      G     : Graph;
      Order : Order_Array (1 .. 20);
      Rev   : Order_Array (1 .. 20);
      Pos   : array (Vertex_Id) of Natural := [others => 0];
   begin
      Section ("7. Disconnected graphs");

      --  Two edges: 1—2 and 3—4
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 3, 4);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "two edges start 1");
      Check (Order (2) = 2, "two edges then 2");
      Check (Is_Permutation (Order, 4), "two edges permutation");
      Rev (1 .. 4) := Reverse_Order (Order, 4);
      Check (Is_PEO (G, Rev (1 .. 4)), "two edges reverse PEO");

      Lex_BFS (G, 3, Order);
      Check (Order (1) = 3, "two edges Start=3");
      Check (Order (2) = 4, "two edges then 4");

      --  Three components: edge + isolate + edge
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 4, 5);
      --  3 isolated
      Lex_BFS (G, 1, Order);
      Check (Is_Permutation (Order, 5), "3-comp permutation");
      for I in 1 .. 5 loop
         Pos (Order (Vertex_Id (I))) := I;
      end loop;
      Check (Pos (1) < Pos (2), "comp: 1 before 2");
      Rev (1 .. 5) := Reverse_Order (Order, 5);
      Check (Is_PEO (G, Rev (1 .. 5)), "3-comp reverse PEO");

      --  Two complete components K3 + K2
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5);
      Lex_BFS (G, 4, Order);
      Check (Order (1) = 4, "K3+K2 start 4");
      Check (Order (2) = 5, "K3+K2 then 5");
      Check (Is_Permutation (Order, 5), "K3+K2 permutation");
      Rev (1 .. 5) := Reverse_Order (Order, 5);
      Check (Is_PEO (G, Rev (1 .. 5)), "K3+K2 reverse PEO");
   end Test_Disconnected;

   -------------------------------------------------------------------------
   -- 8. API / duplicates / adjacency
   -------------------------------------------------------------------------

   procedure Test_API is
      G     : Graph;
      Order : Order_Array (1 .. 10);
   begin
      Section ("8. API counters, duplicates, adjacency");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);  -- duplicate
      Check (Edge_Count (G) = 1, "duplicate ignored");
      Add_Edge (G, 2, 1);  -- same undirected
      Check (Edge_Count (G) = 1, "reverse duplicate ignored");
      Add_Edge (G, 2, 2);  -- self-loop
      Check (Edge_Count (G) = 1, "self-loop ignored");
      Check (not Is_Adjacent (G, 2, 2), "not adjacent to self");
      Check (Is_Adjacent (G, 1, 2), "adj 1-2");
      Check (Is_Adjacent (G, 2, 1), "adj 2-1");
      Check (not Is_Adjacent (G, 1, 3), "not adj 1-3");

      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Check (Edge_Count (G) = 3, "three edges");
      Check (Vertex_Count (G) = 4, "N=4");

      Lex_BFS (G, Order);
      Check (Order (1) = 1, "default overload start 1");

      Clear (G, 3);
      Check (Edge_Count (G) = 0, "clear resets edges");
      Check (Vertex_Count (G) = 3, "clear sets N");
      Lex_BFS (G, 2, Order);
      Check (Order (1) = 2, "after clear Start=2");
   end Test_API;

   -------------------------------------------------------------------------
   -- 9. Invalid_Argument
   -------------------------------------------------------------------------

   procedure Test_Invalid is
      G   : Graph;
      Bad : Order_Array (1 .. 3);
   begin
      Section ("9. Invalid_Argument");

      Check (Clear_Raises (Nat (Max_Vertices) + 1), "Clear N too large");
      Clear (G, 3);
      Check (Add_Raises (G, 1, 4), "Add_Edge To out of range");
      Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");
      Check (Adj_Raises (G, 1, 4), "Is_Adjacent out of range");
      Check (Lex_Raises_Start (G, 4, 5), "Lex_BFS Start out of range");
      Check (Lex_Raises_Bounds (G, 2, 5), "Lex_BFS Order'First /= 1");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Check (Lex_Raises_Start (G, 1, 2), "Lex_BFS Order too short");

      Clear (G, 0);
      Check (Lex_Raises_Start (G, 1, 5), "Lex_BFS Start on empty");

      Clear (G, 3);
      Check (PEO_Raises (G, 2, 3), "Is_PEO First /= 1");

      --  Is_PEO non-permutation
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Bad := [1, 2, 2];
      declare
         Raised : Boolean := False;
      begin
         begin
            if Is_PEO (G, Bad) then
               null;
            end if;
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Is_PEO duplicate vertices raises");
      end;

      Clear (G, Max_Vertices);
      Check (Vertex_Count (G) = Max_Vertices, "Clear at Max_Vertices OK");
   end Test_Invalid;

   -------------------------------------------------------------------------
   -- 10. BFS-consistency / lex tie-breaking
   -------------------------------------------------------------------------

   procedure Test_Lex_Properties is
      G     : Graph;
      Order : Order_Array (1 .. 20);
      Pos   : array (Vertex_Id) of Natural := [others => 0];
   begin
      Section ("10. Lex-BFS properties");

      --  On a path, Lex-BFS from an endpoint is ordinary BFS order.
      Clear (G, 6);
      for I in Vertex_Id range 1 .. 5 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Lex_BFS (G, 1, Order);
      for I in 1 .. 6 loop
         Check
           (Order (Vertex_Id (I)) = Vertex_Id (I),
            "path BFS layer" & Integer'Image (I));
      end loop;

      --  Tie-break: house-like — 1 connected to 2 and 3; 2—4; 3—4; 4—5
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "house start 1");
      for I in 1 .. 5 loop
         Pos (Order (Vertex_Id (I))) := I;
      end loop;
      Check (Pos (2) < Pos (4), "2 before 4");
      Check (Pos (3) < Pos (4), "3 before 4");
      Check (Pos (4) < Pos (5), "4 before 5");
      Check (Is_Permutation (Order, 5), "house permutation");

      --  Complete bipartite K2,3 is not chordal (has C4)
      Clear (G, 5);
      --  Parts {1,2} and {3,4,5}
      for A in Vertex_Id range 1 .. 2 loop
         for B in Vertex_Id range 3 .. 5 loop
            Add_Edge (G, A, B);
         end loop;
      end loop;
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "K2,3 start");
      Check (Is_Permutation (Order, 5), "K2,3 permutation");
      declare
         Rev : constant Order_Array := Reverse_Order (Order, 5);
      begin
         Check (not Is_PEO (G, Rev), "K2,3 reverse not PEO");
      end;
   end Test_Lex_Properties;

   -------------------------------------------------------------------------
   -- 11. Larger patterns
   -------------------------------------------------------------------------

   procedure Test_Larger is
      G     : Graph;
      Order : Order_Array (1 .. 100);
      Rev   : Order_Array (1 .. 100);
   begin
      Section ("11. Larger patterns");

      --  Path of 50
      Clear (G, 50);
      for I in Vertex_Id range 1 .. 49 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Lex_BFS (G, 1, Order);
      Check (Is_Permutation (Order, 50), "P50 permutation");
      Check (Order (1) = 1 and then Order (50) = 50, "P50 ends");
      Rev (1 .. 50) := Reverse_Order (Order, 50);
      Check (Is_PEO (G, Rev (1 .. 50)), "P50 reverse PEO");

      --  Star with 30 leaves
      Clear (G, 31);
      for L in Vertex_Id range 2 .. 31 loop
         Add_Edge (G, 1, L);
      end loop;
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "star30 centre first");
      Check (Is_Permutation (Order, 31), "star30 permutation");
      Rev (1 .. 31) := Reverse_Order (Order, 31);
      Check (Is_PEO (G, Rev (1 .. 31)), "star30 reverse PEO");

      --  Cycle C20 — not chordal
      Clear (G, 20);
      for I in Vertex_Id range 1 .. 19 loop
         Add_Edge (G, I, I + 1);
      end loop;
      Add_Edge (G, 20, 1);
      Lex_BFS (G, 1, Order);
      Check (Is_Permutation (Order, 20), "C20 permutation");
      Rev (1 .. 20) := Reverse_Order (Order, 20);
      Check (not Is_PEO (G, Rev (1 .. 20)), "C20 reverse not PEO");

      --  K10
      Clear (G, 10);
      for I in Vertex_Id range 1 .. 10 loop
         for J in Vertex_Id range I + 1 .. 10 loop
            Add_Edge (G, I, J);
         end loop;
      end loop;
      Check (Edge_Count (G) = 45, "K10 edges=45");
      Lex_BFS (G, 5, Order);
      Check (Order (1) = 5, "K10 Start=5");
      Check (Is_Permutation (Order, 10), "K10 permutation");
      Rev (1 .. 10) := Reverse_Order (Order, 10);
      Check (Is_PEO (G, Rev (1 .. 10)), "K10 reverse PEO");

      --  40 isolates
      Clear (G, 40);
      Lex_BFS (G, 17, Order);
      Check (Order (1) = 17, "40 isolates Start=17");
      Check (Is_Permutation (Order, 40), "40 isolates permutation");
   end Test_Larger;

   -------------------------------------------------------------------------
   -- 12. Clear / reset reuse
   -------------------------------------------------------------------------

   procedure Test_Clear_Reset is
      G     : Graph;
      Order : Order_Array (1 .. 10);
   begin
      Section ("12. Clear / reset");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Lex_BFS (G, Order);
      Check (Is_Permutation (Order, 4), "before reset perm");

      Clear (G, 2);
      Check (Vertex_Count (G) = 2, "reset N=2");
      Check (Edge_Count (G) = 0, "reset E=0");
      Add_Edge (G, 1, 2);
      Lex_BFS (G, 2, Order);
      Check (Order (1) = 2 and then Order (2) = 1, "after reset order");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "reset to empty");
      Clear (G, 1);
      Lex_BFS (G, Order);
      Check (Order (1) = 1, "reuse after empty");
   end Test_Clear_Reset;

   -------------------------------------------------------------------------
   -- 13. Systematic small graphs
   -------------------------------------------------------------------------

   procedure Test_Systematic is
      G     : Graph;
      Order : Order_Array (1 .. 12);
      Rev   : Order_Array (1 .. 12);
   begin
      Section ("13. Systematic small graphs");

      --  Every start vertex on P4
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      for S in Vertex_Id range 1 .. 4 loop
         Lex_BFS (G, S, Order);
         Check (Order (1) = S, "P4 start" & Vertex_Id'Image (S));
         Check (Is_Permutation (Order, 4), "P4 perm from" & Vertex_Id'Image (S));
         Rev (1 .. 4) := Reverse_Order (Order, 4);
         Check (Is_PEO (G, Rev (1 .. 4)), "P4 PEO from" & Vertex_Id'Image (S));
      end loop;

      --  Every start on K3
      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      for S in Vertex_Id range 1 .. 3 loop
         Lex_BFS (G, S, Order);
         Check (Order (1) = S, "K3 start" & Vertex_Id'Image (S));
         Rev (1 .. 3) := Reverse_Order (Order, 3);
         Check (Is_PEO (G, Rev (1 .. 3)), "K3 PEO from" & Vertex_Id'Image (S));
      end loop;

      --  Wheel W5 (hub 1 + cycle 2-3-4-5-2) — chordal? W4 is K4; W5 has C4 on rim? 
      --  Wheel W_n often denotes hub + C_{n-1}. W5 = hub+C4 contains induced C4 → not chordal.
      Clear (G, 5);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 1, 4);
      Add_Edge (G, 1, 5);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5);
      Add_Edge (G, 5, 2);
      Lex_BFS (G, 1, Order);
      Check (Order (1) = 1, "W5 hub first");
      Check (Is_Permutation (Order, 5), "W5 permutation");
      Rev (1 .. 5) := Reverse_Order (Order, 5);
      Check (not Is_PEO (G, Rev (1 .. 5)), "W5 (hub+C4) reverse not PEO");

      --  Fan / triangulated path (chordal): 1—2—3—4 with chords 1—3, 2—4
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 4);
      Add_Edge (G, 1, 3);
      Add_Edge (G, 2, 4);
      Lex_BFS (G, 1, Order);
      Rev (1 .. 4) := Reverse_Order (Order, 4);
      Check (Is_PEO (G, Rev (1 .. 4)), "fan reverse PEO");
      Check (Is_Permutation (Order, 4), "fan permutation");
   end Test_Systematic;

   -------------------------------------------------------------------------
   -- 14. Order / PEO edge cases
   -------------------------------------------------------------------------

   procedure Test_PEO_Edge is
      G     : Graph;
      Order : Order_Array (1 .. 5);
      Id    : Order_Array (1 .. 3);
   begin
      Section ("14. PEO edge cases");

      Clear (G, 0);
      declare
         Empty_Order : constant Order_Array (1 .. 1) := [1];
      begin
         Check (Is_PEO (G, Empty_Order), "empty graph Is_PEO True");
      end;

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Id := [1, 2, 1];  -- only first 2 used
      Check (Is_PEO (G, Id (1 .. 2)), "P2 order 1,2 is PEO");
      Check (Is_PEO (G, Reverse_Order (Id (1 .. 2), 2)), "P2 order 2,1 is PEO");

      --  Edgeless: every order is PEO
      Clear (G, 4);
      Order := [3, 1, 4, 2, 1];
      Check (Is_PEO (G, Order (1 .. 4)), "edgeless arbitrary PEO");

      Lex_BFS (G, 4, Order);
      Check (Order (1) = 4, "edgeless Lex start 4");
      Check (Is_PEO (G, Order (1 .. 4)), "edgeless Lex order is PEO");
      Check (Is_PEO (G, Reverse_Order (Order, 4)), "edgeless reverse PEO");
   end Test_PEO_Edge;

begin
   Put_Line ("Lexicographic_Breadth_First_Search test suite");
   Put_Line ("==============================================");

   Test_Trivial;
   Test_Paths;
   Test_Cycles;
   Test_Complete;
   Test_Trees;
   Test_Chordal;
   Test_Disconnected;
   Test_API;
   Test_Invalid;
   Test_Lex_Properties;
   Test_Larger;
   Test_Clear_Reset;
   Test_Systematic;
   Test_PEO_Edge;

   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
