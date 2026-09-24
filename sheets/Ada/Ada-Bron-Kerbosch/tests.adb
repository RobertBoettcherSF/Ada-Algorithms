--  Standalone test suite for Bron_Kerbosch (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bron_Kerbosch; use Bron_Kerbosch;

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
     (G : in out Graph; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Adj_Raises
     (G : Graph; U, V : Vertex_Id) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_Adjacent (G, U, V);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Adj_Raises;

   function Set_Size_Raises (N : Natural) return Boolean is
      S : constant Vertex_Set := [others => False];
      Unused : Natural;
   begin
      Unused := Set_Size (S, N);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Size_Raises;

   -------------------------------------------------------------------------
   -- Brute-force count of maximal cliques for N ≤ 10
   -------------------------------------------------------------------------

   function Brute_Maximal_Count (G : Graph) return Natural is
      N : constant Natural := Vertex_Count (G);
      Total : Natural := 0;

      function Bit (Mask, I : Natural) return Boolean is
        ((Mask / (2 ** I)) mod 2 = 1);

      function Subset_Is_Clique (Mask : Natural) return Boolean is
      begin
         for I in 0 .. N - 1 loop
            if Bit (Mask, I) then
               for J in I + 1 .. N - 1 loop
                  if Bit (Mask, J) then
                     if not Is_Adjacent
                       (G, Vertex_Id (I + 1), Vertex_Id (J + 1))
                     then
                        return False;
                     end if;
                  end if;
               end loop;
            end if;
         end loop;
         return True;
      end Subset_Is_Clique;

      function Is_Maximal_Mask (Mask : Natural) return Boolean is
      begin
         if Mask = 0 then
            return False;
         end if;
         if not Subset_Is_Clique (Mask) then
            return False;
         end if;
         for V in 0 .. N - 1 loop
            if not Bit (Mask, V) then
               declare
                  Ok : Boolean := True;
               begin
                  for U in 0 .. N - 1 loop
                     if Bit (Mask, U) then
                        if not Is_Adjacent
                          (G, Vertex_Id (U + 1), Vertex_Id (V + 1))
                        then
                           Ok := False;
                           exit;
                        end if;
                     end if;
                  end loop;
                  if Ok then
                     return False;
                  end if;
               end;
            end if;
         end loop;
         return True;
      end Is_Maximal_Mask;

   begin
      if N = 0 then
         return 0;
      end if;
      if N > 10 then
         raise Program_Error;
      end if;
      for Mask in 0 .. (2 ** N) - 1 loop
         if Is_Maximal_Mask (Mask) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Brute_Maximal_Count;

   function Clique_To_Mask (S : Vertex_Set; N : Natural) return Natural is
      M : Natural := 0;
   begin
      for I in 1 .. N loop
         if S (Vertex_Id (I)) then
            M := M + 2 ** (I - 1);
         end if;
      end loop;
      return M;
   end Clique_To_Mask;

   procedure Check_Enumeration
     (G : Graph; Expect : Natural; Label : String)
   is
      Cliques : Clique_List;
      Count   : Natural;
      N       : constant Natural := Vertex_Count (G);
      Seen    : array (0 .. 2 ** 10 - 1) of Boolean := [others => False];
      --  Seen sized for N≤10 uniqueness checks; for larger Expect we
      --  only verify Count / maximality / Is_Clique.
   begin
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = Expect, Label & " count = expected");
      Check (Maximal_Clique_Count (G) = Expect,
             Label & " Maximal_Clique_Count");

      for K in 1 .. Count loop
         Check (Is_Clique (G, Cliques.Items (K)),
                Label & " clique" & Natural'Image (K) & " Is_Clique");
         if Expect > 0 or else N > 0 then
            Check (Is_Maximal_Clique (G, Cliques.Items (K)),
                   Label & " clique" & Natural'Image (K) & " maximal");
         end if;
         Check (Set_Size (Cliques.Items (K), N) >= 1
                or else N = 0,
                Label & " clique" & Natural'Image (K) & " nonempty");
      end loop;

      --  Uniqueness for small N
      if N <= 10 and then Count <= Expect then
         for K in 1 .. Count loop
            declare
               M : constant Natural := Clique_To_Mask (Cliques.Items (K), N);
            begin
               Check (not Seen (M),
                      Label & " unique mask" & Natural'Image (M));
               Seen (M) := True;
            end;
         end loop;
      end if;
   end Check_Enumeration;

   procedure Check_Vs_Brute (G : Graph; Label : String) is
      B : constant Natural := Brute_Maximal_Count (G);
   begin
      Check_Enumeration
        (G, B, Label & " (brute=" & Natural'Image (B) & ")");
   end Check_Vs_Brute;

   procedure Make_Complete (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
   end Make_Complete;

   procedure Make_Path (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
   end Make_Path;

   procedure Make_Cycle (G : in out Graph; N : Natural) is
   begin
      Make_Path (G, N);
      if N >= 3 then
         Add_Edge (G, Vertex_Id (1), Vertex_Id (N));
      end if;
   end Make_Cycle;

   procedure Make_Star (G : in out Graph; N : Natural) is
   begin
      Clear (G, N);
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
   end Make_Star;

   procedure Make_Bipartite_Complete
     (G : in out Graph; A, B : Natural)
   is
      N : constant Natural := A + B;
   begin
      Clear (G, N);
      for I in 1 .. A loop
         for J in A + 1 .. N loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
   end Make_Bipartite_Complete;

   -------------------------------------------------------------------------
   -- 1. Empty / single / no edges
   -------------------------------------------------------------------------

   procedure Test_Trivial is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Section ("1. Empty / single / no edges");

      Clear (G, 0);
      Check (Vertex_Count (G) = 0, "empty Vertex_Count = 0");
      Check (Edge_Count (G) = 0, "empty Edge_Count = 0");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 0, "empty Count = 0");
      Check (Maximal_Clique_Count (G) = 0, "empty Maximal_Clique_Count = 0");

      Clear (G, 1);
      Check (Vertex_Count (G) = 1, "single Vertex_Count = 1");
      Check (Edge_Count (G) = 0, "single Edge_Count = 0");
      Check_Enumeration (G, 1, "single vertex");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 1 and then Cliques.Items (1) (1),
             "single clique is {1}");

      Clear (G, 5);
      Check_Enumeration (G, 5, "5 isolates");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      declare
         Seen : array (1 .. 5) of Boolean := [others => False];
      begin
         for K in 1 .. Count loop
            Check (Set_Size (Cliques.Items (K), 5) = 1,
                   "isolate clique" & Natural'Image (K) & " size 1");
            for V in 1 .. 5 loop
               if Cliques.Items (K) (Vertex_Id (V)) then
                  Seen (V) := True;
               end if;
            end loop;
         end loop;
         Check (Seen (1) and Seen (2) and Seen (3) and Seen (4) and Seen (5),
                "all 5 isolates reported");
      end;

      Clear (G, 1);
      Add_Edge (G, 1, 1);
      Check (Edge_Count (G) = 0, "self-loop ignored");
      Check_Enumeration (G, 1, "self-loop only");

      Clear (G, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 1);
      Check (Edge_Count (G) = 1, "duplicates ignored → 1 edge");
      Check (Is_Adjacent (G, 1, 2), "adjacent after Add_Edge");
      Check (Is_Adjacent (G, 2, 1), "adjacency symmetric");
      Check (not Is_Adjacent (G, 1, 1), "not adjacent to self");
      Check_Enumeration (G, 1, "single edge K2 → 1 maximal clique");
   end Test_Trivial;

   -------------------------------------------------------------------------
   -- 2. Triangles and complete Kn
   -------------------------------------------------------------------------

   procedure Test_Complete is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Section ("2. Triangles and complete Kn");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      Check (Edge_Count (G) = 3, "triangle 3 edges");
      Check_Enumeration (G, 1, "triangle K3 → 1 clique");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 1
             and then Cliques.Items (1) (1)
             and then Cliques.Items (1) (2)
             and then Cliques.Items (1) (3),
             "triangle clique is {1,2,3}");
      Check_Vs_Brute (G, "triangle");

      for N in 1 .. 8 loop
         Make_Complete (G, N);
         Check (Edge_Count (G) = N * (N - 1) / 2,
                "K" & Natural'Image (N) & " edge count");
         Check_Enumeration (G, 1, "K" & Natural'Image (N) & " → 1 clique");
         Enumerate_Maximal_Cliques (G, Cliques, Count);
         Check (Set_Size (Cliques.Items (1), N) = N,
                "K" & Natural'Image (N) & " clique size = N");
         Check_Vs_Brute (G, "K" & Natural'Image (N));
      end loop;

      Make_Complete (G, 12);
      Check_Enumeration (G, 1, "K12 → 1 clique");
   end Test_Complete;

   -------------------------------------------------------------------------
   -- 3. Paths, cycles, stars
   -------------------------------------------------------------------------

   procedure Test_Sparse is
      G : Graph;
   begin
      Section ("3. Paths / cycles / stars");

      --  Path Pn: n-1 maximal edge-cliques
      Make_Path (G, 2);
      Check_Enumeration (G, 1, "P2");
      Make_Path (G, 3);
      Check_Enumeration (G, 2, "P3 → 2 edges");
      Check_Vs_Brute (G, "P3");
      Make_Path (G, 8);
      Check_Enumeration (G, 7, "P8 → 7 edges");
      Check_Vs_Brute (G, "P8");

      Make_Cycle (G, 3);
      Check_Enumeration (G, 1, "C3 → 1 triangle");
      Make_Cycle (G, 4);
      Check_Enumeration (G, 4, "C4 → 4 edges");
      Check_Vs_Brute (G, "C4");
      Make_Cycle (G, 5);
      Check_Enumeration (G, 5, "C5 → 5 edges");
      Check_Vs_Brute (G, "C5");
      Make_Cycle (G, 6);
      Check_Enumeration (G, 6, "C6 → 6 edges");

      --  Star: n-1 edge maximal cliques
      Make_Star (G, 5);
      Check_Enumeration (G, 4, "star S5 → 4 edges");
      Check_Vs_Brute (G, "star S5");
      Make_Star (G, 10);
      Check_Enumeration (G, 9, "star S10 → 9 edges");
   end Test_Sparse;

   -------------------------------------------------------------------------
   -- 4. Bipartite (edges as size-2 maximal cliques)
   -------------------------------------------------------------------------

   procedure Test_Bipartite is
      G : Graph;
   begin
      Section ("4. Bipartite (edges as maximal cliques)");

      Make_Bipartite_Complete (G, 2, 2);
      Check_Enumeration (G, 4, "K2,2 → 4 edges");
      Check_Vs_Brute (G, "K2,2");

      Make_Bipartite_Complete (G, 3, 3);
      Check_Enumeration (G, 9, "K3,3 → 9 edges");
      Check_Vs_Brute (G, "K3,3");

      Make_Bipartite_Complete (G, 2, 4);
      Check_Enumeration (G, 8, "K2,4 → 8 edges");
      Check_Vs_Brute (G, "K2,4");

      Make_Path (G, 7);
      Check_Enumeration (G, 6, "P7 bipartite → 6 edges");
   end Test_Bipartite;

   -------------------------------------------------------------------------
   -- 5. Composite / known patterns
   -------------------------------------------------------------------------

   procedure Test_Composite is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Section ("5. Composite / known patterns");

      --  Two disjoint edges → 2 maximal cliques
      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 3, 4);
      Check_Enumeration (G, 2, "2 disjoint edges");
      Check_Vs_Brute (G, "2 edges");

      --  Two triangles sharing a vertex (bowtie)
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4); Add_Edge (G, 4, 5); Add_Edge (G, 5, 1);
      Check_Enumeration (G, 2, "bowtie → 2 triangles");
      Check_Vs_Brute (G, "bowtie");
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 2, "bowtie count again");
      Check (Set_Size (Cliques.Items (1), 5) = 3
             and then Set_Size (Cliques.Items (2), 5) = 3,
             "bowtie both size 3");

      --  Two triangles sharing an edge
      Clear (G, 4);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 2, 4); Add_Edge (G, 4, 3);
      Check_Enumeration (G, 2, "diamond minus edge → 2 triangles");
      Check_Vs_Brute (G, "2 tri share edge");

      --  K4 plus pendant: maximal = K4 and the pendant edge? 
      --  Pendant edge {4,5}: 5 only adjacent to 4, so {4,5} is maximal.
      --  K4 on {1..4} is maximal. → 2 maximal cliques.
      Clear (G, 5);
      for I in 1 .. 4 loop
         for J in I + 1 .. 4 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      Add_Edge (G, 4, 5);
      Check_Enumeration (G, 2, "K4 + pendant → 2 maximal");
      Check_Vs_Brute (G, "K4+pendant");

      --  House: square 1-2-3-4-1 with roof 1-5-2
      --  Maximal: triangle {1,2,5}, edges {2,3},{3,4},{4,1}
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 1); Add_Edge (G, 1, 5); Add_Edge (G, 2, 5);
      Check_Vs_Brute (G, "house");

      --  Wheel W6 = C5 + hub
      Clear (G, 6);
      for I in 2 .. 6 loop
         Add_Edge (G, 1, Vertex_Id (I));
      end loop;
      for I in 2 .. 5 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, 6, 2);
      --  5 triangles (hub + each rim edge)
      Check_Enumeration (G, 5, "wheel W6 → 5 triangles");
      Check_Vs_Brute (G, "wheel W6");

      --  Disjoint K3 ∪ K3
      Clear (G, 6);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5); Add_Edge (G, 5, 6); Add_Edge (G, 6, 4);
      Check_Enumeration (G, 2, "2 disjoint triangles");
      Check_Vs_Brute (G, "2 K3");

      --  K3 plus an isolated vertex → 2 maximal (triangle + singleton)
      Clear (G, 4);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Check_Enumeration (G, 2, "K3 + isolate");
      Check_Vs_Brute (G, "K3+isolate");
   end Test_Composite;

   -------------------------------------------------------------------------
   -- 6. Brute-force battery (n ≤ 10)
   -------------------------------------------------------------------------

   procedure Test_Brute_Battery is
      G : Graph;
   begin
      Section ("6. Brute-force battery n≤10");

      for N in 0 .. 8 loop
         Clear (G, N);
         Check_Vs_Brute (G, "edgeless n=" & Natural'Image (N));
      end loop;

      for N in 3 .. 9 loop
         Make_Path (G, N);
         Check_Vs_Brute (G, "path n=" & Natural'Image (N));
         Make_Cycle (G, N);
         Check_Vs_Brute (G, "cycle n=" & Natural'Image (N));
         Make_Star (G, N);
         Check_Vs_Brute (G, "star n=" & Natural'Image (N));
      end loop;

      for N in 4 .. 9 loop
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 7 + J * 3) mod 5) < 2 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "pattern A n=" & Natural'Image (N));
      end loop;

      for N in 4 .. 9 loop
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 5 + J * 11) mod 7) < 3 then
                  Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
               end if;
            end loop;
         end loop;
         Check_Vs_Brute (G, "pattern B n=" & Natural'Image (N));
      end loop;

      Clear (G, 8);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 4, 5); Add_Edge (G, 6, 7);
      Add_Edge (G, 3, 4); Add_Edge (G, 5, 8);
      Check_Vs_Brute (G, "nested K3 sparse");
   end Test_Brute_Battery;

   -------------------------------------------------------------------------
   -- 7. API / Invalid_Argument / Too_Many_Cliques / reset
   -------------------------------------------------------------------------

   procedure Test_API is
      G       : Graph;
      Cliques : Clique_List;
      Count   : Natural;
      S       : Vertex_Set := [others => False];
   begin
      Section ("7. API / Invalid_Argument / reset");

      Check (Clear_Raises (Nat (Max_Vertices + 1)),
             "Clear(Max_Vertices+1) raises");
      Check (Clear_Raises (Nat (1000)), "Clear(1000) raises");
      Check (not Clear_Raises (Nat (Max_Vertices)),
             "Clear(Max_Vertices) ok");
      Check (not Clear_Raises (Nat (0)), "Clear(0) ok");

      Clear (G, 3);
      Check (Add_Raises (G, 1, 4), "Add_Edge out of range raises");
      Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");
      Check (Adj_Raises (G, 1, 4), "Is_Adjacent out of range");
      Check (Set_Size_Raises (Nat (Max_Vertices + 1)),
             "Set_Size overflow raises");

      Clear (G, 0);
      Check (Add_Raises (G, 1, 2), "Add_Edge on empty raises");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      Check (Edge_Count (G) = 1, "before Clear edge=1");
      Clear (G, 4);
      Check (Edge_Count (G) = 0, "after Clear edge=0");
      Check (Vertex_Count (G) = 4, "after Clear N=4");
      Check_Enumeration (G, 4, "after Clear edgeless → 4 singletons");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 2, "P3 count 2");
      Check (Is_Maximal_Clique (G, Cliques.Items (1)), "P3 #1 maximal");
      Check (Is_Maximal_Clique (G, Cliques.Items (2)), "P3 #2 maximal");

      Check (Nat (Max_Vertices) = Nat (64), "Max_Vertices = 64");
      Check (Nat (Max_Cliques) = Nat (10_000), "Max_Cliques = 10000");
      Check (Nat (Natural (Vertex_Id'Last)) = Nat (Max_Vertices),
             "Vertex_Id'Last");

      --  Is_Maximal_Clique negatives
      Make_Complete (G, 3);
      S := [others => False];
      Check (not Is_Maximal_Clique (G, S), "empty not maximal");
      S (1) := True;
      Check (not Is_Maximal_Clique (G, S), "singleton in K3 not maximal");
      S (2) := True;
      Check (not Is_Maximal_Clique (G, S), "edge in K3 not maximal");
      S (3) := True;
      Check (Is_Maximal_Clique (G, S), "full K3 is maximal");

      Clear (G, 3);
      Add_Edge (G, 1, 2);
      S := [others => False];
      S (1) := True;
      S (2) := True;
      S (3) := True;
      Check (not Is_Clique (G, S), "non-clique detected");
      Check (not Is_Maximal_Clique (G, S), "non-clique not maximal");
   end Test_API;

   -------------------------------------------------------------------------
   -- 8. Larger educational instances (no brute)
   -------------------------------------------------------------------------

   procedure Test_Larger is
      G : Graph;
   begin
      Section ("8. Larger instances (no brute)");

      Make_Complete (G, 20);
      Check_Enumeration (G, 1, "K20");

      Make_Complete (G, 32);
      Check_Enumeration (G, 1, "K32");

      Make_Path (G, 40);
      Check_Enumeration (G, 39, "P40 → 39 edges");

      Make_Star (G, 50);
      Check_Enumeration (G, 49, "S50 → 49 edges");

      Make_Bipartite_Complete (G, 5, 5);
      Check_Enumeration (G, 25, "K5,5 → 25 edges");

      Make_Cycle (G, 30);
      Check_Enumeration (G, 30, "C30 → 30 edges");

      --  Clique of size 8 inside n=40 with path extras
      Clear (G, 40);
      for I in 1 .. 8 loop
         for J in I + 1 .. 8 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J));
         end loop;
      end loop;
      for I in 9 .. 39 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
      end loop;
      Add_Edge (G, 8, 9);
      --  Maximal: K8, edge {8,9}, and path edges {9,10}..{39,40}
      --  {8,9} is maximal (9 not in K8 neighbourhood fully — 9 only
      --  adjacent to 8 among 1..8). Path edges are maximal.
      --  Count = 1 (K8) + 1 ({8,9}) + 31 (edges 9-10 .. 39-40) = 33
      Check_Enumeration (G, 33, "K8 + path tail");

      Make_Complete (G, 64);
      Check_Enumeration (G, 1, "K64 capacity");

      Clear (G, 64);
      Check_Enumeration (G, 64, "64 isolates");
   end Test_Larger;

   -------------------------------------------------------------------------
   -- 9. Helpers / size consistency
   -------------------------------------------------------------------------

   procedure Test_Helpers is
      G : Graph;
      S : Vertex_Set := [others => False];
      Cliques : Clique_List;
      Count   : Natural;
   begin
      Section ("9. Is_Clique / Is_Maximal / Set_Size helpers");

      Make_Complete (G, 4);
      Check (Is_Clique (G, S), "empty set is clique");
      S (1) := True;
      Check (Is_Clique (G, S), "singleton is clique");
      Check (Set_Size (S, 4) = 1, "Set_Size singleton");
      S (2) := True;
      Check (Is_Clique (G, S), "edge is clique in K4");
      S (3) := True;
      S (4) := True;
      Check (Is_Clique (G, S), "all of K4 is clique");
      Check (Set_Size (S, 4) = 4, "Set_Size 4");
      Check (Is_Maximal_Clique (G, S), "K4 full maximal");

      Clear (G, 4);
      Add_Edge (G, 1, 2);
      S := [others => False];
      S (1) := True;
      S (2) := True;
      S (3) := True;
      Check (not Is_Clique (G, S), "non-clique detected");

      --  Every enumerated clique has consistent Set_Size
      Make_Star (G, 6);
      Enumerate_Maximal_Cliques (G, Cliques, Count);
      Check (Count = 5, "S6 count 5");
      for K in 1 .. Count loop
         Check (Set_Size (Cliques.Items (K), 6) = 2,
                "S6 clique" & Natural'Image (K) & " size 2");
         Check (Cliques.Items (K) (1),
                "S6 clique" & Natural'Image (K) & " contains hub");
      end loop;
   end Test_Helpers;

   -------------------------------------------------------------------------
   -- 10. Extra named counts
   -------------------------------------------------------------------------

   procedure Test_Extra_Counts is
      G : Graph;
   begin
      Section ("10. Extra named counts");

      --  Moon–Moser extremal small: complement of triangle matching
      --  Three disjoint edges' complement on 6 verts has 2^3 = 8? 
      --  Actually the classic Moon–Moser graph is the complement of
      --  n/3 disjoint triangles... skip; use known small counts.

      --  Petersen is 10 verts / 15 edges; maximal cliques are all edges
      --  (triangle-free, girth 5) → 15 maximal cliques.
      Clear (G, 10);
      --  Outer pentagon
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 4);
      Add_Edge (G, 4, 5); Add_Edge (G, 5, 1);
      --  Spokes
      Add_Edge (G, 1, 6); Add_Edge (G, 2, 7); Add_Edge (G, 3, 8);
      Add_Edge (G, 4, 9); Add_Edge (G, 5, 10);
      --  Inner star pentagram
      Add_Edge (G, 6, 8); Add_Edge (G, 8, 10); Add_Edge (G, 10, 7);
      Add_Edge (G, 7, 9); Add_Edge (G, 9, 6);
      Check (Edge_Count (G) = 15, "Petersen 15 edges");
      Check_Enumeration (G, 15, "Petersen → 15 edge-cliques");
      Check_Vs_Brute (G, "Petersen");

      --  Complete multipartite K1,1,1 = triangle
      Clear (G, 3);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Check_Enumeration (G, 1, "K1,1,1");

      --  Bull graph: triangle with two pendants on distinct vertices
      Clear (G, 5);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4); Add_Edge (G, 2, 5);
      Check_Vs_Brute (G, "bull");

      --  Butterfly = bowtie already tested; claw K1,3
      Make_Star (G, 4);
      Check_Enumeration (G, 3, "claw K1,3");
      Check_Vs_Brute (G, "claw");

      --  Net graph-ish: triangle with pendant on each vertex
      Clear (G, 6);
      Add_Edge (G, 1, 2); Add_Edge (G, 2, 3); Add_Edge (G, 3, 1);
      Add_Edge (G, 1, 4); Add_Edge (G, 2, 5); Add_Edge (G, 3, 6);
      Check_Vs_Brute (G, "triangle+3 pendants");
   end Test_Extra_Counts;

begin
   Put_Line ("Bron_Kerbosch Ada 2023 — test suite");
   Put_Line ("Max_Vertices =" & Positive'Image (Max_Vertices)
             & "  Max_Cliques =" & Positive'Image (Max_Cliques));

   Test_Trivial;
   Test_Complete;
   Test_Sparse;
   Test_Bipartite;
   Test_Composite;
   Test_Brute_Battery;
   Test_API;
   Test_Larger;
   Test_Helpers;
   Test_Extra_Counts;

   New_Line;
   Put_Line ("Results: "
             & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
